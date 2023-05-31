import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:alist/entity/file_info_resp_entity.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/net/net_error_handler.dart';
import 'package:alist/util/download_utils.dart';
import 'package:alist/util/file_sign_utils.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:dio/dio.dart';
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
            if (_controller.errMsg.value.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      child: Text(_controller.errMsg.value),
                    ),
                    FilledButton(
                      onPressed: () => _controller.retry(),
                      child: const Text("Retry"),
                    )
                  ],
                ),
              );
            }

            return _controller.loading.value
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : buildMarkdownWidget(isDark);
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
      _downloadAndShowMarkdownContent();
    }
  }

  @override
  void onClose() {
    super.onClose();
    _cancelToken.cancel();
  }

  retry() {
    errMsg.value = "";
    _downloadAndShowMarkdownContent();
  }

  void _downloadAndShowMarkdownContent() {
    if (markdownUrl != null && markdownUrl!.isNotEmpty) {
      _downloadByMarkdownUrl(markdownUrl!);
    } else if (markdownPath != null && markdownPath!.isNotEmpty) {
      _predownload(markdownPath!);
    }
  }

  void _predownload(String remotePath) {
    loading.value = true;
    var body = {
      "path": remotePath,
      "password": "",
    };
    DioUtils.instance.requestNetwork<FileInfoRespEntity>(
      Method.post,
      cancelToken: _cancelToken,
      "fs/get",
      params: body,
      onSuccess: (data) async {
        var url = data?.rawUrl;
        markdownUrl = data?.name;
        if (url != null && url.isNotEmpty) {
          _downloadByMarkdownUrl(url, sign: data?.makeCacheUseSign(remotePath));
        }
      },
      onError: (code, message) {
        loading.value = true;
        errMsg.value = message;
        debugPrint("code:$code,message:$message");
      },
    );
  }

  Future<void> _downloadByMarkdownUrl(
    String markdownUrl, {
    String? sign,
  }) async {
    loading.value = true;
    final downloadDir = await DownloadUtils.findDownloadDir("Markdown");
    final filePath = '${downloadDir.path}/${sign ?? "noName"}.md';
    File markdownFile = File(filePath);

    if (sign != null && sign.isNotEmpty) {
      // cache file exists, read cache.
      if (markdownFile.existsSync()) {
        Uint8List markdownTextBytes = await markdownFile.readAsBytes();
        String markdownText = utf8.decode(markdownTextBytes);
        markdownContent.value = markdownText;
        loading.value = false;
        return;
      }
    }

    final tmpFilePath = '$filePath.tmp';
    File tempFile = File(tmpFilePath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    DioUtils.instance
        .download(
      markdownUrl,
      tmpFilePath,
      cancelToken: _cancelToken,
    )
        .then((value) async {
      await tempFile.rename(filePath);
      Uint8List markdownTextBytes = await markdownFile.readAsBytes();
      String markdownText = utf8.decode(markdownTextBytes);
      markdownContent.value = markdownText;
      loading.value = false;
    }).catchError((e) {
      errMsg.value = NetErrorHandler.netErrorToMessage(e);
      loading.value = false;
    });
  }
}
