import 'dart:io';

import 'package:alist/entity/login_resp_entity.dart';
import 'package:alist/generated/images.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/util/constant.dart';
import 'package:alist/util/global.dart';
import 'package:alist/util/keyboard_utils.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/util/user_controller.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:sp_util/sp_util.dart';

typedef LoginSuccessCallback = Function();
typedef LoginFailureCallback = Function(int code, String msg);

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AlistScaffold(
      appbarTitle: Text(Intl.screenName_login.tr),
      body: const SingleChildScrollView(
        child: LoginScreenContainer(),
      ),
    );
  }
}

class LoginScreenContainer extends StatefulWidget {
  const LoginScreenContainer({super.key});

  @override
  State<LoginScreenContainer> createState() => _LoginScreenState();
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

class _LoginScreenState extends State<LoginScreenContainer> {
  final UserController _userController = Get.find();
  final addressController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final _2faController = TextEditingController();
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
    var twofaCode = _2faController.text.trim();

    if (!_checkServerUrl(address)) {
      SmartDialog.showToast(Intl.loginScreen_tips_serverUrlError.tr);
      return;
    }
    if (username.isEmpty || password.isEmpty) {
      SmartDialog.showToast(Intl.loginScreen_tips_usernameOrPasswordEmpty.tr);
      return;
    }

    SmartDialog.showLoading();
    var baseUrl = "${address}api/";
    DioUtils.instance.configBaseUrlAgain(baseUrl);
    DioUtils.instance.requestNetwork<LoginRespEntity>(
      Method.post,
      "auth/login",
      params: {
        'username': username,
        'password': password,
        'otp_code': twofaCode,
      },
      cancelToken: _cancelToken,
      onSuccess: (data) {
        _userController.login(User(
          baseUrl: baseUrl,
          serverUrl: address,
          username: username,
          password: password,
          token: data!.token,
          guest: false,
        ));
        onSuccess();
      },
      onError: (code, message) => onFailure(code, message),
    );
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
    if (!_checkServerUrl(address)) {
      SmartDialog.showToast(Intl.loginScreen_tips_serverUrlError.tr);
      return;
    }

    var baseUrl = "${address}api/";
    DioUtils.instance.configBaseUrlAgain(baseUrl);
    _userController.login(User(
      baseUrl: baseUrl,
      serverUrl: address,
      username: "guest",
      password: null,
      token: null,
      guest: true,
    ));
    Get.offNamed(NamedRouter.home);
  }

