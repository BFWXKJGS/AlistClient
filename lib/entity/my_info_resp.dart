import 'package:alist/generated/json/base/json_field.dart';
import 'package:alist/generated/json/my_info_resp.g.dart';
import 'dart:convert';

@JsonSerializable()
class MyInfoResp {
	late int id;
	late String username;
	late String password;
	@JSONField(name: "base_path")
	String basePath = "";
	int role = 0;
	bool disabled = false;
	int permission = -1;
	@JSONField(name: "sso_id")
	String ssoId = "";
	bool otp = false;

	MyInfoResp();

	factory MyInfoResp.fromJson(Map<String, dynamic> json) => $MyInfoRespFromJson(json);

	Map<String, dynamic> toJson() => $MyInfoRespToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}