import 'package:alist/generated/json/base/json_convert_content.dart';
import 'package:alist/entity/file_rename_req.dart';

FileRenameReq $FileRenameReqFromJson(Map<String, dynamic> json) {
  final FileRenameReq fileRenameReq = FileRenameReq();
  final String? path = jsonConvert.convert<String>(json['path']);
  if (path != null) {
    fileRenameReq.path = path;
  }
  final String? name = jsonConvert.convert<String>(json['name']);
  if (name != null) {
    fileRenameReq.name = name;
  }
  return fileRenameReq;
}

Map<String, dynamic> $FileRenameReqToJson(FileRenameReq entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['path'] = entity.path;
  data['name'] = entity.name;
  return data;
}