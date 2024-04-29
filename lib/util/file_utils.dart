import 'dart:math';

import 'package:alist/entity/file_list_resp_entity.dart';
import 'package:alist/generated/images.dart';
import 'package:alist/l10n/intl_keys.dart' as ikeys;
import 'package:alist/util/constant.dart';
import 'package:alist/util/file_type.dart';
import 'package:alist/util/user_controller.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

final isoDateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
final dateFormatThisYear = DateFormat("MM/dd HH:mm");
final dateFormatThatYear = DateFormat("yyyy/MM/dd HH:mm");
final now = DateTime.now();

class FileUtils {
  static FileType getFileType(bool isDir, String name) {
    if (isDir) {
      return FileType.folder;
    }
    int extIndex = name.lastIndexOf('.');
    if (extIndex <= 0 || extIndex == name.length - 1) {
      return FileType.others;
    }
    String ext = name.substring(extIndex + 1).toLowerCase();
    switch (ext) {
      case "apk":
        return FileType.apk;
      case "md":
        return FileType.markdown;
      case "mp3":
      case "m4a":
      case "m4r":
      case "wav":
      case "aiff":
      case "wma":
      case "mpv":
      case "amr":
      case "ape":
      case "cue":
      case "au":
      case "midi":
      case "realaudio":
      case "vqf":
      case "oggvorbis":
      case "flac":
      case "aac":
        return FileType.audio;
      case "zip":
      case "rar":
      case "7z":
      case "tar":
      case "gz":
      case "bz2":
      case "xz":
      case "lzh":
      case "cab":
      case "iso":
        return FileType.compress;
      case "eml":
        return FileType.email;
      case "swf":
        return FileType.flash;
      case "htm":
      case "html":
      case "xhtml":
      case "mht":
        return FileType.html;
      case "png":
      case "gif":
      case "jpg":
      case "jpeg":
      case "bmp":
      case "tif":
      case "tiff":
      case "ico":
      case "raw":
      case "eps":
      case "pcx":
      case "svg":
      case "webp":
        return FileType.image;
      case "key":
        return FileType.keynote;
      case "numbers":
        return FileType.numbers;
      case "pdf":
        return FileType.pdf;
      case "ppt":
      case "pptx":
      case "pps":
      case "pot":
      case "pptm":
      case "potm":
      case "ppam":
      case "ppsx":
      case "ppsm":
      case "sldx":
      case "sldm":
      case "thmx":
      case "dps":
      case "dpt":
      case "potx":
        return FileType.ppt;
      case "xlsx":
      case "xls":
      case "csv":
        return FileType.excel;
      case "psd":
        return FileType.psd;
      case "txt":
      case "log":
      case "xml":
        return FileType.txt;
      case "mov":
      case "mp4":
      case "avi":
      case "wmv":
      case "rmvb":
      case "3gp":
      case "m4v":
      case "rm":
      case "mpg":
      case "mkv":
      case "f4v":
      case "asf":
      case "asx":
      case "mpeg":
      case "mpe":
      case "dat":
      case "vob":
      case "flv":
      case "ts":
        return FileType.video;
      case "doc":
      case "docx":
      case "dot":
      case "dotx":
      case "docm":
      case "dotm":
      case "wps":
      case "wpt":
      case "rtf":
        return FileType.word;
      case "sketch":
        return FileType.sketch;
      case "py":
      case "java":
      case "cpp":
      case "c":
      case "h":
      case "js":
      case "php":
      case "css":
      case "go":
      case "rb":
      case "swift":
      case "kt":
      case "rs":
      case "sh":
      case "vb":
      case "sql":
      case "scala":
      case "r":
      case "psm1":
      case "ps1":
      case "pas":
      case "m":
      case "lua":
      case "jl":
      case "hs":
      case "f95":
      case "f90":
      case "erl":
      case "exs":
      case "ex":
      case "dart":
      case "coffee":
      case "cbl":
      case "cob":
      case "bat":
      case "asm":
      case "as":
      case "arb":
      case "e":
      case "ey":
        return FileType.code;
    }
    return FileType.others;
  }

  static String getFileIcon(bool isDir, String name) {
    FileType fileType = getFileType(isDir, name);
    switch (fileType) {
      case FileType.folder:
        return Images.fileTypeFolder;
      case FileType.audio:
        return Images.fileTypeAudio;
      case FileType.image:
        return Images.fileTypeImage;
      case FileType.video:
        return Images.fileTypeVideo;
      case FileType.apk:
        return Images.fileTypeApk;
      case FileType.word:
        return Images.fileTypeWord;
      case FileType.numbers:
      case FileType.excel:
        return Images.fileTypeExcel;
      case FileType.ppt:
      case FileType.keynote:
        return Images.fileTypePpt;
      case FileType.txt:
        return Images.fileTypeDocment;
      case FileType.code:
        return Images.fileTypeCode;
      case FileType.pdf:
        return Images.fileTypePdf;
      case FileType.compress:
        return Images.fileTypeZip;
      case FileType.markdown:
        return Images.fileTypeMd;
      default:
        return Images.fileTypeUnknow;
    }
  }

