import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';

class OverflowPositionMiddleText extends StatelessWidget {
  const OverflowPositionMiddleText(this.data, {Key? key, this.maxLines = 1})
      : super(key: key);
  final String? data;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return ExtendedText(
      data ?? "",
      maxLines: maxLines,
      overflowWidget: const TextOverflowWidget(
        align: TextOverflowAlign.center,
        position: TextOverflowPosition.middle,
        child: Text("..."),
      ),
    );
  }
}
