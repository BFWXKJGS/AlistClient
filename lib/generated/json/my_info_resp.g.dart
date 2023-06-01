import 'package:alist/generated/json/base/json_convert_content.dart';
import 'package:alist/entity/my_info_resp.dart';

MyInfoResp $MyInfoRespFromJson(Map<String, dynamic> json) {
	final MyInfoResp myInfoResp = MyInfoResp();
	final int? id = jsonConvert.convert<int>(json['id']);
	if (id != null) {
		myInfoResp.id = id;
	}
	final String? username = jsonConvert.convert<String>(json['username']);
	if (username != null) {
		myInfoResp.username = username;
	}
	final String? password = jsonConvert.convert<String>(json['password']);
	if (password != null) {
		myInfoResp.password = password;
	}
	final String? basePath = jsonConvert.convert<String>(json['base_path']);
	if (basePath != null) {
		myInfoResp.basePath = basePath;
	}
	final int? role = jsonConvert.convert<int>(json['role']);
	if (role != null) {
		myInfoResp.role = role;
	}
	final bool? disabled = jsonConvert.convert<bool>(json['disabled']);
	if (disabled != null) {
		myInfoResp.disabled = disabled;
	}
	final int? permission = jsonConvert.convert<int>(json['permission']);
	if (permission != null) {
		myInfoResp.permission = permission;
	}
	final String? ssoId = jsonConvert.convert<String>(json['sso_id']);
	if (ssoId != null) {
		myInfoResp.ssoId = ssoId;
	}
	final bool? otp = jsonConvert.convert<bool>(json['otp']);
	if (otp != null) {
		myInfoResp.otp = otp;
	}
	return myInfoResp;
}

Map<String, dynamic> $MyInfoRespToJson(MyInfoResp entity) {
	final Map<String, dynamic> data = <String, dynamic>{};
	data['id'] = entity.id;
	data['username'] = entity.username;
	data['password'] = entity.password;
	data['base_path'] = entity.basePath;
	data['role'] = entity.role;
	data['disabled'] = entity.disabled;
	data['permission'] = entity.permission;
	data['sso_id'] = entity.ssoId;
	data['otp'] = entity.otp;
	return data;
}