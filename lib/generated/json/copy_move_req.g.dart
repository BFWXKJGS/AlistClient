import 'package:alist/generated/json/base/json_convert_content.dart';
import 'package:alist/entity/copy_move_req.dart';

CopyMoveReq $CopyMoveReqFromJson(Map<String, dynamic> json) {
  final CopyMoveReq copyMoveReq = CopyMoveReq();
  final String? srcDir = jsonConvert.convert<String>(json['src_dir']);
  if (srcDir != null) {
    copyMoveReq.srcDir = srcDir;
  }
  final String? dstDir = jsonConvert.convert<String>(json['dst_dir']);
  if (dstDir != null) {
    copyMoveReq.dstDir = dstDir;
  }
  final List<String>? names = (json['names'] as List<dynamic>).map(
          (e) => jsonConvert.convert<String>(e) as String).toList();
  if (names != null) {
    copyMoveReq.names = names;
  }
  return copyMoveReq;
}

Map<String, dynamic> $CopyMoveReqToJson(CopyMoveReq entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['src_dir'] = entity.srcDir;
  data['dst_dir'] = entity.dstDir;
  data['names'] = entity.names;
  return data;
}