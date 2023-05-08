import 'package:alist/generated/json/base/json_field.dart';
import 'package:alist/generated/json/donate_config_entity.g.dart';
import 'dart:convert';

@JsonSerializable()
class DonateConfigEntity {
	late String wechat;
	@JSONField(name: "wechat_small")
	late String wechatSmall;
	late String alipay;
	@JSONField(name: "alipay_small")
	late String alipaySmall;

	DonateConfigEntity();

	factory DonateConfigEntity.fromJson(Map<String, dynamic> json) => $DonateConfigEntityFromJson(json);

	Map<String, dynamic> toJson() => $DonateConfigEntityToJson(this);

	@override
	String toString() {
		return jsonEncode(this);
	}
}