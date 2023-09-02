import 'dart:io';

import 'package:alist/entity/app_version_resp.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/util/alist_plugin.dart';
import 'package:alist/util/constant.dart';
import 'package:alist/widget/alist_checkbox.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key, required this.appVersion});

  final AppVersionResp appVersion;

  @override
  Widget build(BuildContext context) {
    UpdateDialogController controller = Get.put(UpdateDialogController());

    return AlertDialog(
      title: Text(Intl.updateDialog_title.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(appVersion.updates),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Obx(
              () => AlistCheckBox(
                value: controller.isIgnoreVersion.value,
                text: Intl.updateDialog_tips_ignore.tr,
                onChanged: (value) {
                  controller.ignoreUpdate(value ?? false);
                },
              ),
            ),
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            controller.onDialogCancel(appVersion);
            SmartDialog.dismiss();
          },
          child: Text(Intl.updateDialog_btn_cancel.tr),
        ),
        TextButton(
          onPressed: () {
            controller.openMarket(appVersion);
            SmartDialog.dismiss();
          },
          child: Text(Intl.updateDialog_btn_ok.tr),
        ),
      ],
    );
  }
}

class UpdateDialogController extends GetxController {
  final isIgnoreVersion = false.obs;

  void openMarket(AppVersionResp appVersion) async {
    if (Platform.isIOS) {
      launchUrl(Uri.parse(appVersion.ios.appStoreUrl),
          mode: LaunchMode.externalNonBrowserApplication);
    } else if (Platform.isAndroid) {
      bool isGooglePlayInstalled =
          await AlistPlugin.isAppInstall("com.android.vending");
      if (isGooglePlayInstalled && appVersion.android.googlePlayUrl.isNotEmpty) {
        AlistPlugin.launchApp("com.android.vending",
            uri: appVersion.android.googlePlayUrl);
      } else {
        launchUrl(Uri.parse(appVersion.android.githubUrl),
            mode: LaunchMode.externalApplication);
      }
    }
  }

  void ignoreUpdate(bool ignore) {
    isIgnoreVersion.value = ignore;
  }

  void onDialogCancel(AppVersionResp appVersion) {
    if (isIgnoreVersion.value) {
      SpUtil.putString(AlistConstant.ignoreAppVersion,
          Platform.isIOS ? appVersion.ios.version : appVersion.android.version);
    }
  }
}
