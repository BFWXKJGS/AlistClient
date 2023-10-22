import 'package:alist/generated/json/base/json_convert_content.dart';
import 'package:alist/entity/file_list_resp_entity.dart';

FileListRespEntity $FileListRespEntityFromJson(Map<String, dynamic> json) {
  final FileListRespEntity fileListRespEntity = FileListRespEntity();
  final List<FileListRespContent>? content = (json['content'] as List<dynamic>?)
      ?.map(
          (e) =>
      jsonConvert.convert<FileListRespContent>(e) as FileListRespContent)
      .toList();
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
  data['content'] = entity.content?.map((v) => v.toJson()).toList();
  data['total'] = entity.total;
  data['readme'] = entity.readme;
  data['write'] = entity.write;
  data['provider'] = entity.provider;
  return data;
}

extension FileListRespEntityExtension on FileListRespEntity {
  FileListRespEntity copyWith({
    List<FileListRespContent>? content,
    int? total,
    String? readme,
    bool? write,
    String? provider,
  }) {
    return FileListRespEntity()
      ..content = content ?? this.content
      ..total = total ?? this.total
      ..readme = readme ?? this.readme
      ..write = write ?? this.write
      ..provider = provider ?? this.provider;
  }
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
  final String? readme = jsonConvert.convert<String>(json['readme']);
  if (readme != null) {
    fileListRespContent.readme = readme;
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
  data['readme'] = entity.readme;
  return data;
}

extension FileListRespContentExtension on FileListRespContent {
  FileListRespContent copyWith({
    String? name,
    int? size,
    bool? isDir,
    String? modified,
    String? sign,
    String? thumb,
    int? type,
    String? readme,
  }) {
    return FileListRespContent()
      ..name = name ?? this.name
      ..size = size ?? this.size
      ..isDir = isDir ?? this.isDir
      ..modified = modified ?? this.modified
      ..sign = sign ?? this.sign
      ..thumb = thumb ?? this.thumb
      ..type = type ?? this.type
      ..readme = readme ?? this.readme;
  }
}