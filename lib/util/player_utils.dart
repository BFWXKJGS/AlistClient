import 'dart:io';

import 'package:flutter_aliplayer/flutter_aliplayer.dart';
import 'package:path_provider/path_provider.dart';

extension FlutterAliplayerExtensions on FlutterAliplayer {
  static const tag = "FijkPlayerExtensions";

  Future<void> commonConfig({
    bool disableVideo = false
  }) async {
    Directory? cacheDir;
    if (Platform.isAndroid) {
      Directory temDir;
      var cacheDirs = await getExternalCacheDirectories();
      if (cacheDirs == null || cacheDirs.isEmpty) {
        temDir = await getTemporaryDirectory();
      } else {
        temDir = cacheDirs[0];
      }
      cacheDir = Directory("${temDir.path}/aliplayer");
    } else if (Platform.isIOS) {
      Directory temDir = await getTemporaryDirectory();
      cacheDir = Directory("${temDir.path}/aliplayer");
    }
    if(!await cacheDir!.exists()){
      cacheDir.create(recursive: true);
    }

    var map = {
      "mMaxSizeMB": 10 * 1024,
      "mMaxDurationS": 3 * 60 * 60,
      "mDir": cacheDir.path,
      "mEnable": true,
      "mDisableVideo": disableVideo,
    };
    await setCacheConfig(map);
  }
}
