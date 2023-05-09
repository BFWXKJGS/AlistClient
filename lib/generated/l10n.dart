// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Alist Client`
  String get appName {
    return Intl.message(
      'Alist Client',
      name: 'appName',
      desc: '',
      args: [],
    );
  }

  /// `Sign in`
  String get screenName_login {
    return Intl.message(
      'Sign in',
      name: 'screenName_login',
      desc: '',
      args: [],
    );
  }

  /// `Root`
  String get screenName_fileListRoot {
    return Intl.message(
      'Root',
      name: 'screenName_fileListRoot',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get screenName_settings {
    return Intl.message(
      'Settings',
      name: 'screenName_settings',
      desc: '',
      args: [],
    );
  }

  /// `Home`
  String get screenName_home {
    return Intl.message(
      'Home',
      name: 'screenName_home',
      desc: '',
      args: [],
    );
  }

  /// `Donate`
  String get screenName_donate {
    return Intl.message(
      'Donate',
      name: 'screenName_donate',
      desc: '',
      args: [],
    );
  }

  /// `About`
  String get screenName_about {
    return Intl.message(
      'About',
      name: 'screenName_about',
      desc: '',
      args: [],
    );
  }

  /// `Username`
  String get loginScreen_hint_username {
    return Intl.message(
      'Username',
      name: 'loginScreen_hint_username',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get loginScreen_hint_password {
    return Intl.message(
      'Password',
      name: 'loginScreen_hint_password',
      desc: '',
      args: [],
    );
  }

  /// `Server URL`
  String get loginScreen_hint_serverUrl {
    return Intl.message(
      'Server URL',
      name: 'loginScreen_hint_serverUrl',
      desc: '',
      args: [],
    );
  }

  /// `Sign in`
  String get loginScreen_button_login {
    return Intl.message(
      'Sign in',
      name: 'loginScreen_button_login',
      desc: '',
      args: [],
    );
  }

  /// `Browse as a guest`
  String get loginScreen_button_guestMode {
    return Intl.message(
      'Browse as a guest',
      name: 'loginScreen_button_guestMode',
      desc: '',
      args: [],
    );
  }

  /// `Server URL is invalid`
  String get loginScreen_tips_serverUrlError {
    return Intl.message(
      'Server URL is invalid',
      name: 'loginScreen_tips_serverUrlError',
      desc: '',
      args: [],
    );
  }

  /// `Username or password is empty`
  String get loginScreen_tips_usernameOrPasswordEmpty {
    return Intl.message(
      'Username or password is empty',
      name: 'loginScreen_tips_usernameOrPasswordEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Account`
  String get settingsScreen_item_account {
    return Intl.message(
      'Account',
      name: 'settingsScreen_item_account',
      desc: '',
      args: [],
    );
  }

  /// `Sign in`
  String get settingsScreen_item_login {
    return Intl.message(
      'Sign in',
      name: 'settingsScreen_item_login',
      desc: '',
      args: [],
    );
  }

  /// `Donate`
  String get settingsScreen_item_donate {
    return Intl.message(
      'Donate',
      name: 'settingsScreen_item_donate',
      desc: '',
      args: [],
    );
  }

  /// `About`
  String get settingsScreen_item_about {
    return Intl.message(
      'About',
      name: 'settingsScreen_item_about',
      desc: '',
      args: [],
    );
  }

  /// `Failed to load photo`
  String get photo_load_failed {
    return Intl.message(
      'Failed to load photo',
      name: 'photo_load_failed',
      desc: '',
      args: [],
    );
  }

  /// `WeChat`
  String get wechat {
    return Intl.message(
      'WeChat',
      name: 'wechat',
      desc: '',
      args: [],
    );
  }

  /// `Alipay`
  String get alipay {
    return Intl.message(
      'Alipay',
      name: 'alipay',
      desc: '',
      args: [],
    );
  }

  /// `Play failed, click retry`
  String get playerSkin_tips_playVideoFailed {
    return Intl.message(
      'Play failed, click retry',
      name: 'playerSkin_tips_playVideoFailed',
      desc: '',
      args: [],
    );
  }

  /// `Do you need to logout？`
  String get tips_logout {
    return Intl.message(
      'Do you need to logout？',
      name: 'tips_logout',
      desc: '',
      args: [],
    );
  }

  /// `Logout`
  String get logout {
    return Intl.message(
      'Logout',
      name: 'logout',
      desc: '',
      args: [],
    );
  }

  /// `Browse as a guest`
  String get guestModeDialog_title {
    return Intl.message(
      'Browse as a guest',
      name: 'guestModeDialog_title',
      desc: '',
      args: [],
    );
  }

  /// `You have not entered the server address, do you want to access the default server as a guest?`
  String get guestModeDialog_content {
    return Intl.message(
      'You have not entered the server address, do you want to access the default server as a guest?',
      name: 'guestModeDialog_content',
      desc: '',
      args: [],
    );
  }

  /// `Yes`
  String get guestModeDialog_btn_ok {
    return Intl.message(
      'Yes',
      name: 'guestModeDialog_btn_ok',
      desc: '',
      args: [],
    );
  }

  /// `No`
  String get guestModeDialog_btn_cancel {
    return Intl.message(
      'No',
      name: 'guestModeDialog_btn_cancel',
      desc: '',
      args: [],
    );
  }

  /// `Directory password`
  String get directoryPasswordDialog_title {
    return Intl.message(
      'Directory password',
      name: 'directoryPasswordDialog_title',
      desc: '',
      args: [],
    );
  }

  /// `ok`
  String get directoryPasswordDialog_btn_ok {
    return Intl.message(
      'ok',
      name: 'directoryPasswordDialog_btn_ok',
      desc: '',
      args: [],
    );
  }

  /// `cancel`
  String get directoryPasswordDialog_btn_cancel {
    return Intl.message(
      'cancel',
      name: 'directoryPasswordDialog_btn_cancel',
      desc: '',
      args: [],
    );
  }

  /// `Password is empty!`
  String get directoryPasswordDialog_tips_passwordEmpty {
    return Intl.message(
      'Password is empty!',
      name: 'directoryPasswordDialog_tips_passwordEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Network error`
  String get net_error_net_error {
    return Intl.message(
      'Network error',
      name: 'net_error_net_error',
      desc: '',
      args: [],
    );
  }

  /// `Data parsing exceptions`
  String get net_error_parse_error {
    return Intl.message(
      'Data parsing exceptions',
      name: 'net_error_parse_error',
      desc: '',
      args: [],
    );
  }

  /// `Network error`
  String get net_error_socket_error {
    return Intl.message(
      'Network error',
      name: 'net_error_socket_error',
      desc: '',
      args: [],
    );
  }

  /// `Server error, please try again later`
  String get net_error_http_error {
    return Intl.message(
      'Server error, please try again later',
      name: 'net_error_http_error',
      desc: '',
      args: [],
    );
  }

  /// `Connection timeout`
  String get net_error_connect_timeout_error {
    return Intl.message(
      'Connection timeout',
      name: 'net_error_connect_timeout_error',
      desc: '',
      args: [],
    );
  }

  /// `Request timeout`
  String get net_error_send_timeout_error {
    return Intl.message(
      'Request timeout',
      name: 'net_error_send_timeout_error',
      desc: '',
      args: [],
    );
  }

  /// `Response timeout`
  String get net_error_receive_timeout_error {
    return Intl.message(
      'Response timeout',
      name: 'net_error_receive_timeout_error',
      desc: '',
      args: [],
    );
  }

  /// `Request cancelled`
  String get net_error_cancel_error {
    return Intl.message(
      'Request cancelled',
      name: 'net_error_cancel_error',
      desc: '',
      args: [],
    );
  }

  /// `bad certificate`
  String get net_error_certificate_error {
    return Intl.message(
      'bad certificate',
      name: 'net_error_certificate_error',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
