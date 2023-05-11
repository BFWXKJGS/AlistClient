import 'dart:io';

import 'package:alist/entity/file_info_resp_entity.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/util/download_utils.dart';
import 'package:alist/util/file_type.dart';
import 'package:alist/net/net_error_getter.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';

class FileReaderScreen extends StatelessWidget {
  FileReaderScreen({Key? key}) : super(key: key);
  final String path = Get.arguments["path"];
  final FileType? fileType = Get.arguments["fileType"];

  @override
  Widget build(BuildContext context) {
    return AlistScaffold(
      appbarTitle: const SizedBox(),
      body: _FileReaderContainer(
        remotePath: path,
        fileType: fileType,
      ),
    );
  }
}

class _FileReaderContainer extends StatefulWidget {
  const _FileReaderContainer(
      {Key? key, required this.remotePath, required this.fileType})
      : super(key: key);
  final String remotePath;
  final FileType? fileType;

  @override
  State<_FileReaderContainer> createState() => _FileReaderContainerState();
}

class _FileReaderContainerState extends State<_FileReaderContainer>
    with NetErrorGetterMixin {
  String? _localPath;
  int _downloadProgress = 0;
  final _cancelToken = CancelToken();
  bool _isOpenSuccessfully = false;
  String? failedMessage;
  String? fileName;

  @override
  void initState() {
    super.initState();
    _predownload(widget.remotePath);
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
    if (failedMessage != null) {
      return Text(failedMessage ?? "");
    } else if (_downloadProgress < 100) {
      return Text("$_downloadProgress%");
    } else if (!_isOpenSuccessfully && failedMessage == null) {
      return Text("$_downloadProgress%");
    } else if (_isOpenSuccessfully) {
      return FilledButton(
          onPressed: () {
            if (null != _localPath) {
              _openFile(_localPath);
            }
          },
          child: const Text("Open again"));
    } else {
      return Text(failedMessage ?? "");
    }
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    super.dispose();
  }

  void _predownload(String remotePath) {
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
        setState(() {
          fileName = data?.name;
        });
        if (url != null && url.isNotEmpty) {
          _download(data?.name ?? "", data!.size, url);
        }
      },
      onError: (code, message, error) {
        SmartDialog.showToast(message ?? netErrorToMessage(error));
        debugPrint("code:$code,message:$message");
      },
    );
  }

  Future<void> _download(String name, int fileSize, String url) async {
    LogUtil.d("start download $name", tag: "FileReaderScreen");
    Directory downloadDir = await DownloadUtils.findDownloadDir("Download");
    LogUtil.d("downloadDir=$downloadDir", tag: "FileReaderScreen");
    final cacheFilePath = '${downloadDir.path}/$name';
    final cacheFile = File(cacheFilePath);
    if (await cacheFile.exists()) {
      if (await cacheFile.length() == fileSize) {
        _openFile(cacheFilePath);
        return;
      } else {
        await cacheFile.delete();
      }
    }

    final downloadTmpFilePath = '${downloadDir.path}/$name.tmp';
    final downloadTmpFile = File(downloadTmpFilePath);
    if (await downloadTmpFile.exists()) {
      await downloadTmpFile.delete();
    }

    DioUtils.instance
        .download(
      url,
      downloadTmpFilePath,
      onReceiveProgress: (count, total) => setState(() {
        _downloadProgress = (count.toDouble() / total * 100).toInt();
      }),
    )
        .then((value) async {
      await downloadTmpFile.rename(cacheFilePath);

      LogUtil.d("open file $name", tag: "FileReaderScreen");
      _openFile(cacheFilePath);
    }).catchError((e) {
      setState(() {
        failedMessage = e.toString();
      });
    });
  }

  _openFile(String? filePath) {
    String? openFileType;
    switch (widget.fileType) {
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
