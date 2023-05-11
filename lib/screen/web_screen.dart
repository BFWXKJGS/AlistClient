import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:alist/net/dio_utils.dart';
import 'package:alist/util/download_utils.dart';
import 'package:alist/util/log_utils.dart';
import 'package:alist/util/markdown_utils.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:alist/widget/alist_will_pop_scope.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebScreen extends StatefulWidget {
  const WebScreen({super.key});

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  String? firstPageTitle = Get.arguments["title"];
  String firstPageUrl = Get.arguments["url"];
  bool isMarkdown = Get.arguments["isMarkdown"] ?? false;

  static const String tag = "_WebScreenState";
  late WebViewController _controller;
  String? _title;
  bool _loading = true;
  int _progress = -1;

  @override
  void initState() {
    super.initState();
    Log.d("tangrui ${Get.arguments}");
    _title = firstPageTitle;
    _initController();

    if (isMarkdown) {
      _downloadMarkDown();
    } else {
      _load(url: firstPageUrl);
    }
  }

  void _load({String? url, String? html}) {
    if (url != null) {
      Log.d("url=$firstPageUrl");
      _controller.loadRequest(Uri.parse(firstPageUrl));
    } else if (html != null) {
      _controller.loadHtmlString(html, baseUrl: firstPageUrl);
    }
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress;
              if (progress >= 98) {
                _loading = false;
              }
            });
          },
          onPageStarted: (String url) {
            LogUtil.d("onPageFinished url=$url onPageStarted", tag: tag);
            setState(() {
              _progress = 0;
              _loading = true;
            });
          },
          onPageFinished: (String url) {
            LogUtil.d("onPageFinished url=$url", tag: tag);
            _controller.getTitle().then((value) {
              if (value != null && "about:blank" != value && value.isNotEmpty) {
                _title = value;
              } else if (url == firstPageUrl) {
                _title = firstPageTitle;
              } else {
                _title = url;
              }
              setState(() {
                _loading = false;
              });
            });
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AlistScaffold(
      appbarTitle: Text(_title ?? ""),
      body: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            child: _progressbar(),
          ),
          AlistWillPopScope(
            onWillPop: () async {
              if (await _controller.canGoBack()) {
                _goBack();
                return false;
              }
              return true;
            },
            child: WebViewWidget(
              controller: _controller,
            ),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    _controller.goBack();
  }

  Widget _progressbar() {
    if (_loading) {
      return LinearProgressIndicator(
        backgroundColor: Colors.transparent,
        minHeight: 2,
        value: _progress >= 0 ? (_progress / 100.0) : null,
      );
    } else {
      return const SizedBox();
    }
  }

  _downloadMarkDown() async {
    final downloadDir = await DownloadUtils.findDownloadDir("Markdown");
    final filePath = '${downloadDir.path}/${firstPageTitle ?? "noName.md"}';
    File file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }

    DioUtils.instance.download(firstPageUrl, filePath).then((value) async {
      Uint8List markdownTextBytes = await file.readAsBytes();
      String markdownText = utf8.decode(markdownTextBytes);
      String html = await MarkdownUtil.toHtml(markdownText);
      _load(html: html);
    });
  }
}
