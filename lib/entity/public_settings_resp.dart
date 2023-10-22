import 'package:alist/generated/json/base/json_field.dart';
import 'package:alist/generated/json/public_settings_resp.g.dart';
import 'dart:convert';
export 'package:alist/generated/json/public_settings_resp.g.dart';

@JsonSerializable()
class PublicSettingsResp {
	@JSONField(name: "allow_indexed")
	String? allowIndexed;
	@JSONField(name: "allow_mounted")
	String? allowMounted;
	String? announcement;
	@JSONField(name: "audio_autoplay")
	String? audioAutoplay;
	@JSONField(name: "audio_cover")
	String? audioCover;
	@JSONField(name: "auto_update_index")
	String? autoUpdateIndex;
	@JSONField(name: "default_page_size")
	String? defaultPageSize;
	@JSONField(name: "external_previews")
	String? externalPreviews;
	String? favicon;
	@JSONField(name: "filename_char_mapping")
	String? filenameCharMapping;
	@JSONField(name: "forward_direct_link_params")
	String? forwardDirectLinkParams;
	@JSONField(name: "hide_files")
	String? hideFiles;
	@JSONField(name: "home_container")
	String? homeContainer;
	@JSONField(name: "home_icon")
	String? homeIcon;
	@JSONField(name: "iframe_previews")
	String? iframePreviews;
	String? logo;
	@JSONField(name: "main_color")
	String? mainColor;
	@JSONField(name: "ocr_api")
	String? ocrApi;
	@JSONField(name: "package_download")
	String? packageDownload;
	@JSONField(name: "pagination_type")
	String? paginationType;
	@JSONField(name: "robots_txt")
	String? robotsTxt;
	@JSONField(name: "search_index")
	String? searchIndex;
	@JSONField(name: "settings_layout")
	String? settingsLayout;
	@JSONField(name: "site_title")
	String? siteTitle;
	@JSONField(name: "sso_login_enabled")
	String? ssoLoginEnabled;
	@JSONField(name: "sso_login_platform")
	String? ssoLoginPlatform;
	String? version;
	@JSONField(name: "video_autoplay")
	String? videoAutoplay;

	PublicSettingsResp();

	factory PublicSettingsResp.fromJson(Map<String, dynamic> json) => $PublicSettingsRespFromJson(json);

	Map<String, dynamic> toJson() => $PublicSettingsRespToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}