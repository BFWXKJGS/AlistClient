import 'package:alist/entity/my_info_resp.dart';
import 'package:alist/entity/public_settings_resp.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'constant.dart';

class UserController extends GetxController {
  var user = User(baseUrl: "", serverUrl: "").obs;
  var searchIndex = "".obs;

  void login(User user, {bool fromCache = false}) {
    this.user.value = user;
    searchIndex.value = "";

    SpUtil.putString(AlistConstant.serverUrl, user.serverUrl);
    SpUtil.putString(AlistConstant.baseUrl, user.baseUrl);
    SpUtil.putString(AlistConstant.username, user.username);
    SpUtil.putString(AlistConstant.password, user.password ?? "");
    SpUtil.putString(AlistConstant.token, user.token ?? "");
    SpUtil.putString(AlistConstant.basePath, user.basePath ?? "");
    SpUtil.putBool(AlistConstant.guest, user.guest);
    SpUtil.putBool(AlistConstant.useDemoServer, user.useDemoServer);

    if (fromCache || user.basePath == null || user.basePath!.isEmpty) {
      requestBasePath(user);
    }
    loadSettings();
  }

  void loadSettings() {
    if (searchIndex.value != "") {
      return;
    }
    DioUtils.instance.requestNetwork<PublicSettingsResp>(
        Method.get, "public/settings", onSuccess: (data) {
      if (data?.searchIndex != null && data?.searchIndex != "none") {
        searchIndex.value = data!.searchIndex!;
      } else {
        searchIndex.value = "";
      }
    });
  }

  void logout() {
    searchIndex.value = "";
    var currentUserValue = user.value;
    var isUseDemoServer = currentUserValue.useDemoServer;
    var guest = currentUserValue.guest;
    var newUserValue = User(
      baseUrl: isUseDemoServer ? "" : currentUserValue.baseUrl,
      serverUrl: isUseDemoServer ? "" : currentUserValue.serverUrl,
      guest: false,
      username: currentUserValue.username,
      password: currentUserValue.password,
      token: null,
    );
    user.value = newUserValue;
    SpUtil.remove(AlistConstant.guest);
    SpUtil.remove(AlistConstant.token);
    SpUtil.remove(AlistConstant.basePath);
    if (isUseDemoServer) {
      SpUtil.remove(AlistConstant.useDemoServer);
      SpUtil.remove(AlistConstant.serverUrl);
      SpUtil.remove(AlistConstant.baseUrl);
    }
    if (guest) {
      SpUtil.remove(AlistConstant.username);
    }
  }

  Future<void> requestBasePath(User requestUser) async {
    DioUtils.instance.requestNetwork<MyInfoResp>(
      Method.get,
      "me",
      options: Options(followRedirects: false),
      onSuccess: (data) {
        User originalUser = user.value;
        if (requestUser == originalUser &&
            data?.basePath != null &&
            data!.basePath.isNotEmpty) {
          SpUtil.putString(AlistConstant.basePath, data.basePath);
          user.value = User(
            baseUrl: originalUser.baseUrl,
            serverUrl: originalUser.serverUrl,
            guest: originalUser.guest,
            username: originalUser.username,
            password: originalUser.password,
            token: originalUser.token,
            basePath: data.basePath,
            useDemoServer: originalUser.useDemoServer,
          );
        }
      },
      onError: (code, msg) {
        LogUtil.d("requestBasePath error: $msg");
      },
    );
  }
}

class User {
  final String baseUrl;
  final String serverUrl;
  final bool guest;
  final String username;
  final String? password;
  final String? token;
  final String? basePath;
  final bool useDemoServer;

  User({
    required this.baseUrl,
    required this.serverUrl,
    this.guest = true,
    this.username = "guest",
    this.password,
    this.token,
    this.basePath,
    this.useDemoServer = false,
  });
}
