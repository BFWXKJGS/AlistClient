import 'dart:async';
import 'dart:io';

import 'package:alist/util/constant.dart';
import 'package:flustars/flustars.dart';

/// 使用代理服务器规避重定向后header设置失效、下载链接有效期过短等问题
class ProxyServer {
  static const tag = "ProxyServer";
  static const headerFlag = "alistheader_";
  static const defaultPort = 28080;
  var _port = defaultPort;
  HttpClient? _httpClient;

  HttpServer? _httpServer;
  final _redirectCache = <String, RedirectCacheValue>{};

  // 通过 key 保存请求返回的内容，目前暂时用于 markdown 内容的保存
  final _content = <String, String>{};
  static const _maxRedirectTimes = 20;

  // 正在代理的链接数量
  var _runningConnectionsCnt = 0;

  void _handleRequest(HttpRequest request) async {
    var httpClient = _httpClient;
    final targetUrl = request.uri.queryParameters['targetUrl'];
    final contentKey = request.uri.queryParameters['contentKey'];
    LogUtil.d("targetUrl=$targetUrl");
    LogUtil.d("contentKey=$contentKey");
    final hasTargetUrl = !(targetUrl == null || targetUrl.isEmpty);
    final hasContentKey = !(contentKey == null || contentKey.isEmpty);

    if (httpClient == null || (!hasTargetUrl && !hasContentKey)) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.close();
      return;
    }
    if (hasContentKey) {
      _writeContentResponse(contentKey, request);
      return;
    }

    final extraHeaders = <String, String>{};
    request.uri.queryParameters.forEach((key, value) {
      if (key.startsWith(headerFlag)) {
        extraHeaders[key.substring(headerFlag.length)] = value;
      }
    });

    RedirectCacheValue? redirectCacheValue =
        _findValidRedirectCacheValue(targetUrl!);
    Uri uri;
    if (redirectCacheValue != null) {
      uri = Uri.parse(redirectCacheValue.target);
    } else {
      uri = Uri.parse(targetUrl);
    }

    var isRequestDone = false;
    var requestDoneFuture =
        request.response.done.then((value) => isRequestDone = true);

    var httpClientRequest = await httpClient.openUrl(request.method, uri);
    httpClientRequest.followRedirects = false;

    // Copy all request headers.
    request.headers.forEach((String name, List<String> values) {
      if (_isValidRequestHeader(name)) {
        httpClientRequest.headers.set(name, values);
      }
      // LogUtil.d("header $name=$values", tag: tag);
    });
    extraHeaders.forEach((key, value) {
      // LogUtil.d("extraHeader $key=$value", tag: tag);
      httpClientRequest.headers.set(key, value);
    });

    // 非重定向情况 copy 请求体
    if (redirectCacheValue == null) {
      // Copy request body to httpClientRequest
      Completer copyingCompleter = Completer();
      request.listen(
        (List<int> data) {
          httpClientRequest.add(data);
        },
        onDone: () => copyingCompleter.complete(),
        onError: (e) => copyingCompleter.completeError(e),
      );
      await copyingCompleter.future;
    }

    var redirectTimes = 0;
    var httpClientResponse = await httpClientRequest.close();
    while (_httpServer != null &&
        httpClientResponse.isRedirect &&
        redirectTimes < _maxRedirectTimes) {
      redirectTimes++;
      httpClientResponse.drain();
      var location =
          httpClientResponse.headers.value(HttpHeaders.locationHeader);
      if (location != null) {
        _addRedirectCache(uri, location);
      }

      // 循环查询重定向缓存
      location = _findTheFinalLocationFromCache(location);

      if (location != null) {
        uri = uri.resolve(location);
        httpClientRequest = await httpClient.getUrl(uri);
        // Set the body or headers as desired.
        httpClientRequest.followRedirects = false;
        request.headers.forEach((String name, List<String> values) {
          // LogUtil.d("header $name=$values", tag: tag);
          if (_isValidRequestHeader(name)) {
            httpClientRequest.headers.set(name, values);
          }
        });
        extraHeaders.forEach((key, value) {
          // LogUtil.d("extraHeader $key=$value", tag: tag);
          httpClientRequest.headers.set(key, value);
        });
        httpClientResponse = await httpClientRequest.close();
      } else {
        break;
      }
    }

    if (isRequestDone) {
      httpClientRequest.close();
      return;
    }

