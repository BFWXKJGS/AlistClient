import 'package:alist/generated/json/base/json_convert_content.dart';
import 'package:alist/entity/login_resp_entity.dart';

LoginRespEntity $LoginRespEntityFromJson(Map<String, dynamic> json) {
	final LoginRespEntity loginRespEntity = LoginRespEntity();
	final String? token = jsonConvert.convert<String>(json['token']);
	if (token != null) {
		loginRespEntity.token = token;
	}
	return loginRespEntity;
}

Map<String, dynamic> $LoginRespEntityToJson(LoginRespEntity entity) {
	final Map<String, dynamic> data = <String, dynamic>{};
	data['token'] = entity.token;
	return data;
}