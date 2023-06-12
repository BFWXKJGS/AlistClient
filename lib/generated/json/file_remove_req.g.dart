import 'package:alist/generated/json/base/json_convert_content.dart';
import 'package:alist/entity/file_remove_req.dart';

FileRemoveReq $FileRemoveReqFromJson(Map<String, dynamic> json) {
	final FileRemoveReq fileRemoveReq = FileRemoveReq();
	final String? dir = jsonConvert.convert<String>(json['dir']);
	if (dir != null) {
		fileRemoveReq.dir = dir;
	}
	final List<String>? names = jsonConvert.convertListNotNull<String>(json['names']);
	if (names != null) {
		fileRemoveReq.names = names;
	}
	return fileRemoveReq;
}

Map<String, dynamic> $FileRemoveReqToJson(FileRemoveReq entity) {
	final Map<String, dynamic> data = <String, dynamic>{};
	data['dir'] = entity.dir;
	data['names'] =  entity.names;
	return data;
}