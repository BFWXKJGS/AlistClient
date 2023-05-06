import 'package:alist/generated/l10n.dart';
import 'package:alist/screen/aboute_screen.dart';
import 'package:alist/screen/audio_player_screen.dart';
import 'package:alist/screen/donate_screen.dart';
import 'package:alist/screen/file_reader_screen.dart';
import 'package:alist/screen/file_list_screen.dart';
import 'package:alist/screen/gallery_screen.dart';
import 'package:alist/screen/home_screen.dart';
import 'package:alist/screen/login_screen.dart';
import 'package:alist/screen/settings_screen.dart';
import 'package:alist/screen/splash_screen.dart';
import 'package:alist/screen/video_player_screen.dart';
import 'package:alist/util/constant.dart';
import 'package:alist/util/router_path.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';

import 'generated/color_schemes.g.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SpUtil.getInstance();
  // sp初始化
  LogUtil.init(isDebug: !Constant.inProduction, maxLen: 512);
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: RoutePath.root,
  observers: [FlutterSmartDialog.observer],
  routes: <RouteBase>[
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RoutePath.root,
      builder: (context, state) => SplashScreen(key: state.pageKey),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RoutePath.login,
      builder: (context, state) => LoginScreen(key: state.pageKey),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RoutePath.home,
      builder: (context, state) => HomeScreen(
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: RoutePath.fileList,
      builder: (context, state) => FileListScreen(
        key: state.pageKey,
        path: state.queryParameters['path'] ?? '',
      ),
    ),
    GoRoute(
      path: RoutePath.settings,
      builder: (context, state) => SettingsScreen(key: state.pageKey),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RoutePath.videoPlayer,
      builder: (context, state) =>
          VideoPlayerScreen(path: state.queryParameters['path'] ?? ''),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RoutePath.audioPlayer,
      builder: (context, state) =>
          AudioPlayerScreen(path: state.queryParameters['path'] ?? ''),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RoutePath.donate,
      builder: (context, state) => const DonateScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RoutePath.about,
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RoutePath.gallery,
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        return GalleryScreen(
          paths: extras["paths"],
          initializedIndex: extras["index"] ?? 0,
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RoutePath.fileReader,
      builder: (context, state) {
        dynamic extra = state.extra;
        return FileReaderScreen(
          path: state.queryParameters['path'] ?? '',
          fileType: extra?["fileType"],
        );
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      builder: FlutterSmartDialog.init(),
      routerConfig: _router,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      title: "Alist",
      theme: ThemeData(
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
          )),
      darkTheme: ThemeData(
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
          )),
    );
  }
}
