import 'dart:io';

import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/database/table/file_download_record.dart';
import 'package:alist/entity/file_info_resp_entity.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/net/net_error_handler.dart';
import 'package:alist/util/file_sign_utils.dart';
import 'package:alist/util/string_utils.dart';
import 'package:alist/util/user_controller.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

typedef OnDownloadSuccessful = Function(String name, String filePath);
typedef OnDownloadFailed = Function(int code, String message);

class DownloadUtils {
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

  // download file by file's remote path.
  static void downloadByPath(
    String path, {
    String fileType = "Download",
    CancelToken? cancelToken,
    OnDownloadSuccessful? onSuccess,
    OnDownloadFailed? onFailed,
    ProgressCallback? onReceiveProgress,
  }) async {
    var body = {
      "path": path,
      "password": "",
    };
    DioUtils.instance.requestNetwork<FileInfoRespEntity>(
      Method.post,
      cancelToken: cancelToken,
      "fs/get",
      params: body,
      onSuccess: (data) async {
        var fileUrl = data?.rawUrl ?? "";
        var fileSign = data?.makeCacheUseSign(path);
        var fileName = data?.name ?? fileSign;
        if (fileName == null || fileName.isEmpty) {
          fileName = "noName";
        }
        fileName = fileName.replaceAll(" ", "").replaceAll("/", "_");

        _downloadByFileUrl(
          path,
          fileName,
          fileUrl,
          sign: fileSign,
          fileType: fileType,
          onSuccess: onSuccess,
          onFailed: onFailed,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
        );
      },
      onError: onFailed,
    );
  }

  static Future<void> _downloadByFileUrl(
    String remotePath,
    String fileName,
    String fileUrl, {
    required String? sign,
    required String fileType,
    OnDownloadSuccessful? onSuccess,
    OnDownloadFailed? onFailed,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    UserController userController = Get.find();
    AlistDatabaseController databaseController = Get.find();
    var downloadRecordRecordDao = databaseController.downloadRecordRecordDao;

    if (sign != null && sign.isNotEmpty) {
      var user = userController.user.value;
      var record = await downloadRecordRecordDao.findRecordBySign(
          user.serverUrl, user.username, sign);

      if (record != null) {
        var localFile = File(record.localPath);
        if (!localFile.existsSync()) {
          downloadRecordRecordDao.deleteRecord(record);
          record = null;
        } else {
          if (onSuccess != null) {
            onSuccess(fileName, record.localPath);
          }
          if (record.remotePath != remotePath) {
            // update remote path.
            var newRecord = FileDownloadRecord(
              id: record.id,
              serverUrl: record.serverUrl,
              userId: record.userId,
              name: record.name,
              remotePath: remotePath,
              sign: record.sign,
              localPath: record.localPath,
              createTime: record.createTime,
            );
            downloadRecordRecordDao.updateRecord(newRecord);
          }
          return;
        }
      }
    }

    final downloadDir = await DownloadUtils.findDownloadDir(fileType);
    String filePath = '${downloadDir.path}/$fileName';
    File downloadFile = File(filePath);

    if (fileName.isNotEmpty) {
      // if file exists, rename
      var index = 0;
      while (await downloadFile.exists()) {
        index++;
        filePath = _makeFileName(downloadDir, fileName, index);
        downloadFile = File(filePath);
      }
    }

    // create a temp file.
    final tmpFilePath = '$filePath.tmp';
    File tempFile = File(tmpFilePath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    DioUtils.instance
        .download(
      fileUrl,
      tmpFilePath,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress
    )
        .then((value) async {
      if (await downloadFile.exists()) {
        await downloadFile.delete();
      }
      await tempFile.rename(filePath);

      if (onSuccess != null) {
        onSuccess(fileName, filePath);
      }

      if (sign != null && sign.isNotEmpty) {
        // insert new file download record.
        var user = userController.user.value;
        var newRecord = FileDownloadRecord(
          serverUrl: user.serverUrl,
          userId: user.username,
          remotePath: remotePath,
          name: fileName,
          sign: sign,
          localPath: filePath,
          createTime: DateTime.now().millisecond,
        );
        downloadRecordRecordDao.insertRecord(newRecord);
      }
    }).catchError((e) {
      if (onFailed != null) {
        var message = NetErrorHandler.netErrorToMessage(e);
        onFailed(-1, message);
      }
    });
  }

  static String _makeFileName(
      Directory downloadDir, String fileName, int index) {
    var indexOfExt = fileName.lastIndexOf(".");
    if (indexOfExt > -1) {
      var fileNameWithoutExt = fileName.substring(0, indexOfExt);
      var ext = fileName.substring(indexOfExt);
      return '${downloadDir.path}/$fileNameWithoutExt($index)$ext';
    } else {
      return '${downloadDir.path}/$fileName($index)';
    }
  }
}
