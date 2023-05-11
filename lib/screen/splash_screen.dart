import 'package:alist/net/dio_utils.dart';
import 'package:alist/net/intercept.dart';
import 'package:alist/util/constant.dart';
import 'package:alist/util/global.dart';
import 'package:alist/util/named_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sp_util/sp_util.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  BuildContext? _context;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await SpUtil.getInstance();
    initDio();
    var token = SpUtil.getString(AlistConstant.token);
    while (_context == null) {
      await Future.delayed(const Duration(milliseconds: 17));
    }
    Locale currentLocal = Localizations.localeOf(_context!);
    if ("zh" == currentLocal.toString()) {
      Global.configServerHost = "alistc.geektang.cn";
      Global.demoServerBaseUrl = "https://www.geektang.cn/alist/";
    }

    if ((token == null || token.isEmpty) &&
        SpUtil.getBool(AlistConstant.guest) != true) {
      Get.offNamed(NamedRouter.login);
    } else {
      Get.offNamed(NamedRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    return const SizedBox();
  }

  @override
  void dispose() {
    _context = null;
    super.dispose();
  }

  void initDio() {
    final List<Interceptor> interceptors = <Interceptor>[];

    /// 统一添加身份验证请求头
    interceptors.add(AuthInterceptor());

    /// 打印Log(生产模式去除)
    if (!AlistConstant.inProduction) {
      interceptors.add(LoggingInterceptor());
    }

    var baseUrl = SpUtil.getString(AlistConstant.baseUrl);
    if (baseUrl == null || baseUrl.isEmpty) {
      baseUrl = Global.demoServerBaseUrl;
    }
    configDio(
      baseUrl: baseUrl,
      interceptors: interceptors,
    );
  }
}
