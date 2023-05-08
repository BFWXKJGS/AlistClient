import 'package:alist/entity/file_list_resp_entity.dart';
import 'package:alist/generated/images.dart';
import 'package:alist/util/file_type.dart';

extension FileListRespContentExtensions on FileListRespContent {
  FileType getFileType() {
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
      case "ts":
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

  String getFileIcon() {
    FileType fileType = getFileType();
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

  String getCompletePath(String? parentPath) {
    var path = '';
    if (parentPath == '/' || parentPath == null) {
      path = "/$name";
    } else {
      path = "$parentPath/$name";
    }
    return path;
  }
}
