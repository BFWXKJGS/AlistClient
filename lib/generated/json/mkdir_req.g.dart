import 'package:alist/generated/json/base/json_convert_content.dart';
import 'package:alist/entity/mkdir_req.dart';

MkdirReq $MkdirReqFromJson(Map<String, dynamic> json) {
  final MkdirReq mkdirReq = MkdirReq();
  final String? path = jsonConvert.convert<String>(json['path']);
  if (path != null) {
    mkdirReq.path = path;
  }
  return mkdirReq;
}

Map<String, dynamic> $MkdirReqToJson(MkdirReq entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['path'] = entity.path;
  return data;
}

extension MkdirReqExtension on MkdirReq {
  MkdirReq copyWith({
    String? path,
  }) {
    return MkdirReq()
      ..path = path ?? this.path;
  }
}