import 'dart:async';
import 'dart:io';

import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/util/download/download_manager.dart';
import 'package:alist/util/download/download_task.dart';
import 'package:alist/util/download/download_task_status.dart';
import 'package:alist/util/file_type.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class FileReaderScreen extends StatelessWidget {
  FileReaderScreen({Key? key}) : super(key: key);
  final FileReaderItem _fileReaderItem = Get.arguments["fileReaderItem"];

  @override
  Widget build(BuildContext context) {
    return AlistScaffold(
      appbarTitle: const SizedBox(),
      body: _FileReaderContainer(fileReaderItem: _fileReaderItem),
    );
  }
}

class _FileReaderContainer extends StatefulWidget {
  const _FileReaderContainer({Key? key, required this.fileReaderItem})
      : super(key: key);
  final FileReaderItem fileReaderItem;

  @override
  State<_FileReaderContainer> createState() => _FileReaderContainerState();
}

class _FileReaderContainerState extends State<_FileReaderContainer> {
  String? _localPath;
  int _downloadProgress = 0;
  bool _isOpenSuccessfully = false;
  String? failedMessage;
  String? fileName;
  DownloadTask? _downloadTask;
  late StreamSubscription _downloadProgressSubscription;
  late StreamSubscription _downloadStatusChangeSubscription;

  @override
  void initState() {
    super.initState();
    _download(widget.fileReaderItem);
    _downloadProgressSubscription =
        DownloadManager.instance.listenDownloadProgressChange((task) {
      if (task == _downloadTask) {
        if (task.contentLength != null) {
          setState(() {
            _downloadProgress =
                (task.downloaded / task.contentLength! * 100).round();
          });
        }
      }
    });
    _downloadStatusChangeSubscription =
        DownloadManager.instance.listenDownloadStatusChange((task) {
      if (task == _downloadTask) {
        if (task.status == DownloadTaskStatus.failed) {
          SmartDialog.showToast(task.failedReason ?? "");
        } else if (task.status == DownloadTaskStatus.finished) {
          _onDownloadFinish(widget.fileReaderItem.fileType);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _localPath == null
                ? const CircularProgressIndicator()
                : const SizedBox(),
            fileName != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Text(fileName ?? ""),
                  )
                : const SizedBox(),
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: buildOpenFileMessage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOpenFileMessage() {
    final fileType = widget.fileReaderItem.fileType;
    if (failedMessage != null) {
      return Text(failedMessage ?? "");
    } else if (_downloadProgress < 100) {
      return Text("$_downloadProgress%");
    } else if (!_isOpenSuccessfully &&
        failedMessage == null &&
        !(fileType == FileType.apk && Platform.isAndroid)) {
      return Text("$_downloadProgress%");
    } else if (_isOpenSuccessfully ||
        (fileType == FileType.apk && Platform.isAndroid)) {
      String text;
      if (fileType == FileType.apk && Platform.isAndroid) {
        text = Intl.fileReaderScreen_install.tr;
      } else {
        text = Intl.fileReaderScreen_openAgain.tr;
      }
      return FilledButton(
          onPressed: () {
            if (null != _localPath) {
              _openFile(_localPath);
            }
          },
          child: Text(text));
    } else {
      return Text(failedMessage ?? "");
    }
  }

  @override
  void dispose() {
    _downloadTask?.cancel();
    _downloadProgressSubscription.cancel();
    _downloadStatusChangeSubscription.cancel();
    super.dispose();
  }

  void _download(FileReaderItem item) async {
    final fileType = widget.fileReaderItem.fileType;
    final requestHeaders = <String, dynamic>{};
    var limitFrequency = 0;
    if (item.provider == "BaiduNetdisk") {
      requestHeaders["User-Agent"] = "pan.baidu.com";
    } else if (item.provider == "AliyundriveOpen") {
      // 阿里云盘下载请求频率限制为 1s/次
      limitFrequency = 1;
    }

    _downloadTask = await DownloadManager.instance.download(
      name: item.name,
      remotePath: item.remotePath,
      sign: item.sign ?? "",
      thumb: item.thumb,
      requestHeaders: requestHeaders,
      limitFrequency: limitFrequency,
    );
    if (_downloadTask == null) {
      SmartDialog.showToast("Download failed.");
      return;
    }
    if (_downloadTask?.status == DownloadTaskStatus.finished) {
      _onDownloadFinish(fileType);
    }
  }

  void _onDownloadFinish(FileType? fileType) {
    LogUtil.d("_onDownloadFinish");
    if (fileType == FileType.apk && Platform.isAndroid) {
      var fileName = widget.fileReaderItem.name;
      setState(() {
        this.fileName = fileName;
        _downloadProgress = 100;
        _localPath = _downloadTask?.savedPath;
      });
    } else {
      var fileName = widget.fileReaderItem.name;
      setState(() {
        this.fileName = fileName;
      });
      _openFile(_downloadTask?.savedPath);
    }
  }

  _openFile(String? filePath) async {
    final fileType = widget.fileReaderItem.fileType;
    if (fileType == FileType.apk &&
        Platform.isAndroid &&
        !await Permission.requestInstallPackages.isGranted) {
      _showInstallPermissionDialog();
    } else {
      String? openFileType;
      switch (fileType) {
        case FileType.txt:
        case FileType.code:
          openFileType = "text/plain";
          break;
        case FileType.pdf:
          openFileType = "application/pdf";
          break;
        case FileType.apk:
          openFileType = "application/vnd.android.package-archive";
          break;
        default:
          openFileType = null;
          break;
      }

      OpenFile.open(filePath, type: openFileType).then((value) {
        if (value.type == ResultType.done) {
          setState(() {
            _isOpenSuccessfully = true;
          });
        } else {
          setState(() {
            _isOpenSuccessfully = false;
            failedMessage = value.message;
          });
        }
      });
      setState(() {
        _downloadProgress = 100;
        _localPath = filePath;
      });
    }
  }

  // just for android.
  void _showInstallPermissionDialog() {
    SmartDialog.show(builder: (context) {
      return AlertDialog(
        title: Text(Intl.installPermissionDialog_title.tr),
        content: Text(Intl.installPermissionDialog_content.tr),
        actions: [
          TextButton(
              onPressed: () {
                SmartDialog.dismiss();
              },
              child: Text(Intl.installPermissionDialog_btn_cancel.tr)),
          TextButton(
              onPressed: () {
                SmartDialog.dismiss();
                Permission.requestInstallPackages.request().then((value) {
                  if (value.isGranted) {
                    _openFile(_localPath);
                  } else {
                    SmartDialog.showToast(
                        Intl.installPermissionDialog_denied.tr);
                  }
                });
              },
              child: Text(Intl.installPermissionDialog_btn_ok.tr)),
        ],
      );
    });
  }
}

class FileReaderItem {
  final String name;
  String? localPath;
  final String remotePath;
  final String? sign;
  final String? provider;
  final String? thumb;
  final FileType? fileType;

  FileReaderItem({
    required this.name,
    this.localPath,
    required this.remotePath,
    this.sign,
    this.provider,
    this.thumb,
    required this.fileType,
  });
}
