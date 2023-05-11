import 'package:alist/generated/images.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/util/constant.dart';
import 'package:alist/util/global.dart';
import 'package:alist/util/log_utils.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/util/widget_utils.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
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

class _SettingsContainerState extends State<_SettingsContainer> {
  PackageInfo? packageInfo;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
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
        itemCount: settingsMenus.length);
  }

  ListTile _buildListItem(
      SettingsMenu settingsMenu, BuildContext context, bool isDarkMode) {
    return ListTile(
      onTap: () {
        if (settingsMenu.route?.isNotEmpty == true) {
          Get.toNamed(settingsMenu.route!);
        } else {
          if (settingsMenu.menuId == MenuId.account) {
            _showAccountDialog(context);
          } else if (settingsMenu.menuId == MenuId.signIn) {
            SpUtil.remove(AlistConstant.guest);
            SpUtil.remove(AlistConstant.token);
            Get.offNamed(NamedRouter.login);
          } else if (settingsMenu.menuId == MenuId.about) {
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
          }
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
          menuId: MenuId.donate,
          name: Intl.settingsScreen_item_donate.tr,
          icon: Images.settingsPageDonate,
          route: NamedRouter.donate),
      SettingsMenu(
        menuId: MenuId.about,
        name: Intl.settingsScreen_item_about.tr,
        icon: Images.settingsPageAbout,
        // route: NamedRouter.about,
      ),
    ];
    if (SpUtil.getBool(AlistConstant.guest) == true) {
      settingsMenus.insert(
          0,
          SettingsMenu(
            menuId: MenuId.signIn,
            name: Intl.settingsScreen_item_login.tr,
            icon: Images.settingsPageAccount,
          ));
    } else {
      settingsMenus.insert(
          0,
          SettingsMenu(
            menuId: MenuId.account,
            name: Intl.settingsScreen_item_account.tr,
            icon: Images.settingsPageAccount,
          ));
    }
    return settingsMenus;
  }

  void _showAccountDialog(BuildContext context) {
    SmartDialog.show(
        alignment: Alignment.bottomCenter,
        builder: (_) {
          return Container(
            width: double.infinity,
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Text(Intl.tips_logout.tr),
                ),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: FilledButton(
                    onPressed: () {
                      SpUtil.remove(AlistConstant.guest);
                      SpUtil.remove(AlistConstant.token);
                      SmartDialog.dismiss();
                      Get.offNamed(NamedRouter.login);
                    },
                    child: Text(Intl.logout.tr),
                  ),
                )
              ],
            ),
          );
        });
  }
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
  donate,
  about,
}
