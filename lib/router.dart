import 'package:alist/screen/aboute_screen.dart';
import 'package:alist/screen/audio_player_screen.dart';
import 'package:alist/screen/donate_screen.dart';
import 'package:alist/screen/file_list/file_list_screen.dart';
import 'package:alist/screen/file_reader_screen.dart';
import 'package:alist/screen/gallery_screen.dart';
import 'package:alist/screen/home_screen.dart';
import 'package:alist/screen/login_screen.dart';
import 'package:alist/screen/markdown_reader_screen.dart';
import 'package:alist/screen/pdf_reader_screen.dart';
import 'package:alist/screen/settings_screen.dart';
import 'package:alist/screen/splash_screen.dart';
import 'package:alist/screen/uploading_files_screen.dart';
import 'package:alist/screen/video_player_screen.dart';
import 'package:alist/screen/web_screen.dart';
import 'package:alist/screen/account_screen.dart';
import 'package:alist/util/named_router.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

class AlistRouter {
  static const fileListRouterStackId = 1;
  static const fileListCopyMoveRouterStackId = 2;

  static final List<GetPage> screens = [
    GetPage(name: NamedRouter.root, page: () => const SplashScreen()),
    GetPage(name: NamedRouter.login, page: () => LoginScreen()),
    GetPage(name: NamedRouter.home, page: () => const HomeScreen()),
    GetPage(name: NamedRouter.fileList, page: () => FileListWrapper()),
    GetPage(name: NamedRouter.settings, page: () => const SettingsScreen()),
    GetPage(
        name: NamedRouter.videoPlayer, page: () => const VideoPlayerScreen()),
    GetPage(
        name: NamedRouter.audioPlayer, page: () => AudioPlayerScreen()),
    GetPage(name: NamedRouter.donate, page: () => const DonateScreen()),
    GetPage(name: NamedRouter.about, page: () => const AboutScreen()),
    GetPage(name: NamedRouter.gallery, page: () => GalleryScreen()),
    GetPage(name: NamedRouter.fileReader, page: () => FileReaderScreen()),
    GetPage(name: NamedRouter.web, page: () => const WebScreen()),
    GetPage(
        name: NamedRouter.markdownReader, page: () => MarkdownReaderScreen()),
    GetPage(name: NamedRouter.pdfReader, page: () => PdfReaderScreen()),
    GetPage(name: NamedRouter.uploadingFiles, page: () => const UploadingFilesScreen()),
    GetPage(name: NamedRouter.account, page: () => const AccountScreen()),
  ];
}