  static Future<String?> makeFileLink(String path, String? sign,
      {bool toastShowTips = true}) async {
    UserController userController = Get.find();
    var user = userController.user.value;
    String? basePath = user.basePath;
    if (basePath == null || basePath.isEmpty) {
      SmartDialog.showLoading();
      await userController.requestBasePath(user);
      SmartDialog.dismiss();
      user = userController.user.value;
      basePath = user.basePath;
    }

    if (basePath == null || basePath.isEmpty) {
      if (toastShowTips) {
        SmartDialog.showToast(ikeys.Intl.tips_makeFileLink_failed.tr);
      }
      return null;
    }

    var encodedPath = _pathEncodeFull(path);
    var encodeBasePath = _pathEncodeFull(user.basePath ?? "");
    if (encodedPath.endsWith("/")) {
      encodedPath = encodedPath.substring(0, encodedPath.length - 1);
    }

    String url = "${user.serverUrl}d$encodeBasePath$encodedPath";
    if (sign != null && sign.isNotEmpty) {
      url = "$url?sign=$sign";
    }
    return url;
  }

  static String _pathEncodeFull(String uri) {
    if (uri.isEmpty || uri == "/") {
      return uri;
    }

    var encodedUri = "";
    for (var value in uri.split("/")) {
      if (value.isNotEmpty) {
        encodedUri += Uri.encodeComponent(value);
        encodedUri += "/";
      }
    }
    return encodedUri;
  }

  static void copyFileLink(String path, String? sign) async {
    String? url = await makeFileLink(path, sign);

    if (url != null && url.isNotEmpty) {
      Uri uri = Uri.parse(url);
      Clipboard.setData(ClipboardData(text: uri.toString()));
      SmartDialog.showToast(ikeys.Intl.tips_link_copied.tr);
    }
  }

  static String? formatBytes(int size) {
    if (size <= 0) return "0B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(size) / log(1024)).floor();
    return "${(size / pow(1024, i)).toStringAsFixed(2)}${suffixes[i]}";
  }

  static String getReformatTime(DateTime? modifyTime, String defaultValue) {
    String? modifyTimeStr;
    if (now.year == modifyTime?.year) {
      modifyTimeStr = dateFormatThisYear.format(modifyTime!);
    } else if (modifyTime != null) {
      modifyTimeStr = dateFormatThatYear.format(modifyTime);
    } else {
      modifyTimeStr = defaultValue;
    }
    return modifyTimeStr;
  }

  static String? getCompleteThumbnail(String? thumbnail) {
    if (thumbnail == null || thumbnail.isEmpty) {
      return null;
    }

    if (!thumbnail.startsWith("http://") && !thumbnail.startsWith("https://")) {
      String serverUrl = SpUtil.getString(AlistConstant.serverUrl) ?? "";
      Uri uri = Uri.parse(serverUrl);
      thumbnail = "${uri.scheme}://${uri.host}:${uri.port}$thumbnail";
    }
    return thumbnail;
  }
}

extension FileListRespContentExtensions on FileListRespContent {
  FileType getFileType() {
    return FileUtils.getFileType(isDir, name);
  }

  String getFileIcon() {
    return FileUtils.getFileIcon(isDir, name);
  }

  String getCompletePath(String? parentPath) {
    var path = '';
    if (parentPath == '/' || parentPath == null) {
      path = "/$name";
    } else {
      path = "$parentPath/$name";
    }
    return path;
  }

  String? formatBytes() {
    if (isDir) return null;
    var size = this.size ?? 0;
    return FileUtils.formatBytes(size);
  }

  DateTime? parseModifiedTime() {
    var modifyTimeStr = modified;
    var indexOnMs = modifyTimeStr.lastIndexOf(".");
    if (indexOnMs > -1) {
      modifyTimeStr = "${modifyTimeStr.substring(0, indexOnMs)}Z";
    }
    DateTime? modifyTime;
    try {
      if (modifyTimeStr.contains("+")) {
        modifyTime = DateTime.parse(modifyTimeStr);
      } else {
        modifyTime = isoDateFormat.parse(modifyTimeStr);
      }
    } catch (e) {
      LogUtil.e(e);
    }
    return modifyTime;
  }

  String getReformatModified(DateTime? modifyTime) {
    return FileUtils.getReformatTime(modifyTime, modified);
  }
}
