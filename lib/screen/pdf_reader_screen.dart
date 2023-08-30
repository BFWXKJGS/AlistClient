import 'dart:async';
import 'dart:io';

import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/util/download/download_manager.dart';
import 'package:alist/util/download/download_task.dart';
import 'package:alist/util/download/download_task_status.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/util/user_controller.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:alist/widget/loading_status_widget.dart';
import 'package:alist/widget/overflow_text.dart';
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
      appbarTitle: OverflowText(text: _controller.pdfItem.name),
      body: Obx(
        () => LoadingStatusWidget(
          loading: _controller.loading.value,
          retryCallback: () => _controller.retry(),
          errorMsg: _controller.errMsg.value,
          child: _buildPDFView(),
        ),
      ),
    );
  }

  Widget _buildPDFView() {
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
  PdfItem pdfItem = Get.arguments['pdfItem'];
  StreamSubscription? _streamSubscription;
  DownloadTask? _downloadTask;
  var loading = false.obs;
  var localPath = "".obs;
  var errMsg = "".obs;

  @override
  void onInit() {
    super.onInit();
    if (pdfItem.localPath == null || pdfItem.localPath!.isEmpty) {
      AlistDatabaseController databaseController = Get.find();
      UserController userController = Get.find();
      final user = userController.user.value;
      databaseController.downloadRecordRecordDao
          .findRecordByRemotePath(
              user.serverUrl, user.username, pdfItem.remotePath)
          .then((value) {
        if (value != null && File(value.localPath).existsSync()) {
          localPath.value = "file://${value.localPath}";
        } else {
          _download();
          _listenStatus();
        }
      });
    } else if (pdfItem.localPath?.isNotEmpty == true) {
      localPath.value = "file://${pdfItem.localPath}";
    }
  }

  @override
  void onClose() {
    _downloadTask?.cancel();
    _streamSubscription?.cancel();
    super.onClose();
  }

  void retry() {
    LogUtil.d("retry");
    errMsg.value = "";
    _download();
  }

  void _download() async {
    loading.value = true;

    final requestHeaders = <String, dynamic>{};
    var limitFrequency = 0;
    if (pdfItem.provider == "BaiduNetdisk") {
      requestHeaders["User-Agent"] = "pan.baidu.com";
    } else if (pdfItem.provider == "AliyundriveOpen") {
      // 阿里云盘下载请求频率限制为 1s/次
      limitFrequency = 1;
    }
    _downloadTask = await DownloadManager.instance.download(
      name: pdfItem.name,
      remotePath: pdfItem.remotePath,
      sign: pdfItem.sign ?? "",
      thumb: pdfItem.thumb,
      requestHeaders: requestHeaders,
      limitFrequency: limitFrequency,
    );
    if (_downloadTask == null) {
      errMsg.value = "Download failed.";
      loading.value = false;
      return;
    }
    if (_downloadTask?.status == DownloadTaskStatus.finished) {
      errMsg.value = "";
      loading.value = false;
      localPath.value = "file://${_downloadTask!.record.localPath}";
    }
  }

  void _listenStatus() {
    _streamSubscription =
        DownloadManager.instance.listenDownloadStatusChange((task) {
      if (task != _downloadTask) {
        return;
      }
      if (task.status == DownloadTaskStatus.finished) {
        errMsg.value = "";
        loading.value = false;
        localPath.value = "file://${task.record.localPath}";
      } else if (task.status == DownloadTaskStatus.failed) {
        errMsg.value = task.failedReason ?? "";
        loading.value = false;
      }
    });
  }
}

class PdfItem {
  final String name;
  String? localPath;
  final String remotePath;
  final String? sign;
  final String? provider;
  final String? thumb;

  PdfItem({
    required this.name,
    this.localPath,
    required this.remotePath,
    this.sign,
    this.provider,
    this.thumb,
  });
}
