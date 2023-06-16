import 'dart:convert';
import 'dart:io';
import 'package:alist/net/json_parse_error.dart';
import 'package:alist/net/net_error_handler.dart';
import 'package:alist/net/redirect_exception.dart';
import 'package:alist/util/constant.dart';
import 'package:alist/util/log_utils.dart';
import 'package:alist/util/named_router.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/foundation.dart';
import 'package:get/route_manager.dart';

import 'base_entity.dart';

/// 默认dio配置
Duration _connectTimeout = const Duration(seconds: 15);
Duration _receiveTimeout = const Duration(seconds: 15);
Duration _sendTimeout = const Duration(seconds: 10);
String _baseUrl = '';
List<Interceptor> _interceptors = [];
bool? _ignoreSSLError;

/// 初始化Dio配置
void configDio(
    {Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    String? baseUrl,
    List<Interceptor>? interceptors,
    bool ignoreSSLError = false}) {
  _connectTimeout = connectTimeout ?? _connectTimeout;
  _receiveTimeout = receiveTimeout ?? _receiveTimeout;
  _sendTimeout = sendTimeout ?? _sendTimeout;
  _baseUrl = baseUrl ?? _baseUrl;
  _interceptors = interceptors ?? _interceptors;
  _ignoreSSLError = ignoreSSLError;
}

typedef NetSuccessCallback<T> = Function(T data);
typedef NetSuccessListCallback<T> = Function(List<T> data);
typedef NetErrorCallback = Function(int code, String msg);

/// @weilu https://github.com/simplezhli
class DioUtils {
  factory DioUtils() => _singleton;

  DioUtils._() {
    _dioInit();
  }

  void _dioInit({bool? ignoreSSLError}) {
    final BaseOptions options = BaseOptions(
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
      sendTimeout: _sendTimeout,

      /// dio默认json解析，这里指定返回UTF8字符串，自己处理解析。（可也以自定义Transformer实现）
      responseType: ResponseType.plain,
      validateStatus: (_) {
        // 不使用http状态码判断状态，使用AdapterInterceptor来处理（适用于标准REST风格）
        return true;
      },
      baseUrl: _baseUrl,
      //      contentType: Headers.formUrlEncodedContentType, // 适用于post form表单提交
    );
    _dio = Dio(options);

    ignoreSSLError ??= _ignoreSSLError;
    if (ignoreSSLError == true) {
      _dioIgnoreSSLError(dio);
      _dioIgnoreSSLError(_streamDio);
    } else {
      _streamDio.httpClientAdapter = IOHttpClientAdapter();
    }

    /// 添加拦截器
    void addInterceptor(Interceptor interceptor) {
      _dio.interceptors.add(interceptor);
      _streamDio.interceptors.add(interceptor);
    }

    _interceptors.forEach(addInterceptor);
  }

  static final DioUtils _singleton = DioUtils._();
  final Dio _streamDio = Dio();

  static DioUtils get instance => DioUtils();

  static late Dio _dio;

  Dio get dio => _dio;

  // 数据返回格式统一，统一处理异常
  Future<BaseEntity<T>> _request<T>(
    String method,
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) async {
    final Response<String> response = await _dio.request<String>(
      url,
      data: data,
      queryParameters: queryParameters,
      options: _checkOptions(method, options),
      cancelToken: cancelToken,
    );

    try {
      if (options?.followRedirects == false &&
          (response.statusCode == 301 ||
              response.statusCode == 302 ||
              response.statusCode == 307 ||
              response.statusCode == 308)) {
        for (var entity in response.headers.map.entries) {
          if (entity.key.toLowerCase() == "location") {
            if (entity.value.isNotEmpty) {
              throw RedirectException(entity.value.first);
            }
          }
        }
      }
      final String responseData = response.data.toString();

      /// 集成测试无法使用 isolate https://github.com/flutter/flutter/issues/24703
      /// 使用compute条件：数据大于10KB（粗略使用10 * 1024）且当前不是集成测试（后面可能会根据Web环境进行调整）
      /// 主要目的减少不必要的性能开销
      final bool isCompute =
          !AlistConstant.isDriverTest && responseData.length > 10 * 1024;
      Log.d('isCompute:$isCompute');
      final Map<String, dynamic> map = isCompute
          ? await compute(parseData, responseData)
          : parseData(responseData);
      return BaseEntity<T>.fromJson(map);
    } catch (e) {
      if (e is RedirectException) {
        rethrow;
      }
      throw JsonParseException(e.toString());
    }
  }

