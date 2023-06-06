import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/database/table/file_password.dart';
import 'package:alist/database/table/file_viewing_record.dart';
import 'package:alist/entity/file_list_resp_entity.dart';
import 'package:alist/generated/images.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/router.dart';
import 'package:alist/screen/file_list/director_password_dialog.dart';
import 'package:alist/screen/file_list/file_list_menu_anchor.dart';
import 'package:alist/util/file_type.dart';
import 'package:alist/util/file_utils.dart';
import 'package:alist/util/log_utils.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/util/user_controller.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:alist/widget/file_list_item_view.dart';
import 'package:dio/dio.dart';
import 'package:extended_text/extended_text.dart';
import 'package:floor/floor.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

typedef FileItemClickCallback = Function(
  BuildContext context,
  List<FileItemVO> files,
  FileItemVO file,
);

class FileListScreen extends StatefulWidget {
  const FileListScreen({
    super.key,
    this.path,
    this.sortBy,
    this.sortByUp,
    this.isRootStack = false,
  });

  final String? path;
  final MenuId? sortBy;
  final bool? sortByUp;
  final bool isRootStack;

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen>
    with AutomaticKeepAliveClientMixin {
  final UserController _userController = Get.find();
  final AlistDatabaseController _databaseController = Get.find();
  final FileListMenuAnchorController _menuAnchorController =
      FileListMenuAnchorController();

  static const String tag = "_FileListScreenState";
  FileListRespEntity? _data;
  List<FileItemVO> _files = [];
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // use key to get the more icon's location and size
  final GlobalKey _moreIconKey = GlobalKey();
  final CancelToken _cancelToken = CancelToken();
  String? _pageName;
  String? _password;
  bool _passwordRetrying = false;
  String path = "";
  bool _forceRefresh = false;
  int? stackId;

  @override
  void initState() {
    super.initState();
    var path = widget.path;
    if (path == null || path.isEmpty) {
      path = "/";
    }
    this.path = path;
    stackId = !widget.isRootStack ? AlistRouter.fileListRouterStackId : null;
    LogUtil.d("sortBy=${widget.sortBy}");
    _menuAnchorController.updateSortBy(widget.sortBy, widget.sortByUp);

    if (_isRootPath(path)) {
      _pageName == null;
    } else {
      _pageName = path.substring(path.lastIndexOf('/') + 1);
    }
    Log.d("path=$path pageName=$_pageName}", tag: tag);

    var user = _userController.user.value;
    _loadFilesPrepare(user, path);
    Log.d("initState", tag: tag);
  }

  Future<void> _loadFilesPrepare(User user, String path) async {
    // query file's password from database.
    var filePassword = await _databaseController.filePasswordDao
        .findPasswordByPath(user.serverUrl, user.username, path);
    if (filePassword != null) {
      _password = filePassword.password;
    }
    if (mounted) {
      _loadFilesWhileWidgetReady();
    }
  }

  bool _isRootPath(String? path) => path == '/' || path == null || path == '';

  // load files when ui ready
  _loadFilesWhileWidgetReady() async {
    do {
      final currentState = _refreshIndicatorKey.currentState;
      if (currentState != null) {
        Log.d("start load file", tag: tag);
        currentState.show();
        break;
      }
      Log.d("ignore load file", tag: tag);
      await Future.delayed(const Duration(milliseconds: 17));
      if (!mounted) {
        break;
      }
    } while (true);
  }

  Future<void> _loadFiles() async {
    var body = {
      "path": path,
      "password": _password ?? "",
      "page": 1,
      "per_page": 0,
      "refresh": _forceRefresh
    };

    return DioUtils.instance.requestNetwork<FileListRespEntity>(
        Method.post, "fs/list", cancelToken: _cancelToken, params: body,
        onSuccess: (data) {
      _forceRefresh = false;
      _menuAnchorController.hasWritePermission.value = data?.write == true;
      setState(
        () {
          _data = data;
          _files = data?.content?.map((e) => _fileResp2VO(e)).toList() ?? [];
          _sort(_files);
        },
      );
    }, onError: (code, msg) {
      _forceRefresh = false;
      if (code == 403) {
        _showDirectorPasswordDialog();
        if (_passwordRetrying) {
          SmartDialog.showToast(msg);
        }
      } else {
        SmartDialog.showToast(msg);
      }
      debugPrint(msg);
    });
  }

  Future<dynamic> _showDirectorPasswordDialog() {
    return SmartDialog.show(
        clickMaskDismiss: false,
        backDismiss: false,
        builder: (context) {
          return DirectorPasswordDialog(
            directorPasswordCallback: (password, remember) {
              _password = password;
              _passwordRetrying = true;
              _refreshIndicatorKey.currentState?.show();

              if (remember) {
                rememberPassword(password);
              } else {
                deleteOriginalPassword();
              }
            },
          );
        });
  }

  @override
  void dispose() {
    super.dispose();
    _cancelToken.cancel();
    Log.d("dispose", tag: tag);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FileListMenuAnchor(
      controller: _menuAnchorController,
      child: _buildScaffold(context),
      onMenuClickCallback: (menu) {
        switch (menu.menuGroupId) {
          case MenuGroupId.operations:
            if (menu.menuId == MenuId.forceRefresh) {
              _forceRefresh = true;
              _refreshIndicatorKey.currentState?.show();
            }
            break;
          case MenuGroupId.sort:
            _menuAnchorController.sortBy.value = menu.menuId;
            _menuAnchorController.sortByUp.value = menu.isUp ?? false;
            setState(() {
              _sort(_files);
            });
            break;
        }
      },
    );
  }

  AlistScaffold _buildScaffold(BuildContext context) {
    return AlistScaffold(
      appbarTitle: ExtendedText(
        _pageName ?? Intl.screenName_fileListRoot.tr,
        maxLines: 1,
        overflowWidget: const TextOverflowWidget(
          position: TextOverflowPosition.middle,
          child: Text("..."),
        ),
      ),
      appbarActions: [_menuMoreIcon()],
      onLeadingDoubleTap: () =>
          Get.until((route) => route.isFirst, id: stackId),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () => _loadFiles(),
        child: _FileListView(
          path: path,
          readme: _data?.readme,
          files: _files,
          onFileItemClick: _onFileTap,
        ),
      ),
    );
  }

