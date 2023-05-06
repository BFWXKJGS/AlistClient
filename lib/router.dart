import 'package:alist/screen/aboute_screen.dart';
import 'package:alist/screen/audio_player_screen.dart';
import 'package:alist/screen/donate_screen.dart';
import 'package:alist/screen/file_list_screen.dart';
import 'package:alist/screen/file_reader_screen.dart';
import 'package:alist/screen/gallery_screen.dart';
import 'package:alist/screen/home_screen.dart';
import 'package:alist/screen/login_screen.dart';
import 'package:alist/screen/settings_screen.dart';
import 'package:alist/screen/splash_screen.dart';
import 'package:alist/screen/video_player_screen.dart';
import 'package:alist/util/named_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  observers: [FlutterSmartDialog.observer],
  routes: <RouteBase>[
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/',
      name: NamedRouter.root,
      pageBuilder: (context, state) => AlistTransitionPage<void>(
        key: state.pageKey,
        restorationId: state.pageKey.value,
        child: SplashScreen(key: state.pageKey),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/login',
      name: NamedRouter.login,
      pageBuilder: (context, state) => AlistTransitionPage<void>(
        key: state.pageKey,
        restorationId: state.pageKey.value,
        child: LoginScreen(key: state.pageKey),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/home',
      name: NamedRouter.home,
      pageBuilder: (context, state) => AlistTransitionPage<void>(
        key: state.pageKey,
        restorationId: state.pageKey.value,
        child: HomeScreen(
          key: state.pageKey,
        ),
      ),
    ),
    GoRoute(
      path: '/fileList',
      name: NamedRouter.fileList,
      pageBuilder: (context, state) => AlistTransitionPage<void>(
        key: state.pageKey,
        restorationId: state.pageKey.value,
        child: FileListScreen(
          key: state.pageKey,
          path: state.queryParameters['path'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/settings',
      name: NamedRouter.settings,
      pageBuilder: (context, state) => AlistTransitionPage<void>(
        key: state.pageKey,
        restorationId: state.pageKey.value,
        child: SettingsScreen(key: state.pageKey),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/videoPlayer',
      name: NamedRouter.videoPlayer,
      pageBuilder: (context, state) => AlistTransitionPage<void>(
        key: state.pageKey,
        restorationId: state.pageKey.value,
        child: VideoPlayerScreen(path: state.queryParameters['path'] ?? ''),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/audioPlayer',
      name: NamedRouter.audioPlayer,
      pageBuilder: (context, state) => AlistTransitionPage<void>(
        key: state.pageKey,
        restorationId: state.pageKey.value,
        child: AudioPlayerScreen(path: state.queryParameters['path'] ?? ''),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/donate',
      name: NamedRouter.donate,
      pageBuilder: (context, state) => AlistTransitionPage<void>(
        key: state.pageKey,
        restorationId: state.pageKey.value,
        child: const DonateScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/about',
      name: NamedRouter.about,
      pageBuilder: (context, state) => AlistTransitionPage<void>(
        key: state.pageKey,
        restorationId: state.pageKey.value,
        child: const AboutScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/gallery',
      name: NamedRouter.gallery,
      pageBuilder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        return AlistTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: GalleryScreen(
            paths: extras["paths"],
            initializedIndex: extras["index"] ?? 0,
          ),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/fileReader',
      name: NamedRouter.fileReader,
      pageBuilder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        return AlistTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: FileReaderScreen(
            path: state.queryParameters['path'] ?? '',
            fileType: extras["fileType"],
          ),
        );
      },
    ),
  ],
);

class AlistTransitionPage<T> extends CustomTransitionPage<T> {
  AlistTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
            opacity: CurveTween(curve: Curves.easeIn).animate(animation),
            child: SlideTransition(
              position: animation.drive(
                Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).chain(
                  CurveTween(curve: Curves.easeIn),
                ),
              ),
              child: child,
            )),
  );
}