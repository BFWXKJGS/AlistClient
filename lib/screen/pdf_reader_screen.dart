import 'dart:io';

import 'package:alist/util/download_utils.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:alist/widget/loading_status_widget.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';

class PdfReaderScreen extends StatelessWidget {
  final PdfReaderScreenController _controller =
      Get.put(PdfReaderScreenController());

  PdfReaderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlistScaffold(
      appbarTitle: Text(_controller.title),
      body: Obx(
        () => LoadingStatusWidget(
          loading: _controller.loading.value,
          retryCallback: () => _controller.retry(),
          errorMsg: _controller.errMsg.value,
          child: buildPDFView(),
        ),
      ),
    );
  }

  Widget buildPDFView() {
    return Obx(
      () => _controller.localPath.value.isNotEmpty
          ? PDFView(
              filePath: _controller.localPath.value,
              autoSpacing: !Platform.isAndroid,
              pageSnap: false,
              enableSwipe: true,
              pageFling: false,
              fitEachPage: false,
              fitPolicy: FitPolicy.WIDTH,
              preventLinkNavigation: true,
              onLinkHandler: (url) {
                Get.toNamed(NamedRouter.web, arguments: {"url": url});
              },
              nightMode: Get.isDarkMode,
              onError: (e) {
                LogUtil.e(e);
              },
            )
          : const SizedBox(),
    );
  }
}

class PdfReaderScreenController extends GetxController {
  String title = Get.arguments['title'] ?? "";
  String fileRemotePath = Get.arguments['path'] ?? "";
  final _cancelToken = CancelToken();
  var loading = false.obs;
  var localPath = "".obs;
  var errMsg = "".obs;

  @override
  void onInit() {
    super.onInit();
    _download(fileRemotePath);
  }

  @override
  void onClose() {
    _cancelToken.cancel();
    super.onClose();
  }

  void retry() {
    LogUtil.d("retry");
    errMsg.value = "";
    _download(fileRemotePath);
  }

  void _download(String remotePath) {
    loading.value = true;
    DownloadUtils.downloadByPath(
      remotePath,
      fileType: "PDF",
      cancelToken: _cancelToken,
      onSuccess: (_, localPath) {
        loading.value = false;
        LogUtil.d("localPath=$localPath");
        if (Platform.isAndroid) {
          this.localPath.value = "file://$localPath";
        } else {
          this.localPath.value = localPath;
        }
      },
      onFailed: (code, message) {
        loading.value = false;
        errMsg.value = message;
      },
    );
  }
}
