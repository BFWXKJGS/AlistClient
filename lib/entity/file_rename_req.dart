import 'package:alist/generated/json/base/json_field.dart';
import 'package:alist/generated/json/file_rename_req.g.dart';
import 'dart:convert';

@JsonSerializable()
class FileRenameReq {
	late String path;
	late String name;

	FileRenameReq();

	factory FileRenameReq.fromJson(Map<String, dynamic> json) => $FileRenameReqFromJson(json);

	Map<String, dynamic> toJson() => $FileRenameReqToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}