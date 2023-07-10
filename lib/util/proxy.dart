import 'dart:async';
import 'dart:io';

import 'package:flustars/flustars.dart';

/// 使用代理服务器规避重定向后header设置失效、下载链接有效期过短等问题
class ProxyServer {
  static const tag = "ProxyServer";
  static const defaultPort = 28080;
  var _port = defaultPort;
  final _httpClient = HttpClient();
  HttpServer? _httpServer;
  final _redirectCache = <String, RedirectCacheValue>{};
  static const _maxRedirectTimes = 10;

  void _handleRequest(HttpRequest request) async {
    final targetUrl = request.uri.queryParameters['targetUrl']!;
    final extraHeaders = <String, String>{};
    request.uri.queryParameters.forEach((key, value) {
      if (key.startsWith("alistheader_")) {
        extraHeaders[key.substring("alistheader_".length)] = value;
      }
    });

    RedirectCacheValue? redirectCacheValue =
        _findValidRedirectCacheValue(targetUrl);
    Uri uri;
    if (redirectCacheValue != null) {
      uri = Uri.parse(redirectCacheValue.target);
    } else {
      uri = Uri.parse(targetUrl);
    }

    _httpClient.autoUncompress = false;
    var httpClientRequest = await _httpClient.openUrl(request.method, uri);
    httpClientRequest.followRedirects = false;

    // Copy all request headers.
    request.headers.forEach((String name, List<String> values) {
      if (_isValidRequestHeader(name)) {
        httpClientRequest.headers.set(name, values);
      }
      LogUtil.d("header $name=$values", tag: tag);
    });
    extraHeaders.forEach((key, value) {
      LogUtil.d("extraHeader $key=$value", tag: tag);
      httpClientRequest.headers.set(key, value);
    });

    // 非重定向情况 copy 请求体
    if (redirectCacheValue == null) {
      // Copy request body to httpClientRequest
      Completer copyingCompleter = Completer();
      request.listen((List<int> data) {
        httpClientRequest.add(data);
      }, onDone: () => copyingCompleter.complete());
      await copyingCompleter.future;
    }

    var redirectTimes = 0;
    var httpClientResponse = await httpClientRequest.close();
    while (httpClientResponse.isRedirect && redirectTimes < _maxRedirectTimes) {
      redirectTimes++;
      httpClientResponse.drain();
      var location =
          httpClientResponse.headers.value(HttpHeaders.locationHeader);
      if (location != null) {
        _addRedirectCache(uri, location);
      }

      // 循环查询重定向缓存
      do {
        if (location == null) {
          break;
        }
        redirectCacheValue = _findValidRedirectCacheValue(location);
        if (redirectCacheValue != null) {
          location = redirectCacheValue.target;
        }
      } while (redirectCacheValue != null);

      if (location != null) {
        uri = uri.resolve(location);
        httpClientRequest = await _httpClient.getUrl(uri);
        // Set the body or headers as desired.
        httpClientRequest.followRedirects = false;
        request.headers.forEach((String name, List<String> values) {
          LogUtil.d("header $name=$values", tag: tag);
          if (_isValidRequestHeader(name)) {
            httpClientRequest.headers.set(name, values);
          }
        });
        extraHeaders.forEach((key, value) {
          LogUtil.d("extraHeader $key=$value", tag: tag);
          httpClientRequest.headers.set(key, value);
        });
        httpClientResponse = await httpClientRequest.close();
      } else {
        break;
      }
    }

    request.response.statusCode = httpClientResponse.statusCode;

    httpClientResponse.headers.forEach((name, values) {
      request.response.headers
          .set(name, values.map((e) => Uri.encodeComponent(e)));
    });

    await httpClientResponse.pipe(request.response);
    _clearInvalidRedirectCache();
  }

  bool _isValidRequestHeader(String name) =>
      name.toLowerCase() != "host" && name.toLowerCase() != "x-device-id";

  // 清除已过期的重定向缓存
  void _clearInvalidRedirectCache() {
    var currentMillisecond = DateTime.now().millisecond;
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
    var validTime = DateTime.now().millisecond + 10 * 60 * 1000;
    _redirectCache[uri.toString()] = RedirectCacheValue(location, validTime);
  }

  // 查询到一个有效期内的缓存
  RedirectCacheValue? _findValidRedirectCacheValue(String targetUrl) {
    var redirectCacheValue = _redirectCache[targetUrl];
    if (redirectCacheValue != null) {
      var currentMillisecond = DateTime.now().millisecond;
      if (redirectCacheValue.validTime < currentMillisecond) {
        // 无效缓存
        _redirectCache.remove(targetUrl);
        redirectCacheValue = null;
      } else {
        LogUtil.d("缓存命中 $targetUrl");
      }
    }
    return redirectCacheValue;
  }

  Future<void> start({int port = defaultPort}) async {
    if (_httpServer != null) {
      return;
    }

    HttpServer? server;
    try {
      server = await HttpServer.bind('127.0.0.1', port);
    } catch (e) {
      await start(port: port + 1);
      return;
    }
    if (_httpServer != null) {
      server.close();
      return;
    }

    _port = port;
    _httpServer = server;
    _handRequests(server);
  }

  Future<void> _handRequests(HttpServer server) async {
    await for (HttpRequest request in server) {
      _handleRequest(request);
    }
  }

  Uri makeProxyUrl(String targetUrl, {Map<String, String>? headers}) {
    if (_httpServer == null) throw Exception("Proxy server is not started");
    var queryParameters = {"targetUrl": targetUrl};
    headers?.forEach((key, value) {
      queryParameters["alistheader_$key"] = value;
    });

    return Uri(
      scheme: "http",
      host: "127.0.0.1",
      port: _port,
      queryParameters: queryParameters,
    );
  }

  Future<void> stop() async {
    var httpServer = _httpServer;
    _httpServer = null;
    await httpServer?.close();
    LogUtil.d("stop proxy server", tag: tag);
  }
}

class RedirectCacheValue {
  String target;
  int validTime;

  RedirectCacheValue(this.target, this.validTime);
}
