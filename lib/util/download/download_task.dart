import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alist/entity/downloads_info.dart';
import 'package:alist/util/download/download_manager.dart';
import 'package:alist/util/download/download_task_status.dart';
import 'package:alist/util/string_utils.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';

class DownloadTask {
  final DownloadManager _downloadManager;
  final String url;
  final String savedPath;
  final CancelToken _cancelToken;
  final DownloadTaskStatusCallback _statusCallbacks;
  final Map<String, dynamic> requestHeaders;
  final int limitFrequency;
  var _taskMoving = false;
  DownloadTaskStatus _status;
  int? contentLength;
  int downloaded = 0;
  String? failedReason;

  DownloadTask({
    required DownloadManager downloadManager,
    required DownloadTaskStatusCallback statusCallback,
    required this.url,
    required this.requestHeaders,
    required this.savedPath,
    required this.limitFrequency,
    required CancelToken cancelToken,
    DownloadTaskStatus status = DownloadTaskStatus.waiting,
  })  : _cancelToken = cancelToken,
        _downloadManager = downloadManager,
        _statusCallbacks = statusCallback,
        _status = status;

  DownloadTaskStatus get status => _status;

  bool get taskMoving => _taskMoving;

  void start() async {
    _taskMoving = false;
    if (_recheckCurrentStatus()) {
      return;
    }
    _setCurrentStatus(DownloadTaskStatus.downloading);

    var tmpFile = File("$savedPath.tmp");
    var fileDownloadInfo = File("$savedPath.downloads");
    DownloadsInfo? downloadsInfo;
    var tmpFileExists = tmpFile.existsSync();
    var downloadInfoFileExists = fileDownloadInfo.existsSync();

    if (tmpFileExists && !downloadInfoFileExists) {
      await tmpFile.delete();
      tmpFileExists = false;
    } else if (!tmpFileExists && downloadInfoFileExists) {
      await fileDownloadInfo.delete();
      downloadInfoFileExists = false;
    } else if (tmpFileExists && downloadInfoFileExists) {
      try {
        var savedJson = await fileDownloadInfo.readAsString();
        var downloadsInfoTmp = DownloadsInfo.fromJson(jsonDecode(savedJson));
        if (!downloadsInfoTmp.isSupportRange ||
            tmpFile.lengthSync() > (downloadsInfoTmp.contentLength ?? 0)) {
          await fileDownloadInfo.delete();
          await tmpFile.delete();
          tmpFileExists = false;
          downloadInfoFileExists = false;
        } else if (tmpFile.lengthSync() ==
            (downloadsInfoTmp.contentLength ?? 0)) {
          await _onDownloadFinish(
              downloadsInfoTmp.decompress, tmpFile, fileDownloadInfo);
          return;
        } else {
          downloadsInfo = downloadsInfoTmp;
        }
      } catch (e) {
        await fileDownloadInfo.delete();
        await tmpFile.delete();
      }
    }

    Map<String, dynamic> requestHeader = requestHeaders;
    if (downloadsInfo != null && tmpFileExists) {
      requestHeader[HttpHeaders.rangeHeader] = "bytes=${tmpFile.lengthSync()}-";
      requestHeader[HttpHeaders.ifRangeHeader] =
          downloadsInfo.etag ?? downloadsInfo.lastModified ?? "";
      LogUtil.d("headers=$requestHeader");
      downloaded = tmpFile.lengthSync();
    }
    contentLength = downloadsInfo?.contentLength;

    late HttpClientResponse httpResponse;
    try {
      httpResponse = await _downloadManager.request(this, requestHeader);
    } catch (e) {
      _setCurrentStatus(DownloadTaskStatus.failed, reason: e.toString());
      return;
    }
    if (_recheckCurrentStatus()) {
      return;
    }

    final statusCode = httpResponse.statusCode;
    if (statusCode >= 200 && statusCode < 300) {
      var isPartialContent = statusCode == HttpStatus.partialContent;
      var decompress =
          httpResponse.headers.value(HttpHeaders.contentEncodingHeader) ==
              "gzip";
      String? contentLength;
      if (isPartialContent) {
        var contentRange =
            httpResponse.headers.value(HttpHeaders.contentRangeHeader);
        contentLength = contentRange?.substringAfterLast("/")?.trim();
        LogUtil.d("isPartialContent $contentLength");
      } else {
        contentLength =
            httpResponse.headers.value(HttpHeaders.contentLengthHeader);
      }
      var eTag = httpResponse.headers.value(HttpHeaders.etagHeader);
      var lastModified =
          httpResponse.headers.value(HttpHeaders.lastModifiedHeader);
      var acceptRanges =
          httpResponse.headers.value(HttpHeaders.acceptRangesHeader);
      var contentLengthInt = int.tryParse(contentLength ?? "") ?? 0;
      var isSupportRange = acceptRanges?.toLowerCase() == "bytes" &&
          contentLength != null &&
          contentLength.isNotEmpty &&
          contentLengthInt > 0 &&
          ((eTag != null && eTag.isNotEmpty) ||
              (lastModified != null && lastModified.isNotEmpty));
      this.contentLength = contentLengthInt;

      downloaded = isPartialContent ? downloaded : 0;
      LogUtil.d("statusCode=$statusCode");
      if (!isPartialContent) {
        if (tmpFileExists) {
          await tmpFile.delete();
        }
        if (downloadInfoFileExists) {
          await fileDownloadInfo.delete();
        }
      }

      downloadsInfo = DownloadsInfo()
        ..isSupportRange = isSupportRange
        ..contentLength = contentLengthInt
        ..lastModified = lastModified
        ..decompress = decompress
        ..etag = eTag;
      var downloadsInfoJson = downloadsInfo.toString();
      var writeFileDownloadInfo =
          fileDownloadInfo.writeAsString(downloadsInfoJson);

      Future<void>? asyncWrite;
      late StreamSubscription<List<int>> subscription;
      subscription = httpResponse.listen((event) {
        subscription.pause();
        asyncWrite =
            tmpFile.writeAsBytes(event, mode: FileMode.append).then((value) {
          downloaded += event.length;
          // LogUtil.d("download progress: $downloaded/$contentLength");

          if (!_recheckCurrentStatus()) {
            subscription.resume();
          } else {
            subscription.cancel();
          }
        }).catchError((Object e) async {
          subscription.cancel();
          _setCurrentStatus(DownloadTaskStatus.failed, reason: e.toString());
        });
      }, onDone: () async {
        if (!_recheckCurrentStatus()) {
          await asyncWrite;
          await writeFileDownloadInfo;
          await _onDownloadFinish(decompress, tmpFile, fileDownloadInfo);
          _setCurrentStatus(DownloadTaskStatus.finished);
        }
      }, onError: (e) async {
        if (!_recheckCurrentStatus()) {
          _setCurrentStatus(DownloadTaskStatus.failed, reason: e.toString());
          await asyncWrite;
        }
      }, cancelOnError: true);
    } else {
      if (!_recheckCurrentStatus()) {
        _setCurrentStatus(DownloadTaskStatus.failed,
            reason: "statusCode: $statusCode");
      }
    }
  }

