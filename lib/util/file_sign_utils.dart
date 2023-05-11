import 'package:alist/entity/file_info_resp_entity.dart';
import 'package:alist/util/string_utils.dart';

extension FileInfoRespExtensions on FileInfoRespEntity {
  String makeCacheUseSign(String path) {
    // prefer to use the sign returned by the server
    String sign = this.sign;
    if (sign.isEmpty) {
      //  If the returned signature is empty, then create a sign based on the existing information
      sign = "${path}_${provider}_${size}_$modified".md5String();
    }
    return sign;
  }
}
