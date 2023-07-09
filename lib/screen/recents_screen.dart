import 'dart:async';

import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/database/table/file_viewing_record.dart';
import 'package:alist/entity/file_list_resp_entity.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/util/file_type.dart';
import 'package:alist/util/file_utils.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/util/string_utils.dart';
import 'package:alist/util/user_controller.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:alist/widget/file_details_dialog.dart';
import 'package:alist/widget/file_list_item_view.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class RecentsScreen extends StatefulWidget {
  const RecentsScreen({Key? key}) : super(key: key);

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen>
    with AutomaticKeepAliveClientMixin {
  final UserController _userController = Get.find();
  final CancelToken _cancelToken = CancelToken();
  final AlistDatabaseController _databaseController = Get.find();
  final _loading = true.obs;
  final _list = <FileViewingRecord>[].obs;
  StreamSubscription? _recordListSubscription;
  StreamSubscription? _userStreamSubscription;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _userController.user.value;
    _userStreamSubscription = _userController.user.stream.listen((event) {
      if (_currentUser?.serverUrl != event.serverUrl ||
          _currentUser?.username != event.username) {
        _currentUser = event;
        _recordListSubscription?.cancel();
        _queryRecents();
      }
    });
    _queryRecents();
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    _userStreamSubscription?.cancel();
    _recordListSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AlistScaffold(
      appbarTitle: Text(Intl.screenName_recents.tr),
      body: Obx(
        () => !_loading.value && _list.isEmpty
            ? Center(
                child: Text(Intl.recentsScreen_noRecord.tr),
              )
            : _fileListView(),
      ),
    );
  }

  Widget _fileListView() {
    return SlidableAutoCloseBehavior(
      child: ListView.separated(
        itemBuilder: (context, item) {
          var record = _list[item];
          return _fileListItemView(context, record);
        },
        separatorBuilder: (context, item) => const Divider(),
        itemCount: _list.length,
      ),
    );
  }

  Widget _fileListItemView(BuildContext context, FileViewingRecord record) {
    var createTime = DateTime.fromMillisecondsSinceEpoch(record.createTime);
    return Slidable(
      key: Key(record.path),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _showDetailsDialog(context, record),
            backgroundColor: Get.theme.colorScheme.secondary,
            foregroundColor: Colors.white,
            label: Intl.recentsScreen_menu_details.tr,
          ),
          SlidableAction(
            onPressed: (context) => _deleteRecord(record),
            backgroundColor: const Color(0xFFFE4A49),
            foregroundColor: Colors.white,
            label: Intl.recentsScreen_menu_delete.tr,
          ),
        ],
      ),
      child: FileListItemView(
        icon: FileUtils.getFileIcon(false, record.name),
        fileName: record.name,
        thumbnail: record.thumb,
        time: FileUtils.getReformatTime(createTime, ""),
        sizeDesc: FileUtils.formatBytes(record.size),
        onTap: () => _onFileTap(context, record),
        onMoreIconButtonTap: () => _showBottomMenuDialog(context, record),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  void _queryRecents() {
    var user = _userController.user.value;
    _recordListSubscription = _databaseController.fileViewingRecordDao
        .recordList(user.serverUrl, user.username)
        .listen((list) {
      _list.value = list ?? [];
      _loading.value = false;
    });
  }

  void _onFileTap(BuildContext context, FileViewingRecord file) {
    FileType fileType = FileUtils.getFileType(false, file.name);

    switch (fileType) {
      case FileType.video:
        _gotoVideoPlayer(file);
        break;
      case FileType.audio:
        _gotoAudioPlayer(file);
        break;
      case FileType.image:
        List<String> paths = [file.path];
        Get.toNamed(
          NamedRouter.gallery,
          arguments: {"paths": paths, "index": 0},
        );
        break;
      case FileType.pdf:
        Get.toNamed(
          NamedRouter.pdfReader,
          arguments: {"path": file.path, "title": file.name},
        );
        break;
      case FileType.markdown:
        Get.toNamed(
          NamedRouter.markdownReader,
          arguments: {"markdownPath": file.path, "title": file.name},
        );
        break;
      case FileType.txt:
      case FileType.word:
      case FileType.excel:
      case FileType.ppt:
      case FileType.code:
      case FileType.apk:
      case FileType.compress:
        Get.toNamed(
          NamedRouter.fileReader,
          arguments: {"path": file.path, "fileType": fileType},
        );
        break;
      default:
        Get.toNamed(
          NamedRouter.fileReader,
          arguments: {"path": file.path, "fileType": fileType},
        );
        break;
    }
  }

  void _deleteRecord(FileViewingRecord record) {
    _databaseController.fileViewingRecordDao.deleteRecord(record);
  }

  _showDetailsDialog(BuildContext context, FileViewingRecord record) {
    var modified = DateTime.fromMillisecondsSinceEpoch(record.modified);
    showModalBottomSheet(
      context: context,
      builder: (context) => FileDetailsDialog(
        name: record.name,
        size: FileUtils.formatBytes(record.size),
        path: record.path,
        modified: FileUtils.getReformatTime(modified, ""),
        thumb: record.thumb,
        provider: record.provider,
      ),
    );
  }

  _showBottomMenuDialog(BuildContext context, FileViewingRecord record) {
    var modified = DateTime.fromMillisecondsSinceEpoch(record.modified);
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: SafeArea(
              child: Wrap(
                children: [
                  FileListItemView(
                    icon: FileUtils.getFileIcon(false, record.name),
                    fileName: record.name,
                    thumbnail: record.thumb,
                    time: FileUtils.getReformatTime(modified, ""),
                    sizeDesc: FileUtils.formatBytes(record.size),
                    onTap: () {
                      Navigator.pop(context);
                      _onFileTap(context, record);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.open_in_new),
                    title: Text(Intl.recentsScreen_menu_open.tr),
                    onTap: () {
                      Navigator.pop(context);
                      _onFileTap(context, record);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder_rounded),
                    title: Text(Intl.recentsScreen_menu_showInFolder.tr),
                    onTap: () {
                      Navigator.pop(context);
                      _openFileDirectory(record);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.link_rounded),
                    title: Text(Intl.fileList_menu_copyLink.tr),
                    onTap: () {
                      Navigator.pop(context);
                      FileUtils.copyFileLink(record.path, record.sign);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: Text(Intl.recentsScreen_menu_delete.tr),
                    onTap: () {
                      Navigator.pop(context);
                      _deleteRecord(record);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: Text(Intl.recentsScreen_menu_details.tr),
                    onTap: () {
                      Navigator.pop(context);
                      _showDetailsDialog(context, record);
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  void _openFileDirectory(FileViewingRecord record) {
    var path = record.path;
    var index = path.lastIndexOf("/");
    if (index >= 0) {
      path = path.substring(0, index);
    }
    LogUtil.d("path=$path index=$index");
    Get.toNamed(
      NamedRouter.fileList,
      arguments: {"path": path},
    );
  }

  Future<List<FileItemVO>?> _loadFilesPrepare(
    String folderPath,
    String filePath,
    FileType fileType,
  ) async {
    final userController = Get.find<UserController>();
    final databaseController = Get.find<AlistDatabaseController>();
    final user = userController.user.value;

    // query file's password from database.
    var filePassword = await databaseController.filePasswordDao
        .findPasswordByPath(user.serverUrl, user.username, folderPath);
    String? password;
    if (filePassword != null) {
      password = filePassword.password;
    }
    return await _loadFiles(folderPath, filePath, password, fileType);
  }

  Future<List<FileItemVO>?> _loadFiles(
    String folderPath,
    String filePath,
    String? password,
    FileType fileType,
  ) async {
    var body = {
      "path": folderPath,
      "password": password ?? "",
      "page": 1,
      "per_page": 0,
      "refresh": false
    };

    List<FileItemVO>? result;
    await DioUtils.instance.requestNetwork<FileListRespEntity>(
        Method.post, "fs/list", cancelToken: _cancelToken, params: body,
        onSuccess: (data) {
      var files = data?.content
          ?.map((e) => _fileResp2VO(folderPath, data.provider, e))
          .where((element) => element.type == fileType)
          .toList();
      files?.sort((a, b) => a.name.compareTo(b.name));
      result = files;
    }, onError: (code, msg) {
      SmartDialog.showToast(msg);
      debugPrint(msg);
    });
    return result;
  }

  FileItemVO _fileResp2VO(
      String path, String provider, FileListRespContent resp) {
    DateTime? modifyTime = resp.parseModifiedTime();
    String? modifyTimeStr = resp.getReformatModified(modifyTime);

    return FileItemVO(
      name: resp.name,
      path: resp.getCompletePath(path),
      size: resp.isDir ? null : resp.size,
      sizeDesc: resp.formatBytes(),
      isDir: resp.isDir,
      modified: modifyTimeStr,
      typeInt: resp.type,
      type: resp.getFileType(),
      thumb: resp.thumb,
      sign: resp.sign,
      icon: resp.getFileIcon(),
      modifiedMilliseconds: modifyTime?.millisecondsSinceEpoch ?? -1,
      provider: provider,
    );
  }

  void _gotoVideoPlayer(FileViewingRecord file) async {
    SmartDialog.showLoading();
    var files = await _loadFilesPrepare(
        file.path.substringBeforeLast("/")!, file.path, FileType.video);
    SmartDialog.dismiss();
    if (files == null) {
      return;
    }

    var index = files.lastIndexWhere((element) => element.path == file.path);
    if (index == -1) {
      index = 0;
    }
    Get.toNamed(
      NamedRouter.videoPlayer,
      arguments: {
        "videos": files,
        "index": index,
      },
    );
  }

  void _gotoAudioPlayer(FileViewingRecord file) async {
    SmartDialog.showLoading();
    var files = await _loadFilesPrepare(
        file.path.substringBeforeLast("/")!, file.path, FileType.audio);
    SmartDialog.dismiss();
    if (files == null) {
      return;
    }

    var index = files.lastIndexWhere((element) => element.path == file.path);
    if (index == -1) {
      index = 0;
    }
    Get.toNamed(
      NamedRouter.audioPlayer,
      arguments: {
        "audios": files,
        "index": index,
      },
    );
  }
}
