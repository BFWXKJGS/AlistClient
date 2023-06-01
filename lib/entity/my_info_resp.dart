import 'package:alist/generated/json/base/json_field.dart';
import 'package:alist/generated/json/my_info_resp.g.dart';
import 'dart:convert';

@JsonSerializable()
class MyInfoResp {
	late int id;
	late String username;
	late String password;
	@JSONField(name: "base_path")
	late String basePath;
	late int role;
	late bool disabled;
	late int permission;
	@JSONField(name: "sso_id")
	late String ssoId;
	late bool otp;

	MyInfoResp();

	factory MyInfoResp.fromJson(Map<String, dynamic> json) => $MyInfoRespFromJson(json);

	Map<String, dynamic> toJson() => $MyInfoRespToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}