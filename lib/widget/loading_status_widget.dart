import 'package:alist/l10n/intl_keys.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoadingStatusWidget extends StatelessWidget {
  const LoadingStatusWidget({
    Key? key,
    required this.loading,
    this.errorMsg,
    required this.child,
    required this.retryCallback,
  }) : super(key: key);
  final bool loading;
  final String? errorMsg;
  final Widget child;
  final VoidCallback retryCallback;

  @override
  Widget build(BuildContext context) {
    if (errorMsg != null && errorMsg!.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Text(errorMsg!),
            ),
            FilledButton(
              onPressed: () {
                LogUtil.d("retry...");
                retryCallback();
              },
              child: Text(Intl.loadingStatusWidget_retry.tr),
            )
          ],
        ),
      );
    } else if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return child;
    }
  }
}
