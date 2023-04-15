import 'package:alist/generated/json/base/json_convert_content.dart';
import 'package:alist/entity/file_list_resp_entity.dart';

FileListRespEntity $FileListRespEntityFromJson(Map<String, dynamic> json) {
	final FileListRespEntity fileListRespEntity = FileListRespEntity();
	final List<FileListRespContent>? content = jsonConvert.convertListNotNull<FileListRespContent>(json['content']);
	if (content != null) {
		fileListRespEntity.content = content;
	}
	final int? total = jsonConvert.convert<int>(json['total']);
	if (total != null) {
		fileListRespEntity.total = total;
	}
	final String? readme = jsonConvert.convert<String>(json['readme']);
	if (readme != null) {
		fileListRespEntity.readme = readme;
	}
	final bool? write = jsonConvert.convert<bool>(json['write']);
	if (write != null) {
		fileListRespEntity.write = write;
	}
	final String? provider = jsonConvert.convert<String>(json['provider']);
	if (provider != null) {
		fileListRespEntity.provider = provider;
	}
	return fileListRespEntity;
}

Map<String, dynamic> $FileListRespEntityToJson(FileListRespEntity entity) {
	final Map<String, dynamic> data = <String, dynamic>{};
	data['content'] =  entity.content.map((v) => v.toJson()).toList();
	data['total'] = entity.total;
	data['readme'] = entity.readme;
	data['write'] = entity.write;
	data['provider'] = entity.provider;
	return data;
}

FileListRespContent $FileListRespContentFromJson(Map<String, dynamic> json) {
	final FileListRespContent fileListRespContent = FileListRespContent();
	final String? name = jsonConvert.convert<String>(json['name']);
	if (name != null) {
		fileListRespContent.name = name;
	}
	final int? size = jsonConvert.convert<int>(json['size']);
	if (size != null) {
		fileListRespContent.size = size;
	}
	final bool? isDir = jsonConvert.convert<bool>(json['is_dir']);
	if (isDir != null) {
		fileListRespContent.isDir = isDir;
	}
	final String? modified = jsonConvert.convert<String>(json['modified']);
	if (modified != null) {
		fileListRespContent.modified = modified;
	}
	final String? sign = jsonConvert.convert<String>(json['sign']);
	if (sign != null) {
		fileListRespContent.sign = sign;
	}
	final String? thumb = jsonConvert.convert<String>(json['thumb']);
	if (thumb != null) {
		fileListRespContent.thumb = thumb;
	}
	final int? type = jsonConvert.convert<int>(json['type']);
	if (type != null) {
		fileListRespContent.type = type;
	}
	return fileListRespContent;
}

Map<String, dynamic> $FileListRespContentToJson(FileListRespContent entity) {
	final Map<String, dynamic> data = <String, dynamic>{};
	data['name'] = entity.name;
	data['size'] = entity.size;
	data['is_dir'] = entity.isDir;
	data['modified'] = entity.modified;
	data['sign'] = entity.sign;
	data['thumb'] = entity.thumb;
	data['type'] = entity.type;
	return data;
}