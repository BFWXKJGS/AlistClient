import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/database/table/file_password.dart';
import 'package:alist/database/table/file_viewing_record.dart';
import 'package:alist/entity/file_list_resp_entity.dart';
import 'package:alist/entity/file_remove_req.dart';
import 'package:alist/entity/file_rename_req.dart';
import 'package:alist/generated/images.dart';
import 'package:alist/generated/mkdir_req.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/router.dart';
import 'package:alist/screen/file_list/director_password_dialog.dart';
import 'package:alist/screen/file_list/file_copy_move_dialog.dart';
import 'package:alist/screen/file_list/file_list_menu_anchor.dart';
import 'package:alist/screen/file_list/file_rename_dialog.dart';
import 'package:alist/screen/file_list/mkdir_dialog.dart';
import 'package:alist/util/file_type.dart';
import 'package:alist/util/file_utils.dart';
import 'package:alist/util/focus_node_utils.dart';
import 'package:alist/util/log_utils.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/util/string_utils.dart';
import 'package:alist/util/user_controller.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:alist/widget/file_details_dialog.dart';
import 'package:alist/widget/file_list_item_view.dart';
import 'package:dio/dio.dart' as dio;
import 'package:floor/floor.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

typedef FileItemClickCallback = Function(BuildContext context, int index);

typedef FileDeleteCallback = Function(BuildContext context, int index);

