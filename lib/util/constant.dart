import 'package:flutter/foundation.dart';

class AlistConstant {
  /// App运行在Release环境时，inProduction为true；当App运行在Debug和Profile环境时，inProduction为false
  static const bool inProduction = kReleaseMode;

  static bool isDriverTest = false;
  static bool isUnitTest = false;

  static const String data = 'data';
  static const String message = 'message';
  static const String code = 'code';

  static const String address = 'address';
  static const String baseUrl = 'baseUrl';
  static const String username = 'username';
  static const String password = 'password';
  static const String token = 'token';
  static const String guest = 'guest';

  static const String locale = 'locale';
}
