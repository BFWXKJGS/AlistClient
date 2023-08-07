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
    bool isSucceed =
        await methodChannel.invokeMethod("isScopedStorage");
    return isSucceed;
  }
}