typedef FileMoreIconClickCallback = Function(BuildContext context, int index);

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
  final dio.CancelToken _cancelToken = dio.CancelToken();
  String? _pageName;
  String? _password;
  bool _passwordRetrying = false;
  String path = "";
  bool _forceRefresh = false;
  int? stackId;
  bool _hasWritePermission = false;

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
      _passwordRetrying = false;
      _forceRefresh = false;
      _menuAnchorController.hasWritePermission.value = data?.write == true;
      _hasWritePermission = data?.write == true;
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
    FocusNode focusNode = FocusNode().autoFocus();
    return SmartDialog.show(
        clickMaskDismiss: false,
        backDismiss: false,
        builder: (context) {
          return DirectorPasswordDialog(
            focusNode: focusNode,
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
            } else if (menu.menuId == MenuId.newFolder) {
              _showNewFolderDialog();
            } else if (menu.menuId == MenuId.uploadFiles) {
              _uploadFiles();
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

  Future<void> _uploadFiles() async {
    ImagePicker picker = ImagePicker();
    SmartDialog.showLoading(msg: Intl.fileList_tip_processing.tr);
    List<XFile> medias = await picker
        .pickMultipleMedia(requestFullMetadata: false)
        .catchError((e) {
      if (e is PlatformException) {
        if (e.code == "photo_access_denied") {
          SmartDialog.showToast(Intl.fileList_tips_permissionGalleyDenied.tr);
        }
      }
      LogUtil.e(e);
      return <XFile>[];
    });
    SmartDialog.dismiss();
    var filePaths = medias.map((e) => e.path).toList();
    if (filePaths.isNotEmpty) {
      var originalFileNames = _files.map((e) => e.name).toSet();
      await Get.toNamed(
        NamedRouter.uploadingFiles,
        arguments: {
          "filePaths": filePaths,
          "remotePath": path,
          "originalFileNames": originalFileNames,
        },
      );
      _refreshIndicatorKey.currentState?.show();
    }
  }

  AlistScaffold _buildScaffold(BuildContext context) {
    return AlistScaffold(
      appbarTitle: Text(_pageName ?? Intl.screenName_fileListRoot.tr),
      appbarActions: [_menuMoreIcon()],
      onLeadingDoubleTap: () =>
          Get.until((route) => route.isFirst, id: stackId),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () => _loadFiles(),
        child: SlidableAutoCloseBehavior(
          child: _FileListView(
            path: path,
            readme: _data?.readme,
            files: _files,
            hasWritePermission: _hasWritePermission,
            onFileItemClick: _onFileTap,
            onFileMoreIconButtonTap: _onFileMoreIconButtonTap,
            fileDeleteCallback: (context, index) {
              _tryDeleteFile(_files[index]);
            },
          ),
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
              position: Offset(position.dx + size.width - 180 - 10,
                  position.dy + size.height));
        }
      },
      icon: const Icon(Icons.more_horiz_rounded),
    );
  }

  void _onFileTap(BuildContext context, int index) {
    var file = _files[index];
    var files = _files;
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
        _goAudioPlayerScreen(file, files);
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

  void _goAudioPlayerScreen(FileItemVO file, List<FileItemVO> files) async {
    var audios =
        files.where((element) => element.type == FileType.audio).toList();
    final index = audios.indexOf(file);

    Get.toNamed(
      NamedRouter.audioPlayer,
      arguments: {"audios": audios, "index": index},
    );
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
        provider: _data?.provider);
  }

  _showBottomMenuDialog(
      BuildContext widgetContext, FileItemVO file, int index) {
    showModalBottomSheet(
        context: Get.context!,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: SafeArea(
              child: Wrap(
                children: [
                  FileListItemView(
                    icon: FileUtils.getFileIcon(file.isDir, file.name),
                    fileName: file.name,
                    thumbnail: file.thumb,
                    time: file.modified,
                    sizeDesc: file.sizeDesc,
                    onTap: () {
                      Navigator.pop(context);
                      _onFileTap(context, index);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.open_in_new),
                    title: Text(Intl.fileList_menu_open.tr),
                    onTap: () {
                      Navigator.pop(context);
                      _onFileTap(context, index);
                    },
                  ),
                  if (!file.isDir)
                    ListTile(
                      leading: const Icon(Icons.link_rounded),
                      title: Text(Intl.fileList_menu_copyLink.tr),
                      onTap: () {
                        Navigator.pop(context);
                        _copyFileLink(file);
                      },
                    ),
                  if (_hasWritePermission)
                    ListTile(
                      leading: const Icon(Icons.file_copy),
                      title: Text(Intl.fileList_menu_copy.tr),
                      onTap: () {
                        Navigator.pop(context);
                        _copyMoveStart(file, true);
                      },
                    ),
                  if (_hasWritePermission)
                    ListTile(
                      leading: const Icon(Icons.drive_file_move_rounded),
                      title: Text(Intl.fileList_menu_move.tr),
                      onTap: () {
                        Navigator.pop(context);
                        _copyMoveStart(file, false);
                      },
                    ),
                  if (_hasWritePermission)
                    ListTile(
                      leading:
                          const Icon(Icons.drive_file_rename_outline_rounded),
                      title: Text(Intl.fileList_menu_rename.tr),
                      onTap: () {
                        Navigator.pop(context);
                        _showRenameDialog(file);
                      },
                    ),
                  if (_hasWritePermission)
                    ListTile(
                      leading: const Icon(Icons.delete),
                      title: Text(Intl.fileList_menu_delete.tr),
                      onTap: () {
                        Navigator.pop(context);
                        _tryDeleteFile(file);
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: Text(Intl.fileList_menu_details.tr),
                    onTap: () {
                      Navigator.pop(context);
                      _showDetailsDialog(file);
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  void _copyMoveStart(FileItemVO file, bool isCopy) {
    LogUtil.d("showBottomSheet");
    String originalFolder = file.path.substringBeforeLast("/")!;
    if (originalFolder.isEmpty) {
      originalFolder = "/";
    }

    var future = Get.bottomSheet(
      FileCopyMoveDialog(
        originalFolder: originalFolder,
        names: [file.name],
        isCopy: isCopy,
      ),
      isScrollControlled: true,
    );
    future.then((value) {
      if (value != null && value["result"] == true) {
        _refreshIndicatorKey.currentState?.show();
      }
    });
  }

  void _showDetailsDialog(FileItemVO file) {
    showModalBottomSheet(
      context: Get.context!,
      builder: (context) => FileDetailsDialog(
        name: file.name,
        size: file.sizeDesc,
        path: file.path,
        modified: file.modified,
        thumb: file.thumb,
        provider: file.provider,
      ),
    );
  }

  _tryDeleteFile(file) {
    SmartDialog.show(
        clickMaskDismiss: false,
        keepSingle: true,
        builder: (context) {
          return AlertDialog(
            title: Text(Intl.deleteFileDialog_title.tr),
            content: Text.rich(
              TextSpan(
                text: Intl.deleteFileDialog_content_part1.tr,
                children: [
                  TextSpan(
                      text: file.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: Intl.deleteFileDialog_content_part2.tr),
                ],
                style: const TextStyle(fontSize: 16),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  SmartDialog.dismiss();
                },
                child: Text(Intl.deleteFileDialog_btn_cancel.tr),
              ),
              TextButton(
                onPressed: () {
                  SmartDialog.dismiss();
                  _httpDeleteFile(file);
                },
                child: Text(Intl.deleteFileDialog_btn_ok.tr),
              ),
            ],
          );
        });
  }

  void _httpDeleteFile(FileItemVO file) {
    FileRemoveReq req = FileRemoveReq();
    req.dir = file.path.substringBeforeLast("/${file.name}")!;
    if (req.dir == "") {
      req.dir = "/";
    }
    req.names = [file.name];

    SmartDialog.showLoading(msg: Intl.fileList_tips_deleting.tr);
    DioUtils.instance.requestNetwork(Method.post, "fs/remove",
        params: req.toJson(), onSuccess: (data) {
      SmartDialog.dismiss();
      _files.remove(file);
      setState(() {});
    }, onError: (code, msg) {
      SmartDialog.showToast(msg);
      SmartDialog.dismiss();
    });
  }

  _onFileMoreIconButtonTap(BuildContext context, int index) {
    _showBottomMenuDialog(context, _files[index], index);
  }

  void _showRenameDialog(FileItemVO file) {
    final textEditingController = TextEditingController(text: file.name);
    final focusNode = FocusNode().autoFocus();
    SmartDialog.show(builder: (context) {
      return FileRenameDialog(
        controller: textEditingController,
        focusNode: focusNode,
        onCancel: () => SmartDialog.dismiss(),
        onConfirm: () {
          SmartDialog.dismiss();
          _httpRenameFile(file, textEditingController.text.trim());
        },
      );
    });
  }

  void _httpRenameFile(FileItemVO file, String newName) {
    if (file.name == newName) {
      return;
    }

    FileRenameReq req = FileRenameReq();
    req.path = file.path;
    req.name = newName;
    SmartDialog.showLoading(msg: Intl.fileList_tips_renaming.tr);
    DioUtils.instance.requestNetwork(Method.post, "fs/rename",
        params: req.toJson(), onSuccess: (data) {
      file.path = "${file.path.substringBeforeLast(file.name)!}$newName";
      file.name = newName;
      setState(() {});
      SmartDialog.dismiss();
    }, onError: (code, msg) {
      SmartDialog.dismiss();
      SmartDialog.showToast(msg);
    });
  }

  void _showNewFolderDialog() {
    SmartDialog.show(builder: (context) {
      TextEditingController textController = TextEditingController();
      FocusNode focusNode = FocusNode().autoFocus();
      return MkdirDialog(
        controller: textController,
        focusNode: focusNode,
        onCancel: () => SmartDialog.dismiss(),
        onConfirm: () {
          SmartDialog.dismiss();
          _httpMkdir(textController.text.trim());
        },
      );
    });
  }

  void _httpMkdir(String text) {
    MkdirReq req = MkdirReq();
    if (path == "/") {
      req.path = "/$text";
    } else {
      req.path = "$path/$text";
    }

    SmartDialog.showLoading();
    DioUtils.instance.requestNetwork(
      Method.post,
      "fs/mkdir",
      params: req.toJson(),
      onSuccess: (data) {
        SmartDialog.dismiss();
        SmartDialog.showToast(Intl.mkdirDialog_createSuccess.tr);
        _refreshIndicatorKey.currentState?.show();
        Get.toNamed(
          NamedRouter.fileList,
          arguments: {"path": req.path},
          id: AlistRouter.fileListCopyMoveRouterStackId,
        );
      },
      onError: (code, msg) {
        SmartDialog.dismiss();
        SmartDialog.showToast(msg);
      },
    );
  }

  void _copyFileLink(FileItemVO file) async {
    FileUtils.copyFileLink(file.path, file.sign);
  }
}

class _FileListView extends StatelessWidget {
  const _FileListView({
    Key? key,
    required this.files,
    required this.path,
    required this.readme,
    required this.onFileItemClick,
    this.hasWritePermission = false,
    this.onFileMoreIconButtonTap,
    this.fileDeleteCallback,
  }) : super(key: key);
  final String? path;
  final String? readme;
  final List<FileItemVO> files;
  final bool hasWritePermission;
  final FileItemClickCallback onFileItemClick;
  final FileMoreIconClickCallback? onFileMoreIconButtonTap;
  final FileDeleteCallback? fileDeleteCallback;

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
          return Slidable(
            key: Key(file.path),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) => _showDetailsDialog(context, file),
                  backgroundColor: Get.theme.colorScheme.secondary,
                  foregroundColor: Colors.white,
                  label: Intl.recentsScreen_menu_details.tr,
                ),
                if (hasWritePermission)
                  SlidableAction(
                    onPressed: (context) {
                      if (null != fileDeleteCallback) {
                        fileDeleteCallback!(context, index);
                      }
                    },
                    backgroundColor: const Color(0xFFFE4A49),
                    foregroundColor: Colors.white,
                    label: Intl.recentsScreen_menu_delete.tr,
                  ),
              ],
            ),
            child: FileListItemView(
              icon: file.icon,
              fileName: file.name,
              thumbnail: file.thumb,
              time: file.modified,
              sizeDesc: file.sizeDesc,
              onTap: () => onFileItemClick(context, index),
              onMoreIconButtonTap: () {
                if (onFileMoreIconButtonTap != null) {
                  onFileMoreIconButtonTap!(context, index);
                }
              },
            ),
          );
        }
      },
    );
  }

  _showDetailsDialog(BuildContext context, FileItemVO file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => FileDetailsDialog(
        name: file.name,
        size: file.sizeDesc,
        path: file.path,
        modified: file.modified,
        thumb: file.thumb,
        provider: file.provider,
      ),
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
