import 'package:alist/generated/json/base/json_field.dart';
import 'package:alist/generated/json/file_remove_req.g.dart';
import 'dart:convert';

@JsonSerializable()
class FileRemoveReq {
	late String dir;
	late List<String> names;

	FileRemoveReq();

	factory FileRemoveReq.fromJson(Map<String, dynamic> json) => $FileRemoveReqFromJson(json);

	Map<String, dynamic> toJson() => $FileRemoveReqToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}