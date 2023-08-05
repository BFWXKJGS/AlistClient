import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/database/table/file_download_record.dart';
import 'package:alist/entity/downloads_info.dart';
import 'package:alist/util/download_utils.dart';
import 'package:alist/util/file_utils.dart';
import 'package:alist/util/iterator.dart';
import 'package:alist/util/string_utils.dart';
import 'package:alist/util/user_controller.dart';
import 'package:alist/widget/file_list_item_view.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

typedef DownloadTaskStatusCallback = void Function(
    DownloadTask task, DownloadTaskStatus status, String? reason);

class DownloadManager {
  static final DownloadManager instance = DownloadManager();
  final HttpClient _httpClient = HttpClient()..autoUncompress = false;
  final Queue<DownloadTask> _waitingTasks = Queue();
  final Queue<DownloadTask> _runningTasks = Queue();
  late DownloadTaskStatusCallback _taskStatusCallback;
  final _downloadStatusChangeStreamController =
      StreamController<DownloadTask>.broadcast();
  final _downloadProgressChangeStreamController =
      StreamController<DownloadTask>.broadcast();
  var _maxRunningTaskCount = 1;
  Timer? _progressTimer;

  DownloadManager() {
    _taskStatusCallback = _onDownloadTaskStatusChange;
  }

  Future<DownloadTask?> downloadFileItem(FileItemVO file,
      {CancelToken? cancelToken}) async {
    return download(
      name: file.name,
      remotePath: file.path,
      sign: file.sign,
      thumb: file.thumb,
      cancelToken: cancelToken,
    );
  }

  Future<DownloadTask?> download({
    required String name,
    required String remotePath,
    required String sign,
    String? thumb,
    CancelToken? cancelToken,
  }) async {
    var fileUrl = await FileUtils.makeFileLink(remotePath, sign);
    if (fileUrl == null) {
      return null;
    }

    var waitingTask =
        _waitingTasks.firstWhereOrNull((element) => element.url == fileUrl);
    if (waitingTask != null) {
      SmartDialog.showToast("已经在下载队列中了，请勿重复添加");
      return null;
    }
    var runningTask =
        _runningTasks.firstWhereOrNull((element) => element.url == fileUrl);
    if (runningTask != null) {
      SmartDialog.showToast("该任务正在下载中");
      return null;
    }
    cancelToken = cancelToken ?? CancelToken();

    AlistDatabaseController databaseController = Get.find();
    var downloadRecordRecordDao = databaseController.downloadRecordRecordDao;
    UserController userController = Get.find();
    var user = userController.user.value;
    var record = await downloadRecordRecordDao.findRecordByRemotePath(
        user.serverUrl, user.username, remotePath);

    if (record != null) {
      var localFile = File(record.localPath);
      if (record.sign == sign && localFile.existsSync()) {
        var override = await _showRedownloadConfirmDialog();
        if (!(override ?? false)) {
          return null;
        }
        await localFile.delete();
        await downloadRecordRecordDao.deleteRecord(record);
        record = null;
      }
    }

    String savedFileName;
    String filePath;
    if (record == null) {
      var downloadDir = await DownloadUtils.findDownloadDir("Downloads");
      savedFileName = _makeDownloadFileName(name);
      filePath = p.join(downloadDir.path, savedFileName);

      var newRecord = FileDownloadRecord(
        serverUrl: user.serverUrl,
        userId: user.username,
        remotePath: remotePath,
        name: name,
        sign: sign,
        thumbnail: thumb,
        localPath: filePath,
        createTime: DateTime.now().millisecond,
      );
      await downloadRecordRecordDao.insertRecord(newRecord);
    } else {
      savedFileName = record.localPath.substringAfterLast("/")!;
      filePath = record.localPath;
    }
    var parentFolder = Directory(filePath).parent;
    if (!parentFolder.existsSync()) {
      await parentFolder.create(recursive: true);
    }

    DownloadTask task = DownloadTask(
      httpClient: _httpClient,
      statusCallback: _taskStatusCallback,
      url: fileUrl,
      savedPath: filePath,
      cancelToken: cancelToken,
    );
    LogUtil.d(
        "_runningTasks.length=${_runningTasks.length} $_maxRunningTaskCount");
    if (_runningTasks.length >= _maxRunningTaskCount) {
      LogUtil.d("add waiting task");
      _onDownloadTaskStatusChange(task, DownloadTaskStatus.waiting, null);
    } else {
      LogUtil.d("task start");
      task.start();
      _startListenProgress();
    }
    return task;
  }

  StreamSubscription<DownloadTask> listenDownloadStatusChange(
      void Function(DownloadTask task) onStatusChange) {
    return _downloadStatusChangeStreamController.stream.listen(onStatusChange);
  }

  StreamSubscription<DownloadTask> listenDownloadProgressChange(
      void Function(DownloadTask task) onProgressChange) {
    var result =
        _downloadProgressChangeStreamController.stream.listen(onProgressChange);
    _startListenProgress();
    return result;
  }

  void setMaxRunningTaskCount(int count) {
    if (_maxRunningTaskCount == count) {
      return;
    }
    if (count < 1) {
      throw ArgumentError("maxRunningTaskCount must be greater than 0");
    }
    var originalCount = _maxRunningTaskCount;
    _maxRunningTaskCount = count;

    if (originalCount > count && _runningTasks.isNotEmpty) {
      var diff = originalCount - count;
      for (var i = 0; i < diff; i++) {
        if (_runningTasks.isNotEmpty) {
          var task = _runningTasks.removeFirst();
          task.moveToWaiting();
        } else {
          break;
        }
      }
    } else if (count > originalCount && _waitingTasks.isNotEmpty) {
      var diff = originalCount - count;
      for (var i = 0; i < diff; i++) {
        if (_waitingTasks.isNotEmpty) {
          var task = _waitingTasks.removeLast();
          task.start();
        } else {
          break;
        }
      }
    }
  }

