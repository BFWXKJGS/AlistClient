import 'dart:io';

import 'package:alist/entity/player_resolve_info_entity.dart';
import 'package:alist/generated/images.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/util/constant.dart';
import 'package:alist/util/video_player_util.dart';
import 'package:alist/util/widget_utils.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:alist/widget/player_selector_dialog.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlayerSettingsScreen extends StatefulWidget {
  const PlayerSettingsScreen({super.key});

  @override
  State<PlayerSettingsScreen> createState() => _PlayerSettingsScreenState();
}

class _PlayerSettingsScreenState extends State<PlayerSettingsScreen> {
  var videoPlayerName = "";

  @override
  void initState() {
    super.initState();
    videoPlayerName = SpUtil.getString(AlistConstant.videoPlayerName) ?? "";
    if (videoPlayerName == "") {
      if (Platform.isAndroid) {
        videoPlayerName = "ExoPlayer (AList Client)";
      } else {
        videoPlayerName = AlistConstant.appName;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = WidgetUtils.isDarkMode(context);
    return AlistScaffold(
        appbarTitle: Text(Intl.screenName_playerSettings.tr),
        body: Column(
          children: [
            ListTile(
              onTap: () => _showPlayerSelectorDialog(context),
              title: Text(Intl.playerSettings_player_in_use.tr),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    videoPlayerName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.normal),
                  ),
                  Image.asset(
                    Images.iconArrowRight,
                    color: isDarkMode ? Colors.white : null,
                  )
                ],
              ),
            )
          ],
        ));
  }

  void _showPlayerSelectorDialog(BuildContext context) async {
    List<ExternalPlayerEntity> externalPlayerList =
        await VideoPlayerUtil.loadPlayerResoleInfoList();
    if (!context.mounted) {
      return;
    }

    showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (context) {
          return PlayerSelectorDialog(
            players: externalPlayerList,
            onPlayerClick: (info) {
              var isInternal = info.label.contains("AList Client");
              if (isInternal) {
                videoPlayerName = info.label.replaceAll("\n", "");
                SpUtil.putString(
                    AlistConstant.videoPlayerName, videoPlayerName);
                SpUtil.putString(AlistConstant.playerType, info.packageName);
                SpUtil.remove(AlistConstant.videoPlayerRouter);
                setState(() {});
              } else {
                // externalPlayer
                SpUtil.remove(AlistConstant.playerType);
                SpUtil.putString(AlistConstant.videoPlayerName, info.label);
                SpUtil.putString(AlistConstant.videoPlayerRouter,
                    "${info.packageName}/${info.activity}");
                setState(() {
                  videoPlayerName = info.label;
                });
              }
              Navigator.of(context).pop();
            },
          );
        });
  }
}
