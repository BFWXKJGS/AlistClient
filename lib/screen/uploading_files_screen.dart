import 'dart:io';

import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/net/net_error_handler.dart';
import 'package:alist/util/string_utils.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UploadingFilesScreen extends StatelessWidget {
  const UploadingFilesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(UploadingFilesController());
    return AlistScaffold(
      appbarTitle: Text(Intl.screenName_uploadingFiles.tr),
      body: Obx(
        () => ListView.separated(
          itemBuilder: (context, index) {
            var item = controller.allFiles[index];
            return _buildUploadingFileItem(context, controller, item);
          },
          separatorBuilder: (context, index) {
            return const Divider();
          },
          itemCount: controller.allFiles.length,
        ),
      ),
    );
  }

  Widget _buildUploadingFileItem(BuildContext context,
      UploadingFilesController controller, UploadingFile item) {
    return InkWell(
      onTap: item.isError
          ? () {
              controller.retry(item);
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            buildStatusText(context, item),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: item.progress,
                minHeight: 4,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildStatusText(BuildContext context, UploadingFile file) {
    Widget statusText;
    var statusTextStyle = const TextStyle(fontSize: 12);
    var backgroundColor = Colors.grey[200];
    var colorScheme = Theme.of(context).colorScheme;
    if (file.isError) {
      backgroundColor = colorScheme.error;
      statusText = Text(
        Intl.uploadingFileScreen_status_error.tr,
        style: statusTextStyle.copyWith(
          color: colorScheme.onError,
        ),
      );
    } else if (file.count == 0) {
      backgroundColor = const Color(0xffe4effc);
      statusText = Text(
        Intl.uploadingFileScreen_status_waiting.tr,
        style: statusTextStyle.copyWith(
          color: const Color(0xff0059cf),
        ),
      );
    } else if (file.count == file.total) {
      backgroundColor = const Color(0xffddf3e4);
      statusText = Text(
        Intl.uploadingFileScreen_status_completed.tr,
        style: statusTextStyle.copyWith(
          color: const Color(0xff277f57),
        ),
      );
    } else {
      backgroundColor = const Color(0xffe4effc);
      statusText = Text(
        Intl.uploadingFileScreen_status_uploading.tr,
        style: statusTextStyle.copyWith(
          color: const Color(0xff0059cf),
        ),
      );
    }
    Widget textWithContainer = Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(2),
      ),
      child: statusText,
    );

    if (file.isError) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          textWithContainer,
          const SizedBox(width: 10),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(file.errorMessage ?? ""),
          )),
        ],
      );
    } else {
      return Align(
        alignment: Alignment.centerLeft,
        child: textWithContainer,
      );
    }
  }
}

class UploadingFilesController extends GetxController {
  final List<String> filePaths = Get.arguments?["filePaths"] ?? [];
  final String remotePath = Get.arguments?["remotePath"] ?? "";
  final Set<String> originalFileNames =
      Get.arguments?["originalFileNames"] ?? [];
  final allFiles = <UploadingFile>[].obs;
  final _uploadingFiles = <UploadingFile>[];
  final dio.CancelToken _cancelToken = dio.CancelToken();
  var _isUploading = false;

  @override
  void onInit() {
    super.onInit();
    for (var filePath in filePaths) {
      var uploadingFile = UploadingFile(
          filePath, filePath.substringAfterLast("/")!, 0, 0, 0, false, null);
      allFiles.add(uploadingFile);
      _uploadingFiles.add(uploadingFile);
    }
    _uploadFiles();
  }

  void _uploadFiles() async {
    if (_uploadingFiles.isEmpty) {
      return;
    }

    _isUploading = true;
    while (_uploadingFiles.isNotEmpty) {
      var uploadingFile = _uploadingFiles.removeAt(0);
      var index = allFiles.indexOf(uploadingFile);

      var file = File(uploadingFile.filePath);
      String? remoteFileName = _makeRemoteFileName(file);
      var remotePath = "${this.remotePath}/$remoteFileName";
      if (remotePath == "/") {
        remotePath = "/$remoteFileName";
      }

      dio.Response<Map<String, dynamic>>? response;
      try {
        response = await DioUtils.instance.upload(
          "fs/put",
          file,
          remotePath,
          cancelToken: _cancelToken,
          onSendProgress: (count, total) {
            uploadingFile.count = count;
            uploadingFile.total = total;
            int progress = (count.toDouble() / total * 100).round();
            if ((uploadingFile.progress * 100).round() != progress) {
              LogUtil.d("progress=$progress");
              uploadingFile.progress = progress / 100.0;
              allFiles[index] = uploadingFile;
            }
          },
        );
      } catch (e) {
        LogUtil.e(e);
        allFiles[index].isError = true;
        allFiles[index] = uploadingFile;
        uploadingFile.errorMessage = NetErrorHandler.netErrorToMessage(e);
        continue;
      }

      if (response.statusCode != 200 || response.data?["code"] != 200) {
        uploadingFile.isError = true;
        if (response.statusCode != 200) {
          uploadingFile.errorMessage = "statusCode=${response.statusCode}";
        } else {
          uploadingFile.errorMessage = response.data?["message"];
        }
      }
      allFiles[index] = uploadingFile;
    }
    _isUploading = false;
  }

  /// create a remote file name
  /// the original name of the file is used by default
  /// if there is a renamed file then change the name and return
  String? _makeRemoteFileName(File file) {
    var fileNameOriginal = file.path.substringAfterLast("/")!;
    var hasExt = fileNameOriginal.contains(".");
    var fileNameWithoutExt = fileNameOriginal.substringBeforeLast(".")!;
    var ext = hasExt ? fileNameOriginal.substringAfterLast(".")! : "";

    var fileNameRemote = fileNameOriginal;
    var index = 1;
    do {
      if (!originalFileNames.contains(fileNameRemote)) {
        // not duplicate file
        break;
      }
      // try to change file name
      if (hasExt) {
        fileNameRemote = "$fileNameWithoutExt($index).$ext";
      } else {
        fileNameRemote = "$fileNameWithoutExt($index)";
      }
      index++;
    } while (true);
    return fileNameRemote;
  }

  void retry(UploadingFile item) {
    item.isError = false;
    item.errorMessage = null;
    var index = allFiles.indexOf(item);
    allFiles[index] = item;

    _uploadingFiles.add(item);
    if (!_isUploading) {
      _uploadFiles();
    }
  }
}

class UploadingFile {
  String filePath;
  String fileName;
  int count;
  int total;
  double progress;
  bool isError;
  String? errorMessage;

  UploadingFile(
    this.filePath,
    this.fileName,
    this.count,
    this.total,
    this.progress,
    this.isError,
    this.errorMessage,
  );
}
