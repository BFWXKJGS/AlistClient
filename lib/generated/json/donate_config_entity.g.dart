import 'package:alist/generated/json/base/json_convert_content.dart';
import 'package:alist/entity/donate_config_entity.dart';

DonateConfigEntity $DonateConfigEntityFromJson(Map<String, dynamic> json) {
	final DonateConfigEntity donateConfigEntity = DonateConfigEntity();
	final String? wechat = jsonConvert.convert<String>(json['wechat']);
	if (wechat != null) {
		donateConfigEntity.wechat = wechat;
	}
	final String? wechatSmall = jsonConvert.convert<String>(json['wechat_small']);
	if (wechatSmall != null) {
		donateConfigEntity.wechatSmall = wechatSmall;
	}
	final String? alipay = jsonConvert.convert<String>(json['alipay']);
	if (alipay != null) {
		donateConfigEntity.alipay = alipay;
	}
	final String? alipaySmall = jsonConvert.convert<String>(json['alipay_small']);
	if (alipaySmall != null) {
		donateConfigEntity.alipaySmall = alipaySmall;
	}
	return donateConfigEntity;
}

Map<String, dynamic> $DonateConfigEntityToJson(DonateConfigEntity entity) {
	final Map<String, dynamic> data = <String, dynamic>{};
	data['wechat'] = entity.wechat;
	data['wechat_small'] = entity.wechatSmall;
	data['alipay'] = entity.alipay;
	data['alipay_small'] = entity.alipaySmall;
	return data;
}