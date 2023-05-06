import 'dart:math';

import 'package:alist/generated/l10n.dart';
import 'package:alist/router.dart';
import 'package:alist/util/constant.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'generated/color_schemes.g.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SpUtil.getInstance();
  // sp初始化
  LogUtil.init(isDebug: !Constant.inProduction, maxLen: 512);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      builder: _routerBuilder,
      routerConfig: router,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      title: "Alist",
      theme: _lightTheme(context),
      darkTheme: _dartTheme(context),
    );
  }

  Widget _routerBuilder(BuildContext context, Widget? widget) {
    final smartDialogInit = FlutterSmartDialog.init();
    // limit text scale factor, >=0.9 && <=1.1
    final originalTextScaleFactor = MediaQuery
        .of(context)
        .textScaleFactor;
    var newTextScaleFactor = min(originalTextScaleFactor, 1.1);
    newTextScaleFactor = max(newTextScaleFactor, 0.9);

    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaleFactor: newTextScaleFactor),
      child: smartDialogInit(context, widget),
    );
  }

  ThemeData _dartTheme(BuildContext context) {
    return ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        dividerTheme: DividerTheme.of(context).copyWith(
          thickness: 0,
          space: 0,
        ),
        appBarTheme: AppBarTheme.of(context).copyWith(
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ));
  }

  ThemeData _lightTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      hintColor: const Color(0xFFBBBBBB),
      colorScheme: lightColorScheme,
      dividerTheme: DividerTheme.of(context).copyWith(
        thickness: 0,
        space: 0,
      ),
      appBarTheme: AppBarTheme.of(context).copyWith(
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
    );
  }
}
