import 'dart:io';

import 'package:alist/generated/l10n.dart';
import 'package:alist/net/json_parse_error.dart';
import 'package:alist/util/log_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

mixin NetErrorGetterMixin<T extends StatefulWidget> on State<T> {
  String netErrorToMessage(dynamic error) {
    if (error is JsonParseException) {
      return S.of(context).net_error_parse_error;
    }
    if (error is SocketException) {
      return S.of(context).net_error_socket_error;
    }
    if (error is HttpException) {
      return S.of(context).net_error_http_error;
    }
    if (error is FormatException) {
      return S.of(context).net_error_parse_error;
    }
    if (error is DioError) {
      Log.d(error.type.toString());
      switch(error.type){
        case DioErrorType.connectionTimeout:
          return S.of(context).net_error_connect_timeout_error;
        case DioErrorType.sendTimeout:
          return S.of(context).net_error_send_timeout_error;
        case DioErrorType.receiveTimeout:
          return S.of(context).net_error_receive_timeout_error;
        case DioErrorType.badCertificate:
          return S.of(context).net_error_certificate_error;
        case DioErrorType.badResponse:
          return S.of(context).net_error_net_error;
        case DioErrorType.cancel:
          return S.of(context).net_error_cancel_error;
        case DioErrorType.connectionError:
          return S.of(context).net_error_net_error;
        default:
          break;
      }
    }
    return S.of(context).net_error_net_error;
  }
}
