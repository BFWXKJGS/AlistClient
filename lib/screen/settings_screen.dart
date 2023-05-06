import 'package:alist/generated/images.dart';
import 'package:alist/util/constant.dart';
import 'package:alist/util/router_path.dart';
import 'package:alist/util/widget_utils.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';

import 'package:alist/generated/l10n.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = WidgetUtils.isDarkMode(context);
    final settingsMenus = [
      SettingsMenu(
          menuId: MenuId.donate,
          name: S.of(context).settingsScreen_item_donate,
          icon: Images.settingsPageDonate,
          route: RoutePath.donate),
      SettingsMenu(
        menuId: MenuId.about,
        name: S.of(context).settingsScreen_item_about,
        icon: Images.settingsPageAbout,
        route: RoutePath.about,
      ),
    ];
    if (SpUtil.getBool(Constant.guest) == true) {
      settingsMenus.insert(
          0,
          SettingsMenu(
            menuId: MenuId.signIn,
            name: S.of(context).settingsScreen_item_login,
            icon: Images.settingsPageAccount,
          ));
    } else {
      settingsMenus.insert(
          0,
          SettingsMenu(
            menuId: MenuId.account,
            name: S.of(context).settingsScreen_item_account,
            icon: Images.settingsPageAccount,
          ));
    }

    return AlistScaffold(
      appbarTitle: Text(S.of(context).screenName_settings),
      body: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemBuilder: (child, index) {
            var settingsMenu = settingsMenus[index];
            return ListTile(
              onTap: () {
                if (settingsMenu.route?.isNotEmpty == true) {
                  context.push(settingsMenu.route!);
                } else {
                  if (settingsMenu.menuId == MenuId.account) {
                    _showAccountDialog(context);
                  } else if (settingsMenu.menuId == MenuId.signIn) {
                    SpUtil.remove(Constant.guest);
                    SpUtil.remove(Constant.token);
                    context.go(RoutePath.login);
                  }
                }
              },
              horizontalTitleGap: 2,
              tileColor:
                  Theme.of(context).colorScheme.background.withAlpha(125),
              minVerticalPadding: 15,
              leading: Image.asset(
                settingsMenu.icon,
                color: isDarkMode ? Colors.white : null,
              ),
              title: Text(settingsMenu.name),
              trailing: Image.asset(
                Images.iconArrowRight,
                color: isDarkMode ? Colors.white : null,
              ),
            );
          },
          separatorBuilder: (child, index) {
            return const Divider();
          },
          itemCount: settingsMenus.length),
    );
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
                  child: Text(S.of(context).tips_logout),
                ),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: FilledButton(
                    onPressed: () {
                      SpUtil.remove(Constant.guest);
                      SpUtil.remove(Constant.token);
                      SmartDialog.dismiss();
                      context.go(RoutePath.login);
                    },
                    child: Text(S.of(context).logout),
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
