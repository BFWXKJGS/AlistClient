import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/database/dao/file_download_record_dao.dart';
import 'package:alist/entity/downloads_info.dart';
import 'package:alist/screen/video_player_screen.dart';
import 'package:alist/util/download_manager.dart';
import 'package:alist/util/file_type.dart';
import 'package:alist/util/file_utils.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/util/user_controller.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:alist/widget/overflow_text.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';

class DownloadManagerScreen extends StatelessWidget {
  const DownloadManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DownloadManagerController());
    return AlistScaffold(
      appbarTitle: Text("下载管理"),
      body:
          SlidableAutoCloseBehavior(child: _buildDownloadListView(controller)),
    );
  }

  Widget _buildDownloadListView(DownloadManagerController controller) {
    return Obx(
      () => controller._downloadList.isEmpty
          ? const Center(
              child: Text("暂无下载记录"),
            )
          : ListView.separated(
              itemBuilder: (context, index) =>
                  _buildDownloadItem(controller, index),
              separatorBuilder: (context, index) => const Divider(),
              itemCount: controller._downloadList.length,
            ),
    );
  }

  Widget _buildDownloadItem(DownloadManagerController controller, int index) {
    var downloadItem = controller._downloadList[index];
    String? thumbnail = FileUtils.getCompleteThumbnail(downloadItem.thumbnail);
    String icon = FileUtils.getFileIcon(false, downloadItem.name);
    Widget content = ListTile(
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (thumbnail != null && thumbnail.isNotEmpty)
            _buildThumbnailView(icon, thumbnail)
          else
            Image.asset(icon)
        ],
      ),
      title: OverflowText(text: downloadItem.name),
      subtitle: Obx(() {
        return Text(downloadItem.status.value);
      }),
      trailing: Obx(() => _buildTrailing(controller, downloadItem)),
      onTap: () => controller.onTap(downloadItem),
    );
    return Slidable(
      key: Key(downloadItem.id.toString()),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) => controller.delete(downloadItem),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            label: "删除",
          ),
        ],
      ),
      child: content,
    );
  }

  ClipRRect _buildThumbnailView(String icon, String thumbnail) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      child: ExtendedImage.network(
        thumbnail,
        fit: BoxFit.cover,
        width: 35,
        height: 35,
        loadStateChanged: (state) {
          if (state.extendedImageLoadState != LoadState.completed) {
            return Image.asset(icon);
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTrailing(
      DownloadManagerController controller, DownloadItem downloadItem) {
    final status = downloadItem.downloadStatus.value;
    if (status == DownloadTaskStatus.waiting ||
        status == DownloadTaskStatus.downloading ||
        status == DownloadTaskStatus.decompressing) {
      return IconButton(
          onPressed: () => controller.pause(downloadItem),
          icon: const Icon(Icons.pause_rounded));
    } else if (status == DownloadTaskStatus.paused ||
        status == DownloadTaskStatus.canceled ||
        status == DownloadTaskStatus.failed) {
      return IconButton(
          onPressed: () => controller.download(downloadItem),
          icon: const Icon(Icons.play_arrow_rounded));
    }
    return const SizedBox();
  }
}

class DownloadManagerController extends GetxController {
  final _downloadList = <DownloadItem>[].obs;
  late StreamSubscription _downloadProgressSubscription;
  late StreamSubscription _downloadStatusSubscription;

  @override
  void onInit() {
    super.onInit();
    _findDownloadList();
    _downloadProgressSubscription =
        DownloadManager.instance.listenDownloadProgressChange((task) {
      if (task.status != DownloadTaskStatus.downloading) {
        return;
      }
      var item = _downloadList
          .firstWhereOrNull((element) => element.savedPath == task.savedPath);
      if (item != null) {
        item.downloadStatus.value = task.status;
        if (task.contentLength != null) {
          item.status.value =
              "下载中(${(task.downloaded / task.contentLength! * 100).toStringAsFixed(2)}%)";
        } else {
          item.status.value = "下载中";
        }
      }
    });
    _downloadStatusSubscription =
        DownloadManager.instance.listenDownloadStatusChange((task) {
      var item = _downloadList
          .firstWhereOrNull((element) => element.savedPath == task.savedPath);
      if (item != null) {
        item.downloadStatus.value = task.status;
        switch (item.downloadStatus.value) {
          case DownloadTaskStatus.finished:
            item.status.value = "已下载完毕";
            break;
          case DownloadTaskStatus.failed:
            item.status.value = "下载失败(${task.failedReason ?? ""})";
            break;
          case DownloadTaskStatus.paused:
            if (task.contentLength != null) {
              item.status.value =
                  "已暂停(已下载${(task.downloaded / task.contentLength! * 100).toStringAsFixed(2)}%)";
            } else {
              item.status.value = "已暂停";
            }
            break;
          case DownloadTaskStatus.waiting:
            item.status.value = "等待中";
            break;
          case DownloadTaskStatus.downloading:
            if (task.contentLength != null) {
              item.status.value =
                  "下载中(${(task.downloaded / task.contentLength! * 100).toStringAsFixed(2)}%)";
            } else {
              item.status.value = "下载中";
            }
            break;
          case DownloadTaskStatus.decompressing:
            item.status.value = "解压中";
            break;
          case DownloadTaskStatus.canceled:
            item.status.value = "已取消";
            break;
        }
      }
    });
  }

  @override
  void onClose() {
    _downloadProgressSubscription.cancel();
    _downloadStatusSubscription.cancel();
    super.onClose();
  }

  void _findDownloadList() async {
    UserController userController = Get.find();
    var user = userController.user.value;
    AlistDatabaseController databaseController = Get.find();
    FileDownloadRecordRecordDao downloadRecordRecordDao =
        databaseController.downloadRecordRecordDao;

    var files =
        await downloadRecordRecordDao.findAll(user.serverUrl, user.username);
    if (files == null || files.isEmpty) {
      return;
    }
    var downloadManager = DownloadManager.instance;

    var downloadItems = files.map((e) {
      var task = downloadManager.findTaskBySavedPath(e.localPath);
      if (task != null) {
        var status = task.status == DownloadTaskStatus.waiting ? "等待中" : "下载中";
        return DownloadItem(
          id: e.id ?? 0,
          name: e.name,
          remotePath: e.remotePath,
          savedPath: e.localPath,
          sign: e.sign,
          status: status,
          downloadStatus: task.status,
          thumbnail: e.thumbnail,
        );
      } else {
        var localFile = File(e.localPath);
        if (localFile.existsSync()) {
          return DownloadItem(
            id: e.id ?? 0,
            name: e.name,
            remotePath: e.remotePath,
            savedPath: e.localPath,
            sign: e.sign,
            status: "已下载完毕",
            downloadStatus: DownloadTaskStatus.finished,
            thumbnail: e.thumbnail,
          );
        }

        var tmpFile = File("${e.localPath}.tmp");
        var downloadInfoFile = File("${e.localPath}.downloads");
        if (tmpFile.existsSync() || downloadInfoFile.existsSync()) {
          var contentLength = _readContentLength(downloadInfoFile);
          if (contentLength != null) {
            return DownloadItem(
              id: e.id ?? 0,
              name: e.name,
              remotePath: e.remotePath,
              savedPath: e.localPath,
              sign: e.sign,
              status:
                  "已暂停(已下载${(tmpFile.lengthSync() / contentLength * 100).toStringAsFixed(2)}%)",
              downloadStatus: DownloadTaskStatus.paused,
              thumbnail: e.thumbnail,
            );
          }

          return DownloadItem(
            id: e.id ?? 0,
            name: e.name,
            remotePath: e.remotePath,
            savedPath: e.localPath,
            sign: e.sign,
            status: "已暂停",
            downloadStatus: DownloadTaskStatus.paused,
            thumbnail: e.thumbnail,
          );
        }

        return DownloadItem(
          id: e.id ?? 0,
          name: e.name,
          remotePath: e.remotePath,
          savedPath: e.localPath,
          sign: e.sign,
          status: "已暂停(已下载0%)",
          downloadStatus: DownloadTaskStatus.paused,
          thumbnail: e.thumbnail,
        );
      }
    });
    _downloadList.value = downloadItems.toList();
    LogUtil.d("downloadItems=${downloadItems.length}");
  }

  int? _readContentLength(File downloadInfoFile) {
    try {
      var savedJson = downloadInfoFile.readAsStringSync();
      var downloadsInfo = DownloadsInfo.fromJson(jsonDecode(savedJson));
      return downloadsInfo.contentLength;
    } catch (e) {
      return null;
    }
  }

  void download(DownloadItem downloadItem) {
    DownloadManager.instance.download(
      name: downloadItem.name,
      remotePath: downloadItem.remotePath ?? "",
      sign: downloadItem.sign ?? "",
      thumb: downloadItem.thumbnail,
    );
  }

  void pause(DownloadItem downloadItem) {
    DownloadManager.instance.pause(downloadItem.savedPath);
  }

  void delete(DownloadItem downloadItem) {
    DownloadManager.instance.cancel(downloadItem.savedPath);
    _downloadList.removeWhere((element) => element == downloadItem);
    AlistDatabaseController databaseController = Get.find();
    FileDownloadRecordRecordDao downloadRecordRecordDao =
        databaseController.downloadRecordRecordDao;
    downloadRecordRecordDao.deleteById(downloadItem.id);
    var savedFile = File(downloadItem.savedPath);
    if (savedFile.existsSync()) {
      savedFile.delete();
    }
    var tmpFile = File("${downloadItem.savedPath}.tmp");
    if (tmpFile.existsSync()) {
      tmpFile.delete();
    }
    var downloadInfoFile = File("${downloadItem.savedPath}.downloads");
    if (downloadInfoFile.existsSync()) {
      downloadInfoFile.delete();
    }
  }

  void onTap(DownloadItem downloadItem) {
    var fileType = FileUtils.getFileType(false, downloadItem.name);
    switch (fileType) {
      case FileType.video:
        var video = VideoItem(
          name: downloadItem.name,
          localPath: downloadItem.savedPath,
          remotePath: downloadItem.remotePath ?? "",
          sign: downloadItem.sign ?? "",
        );
        Get.toNamed(NamedRouter.videoPlayer, arguments: {
          "videos": [video],
          "index": 0
        });
        break;
      default:
        break;
    }
  }
}

class DownloadItem {
  final int id;
  final String name;
  final String? remotePath;
  final String? sign;
  final RxString status;
  final Rx<DownloadTaskStatus> downloadStatus;
  final String savedPath;
  String? thumbnail;

  DownloadItem({
    required this.id,
    required this.name,
    required this.remotePath,
    required this.savedPath,
    required this.sign,
    required String status,
    required DownloadTaskStatus downloadStatus,
    this.thumbnail,
  })  : status = status.obs,
        downloadStatus = downloadStatus.obs;
}
