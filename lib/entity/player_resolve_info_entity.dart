import 'package:alist/generated/json/base/json_field.dart';
import 'package:alist/generated/json/player_resolve_info_entity.g.dart';
import 'dart:convert';
export 'package:alist/generated/json/player_resolve_info_entity.g.dart';

@JsonSerializable()
class ExternalPlayerEntity {
	late String packageName;
	late String activity;
	late String label;
	late String icon;

	ExternalPlayerEntity();

	factory ExternalPlayerEntity.fromJson(Map<String, dynamic> json) => $ExternalPlayerEntityFromJson(json);

	Map<String, dynamic> toJson() => $ExternalPlayerEntityToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}