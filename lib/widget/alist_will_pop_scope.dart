import 'dart:io';

import 'package:flutter/material.dart';

class AlistWillPopScope extends StatelessWidget {
  const AlistWillPopScope({
    Key? key,
    required this.child,
    this.onWillPop,
    this.alwaysAllowSwipeBackOnIOS = true,
  }) : super(key: key);

  final Widget child;
  final WillPopCallback? onWillPop;
  final bool alwaysAllowSwipeBackOnIOS;

  @override
  Widget build(BuildContext context) {
    final onWillPop =
        (Platform.isIOS && alwaysAllowSwipeBackOnIOS) ? null : this.onWillPop;
    return WillPopScope(onWillPop: onWillPop, child: child);
  }
}
