import 'package:alist/l10n/intl_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

typedef DirectorPasswordCallback = Function(
  String password,
  bool rememberPassword,
);

class DirectorPasswordDialog extends StatefulWidget {
  const DirectorPasswordDialog(
      {Key? key, required this.directorPasswordCallback})
      : super(key: key);
  final DirectorPasswordCallback directorPasswordCallback;

  @override
  State<DirectorPasswordDialog> createState() => _DirectorPasswordDialogState();
}

class _DirectorPasswordDialogState extends State<DirectorPasswordDialog> {
  final TextEditingController _controller = TextEditingController();
  var _isRememberPassword = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(Intl.directoryPasswordDialog_title.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            obscureText: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isCollapsed: true,
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 11, vertical: 12),
            ),
          ),
          Row(
            children: [
              Checkbox(
                  value: _isRememberPassword,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (checked) {
                    setState(() {
                      _isRememberPassword = checked ?? false;
                    });
                  }),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isRememberPassword = !_isRememberPassword;
                  });
                },
                child: const Text("记住密码？"),
              ),
            ],
          )
        ],
      ),
      actions: [
        TextButton(
            onPressed: () {
              SmartDialog.dismiss();
            },
            child: Text(
              Intl.directoryPasswordDialog_btn_cancel.tr,
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            )),
        TextButton(
            onPressed: () {
              _onConfirm(context);
            },
            child: Text(
              Intl.directoryPasswordDialog_btn_ok.tr,
            ))
      ],
    );
  }

  void _onConfirm(BuildContext context) {
    String password = _controller.text;
    if (password.isEmpty) {
      SmartDialog.showToast(Intl.directoryPasswordDialog_tips_passwordEmpty.tr);
      return;
    }
    widget.directorPasswordCallback(password, _isRememberPassword);
    SmartDialog.dismiss();
  }
}
