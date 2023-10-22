import 'package:alist/widget/alist_scaffold.dart';
import 'package:alist/widget/alist_will_pop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

class WebScreen extends StatefulWidget {
  const WebScreen({super.key});

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  String? firstPageTitle = Get.arguments["title"];
  String firstPageUrl = Get.arguments["url"] ?? "";

  static const String tag = "_WebScreenState";
  late final InAppWebViewGroupOptions webViewOptions;
  InAppWebViewController? _webViewController;
  String? _title;
  bool _loading = true;
  int _progress = -1;

  @override
  void initState() {
    super.initState();
    _title = firstPageTitle;
    webViewOptions = InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
          useShouldOverrideUrlLoading: true,
          mediaPlaybackRequiresUserGesture: false,
        ),
        android: AndroidInAppWebViewOptions(
            useHybridComposition: true,
            mixedContentMode:
                AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW),
        ios: IOSInAppWebViewOptions(
          allowsInlineMediaPlayback: true,
        ));
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
              if (_webViewController != null &&
                  await _webViewController!.canGoBack()) {
                _goBack();
                return false;
              }
              return true;
            },
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: Uri.tryParse(firstPageUrl)),
              onLoadStart: (controller, uri) {
                debugPrint("onLoadStart");
                setState(() {
                  _progress = 0;
                  _loading = true;
                });
              },
              onLoadStop: (controller, uri) {
                setState(() {
                  _loading = false;
                });
              },
              onTitleChanged: (controller, value) {
                if (value != null &&
                    "about:blank" != value &&
                    value.isNotEmpty) {
                  _title = value;
                }
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress;
                  if (progress >= 98) {
                    _loading = false;
                  }
                });
              },
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
            ),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    _webViewController?.goBack();
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
}
