import 'package:flutter/foundation.dart';
import 'package:markdown/markdown.dart';

class MarkdownUtil {
  static Future<String> toHtml(String markdown) async {
    return compute(_toHtmlInner, markdown);
  }

  static String _toHtmlInner(String markdown) {
    return markdownToHtml(
      markdown,
      inlineSyntaxes: [InlineHtmlSyntax()],
    );
  }
}
