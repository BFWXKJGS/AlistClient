import 'package:alist/l10n/intl_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MkdirDialog extends StatefulWidget {
  const MkdirDialog({
    Key? key,
    required this.controller,
    required this.focusNode,
    this.onConfirm,
    this.onCancel,
  }) : super(key: key);
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  State<MkdirDialog> createState() => _MkdirDialogState();
}

class _MkdirDialogState extends State<MkdirDialog> {
  var _showClear = false;
  var _hasContent = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      var showClear = widget.controller.text.isNotEmpty;
      var hasContent = widget.controller.text.trim().isNotEmpty;
      if (_showClear != showClear || _hasContent != hasContent) {
        setState(() {
          _showClear = showClear;
          _hasContent = hasContent;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(Intl.mkdirDialog_title.tr),
      content: TextField(
        focusNode: widget.focusNode,
        autofocus: true,
        controller: widget.controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: Intl.mkdirDialog_hint.tr,
          suffixIcon: _showClear
              ? IconButton(
                  onPressed: () => widget.controller.clear(),
                  icon: const Icon(Icons.close),
                )
              : null,
          isCollapsed: true,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: Text(Intl.mkdirDialog_cancel.tr),
        ),
        TextButton(
          onPressed: _hasContent ? widget.onConfirm : null,
          child: Text(Intl.mkdirDialog_ok.tr),
        ),
      ],
    );
  }
}
