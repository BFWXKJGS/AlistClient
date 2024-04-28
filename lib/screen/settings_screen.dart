import 'dart:async';
import 'dart:io';

import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/generated/images.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/util/constant.dart';
import 'package:alist/util/global.dart';
import 'package:alist/util/log_utils.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/util/user_controller.dart';
import 'package:alist/util/widget_utils.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AlistScaffold(
        appbarTitle: Text(Intl.screenName_settings.tr),
        body: const _SettingsContainer());
  }
}

class _SettingsContainer extends StatefulWidget {
  const _SettingsContainer({Key? key}) : super(key: key);

  @override
  State<_SettingsContainer> createState() => _SettingsContainerState();
}

class _SettingsContainerState extends State<_SettingsContainer>
    with AutomaticKeepAliveClientMixin {
  PackageInfo? packageInfo;
  final AlistDatabaseController _databaseController = Get.find();
  final UserController _userController = Get.find();
  StreamSubscription? _serverStreamSubscription;
  final _userCnt = 0.obs;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();

    _serverStreamSubscription =
        _databaseController.serverDao.serverList().listen((event) {
      _userCnt.value = event?.length ?? 0;
    });
  }

  @override
  void dispose() {
    _serverStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = WidgetUtils.isDarkMode(context);
    List<SettingsMenu> settingsMenus = _buildSettingsMenuItems(context);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemBuilder: (child, index) {
        var settingsMenu = settingsMenus[index];
        return _buildListItem(settingsMenu, context, isDarkMode);
      },
      separatorBuilder: (child, index) {
        return const Divider();
      },
      itemCount: settingsMenus.length,
    );
  }

  ListTile _buildListItem(
      SettingsMenu settingsMenu, BuildContext context, bool isDarkMode) {
    return ListTile(
      onTap: () {
        switch (settingsMenu.menuId) {
          case MenuId.signIn:
            _userController.logout();
            Get.offNamed(NamedRouter.login);
            break;
          case MenuId.downloads:
          case MenuId.donate:
          case MenuId.account:
          case MenuId.cacheManager:
          case MenuId.playerSettings:
            Get.toNamed(settingsMenu.route!);
            break;
          case MenuId.privacyPolicy:
            String local = "en_US";
            if (Get.locale?.toString().startsWith("zh_") == true) {
              local = "zh";
            }

            final url =
                "https://${Global.configServerHost}/alist_h5/privacyPolicy?version=${packageInfo?.version ?? ""}&lang=$local";
            Log.d("url:$url");
            Get.toNamed(
              NamedRouter.web,
              arguments: {
                "url": url,
                "title": Intl.settingsScreen_item_privacyPolicy.tr
              },
            );
            break;
          case MenuId.about:
            String local = "en_US";
            if (Get.locale?.toString().startsWith("zh_") == true) {
              local = "zh";
            }

            final url =
                "https://${Global.configServerHost}/alist_h5/declaration?version=${packageInfo?.version ?? ""}&lang=$local";
            Log.d("url:$url");
            Get.toNamed(
              NamedRouter.web,
              arguments: {"url": url, "title": Intl.screenName_about.tr},
            );
            break;
        }
      },
      horizontalTitleGap: 2,
      tileColor: Theme.of(context).colorScheme.background.withAlpha(125),
      minVerticalPadding: 15,
      leading: Image.asset(settingsMenu.icon),
      title: Text(settingsMenu.name),
      trailing: Image.asset(
        Images.iconArrowRight,
        color: isDarkMode ? Colors.white : null,
      ),
    );
  }

  _initPackageInfo() async {
    packageInfo = await PackageInfo.fromPlatform();
  }

  List<SettingsMenu> _buildSettingsMenuItems(BuildContext context) {
    final settingsMenus = [
      SettingsMenu(
          menuId: MenuId.downloads,
          name: Intl.settingsScreen_item_downloads.tr,
          icon: Images.settingsScreenDownload,
          route: NamedRouter.downloadManager),
      SettingsMenu(
          menuId: MenuId.cacheManager,
          name: Intl.settingsScreen_item_cacheManagement.tr,
          icon: Images.settingsScreenCacheManager,
          route: NamedRouter.cacheManager),
      SettingsMenu(
          menuId: MenuId.playerSettings,
          name: Intl.settingsScreen_item_videoPlayer.tr,
          icon: Images.settingsScreenPlayer,
          route: NamedRouter.playerSettings),
      SettingsMenu(
          menuId: MenuId.privacyPolicy,
          name: Intl.settingsScreen_item_privacyPolicy.tr,
          icon: Images.settingsScreenPrivacyPolicy,
          route: NamedRouter.donate),
      SettingsMenu(
        menuId: MenuId.about,
        name: Intl.settingsScreen_item_about.tr,
        icon: Images.settingsScreenAbout,
        // route: NamedRouter.about,
      ),
    ];
    if (!Platform.isIOS) {
      // ios app store no internal purchase allowed
      settingsMenus.insert(
        0,
        SettingsMenu(
            menuId: MenuId.donate,
            name: Intl.settingsScreen_item_donate.tr,
            icon: Images.settingsScreenDonate,
            route: NamedRouter.donate),
      );
    }
    if (_userCnt.value == 0 &&
        SpUtil.getBool(AlistConstant.useDemoServer) == true) {
      settingsMenus.insert(
          0,
          SettingsMenu(
            menuId: MenuId.signIn,
            name: Intl.settingsScreen_item_login.tr,
            icon: Images.settingsScreenAccount,
          ));
    } else {
      settingsMenus.insert(
          0,
          SettingsMenu(
            menuId: MenuId.account,
            name: Intl.settingsScreen_item_account.tr,
            icon: Images.settingsScreenAccount,
            route: NamedRouter.account,
          ));
    }
    return settingsMenus;
  }

  @override
  bool get wantKeepAlive => true;
}

class SettingsMenu {
  final String name;
  final String icon;
  final String? route;
  final MenuId menuId;

  SettingsMenu({
    required this.name,
    required this.icon,
    this.route,
    required this.menuId,
  });
}

enum MenuId {
  signIn,
  account,
  downloads,
  donate,
  privacyPolicy,
  about,
  cacheManager,
  playerSettings
}
