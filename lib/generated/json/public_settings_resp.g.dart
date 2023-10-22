import 'package:alist/generated/json/base/json_convert_content.dart';
import 'package:alist/entity/public_settings_resp.dart';

PublicSettingsResp $PublicSettingsRespFromJson(Map<String, dynamic> json) {
  final PublicSettingsResp publicSettingsResp = PublicSettingsResp();
  final String? allowIndexed = jsonConvert.convert<String>(
      json['allow_indexed']);
  if (allowIndexed != null) {
    publicSettingsResp.allowIndexed = allowIndexed;
  }
  final String? allowMounted = jsonConvert.convert<String>(
      json['allow_mounted']);
  if (allowMounted != null) {
    publicSettingsResp.allowMounted = allowMounted;
  }
  final String? announcement = jsonConvert.convert<String>(
      json['announcement']);
  if (announcement != null) {
    publicSettingsResp.announcement = announcement;
  }
  final String? audioAutoplay = jsonConvert.convert<String>(
      json['audio_autoplay']);
  if (audioAutoplay != null) {
    publicSettingsResp.audioAutoplay = audioAutoplay;
  }
  final String? audioCover = jsonConvert.convert<String>(json['audio_cover']);
  if (audioCover != null) {
    publicSettingsResp.audioCover = audioCover;
  }
  final String? autoUpdateIndex = jsonConvert.convert<String>(
      json['auto_update_index']);
  if (autoUpdateIndex != null) {
    publicSettingsResp.autoUpdateIndex = autoUpdateIndex;
  }
  final String? defaultPageSize = jsonConvert.convert<String>(
      json['default_page_size']);
  if (defaultPageSize != null) {
    publicSettingsResp.defaultPageSize = defaultPageSize;
  }
  final String? externalPreviews = jsonConvert.convert<String>(
      json['external_previews']);
  if (externalPreviews != null) {
    publicSettingsResp.externalPreviews = externalPreviews;
  }
  final String? favicon = jsonConvert.convert<String>(json['favicon']);
  if (favicon != null) {
    publicSettingsResp.favicon = favicon;
  }
  final String? filenameCharMapping = jsonConvert.convert<String>(
      json['filename_char_mapping']);
  if (filenameCharMapping != null) {
    publicSettingsResp.filenameCharMapping = filenameCharMapping;
  }
  final String? forwardDirectLinkParams = jsonConvert.convert<String>(
      json['forward_direct_link_params']);
  if (forwardDirectLinkParams != null) {
    publicSettingsResp.forwardDirectLinkParams = forwardDirectLinkParams;
  }
  final String? hideFiles = jsonConvert.convert<String>(json['hide_files']);
  if (hideFiles != null) {
    publicSettingsResp.hideFiles = hideFiles;
  }
  final String? homeContainer = jsonConvert.convert<String>(
      json['home_container']);
  if (homeContainer != null) {
    publicSettingsResp.homeContainer = homeContainer;
  }
  final String? homeIcon = jsonConvert.convert<String>(json['home_icon']);
  if (homeIcon != null) {
    publicSettingsResp.homeIcon = homeIcon;
  }
  final String? iframePreviews = jsonConvert.convert<String>(
      json['iframe_previews']);
  if (iframePreviews != null) {
    publicSettingsResp.iframePreviews = iframePreviews;
  }
  final String? logo = jsonConvert.convert<String>(json['logo']);
  if (logo != null) {
    publicSettingsResp.logo = logo;
  }
  final String? mainColor = jsonConvert.convert<String>(json['main_color']);
  if (mainColor != null) {
    publicSettingsResp.mainColor = mainColor;
  }
  final String? ocrApi = jsonConvert.convert<String>(json['ocr_api']);
  if (ocrApi != null) {
    publicSettingsResp.ocrApi = ocrApi;
  }
  final String? packageDownload = jsonConvert.convert<String>(
      json['package_download']);
  if (packageDownload != null) {
    publicSettingsResp.packageDownload = packageDownload;
  }
  final String? paginationType = jsonConvert.convert<String>(
      json['pagination_type']);
  if (paginationType != null) {
    publicSettingsResp.paginationType = paginationType;
  }
  final String? robotsTxt = jsonConvert.convert<String>(json['robots_txt']);
  if (robotsTxt != null) {
    publicSettingsResp.robotsTxt = robotsTxt;
  }
  final String? searchIndex = jsonConvert.convert<String>(json['search_index']);
  if (searchIndex != null) {
    publicSettingsResp.searchIndex = searchIndex;
  }
  final String? settingsLayout = jsonConvert.convert<String>(
      json['settings_layout']);
  if (settingsLayout != null) {
    publicSettingsResp.settingsLayout = settingsLayout;
  }
  final String? siteTitle = jsonConvert.convert<String>(json['site_title']);
  if (siteTitle != null) {
    publicSettingsResp.siteTitle = siteTitle;
  }
  final String? ssoLoginEnabled = jsonConvert.convert<String>(
      json['sso_login_enabled']);
  if (ssoLoginEnabled != null) {
    publicSettingsResp.ssoLoginEnabled = ssoLoginEnabled;
  }
  final String? ssoLoginPlatform = jsonConvert.convert<String>(
      json['sso_login_platform']);
  if (ssoLoginPlatform != null) {
    publicSettingsResp.ssoLoginPlatform = ssoLoginPlatform;
  }
  final String? version = jsonConvert.convert<String>(json['version']);
  if (version != null) {
    publicSettingsResp.version = version;
  }
  final String? videoAutoplay = jsonConvert.convert<String>(
      json['video_autoplay']);
  if (videoAutoplay != null) {
    publicSettingsResp.videoAutoplay = videoAutoplay;
  }
  return publicSettingsResp;
}

