
import 'dart:convert';
import 'package:crypto/crypto.dart';

extension StringExtensions on String? {
  String? substringAfterLast(String separator) {
    if (this == null) {
      return null;
    }

    final index = this!.lastIndexOf(separator);
    if (index == -1) {
      return this;
    }
    return this!.substring(index + separator.length);
  }

  String? substringBeforeLast(String separator) {
    if (this == null) {
      return null;
    }

    final index = this!.lastIndexOf(separator);
    if (index == -1) {
      return this;
    }
    return this!.substring(0, index);
  }

  String md5String(){
    var bytes = utf8.encode(this ?? "");
    var md5Hash = md5.convert(bytes);
    String md5String = md5Hash.toString();
    return md5String;
  }
}
