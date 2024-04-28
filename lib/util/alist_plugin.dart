import 'dart:convert';

import 'package:alist/entity/player_resolve_info_entity.dart';
import 'package:alist/generated/json/base/json_convert_content.dart';
import 'package:alist/util/method_call_handler.dart';
import 'package:flutter/services.dart';

class AlistPlugin {
  static const _methodChannel = MethodChannel("com.github.alist.client.plugin");

  static void setupChannel() {
    _methodChannel.setMethodCallHandler((MethodCall call) async {
      return MethodCallHandler.hand(call);
    });
  }

  // just for android
  static Future<bool> isAppInstall(String packageName) async {
    Map<String, String?> params = {"packageName": packageName};
    bool isInstalled =
        await _methodChannel.invokeMethod("isAppInstalled", params);
    return isInstalled;
  }

  // just for android
  static Future<bool> launchApp(String packageName, {String? uri}) async {
    Map<String, String?> params = {"packageName": packageName, "uri": uri};
    bool isSucceed = await _methodChannel.invokeMethod("launchApp", params);
    return isSucceed;
  }

  // just for android
  static Future<bool> isScopedStorage() async {
    bool isSucceed = await _methodChannel.invokeMethod("isScopedStorage");
    return isSucceed;
  }

  // just for android
  static Future onDownloadingStart() async {
    await _methodChannel.invokeMethod("onDownloadingStart");
  }

  // just for android
  static Future onDownloadingEnd() async {
    await _methodChannel.invokeMethod("onDownloadingEnd");
  }

  // just for android Q above
  static Future saveFileToLocal(String fileName, String filePath) async {
    await _methodChannel.invokeMethod(
        "saveFileToLocal", {"fileName": fileName, "filePath": filePath});
  }

  // just for android
  static Future<String> getExternalDownloadDir() async {
    dynamic result =
        await _methodChannel.invokeMethod("getExternalDownloadDir");
    if (result is String) {
      return result;
    }
    return "";
  }

  // just for android
  static Future<List<ExternalPlayerEntity>?> loadPlayerResoleInfoList() async {
    var result = await _methodChannel.invokeMethod("loadExternalPlayerList");
    return JsonConvert.fromJsonAsT<List<ExternalPlayerEntity>>(
        jsonDecode(result));
  }

  static Future<bool> playVideoWithExternalPlayer(
      String packageName, String activity, String url) async {
    var result = await _methodChannel.invokeMethod(
        "playVideoWithExternalPlayer",
        {"packageName": packageName, "activity": activity, "url": url});
    return result == true;
  }

  static Future<bool> playVideoWithInternalPlayer(
      List<Map<String, String?>> videos,
      int index,
      Map<String, String>? headers,
      String? playerType) async {
    String? headersStr = headers != null ? jsonEncode(headers) : null;

    var result =
        await _methodChannel.invokeMethod("playVideoWithInternalPlayer", {
      "videos": jsonEncode(videos),
      "index": index,
      "headers": headersStr,
      "playerType": playerType
    });
    return result == true;
  }
}
