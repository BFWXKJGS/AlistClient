import 'dart:io';

import 'package:flustars/flustars.dart';

class DownloadHttpClient {
  final HttpClient _httpClient = HttpClient()..autoUncompress = false;
  int _lastLimitRequestTime = 0;
  bool _requesting = false;

  DownloadHttpClient();

  // limitFrequency 用于解决部分网盘（如：阿里云盘）存在下载链接请求频率限制的问题
  // limitFrequency 为与上一次请求的最小时间隔，单位：秒
  Future<HttpClientResponse> get(String url,
      {Map<String, dynamic>? headers, int? limitFrequency}) async {
    if (limitFrequency == null || limitFrequency < 1) {
      return _getInner(url, headers: headers);
    }

    int now = DateTime.now().millisecondsSinceEpoch;
    if (_requesting || now - _lastLimitRequestTime < limitFrequency * 1000) {
      do {
        await Future.delayed(const Duration(milliseconds: 200));
        now = DateTime.now().millisecondsSinceEpoch;
      } while (_requesting || now - _lastLimitRequestTime < limitFrequency);
    }

    _requesting = true;
    try {
      return await _getInner(url, headers: headers);
    } finally {
      _requesting = false;
      _lastLimitRequestTime = DateTime.now().millisecondsSinceEpoch;
    }
  }

  Future<HttpClientResponse> _getInner(String url,
      {Map<String, dynamic>? headers}) async {
    HttpClientRequest request =
        await _httpClient.openUrl("GET", Uri.parse(url));
    headers?.forEach((key, value) {
      LogUtil.d("header $key=$value");
      request.headers.set(key, value);
    });
    return request.close();
  }
}