  DownloadTask? findTaskBySavedPath(String path) {
    var task =
        _runningTasks.firstWhereOrNull((element) => element.savedPath == path);
    task ??=
        _waitingTasks.firstWhereOrNull((element) => element.savedPath == path);
    return task;
  }

  String _makeDownloadFileName(String originalName) {
    var extension = originalName.substringAfterLast(".") ?? "";
    if (extension.length > 10) {
      // invalid extension
      extension = "";
    } else {
      extension = ".$extension";
    }
    return "${const Uuid().v4()}$extension";
  }

  Future<bool?> _showRedownloadConfirmDialog() async {
    return SmartDialog.show<bool>(builder: (context) {
      return AlertDialog(
        title: Text("文件已存在"),
        content: Text("文件已存在，是否覆盖？"),
        actions: [
          TextButton(
            onPressed: () => SmartDialog.dismiss(result: false),
            child: Text("取消"),
          ),
          TextButton(
            onPressed: () async {
              SmartDialog.dismiss(result: true);
            },
            child: Text("覆盖"),
          ),
        ],
      );
    });
  }

  void _onDownloadTaskStatusChange(task, status, reason) {
    LogUtil.d("task:$status");
    switch (status) {
      case DownloadTaskStatus.waiting:
        if (_waitingTasks.contains(task)) {
          return;
        }
        _waitingTasks.addFirst(task);
        _runningTasks.remove(task);
        break;
      case DownloadTaskStatus.downloading:
      case DownloadTaskStatus.decompressing:
        _startListenProgress();
        if (_runningTasks.contains(task)) {
          return;
        }
        _runningTasks.addFirst(task);
        _waitingTasks.remove(task);
        break;
      case DownloadTaskStatus.paused:
      case DownloadTaskStatus.failed:
      case DownloadTaskStatus.finished:
      case DownloadTaskStatus.canceled:
        _waitingTasks.remove(task);
        _runningTasks.remove(task);

        if (_waitingTasks.isNotEmpty && _runningTasks.length < _maxRunningTaskCount) {
          var nextTask = _waitingTasks.removeLast();
          nextTask.start();
        }

        if (_runningTasks.isEmpty) {
          _stopListenProgress();
        }
        break;
    }
    if (_downloadStatusChangeStreamController.hasListener) {
      _downloadStatusChangeStreamController.sink.add(task);
    }
  }

  void _startListenProgress() {
    if (!_downloadProgressChangeStreamController.hasListener ||
        _runningTasks.isEmpty ||
        _progressTimer != null) {
      return;
    }
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      for (var task in _runningTasks) {
        if (task._status == DownloadTaskStatus.downloading) {
          _downloadProgressChangeStreamController.sink.add(task);
        }
      }
    });
  }

  void _stopListenProgress() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  void pause(String savedPath) {
    var task = findTaskBySavedPath(savedPath);
    if (task != null) {
      task.pause();
    }
  }

  void cancel(String savedPath) {
    var task = findTaskBySavedPath(savedPath);
    if (task != null) {
      task.cancel();
    }
  }
}

class DownloadTask {
  final HttpClient _httpClient;
  final String url;
  final String savedPath;
  final CancelToken _cancelToken;
  final DownloadTaskStatusCallback _statusCallbacks;
  var _taskMoving = false;
  DownloadTaskStatus _status = DownloadTaskStatus.waiting;
  int? contentLength;
  int downloaded = 0;
  String? failedReason;

  DownloadTask({
    required HttpClient httpClient,
    required DownloadTaskStatusCallback statusCallback,
    required this.url,
    required this.savedPath,
    required CancelToken cancelToken,
  })  : _cancelToken = cancelToken,
        _httpClient = httpClient,
        _statusCallbacks = statusCallback;

  get status => _status;

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

    Map<String, dynamic> requestHeader;
    if (downloadsInfo != null && tmpFileExists) {
      requestHeader = {
        HttpHeaders.rangeHeader: "bytes=${tmpFile.lengthSync()}-",
        HttpHeaders.ifRangeHeader:
            downloadsInfo.etag ?? downloadsInfo.lastModified ?? "",
      };
      LogUtil.d("headers=$requestHeader");
      downloaded = tmpFile.lengthSync();
    } else {
      requestHeader = {};
    }
    contentLength = downloadsInfo?.contentLength;

    late HttpClientResponse httpResponse;
    try {
      httpResponse = await _request(url, requestHeader);
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
    if (status == DownloadTaskStatus.failed) {
      failedReason = reason;
    } else if (failedReason != null) {
      failedReason = null;
    }

    LogUtil.d("_setCurrentStatus: $status");
    if (_status != status) {
      LogUtil.d("_setCurrentStatus2: $status");
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

  Future<HttpClientResponse> _request(
      String fileUri, Map<String, dynamic> requestHeader) async {
    HttpClientRequest request =
        await _httpClient.openUrl("GET", Uri.parse(fileUri));
    requestHeader.forEach((key, value) {
      request.headers.set(key, value);
    });
    return request.close();
  }

  void _notifyStatusChanged(DownloadTaskStatus status, {String? reason}) {
    _statusCallbacks(this, status, reason);
  }

  void moveToWaiting() {
    if (_status == DownloadTaskStatus.waiting) {
      _setCurrentStatus(DownloadTaskStatus.waiting);
    } else if (_status == DownloadTaskStatus.downloading ||
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

enum DownloadTaskStatus {
  waiting,
  downloading,
  decompressing,
  paused,
  failed,
  finished,
  canceled,
}
