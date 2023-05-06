import 'package:alist/entity/login_resp_entity.dart';
import 'package:alist/generated/images.dart';
import 'package:alist/generated/l10n.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/util/constant.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';

typedef LoginSuccessCallback = Function();
typedef LoginFailureCallback = Function(int code, String msg);

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AlistScaffold(
      appbarTitle: Text(S.of(context).screenName_login),
      body: const SingleChildScrollView(
        child: LoginPageContainer(),
      ),
    );
  }
}

class LoginPageContainer extends StatefulWidget {
  const LoginPageContainer({super.key});

  @override
  State<LoginPageContainer> createState() => _LoginPageState();
}

class LoginInputDecoration extends InputDecoration {
  const LoginInputDecoration({required String hintText})
      : super(
          hintText: hintText,
          border: const OutlineInputBorder(),
          isCollapsed: true,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
        );
}

class _LoginPageState extends State<LoginPageContainer> {
  final addressController =
      TextEditingController(text: SpUtil.getString(Constant.address) ?? "");
  final usernameController =
      TextEditingController(text: SpUtil.getString(Constant.username) ?? "");
  final passwordController =
      TextEditingController(text: SpUtil.getString(Constant.password) ?? "");
  final CancelToken _cancelToken = CancelToken();

  Future<void> _login(
      {required LoginSuccessCallback onSuccess,
      required LoginFailureCallback onFailure}) async {
    var address = addressController.text.trim();
    if (!address.endsWith("/")) {
      address = "$address/";
    }

    var username = usernameController.text.trim();
    var password = passwordController.text.trim();

    if (!_checkServerUrl(address)) {
      SmartDialog.showToast(S.of(context).loginScreen_tips_serverUrlError);
      return;
    }
    if (username.isEmpty || password.isEmpty) {
      SmartDialog.showToast(
          S.of(context).loginScreen_tips_usernameOrPasswordEmpty);
      return;
    }

    SmartDialog.showLoading();
    var baseUrl = "${address}api/";
    DioUtils.instance.configBaseUrlAgain(baseUrl);
    DioUtils.instance.requestNetwork<LoginRespEntity>(Method.post, "auth/login",
        params: {
          'username': username,
          'password': password,
          'opt_code': '',
        },
        cancelToken: _cancelToken,
        onSuccess: (data) {
          SpUtil.putString(Constant.address, address);
          SpUtil.putString(Constant.baseUrl, baseUrl);
          SpUtil.putString(Constant.username, username);
          SpUtil.putString(Constant.password, password);
          SpUtil.putString(Constant.token, data!.token);
          SpUtil.putBool(Constant.guest, false);
          onSuccess();
        },
        onError: (code, message) => onFailure(code, message));
  }

  bool _checkServerUrl(String serverUrl) {
    if (serverUrl.isEmpty) {
      return false;
    }
    if (!serverUrl.startsWith("http://") && !serverUrl.startsWith("https://")) {
      return false;
    }
    return true;
  }

  _enterVisitorMode(BuildContext context, String address) {
    if (!address.endsWith("/")) {
      address = "$address/";
    }
    SpUtil.remove(Constant.token);
    if (!_checkServerUrl(address)) {
      SmartDialog.showToast(S.of(context).loginScreen_tips_serverUrlError);
      return;
    }

    var baseUrl = "${address}api/";
    DioUtils.instance.configBaseUrlAgain(baseUrl);
    SpUtil.putString(Constant.baseUrl, baseUrl);
    SpUtil.putString(Constant.address, address);
    SpUtil.putBool(Constant.guest, true);

    context.goNamed(NamedRouter.home);
  }

  void _tryEntryDefaultServer(BuildContext context) {
    SmartDialog.show(builder: (_) {
      return AlertDialog(
        title: Text(S.of(context).guestModeDialog_title),
        content: Text(S.of(context).guestModeDialog_content),
        actions: [
          TextButton(
            onPressed: () {
              SmartDialog.dismiss();
            },
            child: Text(
              S.of(context).guestModeDialog_btn_cancel,
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
          TextButton(
            onPressed: () {
              _enterVisitorMode(context, Constant.defaultServerUrl);
              SmartDialog.dismiss();
            },
            child: Text(S.of(context).guestModeDialog_btn_ok),
          ),
        ],
      );
    });
  }

  _onLoginButtonClick(BuildContext context) {
    _login(
      onSuccess: () {
        SmartDialog.dismiss();
        context.goNamed(NamedRouter.home);
      },
      onFailure: (code, message) {
        SmartDialog.dismiss();
        SmartDialog.showToast(message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration phoneNumberDecoration = LoginInputDecoration(
      hintText: S.of(context).loginScreen_hint_username,
    );
    InputDecoration passwordDecoration = LoginInputDecoration(
      hintText: S.of(context).loginScreen_hint_password,
    );
    InputDecoration addressDecoration = LoginInputDecoration(
      hintText: S.of(context).loginScreen_hint_serverUrl,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 50, 25, 0),
      child: Column(
        children: [
          Image.asset(Images.logo),
          LoginTextField(
            padding: const EdgeInsets.only(top: 30),
            icon: Image.asset(Images.loginPageServerUrl),
            decoration: addressDecoration,
            controller: addressController,
          ),
          LoginTextField(
            padding: const EdgeInsets.only(top: 20),
            icon: Image.asset(Images.loginPageAccount),
            decoration: phoneNumberDecoration,
            controller: usernameController,
          ),
          LoginTextField(
            padding: const EdgeInsets.only(top: 20),
            obscureText: true,
            icon: Image.asset(Images.loginPagePassword),
            decoration: passwordDecoration,
            controller: passwordController,
          ),
          const SizedBox(
            height: 30,
          ),
          FilledButton(
            onPressed: () {
              _onLoginButtonClick(context);
            },
            child: Center(
              child: Text(S.of(context).loginScreen_button_login),
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () {
              var address = addressController.text.trim();
              if (address.isEmpty) {
                _tryEntryDefaultServer(context);
              } else {
                _enterVisitorMode(context, address);
              }
            },
            child: Center(
              child: Text(S.of(context).loginScreen_button_guestMode),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _cancelToken.cancel();
  }
}

class LoginTextField extends StatelessWidget {
  const LoginTextField({
    super.key,
    required this.icon,
    required this.decoration,
    required this.controller,
    required this.padding,
    this.obscureText = false,
  });

  final InputDecoration decoration;
  final TextEditingController controller;
  final Widget icon;
  final EdgeInsetsGeometry padding;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: icon,
          ),
          Expanded(
            child: TextField(
              decoration: decoration,
              controller: controller,
              obscureText: obscureText,
            ),
          )
        ],
      ),
    );
  }
}
