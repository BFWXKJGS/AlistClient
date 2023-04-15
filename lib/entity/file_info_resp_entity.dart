import 'package:alist/generated/json/base/json_field.dart';
import 'package:alist/generated/json/file_info_resp_entity.g.dart';
import 'dart:convert';

@JsonSerializable()
class FileInfoRespEntity {
	late String name;
	late int size;
	@JSONField(name: "is_dir")
	late bool isDir;
	late String modified;
	late String sign;
	late String thumb;
	late int type;
	@JSONField(name: "raw_url")
	late String rawUrl;
	late String readme;
	late String provider;
	dynamic related;

	FileInfoRespEntity();

	factory FileInfoRespEntity.fromJson(Map<String, dynamic> json) => $FileInfoRespEntityFromJson(json);

	Map<String, dynamic> toJson() => $FileInfoRespEntityToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}