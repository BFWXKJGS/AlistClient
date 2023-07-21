import 'package:alist/generated/json/base/json_field.dart';
import 'package:alist/generated/json/app_version_resp.g.dart';
import 'dart:convert';

@JsonSerializable()
class AppVersionResp {
	late String updates;
	late AppVersionRespAndroid android;
	late AppVersionRespIos ios;

	AppVersionResp();

	factory AppVersionResp.fromJson(Map<String, dynamic> json) => $AppVersionRespFromJson(json);

	Map<String, dynamic> toJson() => $AppVersionRespToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class AppVersionRespAndroid {
	late String version;
	late String githubUrl;
	late String googlePlayUrl;

	AppVersionRespAndroid();

	factory AppVersionRespAndroid.fromJson(Map<String, dynamic> json) => $AppVersionRespAndroidFromJson(json);

	Map<String, dynamic> toJson() => $AppVersionRespAndroidToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class AppVersionRespIos {
	late String version;
	late String appStoreUrl;

	AppVersionRespIos();

	factory AppVersionRespIos.fromJson(Map<String, dynamic> json) => $AppVersionRespIosFromJson(json);

	Map<String, dynamic> toJson() => $AppVersionRespIosToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}