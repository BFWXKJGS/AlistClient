import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/util/constant.dart';
import 'package:alist/util/global.dart';
import 'package:alist/widget/alist_checkbox.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConfigFileNameMaxLinesDialog extends StatelessWidget {
  const ConfigFileNameMaxLinesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(Intl.configFileNameMaxLinesDialog_title.tr,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 10),
            _buildChoices(),
          ],
        ),
      ),
    );
  }

  Padding _buildChoices() {
    callback(int fileNameMaxLines) {
      if (Global.fileNameMaxLines.value != fileNameMaxLines) {
        Global.fileNameMaxLines.value = fileNameMaxLines;
        SpUtil.putInt(AlistConstant.fileNameMaxLines, fileNameMaxLines);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AlistCheckBox(
                value: Global.fileNameMaxLines.value == 1,
                text: Intl.configFileNameMaxLinesDialog_choice_one.tr,
                onChanged: (bool? b) => callback(1),
              ),
              AlistCheckBox(
                value: Global.fileNameMaxLines.value == 2,
                text: Intl.configFileNameMaxLinesDialog_choice_two.tr,
                onChanged: (bool? b) => callback(2),
              ),
              AlistCheckBox(
                value: Global.fileNameMaxLines.value > 2,
                text: Intl.configFileNameMaxLinesDialog_choice_noLimit.tr,
                onChanged: (bool? b) => callback(3),
              )
            ],
          )),
    );
  }
}