  IconButton _menuMoreIcon() {
    return IconButton(
      key: _moreIconKey,
      onPressed: () {
        var menuController = _menuAnchorController.menuController;
        RenderObject? renderObject =
            _moreIconKey.currentContext?.findRenderObject();
        if (renderObject is RenderBox) {
          var position = renderObject.localToGlobal(Offset.zero);
          var size = renderObject.size;
          menuController.open(
              position: Offset(position.dx + size.width - 150 - 10,
                  position.dy + size.height));
        }
      },
      icon: const Icon(Icons.more_horiz_rounded),
    );
  }

  void _onFileTap(
    BuildContext context,
    List<FileItemVO> files,
    FileItemVO file,
  ) {
    FileType fileType = file.type;
    if (!file.isDir) {
      _fileViewingRecord(file);
    }

    switch (fileType) {
      case FileType.folder:
        Get.toNamed(
          NamedRouter.fileList,
          arguments: {
            "path": file.path,
            "sortBy": _menuAnchorController.sortBy.value,
            "sortByUp": _menuAnchorController.sortByUp.value
          },
          preventDuplicates: false,
          id: stackId,
        );
        break;
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
        List<String> paths = [];
        final currentPath = file.path;
        for (var element in files) {
          if (element.type == FileType.image) {
            paths.add(element.path);
          }
        }
        final index = paths.indexOf(currentPath);

        Get.toNamed(
          NamedRouter.gallery,
          arguments: {"paths": paths, "index": index},
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

  @transaction
  Future<void> _fileViewingRecord(FileItemVO file) async {
    var user = _userController.user.value;
    var recordData = _databaseController.fileViewingRecordDao;
    await recordData.deleteByPath(user.serverUrl, user.username, file.path);
    await recordData.insertRecord(FileViewingRecord(
      serverUrl: user.serverUrl,
      userId: user.username,
      remotePath: file.path,
      name: file.name,
      path: file.path,
      size: file.size ?? 0,
      sign: file.sign,
      thumb: file.thumb,
      modified: file.modifiedMilliseconds,
      provider: "",
      createTime: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  @override
  bool get wantKeepAlive => _isRootPath(path);

  @transaction
  Future<void> rememberPassword(String password) async {
    await deleteOriginalPassword();

    var user = _userController.user.value;
    var filePassword = FilePassword(
      serverUrl: user.serverUrl,
      userId: user.username,
      remotePath: path,
      password: password,
      createTime: DateTime.now().millisecond,
    );
    await _databaseController.filePasswordDao.insertFilePassword(filePassword);
  }

  Future<void> deleteOriginalPassword() async {
    var user = _userController.user.value;
    return _databaseController.filePasswordDao
        .deleteByPath(user.serverUrl, user.username, path);
  }

  void _sort(List<FileItemVO> files) {
    if (files.isEmpty) {
      return;
    }
    files.sort((a, b) {
      if (a.isDir && !b.isDir) {
        return -1;
      } else if (b.isDir && !a.isDir) {
        return 1;
      } else {
        var result = 0;
        switch (_menuAnchorController.sortBy.value) {
          case MenuId.fileName:
            result = a.name.compareTo(b.name);
            break;
          case MenuId.fileType:
            result = a.typeInt.compareTo(b.typeInt);
            break;
          case MenuId.modifyTime:
            if (a.modifiedMilliseconds <= 0 && b.modifiedMilliseconds > 0) {
              return 1;
            } else if (b.modifiedMilliseconds <= 0 &&
                a.modifiedMilliseconds > 0) {
              return -1;
            } else {
              result = a.modifiedMilliseconds.compareTo(b.modifiedMilliseconds);
            }
            break;
          default:
            break;
        }
        return _menuAnchorController.sortByUp.value ? result : -result;
      }
    });
  }

  FileItemVO _fileResp2VO(FileListRespContent resp) {
    DateTime? modifyTime = resp.parseModifiedTime(resp);
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
    );
  }
}

class _FileListView extends StatelessWidget {
  const _FileListView({
    Key? key,
    required this.files,
    required this.path,
    required this.readme,
    required this.onFileItemClick,
  }) : super(key: key);
  final String? path;
  final String? readme;
  final List<FileItemVO> files;
  final FileItemClickCallback onFileItemClick;

  @override
  Widget build(BuildContext context) {
    var itemCount = files.length;
    if (readme != null && readme!.isNotEmpty) {
      itemCount++;
    }

    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (context, index) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18), child: Divider()),
      itemBuilder: (context, index) {
        if (index == files.length) {
          // it's readme
          return FileListItemView(
            icon: Images.fileTypeMd,
            fileName: "README.md",
            time: null,
            sizeDesc: null,
            onTap: () {
              if (GetUtils.isURL(readme!)) {
                Get.toNamed(
                  NamedRouter.markdownReader,
                  arguments: {"markdownUrl": readme!, "title": "README.md"},
                );
              } else {
                Get.toNamed(
                  NamedRouter.markdownReader,
                  arguments: {"markdownContent": readme!, "title": "README.md"},
                );
              }
            },
          );
        } else {
          // it's file
          final file = files[index];
          return FileListItemView(
            icon: file.icon,
            fileName: file.name,
            thumbnail: file.thumb,
            time: file.modified,
            sizeDesc: file.sizeDesc,
            onTap: () => onFileItemClick(context, files, file),
          );
        }
      },
    );
  }
}

class FileListWrapper extends StatelessWidget {
  FileListWrapper({Key? key}) : super(key: key);
  final String? path = Get.arguments?["path"];

  @override
  Widget build(BuildContext context) {
    return FileListScreen(path: path, isRootStack: true);
  }
}
