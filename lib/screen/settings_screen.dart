import 'package:alist/generated/images.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/util/global.dart';
import 'package:alist/util/log_utils.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/util/user_controller.dart';
import 'package:alist/util/widget_utils.dart';
import 'package:alist/widget/alist_scaffold.dart';
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
  final UserController _userController = Get.find();

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
        switch (settingsMenu.menuId) {
          case MenuId.signIn:
            _userController.logout();
            Get.offNamed(NamedRouter.login);
            break;
          case MenuId.account:
            _showAccountDialog(context);
            break;
          case MenuId.donate:
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
              arguments: {"url": url, "title": Intl.settingsScreen_item_privacyPolicy.tr},
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
          menuId: MenuId.donate,
          name: Intl.settingsScreen_item_donate.tr,
          icon: Images.settingsScreenDonate,
          route: NamedRouter.donate),
      SettingsMenu(
          menuId: MenuId.privacyPolicy,
          name: Intl.settingsScreen_item_privacyPolicy.tr,
          icon: Images.settingsScreenDonate,
          route: NamedRouter.donate),
      SettingsMenu(
        menuId: MenuId.about,
        name: Intl.settingsScreen_item_about.tr,
        icon: Images.settingsScreenAbout,
        // route: NamedRouter.about,
      ),
    ];
    if (_userController.user().guest == true) {
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
                      _userController.logout();
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
  privacyPolicy,
  about,
}
