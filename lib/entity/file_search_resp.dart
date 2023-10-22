import 'package:alist/generated/json/base/json_field.dart';
import 'package:alist/generated/json/file_search_resp.g.dart';
import 'dart:convert';
export 'package:alist/generated/json/file_search_resp.g.dart';

@JsonSerializable()
class FileSearchResp {
	List<FileSearchRespContent>? content;
	int? total;

	FileSearchResp();

	factory FileSearchResp.fromJson(Map<String, dynamic> json) => $FileSearchRespFromJson(json);

	Map<String, dynamic> toJson() => $FileSearchRespToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}

@JsonSerializable()
class FileSearchRespContent {
	String? parent;
	String? name;
	@JSONField(name: "is_dir")
	bool? isDir;
	int? size;
	int? type;

	FileSearchRespContent();

	factory FileSearchRespContent.fromJson(Map<String, dynamic> json) => $FileSearchRespContentFromJson(json);

	Map<String, dynamic> toJson() => $FileSearchRespContentToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}