Map<String, dynamic> $PublicSettingsRespToJson(PublicSettingsResp entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['allow_indexed'] = entity.allowIndexed;
  data['allow_mounted'] = entity.allowMounted;
  data['announcement'] = entity.announcement;
  data['audio_autoplay'] = entity.audioAutoplay;
  data['audio_cover'] = entity.audioCover;
  data['auto_update_index'] = entity.autoUpdateIndex;
  data['default_page_size'] = entity.defaultPageSize;
  data['external_previews'] = entity.externalPreviews;
  data['favicon'] = entity.favicon;
  data['filename_char_mapping'] = entity.filenameCharMapping;
  data['forward_direct_link_params'] = entity.forwardDirectLinkParams;
  data['hide_files'] = entity.hideFiles;
  data['home_container'] = entity.homeContainer;
  data['home_icon'] = entity.homeIcon;
  data['iframe_previews'] = entity.iframePreviews;
  data['logo'] = entity.logo;
  data['main_color'] = entity.mainColor;
  data['ocr_api'] = entity.ocrApi;
  data['package_download'] = entity.packageDownload;
  data['pagination_type'] = entity.paginationType;
  data['robots_txt'] = entity.robotsTxt;
  data['search_index'] = entity.searchIndex;
  data['settings_layout'] = entity.settingsLayout;
  data['site_title'] = entity.siteTitle;
  data['sso_login_enabled'] = entity.ssoLoginEnabled;
  data['sso_login_platform'] = entity.ssoLoginPlatform;
  data['version'] = entity.version;
  data['video_autoplay'] = entity.videoAutoplay;
  return data;
}

extension PublicSettingsRespExtension on PublicSettingsResp {
  PublicSettingsResp copyWith({
    String? allowIndexed,
    String? allowMounted,
    String? announcement,
    String? audioAutoplay,
    String? audioCover,
    String? autoUpdateIndex,
    String? defaultPageSize,
    String? externalPreviews,
    String? favicon,
    String? filenameCharMapping,
    String? forwardDirectLinkParams,
    String? hideFiles,
    String? homeContainer,
    String? homeIcon,
    String? iframePreviews,
    String? logo,
    String? mainColor,
    String? ocrApi,
    String? packageDownload,
    String? paginationType,
    String? robotsTxt,
    String? searchIndex,
    String? settingsLayout,
    String? siteTitle,
    String? ssoLoginEnabled,
    String? ssoLoginPlatform,
    String? version,
    String? videoAutoplay,
  }) {
    return PublicSettingsResp()
      ..allowIndexed = allowIndexed ?? this.allowIndexed
      ..allowMounted = allowMounted ?? this.allowMounted
      ..announcement = announcement ?? this.announcement
      ..audioAutoplay = audioAutoplay ?? this.audioAutoplay
      ..audioCover = audioCover ?? this.audioCover
      ..autoUpdateIndex = autoUpdateIndex ?? this.autoUpdateIndex
      ..defaultPageSize = defaultPageSize ?? this.defaultPageSize
      ..externalPreviews = externalPreviews ?? this.externalPreviews
      ..favicon = favicon ?? this.favicon
      ..filenameCharMapping = filenameCharMapping ?? this.filenameCharMapping
      ..forwardDirectLinkParams = forwardDirectLinkParams ??
          this.forwardDirectLinkParams
      ..hideFiles = hideFiles ?? this.hideFiles
      ..homeContainer = homeContainer ?? this.homeContainer
      ..homeIcon = homeIcon ?? this.homeIcon
      ..iframePreviews = iframePreviews ?? this.iframePreviews
      ..logo = logo ?? this.logo
      ..mainColor = mainColor ?? this.mainColor
      ..ocrApi = ocrApi ?? this.ocrApi
      ..packageDownload = packageDownload ?? this.packageDownload
      ..paginationType = paginationType ?? this.paginationType
      ..robotsTxt = robotsTxt ?? this.robotsTxt
      ..searchIndex = searchIndex ?? this.searchIndex
      ..settingsLayout = settingsLayout ?? this.settingsLayout
      ..siteTitle = siteTitle ?? this.siteTitle
      ..ssoLoginEnabled = ssoLoginEnabled ?? this.ssoLoginEnabled
      ..ssoLoginPlatform = ssoLoginPlatform ?? this.ssoLoginPlatform
      ..version = version ?? this.version
      ..videoAutoplay = videoAutoplay ?? this.videoAutoplay;
  }
}