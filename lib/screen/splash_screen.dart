import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/net/intercept.dart';
import 'package:alist/util/constant.dart';
import 'package:alist/util/global.dart';
import 'package:alist/util/log_utils.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/util/user_controller.dart';
import 'package:alist/util/widget_utils.dart';
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
  final AlistDatabaseController _databaseController = Get.find();

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await _databaseController.init();
    await SpUtil.getInstance();
    initDio();
    var token = SpUtil.getString(AlistConstant.token, defValue: null);
    while (_context == null) {
      await Future.delayed(const Duration(milliseconds: 17));
    }
    Locale? currentLocal = Get.locale;
    Log.d("local = $currentLocal");
    if (currentLocal?.toString().startsWith("zh_") == true) {
      Global.configServerHost = "alistc.geektang.cn";
      Global.demoServerBaseUrl = "https://www.geektang.cn/alist/";
    }
    makeSureLoginUserInfo(token);
    if ((token == null || token.isEmpty) &&
        SpUtil.getBool(AlistConstant.guest) != true) {
      Get.offNamed(NamedRouter.login);
    } else {
      Get.offNamed(NamedRouter.home);
    }
  }

  void makeSureLoginUserInfo(String? token) {
    UserController userController = Get.find();
    String? serverUrl =
        SpUtil.getString(AlistConstant.serverUrl, defValue: null);
    String? baseUrl = SpUtil.getString(AlistConstant.baseUrl, defValue: null);
    String? username = SpUtil.getString(AlistConstant.username, defValue: null);
    String? password = SpUtil.getString(AlistConstant.password, defValue: null);
    String? token = SpUtil.getString(AlistConstant.token, defValue: null);
    String? basePath = SpUtil.getString(AlistConstant.basePath, defValue: null);
    bool guest = SpUtil.getBool(AlistConstant.guest) ?? false;
    bool useDemoServer = SpUtil.getBool(AlistConstant.useDemoServer) ?? false;
    userController.login(
      User(
        baseUrl: baseUrl ?? "",
        serverUrl: serverUrl ?? "",
        username: username ?? "guest",
        password: password,
        guest: guest,
        token: token,
        basePath: basePath,
        useDemoServer: useDemoServer,
      ),
      fromCache: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    var colorScheme = Theme.of(context).colorScheme;
    Color startColor = colorScheme.primaryContainer;
    const Color endColor = Colors.white;
    var colors = [startColor, endColor];
    bool isDarkMode = WidgetUtils.isDarkMode(context);

    return Container(
      decoration: BoxDecoration(
        gradient: isDarkMode
            ? null
            : LinearGradient(
                colors: colors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        color: isDarkMode ? colorScheme.background : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(Intl.splashScreen_loading.tr),
          ),
        ],
      ),
    );
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

    var ignoreSSLError = SpUtil.getBool(AlistConstant.ignoreSSLError) ?? false;
    var baseUrl = SpUtil.getString(AlistConstant.baseUrl);
    if (baseUrl == null || baseUrl.isEmpty) {
      baseUrl = Global.demoServerBaseUrl;
    }
    configDio(
      baseUrl: baseUrl,
      interceptors: interceptors,
      ignoreSSLError: ignoreSSLError,
    );
  }
}
