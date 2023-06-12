import 'dart:io';

import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/net/json_parse_error.dart';
import 'package:alist/net/redirect_exception.dart';
import 'package:alist/util/log_utils.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:get/get.dart';

class NetErrorHandler {
  static String netErrorToMessage(dynamic error) {
    if (error is RedirectException) {
      return error.message;
    }
    if (error is JsonParseException) {
      return Intl.net_error_parse_error.tr;
    }
    if (error is SocketException) {
      return Intl.net_error_socket_error.tr;
    }
    if (error is HttpException) {
      return Intl.net_error_http_error.tr;
    }
    if (error is FormatException) {
      return Intl.net_error_parse_error.tr;
    }
    if (error is DioException) {
      if (error.error is HandshakeException) {
        return Intl.net_error_certificate_error.tr;
      }
      Log.d(error.type.toString());
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return Intl.net_error_connect_timeout_error.tr;
        case DioExceptionType.sendTimeout:
          return Intl.net_error_send_timeout_error.tr;
        case DioExceptionType.receiveTimeout:
          return Intl.net_error_receive_timeout_error.tr;
        case DioExceptionType.badCertificate:
          return Intl.net_error_certificate_error.tr;
        case DioExceptionType.badResponse:
          return Intl.net_error_net_error.tr;
        case DioExceptionType.cancel:
          return Intl.net_error_cancel_error.tr;
        case DioExceptionType.connectionError:
          return Intl.net_error_net_error.tr;
        default:
          break;
      }
    }
    return Intl.net_error_net_error.tr;
  }
}
