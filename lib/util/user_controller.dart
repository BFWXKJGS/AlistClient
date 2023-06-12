import 'package:get/get.dart';
import 'package:sp_util/sp_util.dart';

import 'constant.dart';

class UserController extends GetxController {
  var user = User(baseUrl: "", serverUrl: "").obs;

  void login(User user) {
    this.user.value = user;

    SpUtil.putString(AlistConstant.serverUrl, user.serverUrl);
    SpUtil.putString(AlistConstant.baseUrl, user.baseUrl);
    SpUtil.putString(AlistConstant.username, user.username ?? "");
    SpUtil.putString(AlistConstant.password, user.password ?? "");
    SpUtil.putString(AlistConstant.token, user.token ?? "");
    SpUtil.putBool(AlistConstant.guest, user.guest);
    SpUtil.putBool(AlistConstant.useDemoServer, user.useDemoServer);
  }

  void logout() {
    var currentUserValue = user.value;
    var isUseDemoServer = currentUserValue.useDemoServer;
    var guest = currentUserValue.guest;
    var newUserValue = User(
        baseUrl: isUseDemoServer ? "" : currentUserValue.baseUrl,
        serverUrl: isUseDemoServer ? "" : currentUserValue.serverUrl,
        guest: false,
        username: currentUserValue.username,
        password: currentUserValue.password,
        token: null);
    user.value = newUserValue;
    SpUtil.remove(AlistConstant.guest);
    SpUtil.remove(AlistConstant.token);
    if (isUseDemoServer) {
      SpUtil.remove(AlistConstant.useDemoServer);
      SpUtil.remove(AlistConstant.serverUrl);
      SpUtil.remove(AlistConstant.baseUrl);
    }
    if (guest) {
      SpUtil.remove(AlistConstant.username);
    }
  }
}

class User {
  final String baseUrl;
  final String serverUrl;
  final bool guest;
  final String username;
  final String? password;
  final String? token;
  final bool useDemoServer;

  User({
    required this.baseUrl,
    required this.serverUrl,
    this.guest = true,
    this.username = "guest",
    this.password,
    this.token,
    this.useDemoServer = false,
  });
}
