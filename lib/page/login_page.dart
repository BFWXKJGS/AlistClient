import 'package:alist/entity/http_result.dart';
import 'package:alist/entity/login_resp_entity.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/util/constant.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'home_page.dart';

typedef LoginSuccessCallback = Function();

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final addressController =
      TextEditingController(text: SpUtil.getString(Constant.address) ?? "");
  final usernameController =
      TextEditingController(text: SpUtil.getString(Constant.username) ?? "");
  final passwordController =
      TextEditingController(text: SpUtil.getString(Constant.password) ?? "");
  final CancelToken _cancelToken = CancelToken();

  Future<HttpResult<T>> toHttpResult<T>(Map<String, dynamic> data) {
    return compute(HttpResult<T>.fromJson, data);
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration phoneNumberDecoration =
        const InputDecoration(hintText: "用户名");
    InputDecoration passwordDecoration = const InputDecoration(hintText: "密码");
    InputDecoration addressDecoration =
        const InputDecoration(hintText: "服务器地址");

    Future<void> login(LoginSuccessCallback callback) async {
      var address = addressController.text.trim();
      var username = usernameController.text.trim();
      var password = passwordController.text.trim();

      var baseUrl = "${address}api/";
      configDio(baseUrl: baseUrl);
      DioUtils.instance
          .requestNetwork<LoginRespEntity>(Method.post, "auth/login",
              params: {
                'username': username,
                'password': password,
                'opt_code': '',
              },
              cancelToken: _cancelToken, onSuccess: (data) {
        SpUtil.putString(Constant.address, address);
        SpUtil.putString(Constant.baseUrl, baseUrl);
        SpUtil.putString(Constant.username, username);
        SpUtil.putString(Constant.password, password);
        SpUtil.putString(Constant.token, data!.token);
        callback();
      }, onError: (code, message) {});
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("登录"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            TextField(
              decoration: addressDecoration,
              controller: addressController,
            ),
            TextField(
              decoration: phoneNumberDecoration,
              controller: usernameController,
            ),
            TextField(
              decoration: passwordDecoration,
              controller: passwordController,
            ),
            const SizedBox(
              height: 20,
            ),
            ButtonX(
              buttonText: "登录",
              onPressed: () {
                login(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomePage(path: "/"),
                    ),
                  );
                });
              },
            ),
            const SizedBox(
              height: 20,
            ),
            ButtonX(
              buttonText: "游客模式",
              onPressed: () {
                SpUtil.remove(Constant.token);
                var address = addressController.text.trim();
                var baseUrl = "${address}api/";
                configDio(baseUrl: baseUrl);
                SpUtil.putString(Constant.baseUrl, baseUrl);
                SpUtil.putString(Constant.address, address);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomePage(path: "/"),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _cancelToken.cancel();
  }
}

class ButtonX extends StatelessWidget {
  final String buttonText;
  final VoidCallback onPressed;

  const ButtonX({
    super.key,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(buttonText),
        ],
      ),
    );
  }
}
