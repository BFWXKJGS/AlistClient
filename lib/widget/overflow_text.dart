import 'package:flutter/material.dart';

class OverflowText extends StatelessWidget {
  static const ellipsis = "...";

  const OverflowText({super.key, required this.text, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      var textStyle = DefaultTextStyle.of(context).style;
      if (style != null) {
        textStyle = textStyle.merge(style);
      }

      var maxWidth = constraints.biggest.width;

      final textSpan = TextSpan(text: text, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      if (textPainter.width > maxWidth) {
        // LogUtil.d("${textPainter.width} $maxWidth");
        var left = 0;
        TextSpan? leftText;
        var leftWidth = 0.0;
        var right = 0;
        TextSpan? rightText;
        var rightWidth = 0.0;

        var ellipsisText = TextSpan(text: ellipsis, style: textStyle);
        textPainter.text = ellipsisText;
        textPainter.layout();
        maxWidth -= textPainter.width;

        while (leftWidth + rightWidth < maxWidth) {
          if (leftWidth <= rightWidth) {
            left++;
            leftText =
                TextSpan(text: text.substring(0, left), style: textStyle);

            textPainter.text = leftText;
            textPainter.layout();
            leftWidth = textPainter.width;

            if (leftWidth + rightWidth > maxWidth) {
              left--;
              leftText =
                  TextSpan(text: text.substring(0, left), style: textStyle);
              break;
            }
          } else {
            right++;
            rightText = TextSpan(
                text: text.substring(text.length - right), style: textStyle);

            textPainter.text = rightText;
            textPainter.layout();
            rightWidth = textPainter.width;

            if (leftWidth + rightWidth > maxWidth) {
              right--;
              rightText = TextSpan(
                  text: text.substring(text.length - right), style: textStyle);
              break;
            }
          }
        }

        return Text(
          "${leftText?.text ?? ""}$ellipsis${rightText?.text ?? ""}",
          style: textStyle,
        );
      } else {
        return Text(text, style: textStyle);
      }
    });
  }
}
