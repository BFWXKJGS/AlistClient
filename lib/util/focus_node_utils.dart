import 'package:flutter/material.dart';

extension FocusNodeUtils on FocusNode {
  FocusNode autoFocus() {
    Future.delayed(const Duration(milliseconds: 100), () => requestFocus());
    return this;
  }
}
