import 'package:alist/generated/json/base/json_field.dart';
import 'package:alist/generated/json/copy_move_req.g.dart';
import 'dart:convert';

@JsonSerializable()
class CopyMoveReq {
	@JSONField(name: "src_dir")
	late String srcDir;
	@JSONField(name: "dst_dir")
	late String dstDir;
	late List<String> names;

	CopyMoveReq();

	factory CopyMoveReq.fromJson(Map<String, dynamic> json) => $CopyMoveReqFromJson(json);

	Map<String, dynamic> toJson() => $CopyMoveReqToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}