  bool _recheckCurrentStatus() {
    if (_cancelToken.isCancelled) {
      _setCurrentStatus(DownloadTaskStatus.canceled);
      return true;
    }
    if (_taskMoving) {
      return true;
    }
    return false;
  }

  void cancel() {
    _cancelToken.cancel();
  }

  void _setCurrentStatus(DownloadTaskStatus status, {String? reason}) {
    LogUtil.d("download failed,reason=$reason");
    if (status == DownloadTaskStatus.failed) {
      failedReason = reason;
    } else if (failedReason != null) {
      failedReason = null;
    }

    if (_status != status) {
      _status = status;

      if (status == DownloadTaskStatus.failed) {
        _notifyStatusChanged(DownloadTaskStatus.failed, reason: reason);
      } else {
        _notifyStatusChanged(status);
      }
    }
  }

  Future<void> _onDownloadFinish(
      bool decompress, File tmpFile, File fileDownloadInfo) async {
    File savedFile = File(savedPath);
    if (savedFile.existsSync()) {
      await savedFile.delete();
    }

    if (decompress) {
      _setCurrentStatus(DownloadTaskStatus.decompressing);
      await tmpFile
          .openRead()
          .transform(gzip.decoder)
          .pipe(savedFile.openWrite());
      await tmpFile.delete();
    } else {
      await tmpFile.rename(savedPath);
    }

    if (!_cancelToken.isCancelled) {
      _setCurrentStatus(DownloadTaskStatus.finished);
      if (fileDownloadInfo.existsSync()) {
        fileDownloadInfo.delete();
      }
    } else {
      _setCurrentStatus(DownloadTaskStatus.canceled);
    }
  }

  void _notifyStatusChanged(DownloadTaskStatus status, {String? reason}) {
    _statusCallbacks(this, status, reason);
  }

  void moveToWaiting() {
    if (_status == DownloadTaskStatus.downloading ||
        _status == DownloadTaskStatus.decompressing) {
      _setCurrentStatus(DownloadTaskStatus.waiting);
      _taskMoving = true;
    }
  }

  void pause() {
    if (_status == DownloadTaskStatus.waiting) {
      _setCurrentStatus(DownloadTaskStatus.paused);
    } else if (_status == DownloadTaskStatus.downloading ||
        _status == DownloadTaskStatus.decompressing) {
      _setCurrentStatus(DownloadTaskStatus.paused);
      _taskMoving = true;
    }
  }
}
