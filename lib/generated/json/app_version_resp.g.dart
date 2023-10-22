import 'package:alist/generated/json/base/json_convert_content.dart';
import 'package:alist/entity/app_version_resp.dart';

AppVersionResp $AppVersionRespFromJson(Map<String, dynamic> json) {
  final AppVersionResp appVersionResp = AppVersionResp();
  final String? updates = jsonConvert.convert<String>(json['updates']);
  if (updates != null) {
    appVersionResp.updates = updates;
  }
  final AppVersionRespAndroid? android = jsonConvert.convert<
      AppVersionRespAndroid>(json['android']);
  if (android != null) {
    appVersionResp.android = android;
  }
  final AppVersionRespIos? ios = jsonConvert.convert<AppVersionRespIos>(
      json['ios']);
  if (ios != null) {
    appVersionResp.ios = ios;
  }
  return appVersionResp;
}

Map<String, dynamic> $AppVersionRespToJson(AppVersionResp entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['updates'] = entity.updates;
  data['android'] = entity.android.toJson();
  data['ios'] = entity.ios.toJson();
  return data;
}

extension AppVersionRespExtension on AppVersionResp {
  AppVersionResp copyWith({
    String? updates,
    AppVersionRespAndroid? android,
    AppVersionRespIos? ios,
  }) {
    return AppVersionResp()
      ..updates = updates ?? this.updates
      ..android = android ?? this.android
      ..ios = ios ?? this.ios;
  }
}

AppVersionRespAndroid $AppVersionRespAndroidFromJson(
    Map<String, dynamic> json) {
  final AppVersionRespAndroid appVersionRespAndroid = AppVersionRespAndroid();
  final String? version = jsonConvert.convert<String>(json['version']);
  if (version != null) {
    appVersionRespAndroid.version = version;
  }
  final String? githubUrl = jsonConvert.convert<String>(json['githubUrl']);
  if (githubUrl != null) {
    appVersionRespAndroid.githubUrl = githubUrl;
  }
  final String? googlePlayUrl = jsonConvert.convert<String>(
      json['googlePlayUrl']);
  if (googlePlayUrl != null) {
    appVersionRespAndroid.googlePlayUrl = googlePlayUrl;
  }
  return appVersionRespAndroid;
}

Map<String, dynamic> $AppVersionRespAndroidToJson(
    AppVersionRespAndroid entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['version'] = entity.version;
  data['githubUrl'] = entity.githubUrl;
  data['googlePlayUrl'] = entity.googlePlayUrl;
  return data;
}

extension AppVersionRespAndroidExtension on AppVersionRespAndroid {
  AppVersionRespAndroid copyWith({
    String? version,
    String? githubUrl,
    String? googlePlayUrl,
  }) {
    return AppVersionRespAndroid()
      ..version = version ?? this.version
      ..githubUrl = githubUrl ?? this.githubUrl
      ..googlePlayUrl = googlePlayUrl ?? this.googlePlayUrl;
  }
}

AppVersionRespIos $AppVersionRespIosFromJson(Map<String, dynamic> json) {
  final AppVersionRespIos appVersionRespIos = AppVersionRespIos();
  final String? version = jsonConvert.convert<String>(json['version']);
  if (version != null) {
    appVersionRespIos.version = version;
  }
  final String? appStoreUrl = jsonConvert.convert<String>(json['appStoreUrl']);
  if (appStoreUrl != null) {
    appVersionRespIos.appStoreUrl = appStoreUrl;
  }
  return appVersionRespIos;
}

Map<String, dynamic> $AppVersionRespIosToJson(AppVersionRespIos entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['version'] = entity.version;
  data['appStoreUrl'] = entity.appStoreUrl;
  return data;
}

extension AppVersionRespIosExtension on AppVersionRespIos {
  AppVersionRespIos copyWith({
    String? version,
    String? appStoreUrl,
  }) {
    return AppVersionRespIos()
      ..version = version ?? this.version
      ..appStoreUrl = appStoreUrl ?? this.appStoreUrl;
  }
}