  void _tryEntryDefaultServer(BuildContext context) {
    SmartDialog.show(builder: (_) {
      return AlertDialog(
        title: Text(Intl.guestModeDialog_title.tr),
        content: Text(Intl.guestModeDialog_content.tr),
        actions: [
          TextButton(
            onPressed: () {
              SmartDialog.dismiss();
            },
            child: Text(
              Intl.guestModeDialog_btn_cancel.tr,
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
          TextButton(
            onPressed: () {
              _enterVisitorMode(context, Global.demoServerBaseUrl);
              SmartDialog.dismiss();
            },
            child: Text(Intl.guestModeDialog_btn_ok.tr),
          ),
        ],
      );
    });
  }

  _onLoginButtonClick(BuildContext context) {
    _login(
      onSuccess: () {
        SmartDialog.dismiss();
        Get.offNamed(NamedRouter.home);
      },
      onFailure: (code, message) {
        SmartDialog.dismiss();
        if (code == 402) {
          // need 2FA code
          if (_2faController.text.isNotEmpty) {
            _2faController.clear();
            SmartDialog.showToast(message);
          }
          FocusManager.instance.primaryFocus?.unfocus();
          _showType2FACodeDialog(context);
          return;
        }
        SmartDialog.showToast(message);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    addressController.text = _userController.user().serverUrl;
    String username = _userController.user().username ?? "";
    if ("guest" != username) {
      usernameController.text = username;
    }
    passwordController.text = _userController.user().password ?? "";
    bool isAgreePrivacyPolicy =
        SpUtil.getBool(AlistConstant.isAgreePrivacyPolicy) ?? false;
    if (!isAgreePrivacyPolicy) {
      Future.delayed(const Duration(microseconds: 200))
          .then((value) => _showAgreementDialog());
    }
    // if (Platform.isIOS) {
    //   _testNetwork();
    // }
  }

  // Used to request network access when entering the app for the first time
  // just for IOS
  void _testNetwork() async {
    await Future.delayed(const Duration(seconds: 1));
    DioUtils.instance.requestNetwork(Method.get, "/").catchError((e) {});
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration phoneNumberDecoration = LoginInputDecoration(
      hintText: Intl.loginScreen_hint_username.tr,
    );
    InputDecoration passwordDecoration = LoginInputDecoration(
      hintText: Intl.loginScreen_hint_password.tr,
    );
    InputDecoration addressDecoration = LoginInputDecoration(
      hintText: Intl.loginScreen_hint_serverUrl.tr,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 50, 25, 0),
      child: Column(
        children: [
          Image.asset(Images.logo),
          LoginTextField(
            padding: const EdgeInsets.only(top: 30),
            icon: Image.asset(Images.loginScreenServerUrl),
            decoration: addressDecoration,
            controller: addressController,
          ),
          LoginTextField(
            padding: const EdgeInsets.only(top: 20),
            icon: Image.asset(Images.loginScreenAccount),
            decoration: phoneNumberDecoration,
            controller: usernameController,
          ),
          LoginTextField(
            padding: const EdgeInsets.only(top: 20),
            obscureText: true,
            icon: Image.asset(Images.loginScreenPassword),
            decoration: passwordDecoration,
            controller: passwordController,
          ),
          const SizedBox(
            height: 30,
          ),
          FilledButton(
            onPressed: () {
              // clear the last 2fa code typed.
              _2faController.text = "";
              KeyboardUtil.hideKeyboard(context);
              _onLoginButtonClick(context);
            },
            child: Center(
              child: Text(Intl.loginScreen_button_login.tr),
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
              child: Text(Intl.loginScreen_button_guestMode.tr),
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

  _showAgreementDialog() {
    SmartDialog.show(
      clickMaskDismiss: false,
      backDismiss: false,
      builder: (context) {
        return AlertDialog(
          title: Text(Intl.privacyDialog_title.tr),
          content: RichText(
              text: TextSpan(children: [
            TextSpan(
                text: Intl.privacyDialog_content_part1.tr,
                style: Theme.of(context).textTheme.bodyMedium),
            TextSpan(
                text: Intl.privacyDialog_link.tr,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    SmartDialog.dismiss();
                    await _goPrivacyPolicyPage();
                    _showAgreementDialog();
                  }),
            TextSpan(
                text: Intl.privacyDialog_content_part2.tr,
                style: Theme.of(context).textTheme.bodyMedium),
          ])),
          actions: [
            TextButton(
                onPressed: () {
                  SmartDialog.dismiss();
                  exit(0);
                },
                child: Text(Intl.privacyDialog_btn_cancel.tr)),
            TextButton(
              onPressed: () {
                SmartDialog.dismiss();
                _testNetwork();
                SpUtil.putBool(AlistConstant.isAgreePrivacyPolicy, true);
              },
              child: Text(Intl.privacyDialog_btn_ok.tr),
            )
          ],
        );
      },
    );
  }

  Future<void> _goPrivacyPolicyPage() async {
    String local = "en_US";
    if (Get.locale?.toString().startsWith("zh_") == true) {
      local = "zh";
    }

    final url =
        "https://${Global.configServerHost}/alist_h5/privacyPolicy?lang=$local";
    await Get.toNamed(
      NamedRouter.web,
      arguments: {"url": url},
    );
  }

  void _showType2FACodeDialog(BuildContext context) {
    SmartDialog.show(
        clickMaskDismiss: false,
        builder: (_) {
          return AlertDialog(
            title: Text(Intl.twofaCodeDialog_title.tr),
            content: TextField(
              controller: _2faController,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isCollapsed: true,
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 11, vertical: 12),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    _2faController.text = "";
                    SmartDialog.dismiss();
                  },
                  child: Text(
                    Intl.twofaCodeDialog_btn_cancel.tr,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary),
                  )),
              TextButton(
                  onPressed: () {
                    SmartDialog.dismiss();
                    _onConfirm(context);
                  },
                  child: Text(
                    Intl.twofaCodeDialog_btn_ok.tr,
                  ))
            ],
          );
        });
  }

  void _onConfirm(BuildContext context) {
    var twofaCode = _2faController.text.trim();
    if (twofaCode.isEmpty) {
      SmartDialog.showToast(Intl.twofaCodeDialog_tips_codeEmpty.tr);
      return;
    }

    KeyboardUtil.hideKeyboard(context);
    _onLoginButtonClick(context);
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
