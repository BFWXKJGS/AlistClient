import 'package:alist/util/constant.dart';
import 'package:alist/util/log_utils.dart';
import 'package:dio/dio.dart';
import 'package:sp_util/sp_util.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final String accessToken = SpUtil.getString(AlistConstant.token) ?? "";
    final String serverUrl = SpUtil.getString(AlistConstant.serverUrl) ?? "";
    final String url = options.uri.toString();
    if (accessToken.isNotEmpty && serverUrl.isNotEmpty && url.startsWith(serverUrl)) {
      options.headers['Authorization'] = accessToken;
    }
    super.onRequest(options, handler);
  }
}

class LoggingInterceptor extends Interceptor {
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _startTime = DateTime.now();
    Log.d('----------Start----------');
    if (options.queryParameters.isEmpty) {
      Log.d('RequestUrl: ${options.baseUrl}${options.path}');
    } else {
      Log.d(
          'RequestUrl: ${options.baseUrl}${options.path}?${Transformer.urlEncodeMap(options.queryParameters)}');
    }
    Log.d('RequestMethod: ${options.method}');
    Log.d('RequestHeaders:${options.headers}');
    Log.d('RequestContentType: ${options.contentType}');
    Log.d('RequestData: ${options.data}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) {
    _endTime = DateTime.now();
    final int duration = _endTime.difference(_startTime).inMilliseconds;
    Log.d('ResponseCode: ${response.statusCode}');
    // 输出结果
    Log.json(response.data.toString());
    Log.d('----------End: $duration 毫秒----------');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    Log.d('----------Error-----------');
    super.onError(err, handler);
  }
}
