import 'dart:io';

import 'package:alist/util/constant.dart';
import 'package:alist/util/string_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sp_util/sp_util.dart';

class DownloadUtils {
  static Future<Directory> findDownloadDir(String fileType) async {
    Directory downloadDir;
    if (Platform.isAndroid) {
      final dirs = await getExternalStorageDirectory();
      if (dirs != null) {
        downloadDir = dirs;
      } else {
        downloadDir = await getTemporaryDirectory();
      }
    } else {
      downloadDir = await getTemporaryDirectory();
    }
    String subPath = SpUtil.getString(Constant.baseUrl).md5String();
    if (SpUtil.getBool(Constant.guest) == true) {
      subPath = "$subPath/guest";
    } else {
      final username = SpUtil.getString(Constant.username);
      subPath = "$subPath/$username";
    }

    downloadDir = Directory("${downloadDir.path}/$subPath/$fileType");
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }
}