  void configAgain(String baseUrl, bool ignoreSSLError) {
    _baseUrl = baseUrl;
    _dioInit(ignoreSSLError: ignoreSSLError);
  }

  Options _checkOptions(String method, Options? options) {
    options ??= Options();
    options.method = method;
    return options;
  }

  Future<dynamic> requestNetwork<T>(
    Method method,
    String url, {
    NetSuccessCallback<T?>? onSuccess,
    NetErrorCallback? onError,
    Object? params,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) {
    return _request<T>(
      method.value,
      url,
      data: params,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    ).then<void>((BaseEntity<T> result) {
      if (cancelToken?.isCancelled != true) {
        if (result.code == 200) {
          onSuccess?.call(result.data);
        } else {
          if (result.code == 401) {
            Get.offAllNamed(NamedRouter.login);
          }
          _onError(result.code, result.message, onError);
        }
      }
    }, onError: (dynamic e) {
      LogUtil.d(e);
      if (cancelToken?.isCancelled != true) {
        _onError(e is RedirectException ? 301 : -1,
            NetErrorHandler.netErrorToMessage(e), onError);
      } else {
        _cancelLogPrint(e, url);
      }
    }).catchError((e) {
      if (cancelToken?.isCancelled != true) {
        _onError(e is RedirectException ? 301 : -1,
            NetErrorHandler.netErrorToMessage(e), onError);
      }
    });
  }

  Future<Response> download(
    String urlPath,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
  }) {
    return _streamDio.download(
      urlPath,
      savePath,
      onReceiveProgress: onReceiveProgress,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      deleteOnError: deleteOnError,
      lengthHeader: lengthHeader,
      data: data,
      options: options,
    );
  }

  Future<Response<Map<String, dynamic>>> upload(
    String urlPath,
    File file,
    String remotePath, {
    ProgressCallback? onSendProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) {
    var fileStream = file.openRead();
    options = options ?? Options();
    options.headers ??= {};
    options.headers!.addAll({
      "File-Path": remotePath,
      Headers.contentTypeHeader: "application/octet-stream",
      Headers.contentLengthHeader: file.lengthSync(),
    });

    var url = urlPath;
    if (!url.startsWith("http://") && !url.startsWith("https://")) {
      url = "${SpUtil.getString(AlistConstant.baseUrl)}$urlPath";
    }

    return _streamDio.put(
      url,
      data: fileStream,
      onSendProgress: onSendProgress,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
    );
  }

  Future<void> requestForString(
    Method method,
    String url, {
    NetSuccessCallback<String?>? onSuccess,
    NetErrorCallback? onError,
    Object? params,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) async {
    try {
      Response<String> response = await _streamDio.request<String>(
        url,
        data: params,
        queryParameters: queryParameters,
        options: _checkOptions(method.value, options),
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200) {
        if (onSuccess != null) {
          onSuccess(response.data);
        }
      } else {
        if (onError != null) {
          onError(-1, response.data ?? "");
        }
      }
    } catch (e) {
      if (onError != null) {
        onError(-1, NetErrorHandler.netErrorToMessage(e));
      }
    }
  }

  void _cancelLogPrint(dynamic e, String url) {
    if (e is DioError && CancelToken.isCancel(e)) {
      Log.e('request cancel： $url');
    }
  }

  void _onError(int code, String msg, NetErrorCallback? onError) {
    Log.e('request error： code: $code, msg: $msg');
    onError?.call(code, msg);
  }

  void _dioIgnoreSSLError(Dio dio) {
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        var client = HttpClient()..idleTimeout = const Duration(seconds: 3);
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
      validateCertificate: (cert, host, port) {
        return true;
      },
    );
  }
}

Map<String, dynamic> parseData(String data) {
  return json.decode(data) as Map<String, dynamic>;
}

enum Method { get, post, put, patch, delete, head }

/// 使用拓展枚举替代 switch判断取值
/// https://zhuanlan.zhihu.com/p/98545689
extension MethodExtension on Method {
  String get value => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD'][index];
}
