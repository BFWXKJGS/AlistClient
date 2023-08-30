import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/database/table/file_download_record.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/util/alist_plugin.dart';
import 'package:alist/util/download/download_http_client.dart';
import 'package:alist/util/download/download_task.dart';
import 'package:alist/util/download/download_task_status.dart';
import 'package:alist/util/file_type.dart';
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
import 'package:path_provider/path_provider.dart';
import 'package:sprintf/sprintf.dart';
import 'package:uuid/uuid.dart';

typedef DownloadTaskStatusCallback = void Function(
    DownloadTask task, DownloadTaskStatus status, String? reason);

class DownloadManager {
  static final DownloadManager instance = DownloadManager();
  final DownloadHttpClient _httpClient = DownloadHttpClient();
  final Queue<DownloadTask> _waitingTasks = Queue();
  final Queue<DownloadTask> _runningTasks = Queue();
  late DownloadTaskStatusCallback _taskStatusCallback;
  final _downloadStatusChangeStreamController =
      StreamController<DownloadTask>.broadcast();
  final _downloadProgressChangeStreamController =
      StreamController<DownloadTask>.broadcast();
  var _maxRunningTaskCount = 5;
  Timer? _progressTimer;

  int get runningTaskSize => _runningTasks.length;

  int get maxRunningTaskCount => _maxRunningTaskCount;

  DownloadManager() {
    _taskStatusCallback = _onDownloadTaskStatusChange;
  }

  Future<DownloadTask?> download({
    required String name,
    required String remotePath,
    required String sign,
    String? thumb,
    Map<String, dynamic>? requestHeaders,
    int? limitFrequency,
    CancelToken? cancelToken,
  }) async {
    var fileUrl = await FileUtils.makeFileLink(remotePath, sign);
    if (fileUrl == null) {
      return null;
    }

    var waitingTask =
        _waitingTasks.firstWhereOrNull((element) => element.url == fileUrl);
    if (waitingTask != null) {
      waitingTask.start();
      _onDownloadTaskStatusChange(
          waitingTask, DownloadTaskStatus.downloading, null);
      return waitingTask;
    }

    var runningTask =
        _runningTasks.firstWhereOrNull((element) => element.url == fileUrl);
    if (runningTask != null) {
      return runningTask;
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
        return DownloadTask(
          downloadManager: this,
          statusCallback: _taskStatusCallback,
          url: fileUrl,
          record: record,
          cancelToken: cancelToken,
          requestHeaders: requestHeaders ?? {},
          limitFrequency: limitFrequency ?? 0,
          status: DownloadTaskStatus.finished,
        );
      }
    }

