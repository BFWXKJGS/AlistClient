import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/screen/file_list_screen.dart';
import 'package:alist/screen/settings_screen.dart';
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
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: Intl.screenName_home.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: Intl.screenName_settings.tr,
          )
        ],
        currentIndex: _currentPage,
        onTap: (int idx) => _pageController.jumpToPage(idx),
      ),
    );
  }
}