    if (_httpServer != null) {
      requestDoneFuture.then((value) {
        LogUtil.d("request is done, so close", tag: tag);
        httpClientRequest.close();
        request.response.close();
      });

      request.response.statusCode = httpClientResponse.statusCode;
      httpClientResponse.headers.forEach((name, values) {
        request.response.headers
            .set(name, values.map((e) => Uri.encodeComponent(e)));
      });

      _runningConnectionsCnt++;
      LogUtil.d("runningConnectionsCnt=$_runningConnectionsCnt", tag: tag);
      await httpClientResponse.pipe(request.response);
      _runningConnectionsCnt--;
      LogUtil.d("runningConnectionsCnt=$_runningConnectionsCnt", tag: tag);
    } else {
      httpClientRequest.close();
      request.response.statusCode = HttpStatus.serviceUnavailable;
      request.response.close();
    }
    _clearInvalidRedirectCache();
  }

  void _writeContentResponse(String contentKey, HttpRequest request) {
    var contentValue = _content[contentKey];
    request.response.headers
        .set(HttpHeaders.accessControlAllowOriginHeader, "*");
    request.response.headers
        .set(HttpHeaders.accessControlAllowMethodsHeader, "GET");
    request.response.headers
        .set(HttpHeaders.accessControlAllowCredentialsHeader, true);
    if (contentValue == null) {
      request.response.statusCode = HttpStatus.notFound;
      request.response.close();
    } else {
      request.response.statusCode = HttpStatus.ok;
      request.response.write(contentValue);
      request.response.close();
    }
  }

  String? _findTheFinalLocationFromCache(String? location) {
    RedirectCacheValue? redirectCacheValue;
    do {
      if (location == null) {
        break;
      }
      redirectCacheValue = _findValidRedirectCacheValue(location);
      if (redirectCacheValue != null) {
        location = redirectCacheValue.target;
      }
    } while (redirectCacheValue != null);
    return location;
  }

  bool _isValidRequestHeader(String name) =>
      name.toLowerCase() != "host" && name.toLowerCase() != "x-device-id";

  // 清除已过期的重定向缓存
  void _clearInvalidRedirectCache() {
    var currentMillisecond = DateTime.now().millisecondsSinceEpoch;
    var invalidKeys = <String>[];
    _redirectCache.forEach((key, value) {
      if (value.validTime < currentMillisecond) {
        invalidKeys.add(key);
      }
    });
    for (var key in invalidKeys) {
      _redirectCache.remove(key);
    }
  }

  // 添加一个缓存
  void _addRedirectCache(Uri uri, String location) {
    var validTime = DateTime.now().millisecondsSinceEpoch + 10 * 60 * 1000;
    _redirectCache[uri.toString()] = RedirectCacheValue(location, validTime);
  }

  // 查询到一个有效期内的缓存
  RedirectCacheValue? _findValidRedirectCacheValue(String targetUrl) {
    var redirectCacheValue = _redirectCache[targetUrl];
    if (redirectCacheValue != null) {
      var currentMillisecond = DateTime.now().millisecondsSinceEpoch;
      if (redirectCacheValue.validTime < currentMillisecond) {
        // 无效缓存
        _redirectCache.remove(targetUrl);
        redirectCacheValue = null;
      } else {
        LogUtil.d("缓存命中 $targetUrl", tag: tag);
      }
    }
    return redirectCacheValue;
  }

  Future<void> start({int port = defaultPort}) async {
    if (_httpServer != null) {
      LogUtil.d("server is already started", tag: tag);
      return;
    }

    HttpServer? server;
    try {
      server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    } catch (e) {
      await start(port: port + 1);
      return;
    }
    if (_httpServer != null) {
      server.close(force: true);
      return;
    }

    _httpClient = _createHttpClient();
    _port = port;
    _httpServer = server;
    _handRequests(server);
  }

  Future<void> _handRequests(HttpServer server) async {
    await for (HttpRequest request in server) {
      try {
        _handleRequest(request);
      } catch (e) {
        _closeRequest(request, e);
      }
    }
  }

  Future<void> _closeRequest(HttpRequest request, Object e) async {
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write('Unexpected error: $e');
    await request.response.close();
  }

  Uri makeProxyUrl(String targetUrl, {Map<String, String>? headers}) {
    if (_httpServer == null) throw Exception("Proxy server is not started");
    var queryParameters = {"targetUrl": targetUrl};
    headers?.forEach((key, value) {
      queryParameters["$headerFlag$key"] = value;
    });

    return Uri(
      scheme: "http",
      host: "127.0.0.1",
      port: _port,
      queryParameters: queryParameters,
    );
  }

  Uri makeContentUri(String key, String value) {
    if (_httpServer == null) throw Exception("Proxy server is not started");
    var encodeKey = Uri.encodeComponent(key);
    _content[encodeKey] = value;

    var queryParameters = {"contentKey": encodeKey};
    return Uri(
      scheme: "http",
      host: "127.0.0.1",
      port: _port,
      queryParameters: queryParameters,
    );
  }

  Future<void> stop() async {
    var httpServer = _httpServer;
    var httpClient = _httpClient;
    _httpServer = null;
    _httpClient = null;
    _content.clear();
    await httpServer?.close(force: true);
    try {
      httpClient?.close(force: true);
    } catch (e) {
      // ignore error
    }
    LogUtil.d("stop proxy server", tag: tag);
  }
}

HttpClient _createHttpClient() {
  var httpClient = HttpClient();
  httpClient.autoUncompress = false;
  httpClient.badCertificateCallback = (cert, host, port) {
    if (SpUtil.getBool(AlistConstant.ignoreSSLError) ?? false) {
      return true;
    }
    return false;
  };
  return httpClient;
}

class RedirectCacheValue {
  String target;
  int validTime;

  RedirectCacheValue(this.target, this.validTime);
}