    String savedFileName;
    String filePath;
    if (record == null) {
      var downloadDir = await findDownloadDir("Downloads");
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
        requestHeaders: jsonEncode(requestHeaders ?? {}),
        limitFrequency: limitFrequency,
        createTime: DateTime.now().millisecondsSinceEpoch,
      );
      var recordId = await downloadRecordRecordDao.insertRecord(newRecord);
      newRecord.id = recordId;
      record = newRecord;
    } else {
      savedFileName = record.localPath.substringAfterLast("/")!;
      filePath = record.localPath;
    }
    var parentFolder = Directory(filePath).parent;
    if (!parentFolder.existsSync()) {
      await parentFolder.create(recursive: true);
    }

    DownloadTask task = DownloadTask(
      downloadManager: this,
      statusCallback: _taskStatusCallback,
      url: fileUrl,
      record: record,
      requestHeaders: requestHeaders ?? {},
      limitFrequency: limitFrequency ?? 0,
      cancelToken: cancelToken,
    );
    //  Ignore the queue and download directly
    task.start();
    _startListenProgress();
    return task;
  }

  Future<DownloadTask?> enqueueFile(FileItemVO file,
      {CancelToken? cancelToken, bool ignoreDuplicates = false}) async {
    final requestHeaders = <String, dynamic>{};
    var limitFrequency = 0;
    if (file.provider == "BaiduNetdisk") {
      requestHeaders[HttpHeaders.userAgentHeader] = "pan.baidu.com";
    } else if (file.provider == "AliyundriveOpen") {
      // 阿里云盘下载请求频率限制为 1s/次
      limitFrequency = 1;
    }

    return enqueue(
        name: file.name,
        remotePath: file.path,
        sign: file.sign,
        thumb: file.thumb,
        requestHeaders: requestHeaders,
        limitFrequency: limitFrequency,
        cancelToken: cancelToken,
        ignoreDuplicates: ignoreDuplicates);
  }

  Future<DownloadTask?> enqueue(
      {required String name,
      required String remotePath,
      required String sign,
      String? thumb,
      Map<String, dynamic>? requestHeaders,
      int? limitFrequency,
      CancelToken? cancelToken,
      bool ignoreDuplicates = false}) async {
    var fileUrl = await FileUtils.makeFileLink(remotePath, sign);
    if (fileUrl == null) {
      return null;
    }

    var waitingTask =
        _waitingTasks.firstWhereOrNull((element) => element.url == fileUrl);
    if (waitingTask != null) {
      SmartDialog.showToast(Intl.downlodManager_tips_repeated.tr);
      return null;
    }
    var runningTask =
        _runningTasks.firstWhereOrNull((element) => element.url == fileUrl);
    if (runningTask != null) {
      SmartDialog.showToast(Intl.downlodManager_tips_downloading.tr);
      return null;
    }
    cancelToken = cancelToken ?? CancelToken();

    AlistDatabaseController databaseController = Get.find();
    var downloadRecordRecordDao = databaseController.downloadRecordRecordDao;
    UserController userController = Get.find();
    var user = userController.user.value;
    var record = await downloadRecordRecordDao.findRecordByRemotePath(
        user.serverUrl, user.username, remotePath);

    if (record != null && ignoreDuplicates) {
      return null;
    }

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
      var downloadDir = await findDownloadDir("Downloads");
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
        requestHeaders: jsonEncode(requestHeaders ?? {}),
        limitFrequency: limitFrequency,
        createTime: DateTime.now().millisecondsSinceEpoch,
      );
      var recordId = await downloadRecordRecordDao.insertRecord(newRecord);
      newRecord.id = recordId;
      record = newRecord;
    } else {
      savedFileName = record.localPath.substringAfterLast("/")!;
      filePath = record.localPath;
    }
    var parentFolder = Directory(filePath).parent;
    if (!parentFolder.existsSync()) {
      await parentFolder.create(recursive: true);
    }

    DownloadTask task = DownloadTask(
      downloadManager: this,
      statusCallback: _taskStatusCallback,
      url: fileUrl,
      record: record,
      requestHeaders: requestHeaders ?? {},
      limitFrequency: limitFrequency ?? 0,
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
      var diff = count - originalCount;
      for (var i = 0; i < diff; i++) {
        if (_waitingTasks.isNotEmpty) {
          var task = _waitingTasks.removeFirst();
          task.start();
        } else {
          break;
        }
      }
    }
  }

  static Future<Directory> findDownloadDir(String fileType) async {
    UserController userController = Get.find();
    Directory downloadDir;
    if (Platform.isAndroid) {
      final dirs = await getExternalStorageDirectory();
      if (dirs != null) {
        downloadDir = dirs;
      } else {
        downloadDir = await getTemporaryDirectory();
      }
    } else {
      downloadDir = await getTemporaryDirectory();
    }
    String subPath = userController.user().baseUrl.md5String();
    final username = userController.user().username;
    subPath = "$subPath/$username";

    downloadDir = Directory("${downloadDir.path}/$subPath/$fileType");
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  DownloadTask? findTaskBySavedPath(String path) {
    var task = _runningTasks
        .firstWhereOrNull((element) => element.record.localPath == path);
    task ??= _waitingTasks
        .firstWhereOrNull((element) => element.record.localPath == path);
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
        title: Text(Intl.redownloadConfirmDialog_title.tr),
        content: Text(Intl.redownloadConfirmDialog_message.tr),
        actions: [
          TextButton(
            onPressed: () => SmartDialog.dismiss(result: false),
            child: Text(Intl.redownloadConfirmDialog_btn_cancel.tr),
          ),
          TextButton(
            onPressed: () async {
              SmartDialog.dismiss(result: true);
            },
            child: Text(Intl.redownloadConfirmDialog_btn_ok.tr),
          ),
        ],
      );
    });
  }

  void _onDownloadTaskStatusChange(
      DownloadTask task, DownloadTaskStatus status, String? reason) {
    switch (status) {
      case DownloadTaskStatus.waiting:
        if (_waitingTasks.contains(task)) {
          return;
        }
        _waitingTasks.addLast(task);
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
        if (Platform.isAndroid) {
          AlistPlugin.onDownloadingStart();
        }
        break;
      case DownloadTaskStatus.paused:
      case DownloadTaskStatus.failed:
      case DownloadTaskStatus.finished:
      case DownloadTaskStatus.canceled:
        _waitingTasks.remove(task);
        _runningTasks.remove(task);
        if (status == DownloadTaskStatus.finished) {
          SmartDialog.showToast(
            sprintf(Intl.downloadManager_tips_fileDownloadFinish.tr,
                [task.record.name]),
          );
        } else {
          SmartDialog.showToast(
            sprintf(Intl.downloadManager_tips_fileDownloadFailed.tr,
                [task.record.name]),
          );
        }

        if (_waitingTasks.isNotEmpty &&
            _runningTasks.length < _maxRunningTaskCount) {
          var nextTask = _waitingTasks.removeFirst();
          nextTask.start();
        }

        if (_runningTasks.isEmpty && _waitingTasks.isEmpty) {
          _stopListenProgress();

          if (Platform.isAndroid) {
            AlistPlugin.onDownloadingEnd();
          }
        }
        break;
    }
    if (_downloadStatusChangeStreamController.hasListener) {
      _downloadStatusChangeStreamController.sink.add(task);
    }
  }

  Future<HttpClientResponse> request(
      DownloadTask task, Map<String, dynamic> requestHeader) async {
    return _httpClient.get(task.url,
        headers: requestHeader, limitFrequency: task.limitFrequency);
  }

  void _startListenProgress() {
    if (!_downloadProgressChangeStreamController.hasListener ||
        _runningTasks.isEmpty ||
        _progressTimer != null) {
      return;
    }
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      for (var task in _runningTasks) {
        if (task.status == DownloadTaskStatus.downloading &&
            task.downloaded > 0) {
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
