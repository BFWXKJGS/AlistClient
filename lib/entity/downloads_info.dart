import 'package:alist/generated/json/base/json_field.dart';
import 'package:alist/generated/json/downloads_info.g.dart';
import 'dart:convert';

@JsonSerializable()
class DownloadsInfo {
  late bool isSupportRange;
  late bool decompress;
  String? lastModified;
  String? etag;
  int? contentLength;

  DownloadsInfo();

  factory DownloadsInfo.fromJson(Map<String, dynamic> json) =>
      $DownloadsInfoFromJson(json);

  Map<String, dynamic> toJson() => $DownloadsInfoToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}