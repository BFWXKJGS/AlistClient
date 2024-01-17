import 'package:alist/generated/json/base/json_field.dart';
import 'package:alist/generated/json/mkdir_req.g.dart';
import 'dart:convert';

@JsonSerializable()
class MkdirReq {
	late String path;

	MkdirReq();

	factory MkdirReq.fromJson(Map<String, dynamic> json) => $MkdirReqFromJson(json);

	Map<String, dynamic> toJson() => $MkdirReqToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}