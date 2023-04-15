import 'package:alist/net/dio_utils.dart';
import 'package:alist/net/intercept.dart';
import 'package:alist/page/login_page.dart';
import 'package:alist/util/constant.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  LogUtil.init(isDebug: !Constant.inProduction, maxLen: 512);
  WidgetsFlutterBinding.ensureInitialized();
  // sp初始化
  await SpUtil.getInstance();
  initDio();
  runApp(const MyApp());
}

void initDio() {
  final List<Interceptor> interceptors = <Interceptor>[];

  /// 统一添加身份验证请求头
  interceptors.add(AuthInterceptor());

  /// 打印Log(生产模式去除)
  if (!Constant.inProduction) {
    interceptors.add(LoggingInterceptor());
  }

  var baseUrl =
      SpUtil.getString(Constant.baseUrl) ?? 'https://www.geektang.cn/api/';
  configDio(
    baseUrl: baseUrl,
    interceptors: interceptors,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}


