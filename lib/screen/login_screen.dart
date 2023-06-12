import 'dart:io';

import 'package:alist/entity/login_resp_entity.dart';
import 'package:alist/entity/my_info_resp.dart';
import 'package:alist/generated/images.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/util/constant.dart';
import 'package:alist/util/focus_node_utils.dart';
import 'package:alist/util/global.dart';
import 'package:alist/util/keyboard_utils.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/util/string_utils.dart';
import 'package:alist/util/user_controller.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

typedef LoginSuccessCallback = Function();
typedef LoginFailureCallback = Function(int code, String msg);

const _bottomBarTypes1 = ["http://", "https://", "www.", "m."];
const _bottomBarTypes2 = ["www.", "m.", ".com", ".cn"];

class LoginScreen extends StatelessWidget {
  final loginScreenController = Get.put(LoginScreenController());

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AlistScaffold(
      appbarTitle: Text(Intl.screenName_login.tr),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              Get.focusScope?.unfocus();
            },
            behavior: HitTestBehavior.translucent,
            child: SingleChildScrollView(
              child: LoginScreenContainer(),
            ),
          ),
          Obx(() => Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: buildServerUrlBottomBar(
                  context,
                  loginScreenController.bottomBarTypes,
                  loginScreenController.keyboardHeight.value > 0 &&
                      loginScreenController.addressTextFieldIsFocused.value,
                ),
              )),
        ],
      ),
    );
  }

  Widget buildServerUrlBottomBar(
      BuildContext context, List<String> bottomBarTypes, bool visible) {
    if (!visible) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Row(
        children: [
          for (var value1 in bottomBarTypes)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  style: ButtonStyle(
                      padding: MaterialStateProperty.all(EdgeInsets.zero),
                      minimumSize:
                          MaterialStateProperty.all(const Size(0, 30))),
                  onPressed: () =>
                      loginScreenController.appendServerUrlText(value1),
                  child: Text(value1),
                ),
              ),
            )
        ],
      ),
    );
  }
}

class LoginScreenContainer extends StatelessWidget {
  LoginScreenContainer({super.key});

  final loginScreenController = Get.find<LoginScreenController>();

  @override
  Widget build(BuildContext context) {
    InputDecoration usernameDecoration = LoginInputDecoration(
      hintText: "guest",
      labelText: Intl.loginScreen_label_username.tr,
    );
    InputDecoration passwordDecoration = LoginInputDecoration(
      hintText: "password",
      labelText: Intl.loginScreen_label_password.tr,
    );
    InputDecoration addressDecoration = LoginInputDecoration(
      hintText: "https://example.com/",
      labelText: Intl.loginScreen_label_serverUrl.tr,
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
            controller: loginScreenController.addressController,
            focusNode: loginScreenController.addressFocusNode,
            keyboardType: TextInputType.url,
          ),
          LoginTextField(
            padding: const EdgeInsets.only(top: 20),
            icon: Image.asset(Images.loginScreenAccount),
            decoration: usernameDecoration,
            controller: loginScreenController.usernameController,
          ),
          LoginTextField(
            padding: const EdgeInsets.only(top: 20),
            obscureText: true,
            icon: Image.asset(Images.loginScreenPassword),
            decoration: passwordDecoration,
            controller: loginScreenController.passwordController,
          ),
          Obx(() => buildSSLErrorIgnoreCheckbox(context)),
          const SizedBox(
            height: 20,
          ),
          FilledButton(
            onPressed: () {
              // clear the last 2fa code typed.
              loginScreenController.twofaController.text = "";
              KeyboardUtil.hideKeyboard(context);
              loginScreenController._onLoginButtonClick(context);
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
              var address = loginScreenController.addressController.text.trim();
              if (address.isEmpty) {
                loginScreenController._tryEntryDefaultServer(context);
              } else {
                loginScreenController._enterVisitorMode(address);
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

  Row buildSSLErrorIgnoreCheckbox(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: loginScreenController.ignoreSSLError.value,
          onChanged: (checked) {
            loginScreenController.ignoreSSLError.value = checked ?? false;
          },
        ),
        GestureDetector(
          onTap: () {
            loginScreenController.ignoreSSLError.value =
                !loginScreenController.ignoreSSLError.value;
          },
          child: Text(Intl.loginScreen_checkbox_ignoreSSLError.tr),
        ),
      ],
    );
  }
}

class LoginInputDecoration extends InputDecoration {
  LoginInputDecoration({required String hintText, required String labelText})
      : super(
          hintText: hintText,
          border: const OutlineInputBorder(),
          isCollapsed: true,
          label: Text(labelText),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
        );
}

class LoginScreenController extends GetxController with WidgetsBindingObserver {
  final UserController userController = Get.find();
  final FocusNode addressFocusNode = FocusNode();
  final addressController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final twofaController = TextEditingController();
  final CancelToken _cancelToken = CancelToken();
  var keyboardHeight = 0.0.obs;
  var bottomBarTypes = _bottomBarTypes1.obs;
  var addressTextFieldIsFocused = false.obs;

