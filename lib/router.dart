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
import 'package:alist/screen/web_screen.dart';
import 'package:alist/util/named_router.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

class AlistRouter {
  static const fileListRouterStackId = 1;

  static final List<GetPage> screens = [
    GetPage(name: NamedRouter.root, page: () => const SplashScreen()),
    GetPage(name: NamedRouter.login, page: () => const LoginScreen()),
    GetPage(name: NamedRouter.home, page: () => const HomeScreen()),
    GetPage(name: NamedRouter.fileList, page: () => const FileListScreen()),
    GetPage(name: NamedRouter.settings, page: () => const SettingsScreen()),
    GetPage(
        name: NamedRouter.videoPlayer, page: () => const VideoPlayerScreen()),
    GetPage(
        name: NamedRouter.audioPlayer, page: () => const AudioPlayerScreen()),
    GetPage(name: NamedRouter.donate, page: () => const DonateScreen()),
    GetPage(name: NamedRouter.about, page: () => const AboutScreen()),
    GetPage(name: NamedRouter.gallery, page: () => GalleryScreen()),
    GetPage(name: NamedRouter.fileReader, page: () => FileReaderScreen()),
    GetPage(name: NamedRouter.web, page: () => const WebScreen()),
  ];
}
