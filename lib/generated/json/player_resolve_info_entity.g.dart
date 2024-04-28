import 'package:alist/generated/json/base/json_convert_content.dart';
import 'package:alist/entity/player_resolve_info_entity.dart';

ExternalPlayerEntity $ExternalPlayerEntityFromJson(Map<String, dynamic> json) {
  final ExternalPlayerEntity externalPlayerEntity = ExternalPlayerEntity();
  final String? packageName = jsonConvert.convert<String>(json['packageName']);
  if (packageName != null) {
    externalPlayerEntity.packageName = packageName;
  }
  final String? activity = jsonConvert.convert<String>(json['activity']);
  if (activity != null) {
    externalPlayerEntity.activity = activity;
  }
  final String? label = jsonConvert.convert<String>(json['label']);
  if (label != null) {
    externalPlayerEntity.label = label;
  }
  final String? icon = jsonConvert.convert<String>(json['icon']);
  if (icon != null) {
    externalPlayerEntity.icon = icon;
  }
  return externalPlayerEntity;
}

Map<String, dynamic> $ExternalPlayerEntityToJson(ExternalPlayerEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['packageName'] = entity.packageName;
  data['activity'] = entity.activity;
  data['label'] = entity.label;
  data['icon'] = entity.icon;
  return data;
}

extension ExternalPlayerEntityExtension on ExternalPlayerEntity {
  ExternalPlayerEntity copyWith({
    String? packageName,
    String? activity,
    String? label,
    String? icon,
  }) {
    return ExternalPlayerEntity()
      ..packageName = packageName ?? this.packageName
      ..activity = activity ?? this.activity
      ..label = label ?? this.label
      ..icon = icon ?? this.icon;
  }
}