  var ignoreSSLError = false.obs;

  @override
  void onInit() {
    super.onInit();
    addressController.addListener(() {
      var text = addressController.text.trim();
      bottomBarTypes.value = text.isEmpty ? _bottomBarTypes1 : _bottomBarTypes2;
    });
    ignoreSSLError.value =
        SpUtil.getBool(AlistConstant.ignoreSSLError) ?? false;

    addressController.text = userController.user().serverUrl;
    String username = userController.user().username ?? "";
    if ("guest" != username) {
      usernameController.text = username;
    }
    passwordController.text = userController.user().password ?? "";
    bool isAgreePrivacyPolicy =
        SpUtil.getBool(AlistConstant.isAgreePrivacyPolicy) ?? false;
    if (!isAgreePrivacyPolicy) {
      Future.delayed(const Duration(microseconds: 200))
          .then((value) => _showAgreementDialog());
    }
    WidgetsBinding.instance.addObserver(this);
    addressFocusNode.addListener(() {
      addressTextFieldIsFocused.value = addressFocusNode.hasFocus;
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (Get.context != null) {
        keyboardHeight.value = MediaQuery.of(Get.context!).viewInsets.bottom;
      }
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelToken.cancel();
    super.onClose();
  }

  Future<void> _login(
      {required LoginSuccessCallback onSuccess,
      required LoginFailureCallback onFailure}) async {
    var address = addressController.text.trim();
    if (address.isEmpty) {
      SmartDialog.showToast(Intl.loginScreen_tips_serverUrlError.tr);
      return;
    }

    if (!address.endsWith("/")) {
      address = "$address/";
    }

    var username = usernameController.text.trim();
    var password = passwordController.text.trim();
    var twofaCode = twofaController.text.trim();
    if (username.isEmpty && password.isEmpty) {
      _enterVisitorMode(address);
      return;
    }

    if (!_checkServerUrl(address)) {
      SmartDialog.showToast(Intl.loginScreen_tips_serverUrlError.tr);
      return;
    }
    if (!address.startsWith("http://") && !address.startsWith("https://")) {
      address = "http://$address";
    }
    if (username.isEmpty || password.isEmpty) {
      SmartDialog.showToast(Intl.loginScreen_tips_usernameOrPasswordEmpty.tr);
      return;
    }

    SmartDialog.showLoading();
    var baseUrl = "${address}api/";
    DioUtils.instance.configAgain(baseUrl, ignoreSSLError.value);
    DioUtils.instance.requestNetwork<LoginRespEntity>(
      Method.post,
      "auth/login",
      params: {
        'username': username,
        'password': password,
        'otp_code': twofaCode,
      },
      options: Options(followRedirects: false),
      cancelToken: _cancelToken,
      onSuccess: (data) {
        userController.login(User(
          baseUrl: baseUrl,
          serverUrl: address,
          username: username,
          password: password,
          token: data!.token,
          guest: false,
        ));
        SpUtil.putBool(AlistConstant.ignoreSSLError, ignoreSSLError.value);
        onSuccess();
      },
      onError: (code, message) => onFailure(code, message),
    );
  }

  bool _checkServerUrl(String serverUrl) {
    if (serverUrl.isEmpty) {
      return false;
    }
    if (serverUrl.contains(" ")) {
      return false;
    }
    return true;
  }

  _enterVisitorMode(String address, {bool useDemoServer = false}) {
    if (!address.endsWith("/")) {
      address = "$address/";
    }
    if (!_checkServerUrl(address)) {
      SmartDialog.showToast(Intl.loginScreen_tips_serverUrlError.tr);
      return;
    }
    if (!address.startsWith("http://") && !address.startsWith("https://")) {
      address = "http://$address";
    }

    var baseUrl = "${address}api/";
    DioUtils.instance.configAgain(baseUrl, ignoreSSLError.value);
    SmartDialog.showLoading(
        msg: "checking...", backDismiss: false, clickMaskDismiss: false);
    DioUtils.instance.requestNetwork<MyInfoResp>(Method.get, "me",
        options: Options(followRedirects: false), onSuccess: (data) {
      if (data?.disabled == true) {
        SmartDialog.showToast(Intl.loginScreen_tips_guestAccountDisabled.tr);
      } else {
        _doAfterEnterVisitorMode(baseUrl, address, data?.username,
            useDemoServer: useDemoServer);
      }
      SmartDialog.dismiss();
    }, onError: (code, message) {
      if (code == 301) {
        var baseUrl = message.substringBeforeLast("api/me")!;
        addressController.text = baseUrl;
        _enterVisitorMode(baseUrl, useDemoServer: useDemoServer);
        return;
      }
      SmartDialog.showToast(message);
      SmartDialog.dismiss();
    });
  }

  void _doAfterEnterVisitorMode(
      String baseUrl, String address, String? username,
      {bool useDemoServer = false}) {
    SpUtil.putBool(AlistConstant.ignoreSSLError, ignoreSSLError.value);
    userController.login(User(
      baseUrl: baseUrl,
      serverUrl: address,
      username: username ?? "guest",
      password: null,
      token: null,
      guest: true,
      useDemoServer: useDemoServer,
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
              SmartDialog.dismiss();
              Future.delayed(Duration.zero).then(
                (value) => _enterVisitorMode(Global.demoServerBaseUrl,
                    useDemoServer: true),
              );
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
        if (code == 301) {
          // redirect
          addressController.text = message;
          _onLoginButtonClick(context);
          return;
        }
        if (code == 402) {
          // need 2FA code
          if (twofaController.text.isNotEmpty) {
            twofaController.clear();
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

  // Used to request network access when entering the app for the first time
  // just for IOS
  void _testNetwork() async {
    await Future.delayed(const Duration(seconds: 1));
    DioUtils.instance.requestNetwork(Method.get, "/").catchError((e) {});
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
    FocusNode focusNode = FocusNode().autoFocus();
    SmartDialog.show(
        clickMaskDismiss: false,
        builder: (_) {
          return AlertDialog(
            title: Text(Intl.twofaCodeDialog_title.tr),
            content: TextField(
              controller: twofaController,
              focusNode: focusNode,
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
                    twofaController.text = "";
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
    var twofaCode = twofaController.text.trim();
    if (twofaCode.isEmpty) {
      SmartDialog.showToast(Intl.twofaCodeDialog_tips_codeEmpty.tr);
      return;
    }

    KeyboardUtil.hideKeyboard(context);
    _onLoginButtonClick(context);
  }

  appendServerUrlText(String text) {
    addressController.text = "${addressController.text}$text";
    addressController.selection = TextSelection.fromPosition(
        TextPosition(offset: addressController.text.length));
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
    this.keyboardType,
    this.focusNode,
  });

  final InputDecoration decoration;
  final TextEditingController controller;
  final Widget icon;
  final EdgeInsetsGeometry padding;
  final bool obscureText;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;

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
              focusNode: focusNode,
              keyboardType: keyboardType,
            ),
          )
        ],
      ),
    );
  }
}
