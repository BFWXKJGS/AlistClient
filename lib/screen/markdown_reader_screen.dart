import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:alist/net/dio_utils.dart';
import 'package:alist/util/download_utils.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:alist/widget/loading_status_widget.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:markdown_widget/markdown_widget.dart';

class MarkdownReaderScreen extends StatelessWidget {
  final MarkdownReaderController _controller =
      Get.put(MarkdownReaderController());

  MarkdownReaderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlistScaffold(
        appbarTitle: Text(_controller.title ?? ""),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Obx(() {
            return LoadingStatusWidget(
              loading: _controller.loading.value,
              errorMsg: _controller.errMsg.value,
              retryCallback: () => _controller.retry(),
              child: buildMarkdownWidget(isDark),
            );
          }),
        ));
  }

  MarkdownWidget buildMarkdownWidget(bool isDark) {
    return MarkdownWidget(
      data: _controller.markdownContent.value,
      config: isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig,
    );
  }
}

class MarkdownReaderController extends GetxController {
  var markdownContent = "".obs;
  var loading = false.obs;
  var errMsg = "".obs;
  String? markdownUrl = Get.arguments["markdownUrl"];
  final String? markdownPath = Get.arguments["markdownPath"];
  final String? title = Get.arguments["title"];
  final CancelToken _cancelToken = CancelToken();

  @override
  void onInit() {
    super.onInit();
    markdownContent.value = Get.arguments["markdownContent"] ?? "";
    if (markdownContent.value.isEmpty) {
      _download();
    }
  }

  @override
  void onClose() {
    super.onClose();
    _cancelToken.cancel();
  }

  retry() {
    errMsg.value = "";
    _download();
  }

  _download() {
    if (markdownPath != null && markdownPath!.isNotEmpty) {
      loading.value = true;
      DownloadUtils.downloadByPath(markdownPath!,
          fileType: "Markdown",
          cancelToken: _cancelToken, onSuccess: (_, localPath) async {
        await _readFileAndShowMarkdown(localPath);
        loading.value = false;
      }, onFailed: (code, message) {
        LogUtil.d("code=$code message=$message");
        loading.value = false;
        errMsg.value = message;
      });
    } else if (markdownUrl != null && markdownUrl!.isNotEmpty) {
      _downloadByMarkdownUrl(markdownUrl!);
    }
  }

  Future<void> _readFileAndShowMarkdown(String localPath) async {
    LogUtil.d("localPath=$localPath");

    File markdownFile = File(localPath);
    Uint8List markdownTextBytes = await markdownFile.readAsBytes();
    String markdownText = utf8.decode(markdownTextBytes);
    markdownContent.value = markdownText;
  }

  Future<void> _downloadByMarkdownUrl(String markdownUrl) async {
    loading.value = true;
    DioUtils.instance.requestForString(Method.get, markdownUrl,
        cancelToken: _cancelToken, onSuccess: (data) {
      markdownContent.value = data ?? "";
      loading.value = false;
    }, onError: (code, message) {
      loading.value = false;
      errMsg.value = message;
    });
  }
}
