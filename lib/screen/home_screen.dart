import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/router.dart';
import 'package:alist/screen/file_list/file_list_navigator.dart';
import 'package:alist/screen/file_list/file_list_screen.dart';
import 'package:alist/screen/recents_screen.dart';
import 'package:alist/screen/settings_screen.dart';
import 'package:alist/widget/bottom_navigation_bar.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: <Widget>[
          FileListNavigator(
            isInFileListStack: _currentPage == 0,
          ),
          const RecentsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: AlistBottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.folder_rounded),
            label: Intl.screenName_home.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.timelapse_rounded),
            label: Intl.screenName_recents.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_rounded),
            label: Intl.screenName_settings.tr,
          )
        ],
        currentIndex: _currentPage,
        onTap: (int idx) => _pageController.jumpToPage(idx),
        onLongPress: (int idx) {
          LogUtil.d("onDoubleTap: $idx");
          if (idx == 0 && _currentPage == 0) {
            Get.until((route) => route.isFirst,
                id: AlistRouter.fileListRouterStackId);
          } else {
            _pageController.jumpToPage(idx);
          }
        },
      ),
    );
  }
}
