import 'package:alist/generated/json/base/json_convert_content.dart';
import 'package:alist/entity/file_info_resp_entity.dart';

FileInfoRespEntity $FileInfoRespEntityFromJson(Map<String, dynamic> json) {
	final FileInfoRespEntity fileInfoRespEntity = FileInfoRespEntity();
	final String? name = jsonConvert.convert<String>(json['name']);
	if (name != null) {
		fileInfoRespEntity.name = name;
	}
	final int? size = jsonConvert.convert<int>(json['size']);
	if (size != null) {
		fileInfoRespEntity.size = size;
	}
	final bool? isDir = jsonConvert.convert<bool>(json['is_dir']);
	if (isDir != null) {
		fileInfoRespEntity.isDir = isDir;
	}
	final String? modified = jsonConvert.convert<String>(json['modified']);
	if (modified != null) {
		fileInfoRespEntity.modified = modified;
	}
	final String? sign = jsonConvert.convert<String>(json['sign']);
	if (sign != null) {
		fileInfoRespEntity.sign = sign;
	}
	final String? thumb = jsonConvert.convert<String>(json['thumb']);
	if (thumb != null) {
		fileInfoRespEntity.thumb = thumb;
	}
	final int? type = jsonConvert.convert<int>(json['type']);
	if (type != null) {
		fileInfoRespEntity.type = type;
	}
	final String? rawUrl = jsonConvert.convert<String>(json['raw_url']);
	if (rawUrl != null) {
		fileInfoRespEntity.rawUrl = rawUrl;
	}
	final String? readme = jsonConvert.convert<String>(json['readme']);
	if (readme != null) {
		fileInfoRespEntity.readme = readme;
	}
	final String? provider = jsonConvert.convert<String>(json['provider']);
	if (provider != null) {
		fileInfoRespEntity.provider = provider;
	}
	final dynamic related = jsonConvert.convert<dynamic>(json['related']);
	if (related != null) {
		fileInfoRespEntity.related = related;
	}
	return fileInfoRespEntity;
}

Map<String, dynamic> $FileInfoRespEntityToJson(FileInfoRespEntity entity) {
	final Map<String, dynamic> data = <String, dynamic>{};
	data['name'] = entity.name;
	data['size'] = entity.size;
	data['is_dir'] = entity.isDir;
	data['modified'] = entity.modified;
	data['sign'] = entity.sign;
	data['thumb'] = entity.thumb;
	data['type'] = entity.type;
	data['raw_url'] = entity.rawUrl;
	data['readme'] = entity.readme;
	data['provider'] = entity.provider;
	data['related'] = entity.related;
	return data;
}