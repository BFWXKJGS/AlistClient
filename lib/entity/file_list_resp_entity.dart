import 'package:alist/generated/json/base/json_field.dart';
import 'package:alist/generated/json/file_list_resp_entity.g.dart';
import 'dart:convert';

@JsonSerializable()
class FileListRespEntity {
	List<FileListRespContent>? content;
	late int total;
	late String readme;
	late bool write;
	late String provider;

	FileListRespEntity();

	factory FileListRespEntity.fromJson(Map<String, dynamic> json) => $FileListRespEntityFromJson(json);

	Map<String, dynamic> toJson() => $FileListRespEntityToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class FileListRespContent {
	late String name;
	late int size;
	@JSONField(name: "is_dir")
	late bool isDir;
	late String modified;
	late String sign;
	late String thumb;
	late int type;
	String? readme;

	FileListRespContent();

	factory FileListRespContent.fromJson(Map<String, dynamic> json) => $FileListRespContentFromJson(json);

	Map<String, dynamic> toJson() => $FileListRespContentToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}