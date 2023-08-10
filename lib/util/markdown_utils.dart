import 'dart:io';

import 'package:alist/util/global.dart';

class MarkdownUtil {
  static makePreviewUrl(String url) {
    String scheme;
    if (Platform.isIOS && url.startsWith("http://")) {
      scheme = "http";
    } else {
      scheme = "https";
    }

    return "$scheme://${Global.configServerHost}/alist_h5/showMarkDown?markdownUrl=${Uri.encodeComponent(url)}";
  }
}
