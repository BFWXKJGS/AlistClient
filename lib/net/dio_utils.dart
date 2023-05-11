import 'dart:convert';

import 'package:alist/net/json_parse_error.dart';
import 'package:alist/util/constant.dart';
import 'package:alist/util/log_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'base_entity.dart';

/// 默认dio配置
Duration _connectTimeout = const Duration(seconds: 15);
Duration _receiveTimeout = const Duration(seconds: 15);
Duration _sendTimeout = const Duration(seconds: 10);
String _baseUrl = '';
List<Interceptor> _interceptors = [];

/// 初始化Dio配置
void configDio({
  Duration? connectTimeout,
  Duration? receiveTimeout,
  Duration? sendTimeout,
  String? baseUrl,
  List<Interceptor>? interceptors,
}) {
  _connectTimeout = connectTimeout ?? _connectTimeout;
  _receiveTimeout = receiveTimeout ?? _receiveTimeout;
  _sendTimeout = sendTimeout ?? _sendTimeout;
  _baseUrl = baseUrl ?? _baseUrl;
  _interceptors = interceptors ?? _interceptors;
}

typedef NetSuccessCallback<T> = Function(T data);
typedef NetSuccessListCallback<T> = Function(List<T> data);
typedef NetErrorCallback = Function(int? code, String? msg, dynamic exception);

/// @weilu https://github.com/simplezhli
class DioUtils {
  factory DioUtils() => _singleton;

  DioUtils._() {
    _dioInit();
  }

  void _dioInit() {
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

    /// 添加拦截器
    void addInterceptor(Interceptor interceptor) {
      _dio.interceptors.add(interceptor);
    }

    _interceptors.forEach(addInterceptor);
  }

  static final DioUtils _singleton = DioUtils._();
  final Dio _downloadDio = Dio();

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
      throw JsonParseException(e.toString());
    }
  }

  void configBaseUrlAgain(String baseUrl) {
    if (_baseUrl != baseUrl) {
      _baseUrl = baseUrl;
      _dioInit();
    }
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
          _onError(result.code, result.message, null, onError);
        }
      }
    }, onError: (dynamic e) {
      if (cancelToken?.isCancelled != true) {
        _onError(null, null, e, onError);
      } else {
        _cancelLogPrint(e, url);
      }
    }).catchError((e) {
      if (cancelToken?.isCancelled != true) {
        _onError(null, null, e, onError);
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
    return _downloadDio.download(
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

  /// 统一处理(onSuccess返回T对象，onSuccessList返回 List<T>)
  void asyncRequestNetwork<T>(
    Method method,
    String url, {
    NetSuccessCallback<T?>? onSuccess,
    NetErrorCallback? onError,
    Object? params,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) {
    Stream.fromFuture(_request<T>(
      method.value,
      url,
      data: params,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    )).asBroadcastStream().listen((result) {
      if (cancelToken?.isCancelled != true) {
        if (result.code == 200) {
          if (onSuccess != null) {
            onSuccess(result.data);
          }
        } else {
          _onError(result.code, result.message, null, onError);
        }
      }
    }, onError: (dynamic e) {
      if (cancelToken?.isCancelled != true) {
        _onError(null, null, e, onError);
      } else {
        _cancelLogPrint(e, url);
      }
    });
  }

  void _cancelLogPrint(dynamic e, String url) {
    if (e is DioError && CancelToken.isCancel(e)) {
      Log.e('request cancel： $url');
    }
  }

  void _onError(
      int? code, String? msg, dynamic exception, NetErrorCallback? onError) {
    Log.e('request error： code: $code, msg: $msg');
    onError?.call(code, msg, exception);
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
