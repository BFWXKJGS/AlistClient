import 'package:alist/generated/json/base/json_field.dart';
import 'package:alist/generated/json/login_resp_entity.g.dart';
import 'dart:convert';

@JsonSerializable()
class LoginRespEntity {
	late String token;

	LoginRespEntity();

	factory LoginRespEntity.fromJson(Map<String, dynamic> json) => $LoginRespEntityFromJson(json);

	Map<String, dynamic> toJson() => $LoginRespEntityToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}