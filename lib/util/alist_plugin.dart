import 'package:flutter/services.dart';

class AlistPlugin {
  static const methodChannel = MethodChannel("com.github.alist.client.plugin");

  // just for android
  static Future<bool> isAppInstall(String packageName) async {
    Map<String, String?> params = {"packageName": packageName};
    bool isInstalled =
        await methodChannel.invokeMethod("isAppInstalled", params);
    return isInstalled;
  }

  // just for android
  static Future<bool> launchApp(String packageName, {String? uri}) async {
    Map<String, String?> params = {"packageName": packageName, "uri": uri};
    bool isSucceed = await methodChannel.invokeMethod("launchApp", params);
    return isSucceed;
  }

  // just for android
  static Future<bool> isScopedStorage() async {
    bool isSucceed = await methodChannel.invokeMethod("isScopedStorage");
    return isSucceed;
  }

  // just for android
  static Future onDownloadingStart() async {
    await methodChannel.invokeMethod("onDownloadingStart");
  }

  // just for android
  static Future onDownloadingEnd() async {
    await methodChannel.invokeMethod("onDownloadingEnd");
  }

  // just for android Q above
  static Future saveFileToLocal(String fileName, String filePath) async {
    await methodChannel.invokeMethod(
        "saveFileToLocal", {"fileName": fileName, "filePath": filePath});
  }

  // just for android
  static Future<String> getExternalDownloadDir() async {
    dynamic result = await methodChannel.invokeMethod("getExternalDownloadDir");
    if (result is String) {
      return result;
    }
    return "";
  }
}
