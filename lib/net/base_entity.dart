import 'package:alist/generated/json/base/json_convert_content.dart';
import 'package:alist/util/constant.dart';

class BaseEntity<T> {

  BaseEntity(this.code, this.message, this.data);

  BaseEntity.fromJson(Map<String, dynamic> json) {
    code = json[AlistConstant.code] as int;
    message = json[AlistConstant.message] as String;
    if (json.containsKey(AlistConstant.data)) {
      data = _generateOBJ<T>(json[AlistConstant.data] as Object?);
    }
  }

  late int code;
  late String message;
  T? data;

  T? _generateOBJ<O>(Object? json) {
    if (json == null) {
      return null;
    }
    if (T.toString() == 'String') {
      return json.toString() as T;
    } else if (T.toString() == 'Map<dynamic, dynamic>') {
      return json as T;
    } else {
      /// List类型数据由fromJsonAsT判断处理
      return JsonConvert.fromJsonAsT<T>(json);
    }
  }
}
