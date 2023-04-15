import 'package:alist/generated/json/base/json_convert_content.dart';

class HttpResult<T> {
  late int code;
  late String message;
  T? data;

  HttpResult(this.code, this.message, this.data);

  HttpResult.fromJson(Map<String, dynamic> json) {
    code = json["code"] as int;
    message = json["message"] as String;
    if (json.containsKey("data")) {
      data = _generateData<T>(json["data"]);
    }
  }

  T? _generateData<O>(dynamic json) {
    if (json == null) {
      return null;
    } else if (T.toString() == 'String') {
      return json.toString() as T;
    } else if (T.toString() == 'Map<dynamic, dynamic>') {
      return json as T;
    } else {
      return JsonConvert.fromJsonAsT<T>(json);
    }
  }

  bool isSuccessful() {
    return code == 200;
  }
}
