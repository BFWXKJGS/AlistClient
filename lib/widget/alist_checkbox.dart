import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AlistCheckBox extends StatelessWidget {
  final bool? value;
  final String text;
  final ValueChanged<bool?>? onChanged;

  const AlistCheckBox({
    super.key,
    required this.value,
    required this.text,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoCheckbox(
          value: value,
          // materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: onChanged,
        ),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: onChanged == null
              ? null
              : () {
                  onChanged!(!(value ?? false));
                },
          child: Text(text),
        ),
      ],
    );
  }
}
