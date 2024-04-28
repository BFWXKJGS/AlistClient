import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/database/dao/file_download_record_dao.dart';
import 'package:alist/entity/downloads_info.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/screen/audio_player_screen.dart';
import 'package:alist/screen/file_reader_screen.dart';
import 'package:alist/screen/gallery_screen.dart';
import 'package:alist/screen/pdf_reader_screen.dart';
import 'package:alist/screen/video_player_screen.dart';
import 'package:alist/util/alist_plugin.dart';
import 'package:alist/util/constant.dart';
import 'package:alist/util/download/download_manager.dart';
import 'package:alist/util/download/download_task_status.dart';
import 'package:alist/util/file_type.dart';
import 'package:alist/util/file_utils.dart';
import 'package:alist/util/markdown_utils.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/util/proxy.dart';
import 'package:alist/util/string_utils.dart';
import 'package:alist/util/user_controller.dart';
import 'package:alist/util/video_player_util.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:alist/widget/overflow_text.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

typedef OnDownloadManagerMenuClickCallback = Function(
    DownloadManagerMenuId menuId);

class DownloadManagerScreen extends StatelessWidget {
  DownloadManagerScreen({super.key});

  // use key to get the more icon's location and size
  final GlobalKey _moreIconKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    DownloadManagerController controller = Get.put(DownloadManagerController());
    Widget scaffold = AlistScaffold(
      appbarTitle: Text(Intl.downloadManagerScreen_title.tr),
      body:
          SlidableAutoCloseBehavior(child: _buildDownloadListView(controller)),
      appbarActions: [_menuMoreIcon(controller)],
    );
    return DownloadManagerAnchor(
      controller: controller,
      child: scaffold,
      onMenuClickCallback: (menuId) => controller.onMenuClick(menuId),
    );
  }

  Widget _buildDownloadListView(DownloadManagerController controller) {
    return Obx(
      () => controller._downloadList.isEmpty
          ? Center(
              child: Text(Intl.recentsScreen_noRecord.tr),
            )
          : ListView.separated(
              itemBuilder: (context, index) =>
                  Obx(() => _buildDownloadItem(context, controller, index)),
              separatorBuilder: (context, index) => const Divider(),
              itemCount: controller._downloadList.length,
            ),
    );
  }

  IconButton _menuMoreIcon(DownloadManagerController controller) {
    return IconButton(
      key: _moreIconKey,
      onPressed: () {
        var menuController = controller.menuController;
        RenderObject? renderObject =
            _moreIconKey.currentContext?.findRenderObject();
        if (renderObject is RenderBox) {
          var position = renderObject.localToGlobal(Offset.zero);
          var size = renderObject.size;
          var menuWidth = controller.menuWidth;
          menuController.open(
              position: Offset(position.dx + size.width - menuWidth - 10,
                  position.dy + size.height));
        }
      },
      icon: const Icon(Icons.more_horiz_rounded),
    );
  }

  Widget _buildDownloadItem(
      BuildContext context, DownloadManagerController controller, int index) {
    var downloadItem = controller._downloadList[index];
    String? thumbnail = FileUtils.getCompleteThumbnail(downloadItem.thumbnail);
    String icon = FileUtils.getFileIcon(false, downloadItem.name);
    bool canSave =
        downloadItem.downloadStatus.value == DownloadTaskStatus.finished &&
            (Platform.isAndroid ||
                (controller.shareDirectoryPath != null &&
                    !downloadItem.savedPath.value
                        .startsWith(controller.shareDirectoryPath!)));

    GestureLongPressCallback? onLongPress;
    if (FileUtils.getFileType(false, downloadItem.name) == FileType.video) {
      onLongPress = () {
        var video = VideoItem(
          name: downloadItem.name,
          localPath: downloadItem.savedPath.value,
          remotePath: downloadItem.remotePath ?? "",
          sign: downloadItem.sign ?? "",
          size: downloadItem.contentLength ?? 0,
          thumb: downloadItem.thumbnail,
          modifiedMilliseconds: 0,
        );
        VideoPlayerUtil.selectThePlayerToPlay(Get.context!, [video], 0);
      };
    }

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
      subtitle: OverflowText(text: downloadItem.status.value),
      trailing: _buildTrailing(controller, downloadItem),
      onTap: () => controller.onTap(downloadItem),
      onLongPress: onLongPress,
    );
    return Slidable(
      key: Key(downloadItem.id.toString()),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: canSave ? 0.5 : 0.25,
        children: [
          if (canSave)
            SlidableAction(
              onPressed: (context) => controller.saveFileToLocal(downloadItem),
              backgroundColor: Get.theme.colorScheme.secondary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              label: Intl.downloadManagerScreen_menu_save.tr,
            ),
          SlidableAction(
            onPressed: (context) => controller.delete(downloadItem),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            label: Intl.downloadManagerScreen_menu_delete.tr,
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

class DownloadManagerAnchor extends StatelessWidget {
  final DownloadManagerController controller;
  final Widget child;
  final OnDownloadManagerMenuClickCallback? onMenuClickCallback;

  const DownloadManagerAnchor({
    super.key,
    required this.controller,
    required this.child,
    this.onMenuClickCallback,
  });

  @override
  Widget build(BuildContext context) {
    final menuWidth = controller.menuWidth;
    return MenuAnchor(
      style: MenuStyle(
          fixedSize: MaterialStatePropertyAll(Size.fromWidth(menuWidth))),
      controller: controller.menuController,
      anchorTapClosesMenu: true,
      onOpen: () {
        controller.isMenuOpen.value = true;
      },
      onClose: () {
        controller.isMenuOpen.value = false;
      },
      menuChildren: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: _buildMenus(
            menuWidth,
            onMenuClickCallback,
          ),
        ),
      ],
      child: Obx(
        () => AbsorbPointer(
          absorbing: controller.isMenuOpen.value,
          child: child,
        ),
      ),
    );
  }

  List<Widget> _buildMenus(double menuWidth,
      OnDownloadManagerMenuClickCallback? onMenuClickCallback) {
    var buttonStartAll = MenuItemButton(
        onPressed: () =>
            onMenuClickCallback?.call(DownloadManagerMenuId.startAll),
        child: Text(Intl.downloadManagerScreen_menu_startAll.tr));
    var buttonPauseAll = MenuItemButton(
        onPressed: () =>
            onMenuClickCallback?.call(DownloadManagerMenuId.pauseAll),
        child: Text(Intl.downloadManagerScreen_menu_pauseAll.tr));
    var buttonBackgroundDownload = MenuItemButton(
        onPressed: () =>
            onMenuClickCallback?.call(DownloadManagerMenuId.backgroundDownload),
        child:
            Text(Intl.downloadManagerScreen_menu_allowBackgroundDownloads.tr));
    var buttonSetRunningQueueSize = MenuItemButton(
        onPressed: () => onMenuClickCallback
            ?.call(DownloadManagerMenuId.setRunningQueueSize),
        child: Text(Intl.downloadManagerScreen_menu_setRunningQueueSize.tr));
    return [
      SizedBox(
        width: menuWidth,
      ),
      buttonStartAll,
      buttonPauseAll,
      if (Platform.isAndroid) buttonBackgroundDownload,
      buttonSetRunningQueueSize,
    ];
  }
}

class DownloadManagerController extends GetxController {
  final _downloadList = <DownloadItem>[].obs;
  late StreamSubscription _downloadProgressSubscription;
  late StreamSubscription _downloadStatusSubscription;
  final isMenuOpen = false.obs;
  final menuController = MenuController();
  var menuWidth = 160.0;
  String? shareDirectoryPath;

  @override
  void onInit() {
    super.onInit();
    _findDownloadList();
    _downloadProgressSubscription =
        DownloadManager.instance.listenDownloadProgressChange((task) {
      if (task.status != DownloadTaskStatus.downloading) {
        return;
      }
      var item = _downloadList.firstWhereOrNull(
          (element) => element.savedPath.value == task.record.localPath);
      if (item != null) {
        item.downloadStatus.value = task.status;
        item.downloaded = task.downloaded;
        item.contentLength = task.contentLength;

        var status = Intl.downloadManagerScreen_status_downloading.tr;
        status = _resetStatus(status, task.downloaded, task.contentLength);
        item.status.value = status;
      }
    });

    _downloadStatusSubscription =
        DownloadManager.instance.listenDownloadStatusChange((task) {
      var item = _downloadList.firstWhereOrNull(
          (element) => element.savedPath.value == task.record.localPath);
      if (item != null) {
        item.downloadStatus.value = task.status;
        switch (item.downloadStatus.value) {
          case DownloadTaskStatus.finished:
            var status = Intl.downloadManagerScreen_status_finish.tr;
            var contentLength = task.contentLength;
            if (File(task.record.localPath).existsSync()) {
              contentLength = File(task.record.localPath).lengthSync();
            }
            if (contentLength != null && contentLength > 0) {
              status = "$status - ${FileUtils.formatBytes(contentLength ?? 0)}";
            }
            item.status.value = status;
            break;
          case DownloadTaskStatus.failed:
            item.status.value =
                "${Intl.downloadManagerScreen_status_downloadFailed.tr}(${task.failedReason ?? ""})";
            break;
          case DownloadTaskStatus.paused:
            var status = Intl.downloadManagerScreen_status_pause.tr;
            status = _resetStatus(status, task.downloaded, task.contentLength);
            item.status.value = status;
            break;
          case DownloadTaskStatus.waiting:
            var status = Intl.downloadManagerScreen_status_waiting.tr;
            status = _resetStatus(status, task.downloaded, task.contentLength);
            item.status.value = status;
            break;
          case DownloadTaskStatus.downloading:
            var status = Intl.downloadManagerScreen_status_downloading.tr;
            var downloaded = task.downloaded;
            var contentLength = task.contentLength;
            if (contentLength == null && downloaded == 0) {
              downloaded = item.downloaded;
              contentLength = item.contentLength;
            }
            status = _resetStatus(status, downloaded, contentLength);
            item.status.value = status;
            break;
          case DownloadTaskStatus.decompressing:
            item.status.value =
                Intl.downloadManagerScreen_status_decompressing.tr;
            break;
          case DownloadTaskStatus.canceled:
            var status = Intl.downloadManagerScreen_status_canceled.tr;
            status = _resetStatus(status, task.downloaded, task.contentLength);
            item.status.value = status;
            break;
        }
      }
    });

    if (Platform.isIOS || Platform.isMacOS) {
      getApplicationDocumentsDirectory()
          .then((value) => shareDirectoryPath = value.path);
    }

    if (Get.locale.toString().contains("zh")) {
      menuWidth = 160;
    } else {
      menuWidth = 220;
    }
  }

  String _resetStatus(String status, int downloaded, int? contentLength) {
    if (downloaded == 0) {
      return status;
    }
    if (contentLength != null && contentLength > 0) {
      status =
          "$status - ${FileUtils.formatBytes(downloaded)}/${FileUtils.formatBytes(contentLength)}";
    } else {
      status = "$status - ${FileUtils.formatBytes(downloaded)}";
    }
    return status;
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

    List<DownloadItem> downloadList = [];
    for (var file in files) {
      var task = downloadManager.findTaskBySavedPath(file.localPath);
      var tmpFile = File("${file.localPath}.tmp");
      var downloadInfoFile = File("${file.localPath}.downloads");

      int? contentLengthInt;
      int downloadedInt = 0;
      if (tmpFile.existsSync() || downloadInfoFile.existsSync()) {
        contentLengthInt = await _readContentLength(downloadInfoFile);
      }
      if (tmpFile.existsSync()) {
        downloadedInt = tmpFile.lengthSync();
      }

      String? status;
      DownloadTaskStatus? downloadStatus;
      if (task != null) {
        downloadStatus = task.status;
        status = task.status == DownloadTaskStatus.waiting
            ? Intl.downloadManagerScreen_status_waiting.tr
            : Intl.downloadManagerScreen_status_downloading.tr;
      } else {
        if (file.finished == true) {
          downloadStatus = DownloadTaskStatus.finished;
          status = Intl.downloadManagerScreen_status_finish.tr;
        } else {
          downloadStatus = DownloadTaskStatus.paused;
          status = Intl.downloadManagerScreen_status_pause.tr;
        }
      }
      if (downloadStatus != DownloadTaskStatus.finished && downloadedInt > 0) {
        status = _resetStatus(status, downloadedInt, contentLengthInt);
      } else if (downloadStatus == DownloadTaskStatus.finished) {
        if (File(file.localPath).existsSync() &&
            File(file.localPath).existsSync()) {
          status =
              "$status - ${FileUtils.formatBytes(File(file.localPath).lengthSync())}";
        }
      }
      var requestHeaders = <String, dynamic>{};
      if (file.requestHeaders != null && file.requestHeaders!.isNotEmpty) {
        requestHeaders = jsonDecode(file.requestHeaders!);
      }

      LogUtil.d("localPath=${file.localPath}");
      var item = DownloadItem(
        id: file.id ?? 0,
        name: file.name,
        remotePath: file.remotePath,
        savedPath: file.localPath,
        sign: file.sign,
        thumbnail: file.thumbnail,
        contentLength: contentLengthInt,
        downloaded: downloadedInt,
        requestHeaders: requestHeaders,
        limitFrequency: file.limitFrequency ?? 0,
        status: status,
        downloadStatus: downloadStatus,
      );
      downloadList.add(item);
    }
    _downloadList.value = downloadList.toList();
    LogUtil.d("downloadItems=${downloadList.length}");
  }

  Future<int?> _readContentLength(File downloadInfoFile) async {
    try {
      var savedJson = await downloadInfoFile.readAsString();
      var json = await compute(jsonDecode, savedJson);
      var downloadsInfo = DownloadsInfo.fromJson(json);
      return downloadsInfo.contentLength;
    } catch (e) {
      return null;
    }
  }

  void download(DownloadItem downloadItem) {
    DownloadManager.instance.enqueue(
      name: downloadItem.name,
      remotePath: downloadItem.remotePath ?? "",
      sign: downloadItem.sign ?? "",
      thumb: downloadItem.thumbnail,
      requestHeaders: downloadItem.requestHeaders,
      limitFrequency: downloadItem.limitFrequency,
    );
  }

  void pause(DownloadItem downloadItem) {
    DownloadManager.instance.pause(downloadItem.savedPath.value);
  }

  void delete(DownloadItem downloadItem) {
    DownloadManager.instance.cancel(downloadItem.savedPath.value);
    _downloadList.removeWhere((element) => element == downloadItem);
    AlistDatabaseController databaseController = Get.find();
    FileDownloadRecordRecordDao downloadRecordRecordDao =
        databaseController.downloadRecordRecordDao;
    downloadRecordRecordDao.deleteById(downloadItem.id);
    var savedFile = File(downloadItem.savedPath.value);
    if (savedFile.existsSync()) {
      savedFile.delete();
    }
    var tmpFile = File("${downloadItem.savedPath.value}.tmp");
    if (tmpFile.existsSync()) {
      tmpFile.delete();
    }
    var downloadInfoFile = File("${downloadItem.savedPath.value}.downloads");
    if (downloadInfoFile.existsSync()) {
      downloadInfoFile.delete();
    }
  }

  void onTap(DownloadItem downloadItem) {
    if (downloadItem.downloadStatus.value != DownloadTaskStatus.finished) {
      if (downloadItem.downloadStatus.value == DownloadTaskStatus.paused) {
        download(downloadItem);
      } else {
        pause(downloadItem);
      }
      return;
    }
    if (!File(downloadItem.savedPath.value).existsSync()) {
      SmartDialog.showToast(Intl.downloadManagerScreen_tips_fileNotFound.tr);
      return;
    }

    var fileType = FileUtils.getFileType(false, downloadItem.name);
    var files = <DownloadItem>[];
    for (var file in _downloadList) {
      if (file.downloadStatus.value != DownloadTaskStatus.finished) {
        continue;
      }
      var type = FileUtils.getFileType(false, file.name);
      if (type == fileType) {
        files.add(file);
      }
    }
    var index = files.indexOf(downloadItem);

    switch (fileType) {
      case FileType.video:
        var videos = files.map((e) {
          return VideoItem(
            name: e.name,
            localPath: e.savedPath.value,
            remotePath: e.remotePath ?? "",
            sign: e.sign ?? "",
            size: e.contentLength ?? 0,
            thumb: e.thumbnail,
            modifiedMilliseconds: 0,
          );
        }).toList();
        VideoPlayerUtil.go(videos, index);
        break;
      case FileType.audio:
        var audios = files.map((e) {
          return AudioItem(
            name: e.name,
            localPath: e.savedPath.value,
            remotePath: e.remotePath ?? "",
            sign: e.sign ?? "",
          );
        }).toList();
        Get.toNamed(NamedRouter.audioPlayer,
            arguments: {"audios": audios, "index": index});
        break;
      case FileType.image:
        var photos = files.map((e) {
          return PhotoItem(
            name: e.name,
            localPath: e.savedPath.value,
            remotePath: e.remotePath ?? "",
            sign: e.sign ?? "",
          );
        }).toList();
        Get.toNamed(NamedRouter.gallery,
            arguments: {"files": photos, "index": index});
        break;
      case FileType.pdf:
        var pdfItem = PdfItem(
          name: downloadItem.name,
          localPath: downloadItem.savedPath.value,
          remotePath: downloadItem.remotePath ?? "",
          sign: downloadItem.sign,
          thumb: downloadItem.thumbnail,
        );
        Get.toNamed(
          NamedRouter.pdfReader,
          arguments: {"pdfItem": pdfItem},
        );
        break;
      case FileType.markdown:
        _previewMarkdown(downloadItem);
        break;
      default:
        var fileReaderItem = FileReaderItem(
          name: downloadItem.name,
          localPath: downloadItem.savedPath.value,
          remotePath: downloadItem.remotePath ?? "",
          sign: downloadItem.sign,
          thumb: downloadItem.thumbnail,
          fileType: fileType,
        );
        Get.toNamed(
          NamedRouter.fileReader,
          arguments: {"fileReaderItem": fileReaderItem},
        );
        break;
    }
  }

  void _previewMarkdown(DownloadItem item) async {
    ProxyServer proxyServer = Get.find();
    // 开启本地代理服务器
    await proxyServer.start();
    var file = File(item.savedPath.value);
    var fileContent = await file.readAsString();

    var proxyUri =
        proxyServer.makeContentUri(item.remotePath ?? "/", fileContent);

    await Get.toNamed(NamedRouter.web, arguments: {
      "url": MarkdownUtil.makePreviewUrl(proxyUri.toString()),
      "title": item.name
    });
    proxyServer.stop();
  }

  void onMenuClick(DownloadManagerMenuId menuId) {
    switch (menuId) {
      case DownloadManagerMenuId.startAll:
        _tryStartAll();
        break;
      case DownloadManagerMenuId.pauseAll:
        _tryPauseAll();
        break;
      case DownloadManagerMenuId.backgroundDownload:
        _requestPermission();
        break;
      case DownloadManagerMenuId.setRunningQueueSize:
        FixedExtentScrollController scrollController =
            FixedExtentScrollController(
                initialItem: DownloadManager.instance.maxRunningTaskCount - 1);
        showModalBottomSheet(
            context: Get.context!,
            builder: (context) {
              return SetMaxRunningTasksSizeDialog(
                scrollController: scrollController,
                onConfirm: () {
                  var maxRunningTaskCount = scrollController.selectedItem + 1;
                  DownloadManager.instance
                      .setMaxRunningTaskCount(maxRunningTaskCount);
                  SpUtil.putInt(
                      AlistConstant.maxRunningTaskCount, maxRunningTaskCount);
                },
              );
            });
        break;
    }
  }

  void _tryStartAll() {
    var list = _downloadList.toList()
      ..sort((a, b) {
        return a.id.compareTo(b.id);
      });
    for (var item in list) {
      if (item.downloadStatus.value == DownloadTaskStatus.waiting ||
          item.downloadStatus.value == DownloadTaskStatus.downloading ||
          item.downloadStatus.value == DownloadTaskStatus.decompressing ||
          item.downloadStatus.value == DownloadTaskStatus.finished) {
        continue;
      }
      DownloadManager.instance.enqueue(
        name: item.name,
        remotePath: item.remotePath ?? "",
        sign: item.sign ?? "",
        thumb: item.thumbnail,
        requestHeaders: item.requestHeaders,
        limitFrequency: item.limitFrequency,
      );
    }
  }

  void _tryPauseAll() {
    var list = _downloadList.toList();
    for (var item in list) {
      if (item.downloadStatus.value == DownloadTaskStatus.waiting ||
          item.downloadStatus.value == DownloadTaskStatus.downloading ||
          item.downloadStatus.value == DownloadTaskStatus.decompressing) {
        DownloadManager.instance.pause(item.savedPath.value);
      }
    }
  }

  void _requestPermission() async {
    var isNotificationGranted = await Permission.notification.isGranted;
    if (!isNotificationGranted) {
      var status = await Permission.notification.request();
      if (status.isGranted) {
        isNotificationGranted = true;
      } else {
        SmartDialog.showToast(
            Intl.downloadManagerScreen_tips_allowNotification.tr);
      }
    }

    if (isNotificationGranted &&
        Platform.isAndroid &&
        DownloadManager.instance.runningTaskSize > 0) {
      AlistPlugin.onDownloadingStart();
    }

    var isIgnoreBatteryOptimizations =
        await Permission.ignoreBatteryOptimizations.isGranted;
    AlistPlugin.onDownloadingStart();
    if (!isIgnoreBatteryOptimizations) {
      var status = await Permission.ignoreBatteryOptimizations.request();
      if (status.isGranted) {
        isIgnoreBatteryOptimizations = true;
      } else {
        SmartDialog.showToast(
            Intl.downloadManagerScreen_tips_ignoreBatteryOptimizations.tr);
      }
    }

    if (isNotificationGranted && isIgnoreBatteryOptimizations) {
      SmartDialog.showToast(
          Intl.downloadManagerScreen_tips_backgroundDownloadSupported.tr);
    }
  }

  void saveFileToLocal(DownloadItem downloadItem) async {
    if (downloadItem.downloadStatus.value != DownloadTaskStatus.finished) {
      return;
    }

    SmartDialog.showLoading();
    try {
      if (Platform.isAndroid) {
        if (await AlistPlugin.isScopedStorage()) {
          await AlistPlugin.saveFileToLocal(
              downloadItem.name, downloadItem.savedPath.value);
          SmartDialog.showToast(Intl.downloadManagerScreen_tips_saved.tr);
          _showTipsWhenFirstSaved();
        } else {
          PermissionStatus permissionStatus =
              await Permission.storage.request();
          if (permissionStatus.isGranted) {
            String downloadDir = await AlistPlugin.getExternalDownloadDir();
            var savedPath = path.join(downloadDir,
                downloadItem.name.replaceAll(" ", "-").replaceAll("/", "_"));
            savedPath = _savedPathRename(savedPath);
            File file = File(downloadItem.savedPath.value);
            file.parent.create(recursive: true);
            file.copy(savedPath);
            SmartDialog.showToast(Intl.downloadManagerScreen_tips_saved.tr);
            _showTipsWhenFirstSaved();
          } else {
            SmartDialog.showToast(
                Intl.galleryScreen_storagePermissionDenied.tr);
          }
        }
      } else if (Platform.isIOS || Platform.isMacOS) {
        final directory = await getApplicationDocumentsDirectory();
        var savedPath = path.join(directory.path,
            downloadItem.name.replaceAll(" ", "-").replaceAll("/", "_"));
        if (downloadItem.savedPath.value != savedPath) {
          savedPath = _savedPathRename(savedPath);

          await File(downloadItem.savedPath.value).rename(savedPath);
          downloadItem.savedPath.value = savedPath;

          AlistDatabaseController databaseController = Get.find();
          FileDownloadRecordRecordDao downloadRecordRecordDao =
              databaseController.downloadRecordRecordDao;

          await downloadRecordRecordDao.updateLocalPath(
              downloadItem.id, savedPath);
        }
        SmartDialog.showToast(Intl.downloadManagerScreen_tips_saved.tr);
        _showTipsWhenFirstSaved();
      }
    } finally {
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  String _savedPathRename(String savedPath) {
    int nameIndex = 0;
    while (File(savedPath).existsSync()) {
      final pre = savedPath.substringBeforeLast("/");
      var name = savedPath.substringAfterLast("/")!;
      final extIndex = name.indexOf(".");
      late final String ext;
      late final String nameWithoutExt;
      if (extIndex > -1) {
        ext = name.substringAfterLast(".")!;
        nameWithoutExt = name.substringBeforeLast(".")!;
      } else {
        ext = "";
        nameWithoutExt = name;
      }
      nameIndex++;
      if (ext != "") {
        savedPath = "$pre/$nameWithoutExt($nameIndex).$ext";
      } else {
        savedPath = "$pre/$nameWithoutExt($nameIndex)";
      }
    }
    return savedPath;
  }

  _showTipsWhenFirstSaved() {
    var isFirstTimeSaveToLocal = SpUtil.getBool(
      AlistConstant.isFirstTimeSaveToLocal,
      defValue: true,
    );
    if (isFirstTimeSaveToLocal == true) {
      SmartDialog.show(
          clickMaskDismiss: false,
          builder: (context) {
            return AlertDialog(
              title: Text(Intl.davTipsDialog_title.tr),
              content: Text(Platform.isAndroid
                  ? Intl.downloadManagerScreen_tips_saved_first_android.tr
                  : Intl.downloadManagerScreen_tips_saved_first_ios.tr),
              actions: [
                TextButton(
                  onPressed: () {
                    SpUtil.putBool(AlistConstant.isFirstTimeSaveToLocal, false);
                    SmartDialog.dismiss();
                  },
                  child: Text(Intl.downloadManager_downloadTipDialog_iKnow.tr),
                ),
              ],
            );
          });
    }
  }
}

class SetMaxRunningTasksSizeDialog extends StatelessWidget {
  const SetMaxRunningTasksSizeDialog({
    super.key,
    required this.scrollController,
    required this.onConfirm,
  });

  final FixedExtentScrollController scrollController;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Get.size.height / 3,
      child: Column(
        children: [
          const SizedBox(
            height: 5,
          ),
          Row(
            children: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child:
                        Text(Intl.setMaxRunningTasksSizeDialog_btn_cancel.tr),
                  )),
              Expanded(
                  child: Center(
                child: Text(
                  Intl.setMaxRunningTasksSizeDialog_title.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              )),
              TextButton(
                  onPressed: () {
                    onConfirm();
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child:
                        Text(Intl.setMaxRunningTasksSizeDialog_btn_confirm.tr),
                  )),
            ],
          ),
          Expanded(
            child: CupertinoPicker.builder(
              itemExtent: 50,
              useMagnifier: true,
              childCount: 20,
              scrollController: scrollController,
              onSelectedItemChanged: (index) {},
              itemBuilder: (context, index) {
                return SizedBox(
                  height: 50,
                  child: Center(
                    child: Text("${index + 1}"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DownloadItem {
  final int id;
  final String name;
  final String? remotePath;
  final String? sign;
  final RxString status;
  final Rx<DownloadTaskStatus> downloadStatus;
  final Map<String, dynamic> requestHeaders;
  final int limitFrequency;
  RxString savedPath;
  String? thumbnail;
  int downloaded;
  int? contentLength;

  DownloadItem({
    required this.id,
    required this.name,
    required this.remotePath,
    required String savedPath,
    required this.sign,
    required String status,
    required DownloadTaskStatus downloadStatus,
    required this.requestHeaders,
    required this.limitFrequency,
    this.thumbnail,
    this.downloaded = 0,
    this.contentLength,
  })  : status = status.obs,
        savedPath = savedPath.obs,
        downloadStatus = downloadStatus.obs;
}

enum DownloadManagerMenuId {
  startAll,
  pauseAll,
  backgroundDownload,
  setRunningQueueSize
}
