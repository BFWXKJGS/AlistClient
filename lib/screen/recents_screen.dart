import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/database/table/file_viewing_record.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/util/file_type.dart';
import 'package:alist/util/file_utils.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/util/user_controller.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:alist/widget/file_details_dialog.dart';
import 'package:alist/widget/file_list_item_view.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';

class RecentsScreen extends StatefulWidget {
  const RecentsScreen({Key? key}) : super(key: key);

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen>
    with AutomaticKeepAliveClientMixin {
  final UserController _userController = Get.find();
  final AlistDatabaseController _databaseController = Get.find();
  final _loading = true.obs;
  final _list = <FileViewingRecord>[].obs;

  @override
  void initState() {
    super.initState();
    _queryRecents();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() => AlistScaffold(
          appbarTitle: Text(Intl.screenName_recents.tr),
          body: !_loading.value && _list.isEmpty
              ? Center(
                  child: Text(Intl.recentsScreen_noRecord.tr),
                )
              : _fileListView(),
        ));
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
    _databaseController.fileViewingRecordDao
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
        Get.toNamed(
          NamedRouter.videoPlayer,
          arguments: {"path": file.path},
        );
        break;
      case FileType.audio:
        Get.toNamed(
          NamedRouter.audioPlayer,
          arguments: {"path": file.path},
        );
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
}
