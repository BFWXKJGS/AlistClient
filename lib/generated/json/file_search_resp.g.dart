import 'package:alist/generated/json/base/json_convert_content.dart';
import 'package:alist/entity/file_search_resp.dart';

FileSearchResp $FileSearchRespFromJson(Map<String, dynamic> json) {
  final FileSearchResp fileSearchResp = FileSearchResp();
  final List<FileSearchRespContent>? content = (json['content'] as List<
      dynamic>?)
      ?.map(
          (e) =>
      jsonConvert.convert<FileSearchRespContent>(e) as FileSearchRespContent)
      .toList();
  if (content != null) {
    fileSearchResp.content = content;
  }
  final int? total = jsonConvert.convert<int>(json['total']);
  if (total != null) {
    fileSearchResp.total = total;
  }
  return fileSearchResp;
}

Map<String, dynamic> $FileSearchRespToJson(FileSearchResp entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['content'] = entity.content?.map((v) => v.toJson()).toList();
  data['total'] = entity.total;
  return data;
}

extension FileSearchRespExtension on FileSearchResp {
  FileSearchResp copyWith({
    List<FileSearchRespContent>? content,
    int? total,
  }) {
    return FileSearchResp()
      ..content = content ?? this.content
      ..total = total ?? this.total;
  }
}

FileSearchRespContent $FileSearchRespContentFromJson(
    Map<String, dynamic> json) {
  final FileSearchRespContent fileSearchRespContent = FileSearchRespContent();
  final String? parent = jsonConvert.convert<String>(json['parent']);
  if (parent != null) {
    fileSearchRespContent.parent = parent;
  }
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    fileSearchRespContent.name = name;
  }
  final bool? isDir = jsonConvert.convert<bool>(json['is_dir']);
  if (isDir != null) {
    fileSearchRespContent.isDir = isDir;
  }
  final int? size = jsonConvert.convert<int>(json['size']);
  if (size != null) {
    fileSearchRespContent.size = size;
  }
  final int? type = jsonConvert.convert<int>(json['type']);
  if (type != null) {
    fileSearchRespContent.type = type;
  }
  return fileSearchRespContent;
}

Map<String, dynamic> $FileSearchRespContentToJson(
    FileSearchRespContent entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['parent'] = entity.parent;
  data['name'] = entity.name;
  data['is_dir'] = entity.isDir;
  data['size'] = entity.size;
  data['type'] = entity.type;
  return data;
}

extension FileSearchRespContentExtension on FileSearchRespContent {
  FileSearchRespContent copyWith({
    String? parent,
    String? name,
    bool? isDir,
    int? size,
    int? type,
  }) {
    return FileSearchRespContent()
      ..parent = parent ?? this.parent
      ..name = name ?? this.name
      ..isDir = isDir ?? this.isDir
      ..size = size ?? this.size
      ..type = type ?? this.type;
  }
}