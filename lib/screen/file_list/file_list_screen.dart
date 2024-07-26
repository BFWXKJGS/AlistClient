import 'dart:async';
import 'dart:io';

import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/database/dao/favorite_dao.dart';
import 'package:alist/database/table/favorite.dart';
import 'package:alist/database/table/file_password.dart';
import 'package:alist/database/table/file_viewing_record.dart';
import 'package:alist/entity/file_list_resp_entity.dart';
import 'package:alist/entity/file_remove_req.dart';
import 'package:alist/entity/file_rename_req.dart';
import 'package:alist/entity/mkdir_req.dart';
import 'package:alist/generated/images.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/router.dart';
import 'package:alist/screen/audio_player_screen.dart';
import 'package:alist/screen/file_list/director_password_dialog.dart';
import 'package:alist/screen/file_list/file_copy_move_dialog.dart';
import 'package:alist/screen/file_list/file_list_menu_anchor.dart';
import 'package:alist/screen/file_list/file_rename_dialog.dart';
import 'package:alist/screen/file_list/mkdir_dialog.dart';
import 'package:alist/screen/file_reader_screen.dart';
import 'package:alist/screen/gallery_screen.dart';
import 'package:alist/screen/pdf_reader_screen.dart';
import 'package:alist/screen/video_player_screen.dart';
import 'package:alist/util/alist_plugin.dart';
import 'package:alist/util/constant.dart';
import 'package:alist/util/download/download_manager.dart';
import 'package:alist/util/file_password_helper.dart';
import 'package:alist/util/file_type.dart';
import 'package:alist/util/file_utils.dart';
import 'package:alist/util/focus_node_utils.dart';
import 'package:alist/util/log_utils.dart';
import 'package:alist/util/markdown_utils.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/util/nature_sort.dart';
import 'package:alist/util/proxy.dart';
import 'package:alist/util/string_utils.dart';
import 'package:alist/util/user_controller.dart';
import 'package:alist/util/video_player_util.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:alist/widget/config_file_name_max_lines_dialog.dart';
import 'package:alist/widget/file_details_dialog.dart';
import 'package:alist/widget/file_list_item_view.dart';
import 'package:alist/widget/overflow_text.dart';
import 'package:dio/dio.dart' as dio;
import 'package:floor/floor.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_document_picker/flutter_document_picker.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:url_launcher/url_launcher.dart';

typedef FileItemClickCallback = Function(BuildContext context, int index);

typedef FileDeleteCallback = Function(BuildContext context, int index);

typedef FileMoreIconClickCallback = Function(BuildContext context, int index);

class FileListScreen extends StatefulWidget {
  const FileListScreen({
    super.key,
    this.path,
    this.sortBy,
    this.sortByUp,
    this.backupPassword,
    this.isRootStack = false,
  });

  final String? path;
  final MenuId? sortBy;
  final bool? sortByUp;
  final bool isRootStack;
  final String? backupPassword;

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
  List<FileItemVO> _files = List.empty(growable: false);

  // use key to get the more icon's location and size
  final GlobalKey _moreIconKey = GlobalKey();
  dio.CancelToken? _cancelToken;
  String? _pageName;
  String? _password;

  bool _queryPassword = true;
  bool _passwordRetrying = false;
  String path = "";
  bool _forceRefresh = false;
  int? stackId;
  bool _hasWritePermission = false;
  User? _currentUser;
  StreamSubscription? _userStreamSubscription;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: true);

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
    if (widget.sortBy != null) {
      _menuAnchorController.updateSortBy(widget.sortBy, widget.sortByUp);
    } else {
      var fileSortWayIndex =
          SpUtil.getInt(AlistConstant.fileSortWayIndex, defValue: -1) ?? -1;
      if (fileSortWayIndex > -1) {
        var fileSortWayUp =
            SpUtil.getBool(AlistConstant.fileSortWayUp) ?? false;
        _menuAnchorController.updateSortBy(
            MenuId.values[fileSortWayIndex], fileSortWayUp);
      }
    }

    if (_isRootPath(path)) {
      _pageName == null;
    } else {
      _pageName = path.substring(path.lastIndexOf('/') + 1);
    }
    Log.d("path=$path pageName=$_pageName}", tag: tag);

    var user = _userController.user.value;
    _currentUser = user;
    if (path == "/") {
      _userStreamSubscription = _userController.user.stream.listen((event) {
        if (_currentUser?.username != event.username ||
            _currentUser?.serverUrl != event.serverUrl) {
          _currentUser = event;

          _queryPassword = true;
          _password = null;
          _refreshController.requestRefresh();
          setState(() {
            _data = null;
            _files = [];
          });
          LogUtil.d("切换User ${_userController.user.value.username}");
        }
      });
    }
    LogUtil.d("initState", tag: tag);
  }

  Future<void> _loadFiles() async {
    // query file's password from database.
    if (_queryPassword) {
      var filePassword = await FilePasswordHelper()
          .fastFindPassword(path, backupPassword: widget.backupPassword);
      if (filePassword != null) {
        _password = filePassword;
      }
      _queryPassword = false;
    }
    return _loadFilesInner();
  }

  bool _isRootPath(String? path) => path == '/' || path == null || path == '';

  Future<void> _loadFilesInner() async {
    var body = {
      "path": path,
      "password": _password ?? "",
      "page": 1,
      "per_page": 0,
      "refresh": _forceRefresh
    };

    _cancelToken?.cancel();
    _cancelToken = dio.CancelToken();
    return DioUtils.instance.requestNetwork<FileListRespEntity>(
        Method.post, "fs/list", cancelToken: _cancelToken, params: body,
        onSuccess: (data) async {
      _passwordRetrying = false;
      _forceRefresh = false;
      _menuAnchorController.hasWritePermission.value = data?.write == true;
      _hasWritePermission = data?.write == true;
      var fileItemVOs = <FileItemVO>[];
      var files = data?.content ?? [];
      for (var file in files) {
        var fileItemVO = _fileResp2VO(data?.provider ?? "", file);
        fileItemVOs.add(fileItemVO);
      }
      _sort(fileItemVOs);
      setState(() {
        _files = fileItemVOs;
      });
      _data = data;
      _refreshController.refreshCompleted();
    }, onError: (code, msg) {
      _refreshController.refreshFailed();
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
              _refreshController.requestRefresh();

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
    _userStreamSubscription?.cancel();
    _cancelToken?.cancel();
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
              _refreshController.requestRefresh();
            } else if (menu.menuId == MenuId.newFolder) {
              _showNewFolderDialog();
            } else if (menu.menuId == MenuId.uploadFiles) {
              if (Platform.isAndroid) {
                _uploadPhotos();
              } else {
                _uploadFiles();
              }
            } else if (menu.menuId == MenuId.uploadPhotos) {
              _uploadPhotos();
            } else if (menu.menuId == MenuId.downloadAll) {
              _downloadAll();
            } else if (menu.menuId == MenuId.configFileNameLines) {
              SmartDialog.show(builder: (context) {
                return const ConfigFileNameMaxLinesDialog();
              });
            }
            break;
          case MenuGroupId.sort:
            _menuAnchorController.sortBy.value = menu.menuId;
            _menuAnchorController.sortByUp.value = menu.isUp ?? false;
            SpUtil.putInt(AlistConstant.fileSortWayIndex, menu.menuId.index);
            SpUtil.putBool(AlistConstant.fileSortWayUp, menu.isUp ?? false);

            var newFiles = _files.toList();
            _sort(newFiles);
            setState(() {
              _files = newFiles;
            });
            break;
        }
      },
    );
  }

  Future<void> _uploadFiles() async {
    SmartDialog.showLoading(msg: Intl.fileList_tip_processing.tr);
    List<String?>? paths = await FlutterDocumentPicker.openDocuments();
    SmartDialog.dismiss();
    if (paths == null || paths.isEmpty) {
      return;
    }
    List<String> filePaths = paths.map((e) => e!).toList();
    var originalFileNames = _files.map((e) => e.name).toSet();
    await Get.toNamed(
      NamedRouter.uploadingFiles,
      arguments: {
        "filePaths": filePaths,
        "remotePath": path,
        "originalFileNames": originalFileNames,
      },
    );
    _refreshController.requestRefresh();
  }

  Future<void> _uploadPhotos() async {
    if (Platform.isAndroid && !await AlistPlugin.isScopedStorage()) {
      if (!await Permission.storage.isGranted) {
        var storageStatus = await Permission.storage.request();
        if (storageStatus.isDenied) {
          SmartDialog.showToast(Intl.fileList_tips_permissionGalleyDenied.tr);
          return;
        }
      }
    }

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
      _refreshController.requestRefresh();
    }
  }

  void _downloadAll() async {
    var files = _files.toList();
    files.removeWhere((element) => element.isDir);
    if (files.isEmpty) {
      SmartDialog.showToast(Intl.fileList_tips_noDownloadableFiles.tr);
      return;
    }

    var hasAdded = false;
    for (var file in files) {
      var task = await DownloadManager.instance
          .enqueueFile(file, ignoreDuplicates: true);
      if (!hasAdded && task != null) {
        hasAdded = true;
      }
    }

    if (hasAdded) {
      var isFirstTimeDownload = SpUtil.getBool(
        AlistConstant.isFirstTimeDownload,
        defValue: true,
      );
      if (isFirstTimeDownload == true) {
        SpUtil.putBool(AlistConstant.isFirstTimeDownload, false);
        _showDownloadTipDialog();
      } else {
        SmartDialog.showToast(Intl.downloadManager_tips_addToQueue.tr);
      }
    } else {
      SmartDialog.showToast(Intl.downloadManager_tips_noDownloadableFiles.tr);
    }
  }

  AlistScaffold _buildScaffold(BuildContext context) {
    return AlistScaffold(
      appbarTitle: OverflowText(
        text: _pageName ?? Intl.screenName_fileListRoot.tr,
      ),
      appbarActions: [
        Obx(() => _userController.searchIndex.isNotEmpty
            ? IconButton(
                onPressed: () {
                  final args = {"folder": path};
                  Get.toNamed(NamedRouter.fileSearch, arguments: args);
                },
                icon: const Icon(Icons.search_rounded))
            : const SizedBox()),
        _menuMoreIcon()
      ],
      onLeadingDoubleTap: () =>
          Get.until((route) => route.isFirst, id: stackId),
      body: SlidableAutoCloseBehavior(
        child: _FileListView(
          path: path,
          readme: _data?.readme,
          files: _files,
          refreshController: _refreshController,
          hasWritePermission: _hasWritePermission,
          onFileItemClick: (context, index) {
            _onFileTap(context, index, false);
          },
          onFileMoreIconButtonTap: _onFileMoreIconButtonTap,
          refreshCallback: _loadFiles,
          fileDeleteCallback: (context, index) {
            _tryDeleteFile(_files[index]);
          },
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

  void _onFileTap(BuildContext context, int index, bool fromDialog) {
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
            "sortByUp": _menuAnchorController.sortByUp.value,
            "backupPassword": _password ?? ""
          },
          preventDuplicates: false,
          id: stackId,
        );
        break;
      case FileType.video:
        _goVideoPlayerScreen(context, file, files, fromDialog);
        break;
      case FileType.audio:
        _goAudioPlayerScreen(file, files);
        break;
      case FileType.image:
        _goGalleryScreen(file, files);
        break;
      case FileType.pdf:
        var pdfItem = PdfItem(
          name: file.name,
          remotePath: file.path,
          sign: file.sign,
          provider: file.provider,
          thumb: file.thumb,
        );
        Get.toNamed(
          NamedRouter.pdfReader,
          arguments: {"pdfItem": pdfItem},
        );
        break;
      case FileType.markdown:
        _previewMarkdown(file);
        break;
      case FileType.txt:
      case FileType.word:
      case FileType.excel:
      case FileType.ppt:
      case FileType.code:
      case FileType.apk:
      case FileType.compress:
      default:
        var fileReaderItem = FileReaderItem(
          name: file.name,
          remotePath: file.path,
          sign: file.sign,
          provider: file.provider,
          thumb: file.thumb,
          fileType: file.type,
        );
        Get.toNamed(
          NamedRouter.fileReader,
          arguments: {"fileReaderItem": fileReaderItem},
        );
        break;
    }
  }

  void _goAudioPlayerScreen(FileItemVO file, List<FileItemVO> files) async {
    var audios = files
        .where((element) => element.type == FileType.audio)
        .map((e) => AudioItem(
              name: e.name,
              remotePath: e.path,
              sign: e.sign,
              provider: e.provider,
            ))
        .toList();
    final index =
        audios.indexWhere((element) => element.remotePath == file.path);

    Get.toNamed(
      NamedRouter.audioPlayer,
      arguments: {"audios": audios, "index": index},
    );
  }

  void _goGalleryScreen(FileItemVO file, List<FileItemVO> files) async {
    var images = files
        .where((element) => element.type == FileType.image)
        .map((e) => PhotoItem(
              name: e.name,
              remotePath: e.path,
              sign: e.sign,
              provider: e.provider,
            ))
        .toList();
    final index =
        images.indexWhere((element) => element.remotePath == file.path);

    Get.toNamed(
      NamedRouter.gallery,
      arguments: {"files": images, "index": index},
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
      provider: file.provider ?? "",
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
      createTime: DateTime.now().millisecondsSinceEpoch,
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
            result = NaturalSort.compare(a.name, b.name);
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

  FileItemVO _fileResp2VO(String provider, FileListRespContent resp) {
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
      thumb: resp.isDir ? "" : resp.thumb,
      sign: resp.sign,
      icon: resp.getFileIcon(),
      modifiedMilliseconds: modifyTime?.millisecondsSinceEpoch ?? -1,
      provider: provider,
    );
  }

  _showBottomMenuDialog(
      BuildContext widgetContext, FileItemVO file, int index) async {
    var user = _userController.user.value;
    Favorite? favorite = await _databaseController.favoriteDao
        .findByPath(user.serverUrl, user.username, file.path);
    if (!mounted) {
      return;
    }
    showModalBottomSheet(
        context: Get.context!,
        isScrollControlled: true,
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
                      _onFileTap(context, index, true);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.open_in_new),
                    title: Text(Intl.fileList_menu_open.tr),
                    onTap: () {
                      Navigator.pop(context);
                      _onFileTap(context, index, true);
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
                  if (!file.isDir)
                    ListTile(
                      leading: const Icon(Icons.download_rounded),
                      title: Text(Intl.fileList_menu_download.tr),
                      onTap: () async {
                        Navigator.pop(context);
                        final task =
                            await DownloadManager.instance.enqueueFile(file);
                        if (task != null) {
                          var isFirstTimeDownload = SpUtil.getBool(
                            AlistConstant.isFirstTimeDownload,
                            defValue: true,
                          );
                          if (isFirstTimeDownload == true) {
                            SpUtil.putBool(
                                AlistConstant.isFirstTimeDownload, false);
                            _showDownloadTipDialog();
                          } else {
                            SmartDialog.showToast(
                                Intl.downloadManager_tips_addToQueue.tr);
                          }
                        }
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
                  if (favorite == null)
                    ListTile(
                      leading: const Icon(Icons.favorite_border_rounded),
                      title: Text(Intl.fileList_menu_favorite.tr),
                      onTap: () {
                        Navigator.pop(context);
                        _favorite(file, true);
                      },
                    ),
                  if (favorite != null)
                    ListTile(
                      leading: const Icon(
                        Icons.favorite_rounded,
                      ),
                      title: Text(Intl.fileList_menu_cancel_favorite.tr),
                      onTap: () {
                        Navigator.pop(context);
                        _favorite(file, false);
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
                      _showDetailsDialog(widgetContext, file);
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
        _refreshController.requestRefresh();
      }
    });
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
    DioUtils.instance.requestNetwork<String?>(Method.post, "fs/remove",
        params: req.toJson(), onSuccess: (data) {
      SmartDialog.dismiss();
      _refreshController.requestRefresh();
    }, onError: (code, msg) {
      SmartDialog.showToast(msg);
      SmartDialog.dismiss();
    });
  }

  _onFileMoreIconButtonTap(BuildContext context, int index) {
    _showBottomMenuDialog(context, _files[index], index);
  }

  void _favorite(FileItemVO file, bool favorite) async {
    AlistDatabaseController databaseController = Get.find();
    FavoriteDao favoriteDao = databaseController.favoriteDao;
    UserController userController = Get.find();
    var user = userController.user.value;

    if (favorite) {
      var favoriteId = await favoriteDao.insertRecord(
        Favorite(
            isDir: file.isDir,
            serverUrl: user.serverUrl,
            userId: user.username,
            remotePath: file.path,
            name: file.name,
            path: file.path,
            size: file.size ?? 0,
            sign: file.sign,
            thumb: file.thumb,
            modified: file.modifiedMilliseconds,
            provider: file.provider ?? "",
            createTime: DateTime.now().millisecondsSinceEpoch),
      );
      LogUtil.d("add favorite , id : $favoriteId");

      var find = await favoriteDao.findByPath(
          user.serverUrl, user.username, file.path);
      LogUtil.d("find = $find");
    } else {
      favoriteDao.deleteByPath(user.serverUrl, user.username, file.path);
    }
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
      _files[_files.indexOf(file)] = file;
      _refreshController.requestRefresh();
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
    DioUtils.instance.requestNetwork<String?>(
      Method.post,
      "fs/mkdir",
      params: req.toJson(),
      onSuccess: (data) {
        SmartDialog.dismiss();
        SmartDialog.showToast(Intl.mkdirDialog_createSuccess.tr);
        _refreshController.requestRefresh();
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

  void _goVideoPlayerScreen(BuildContext context, FileItemVO file,
      List<FileItemVO> files, bool showSelector) {
    var videos = files
        .where((element) => element.type == FileType.video)
        .map((e) => VideoItem(
              name: e.name,
              remotePath: e.path,
              sign: e.sign,
              provider: e.provider,
              thumb: e.thumb,
              size: e.size ?? 0,
              modifiedMilliseconds: e.modifiedMilliseconds,
            ))
        .toList();
    final index =
        videos.indexWhere((element) => element.remotePath == file.path);

    if (showSelector) {
      VideoPlayerUtil.selectThePlayerToPlay(
          Get.context!, videos, index, _password);
    } else {
      VideoPlayerUtil.go(videos, index, _password);
    }
  }

  void _previewMarkdown(FileItemVO file) async {
    var fileLink = await FileUtils.makeFileLink(file.path, file.sign);
    if (fileLink != null) {
      Get.toNamed(NamedRouter.web, arguments: {
        "url": MarkdownUtil.makePreviewUrl(fileLink),
        "title": file.name
      });
    }
  }

  void _showDownloadTipDialog() {
    SmartDialog.show(
        clickMaskDismiss: false,
        builder: (context) {
          return AlertDialog(
            title: Text(Intl.downloadManager_downloadTipDialog_title.tr),
            content: Text(Intl.downloadManager_downloadTipDialog_content.tr),
            actions: [
              TextButton(
                onPressed: () {
                  SmartDialog.dismiss();
                },
                child: Text(Intl.downloadManager_downloadTipDialog_iKnow.tr),
              ),
            ],
          );
        });
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
    required this.refreshController,
    this.onFileMoreIconButtonTap,
    this.fileDeleteCallback,
    required this.refreshCallback,
  }) : super(key: key);
  final String? path;
  final String? readme;
  final List<FileItemVO> files;
  final bool hasWritePermission;
  final FileItemClickCallback onFileItemClick;
  final FileMoreIconClickCallback? onFileMoreIconButtonTap;
  final FileDeleteCallback? fileDeleteCallback;
  final RefreshController refreshController;
  final VoidCallback refreshCallback;

  @override
  Widget build(BuildContext context) {
    var itemCount = files.length;
    if (readme != null && readme!.isNotEmpty) {
      itemCount++;
    }

    return SmartRefresher(
      controller: refreshController,
      onRefresh: refreshCallback,
      child: ListView.separated(
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
                  Get.toNamed(NamedRouter.web, arguments: {
                    "url": MarkdownUtil.makePreviewUrl(readme!),
                    "title": "README.md"
                  });
                } else {
                  _readMarkdownContent();
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
                extentRatio: hasWritePermission ? 0.5 : 0.25,
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
      ),
    );
  }

  void _readMarkdownContent() async {
    ProxyServer proxyServer = Get.find();
    // 开启本地代理服务器
    await proxyServer.start();
    // 设置 path 为本地代理服务器的key，这样就可以通过 http:// 访问 readme 的内容
    // 并且返回对应的本地链接
    var proxyUri = proxyServer.makeContentUri(path ?? "/", readme!);
    LogUtil.d("proxyUri ${proxyUri.toString()}");

    await Get.toNamed(NamedRouter.web, arguments: {
      "url": MarkdownUtil.makePreviewUrl(proxyUri.toString()),
      "title": "README.md"
    });
    proxyServer.stop();
  }
}

_showDetailsDialog(BuildContext context, FileItemVO file) {
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

class FileListWrapper extends StatelessWidget {
  FileListWrapper({Key? key}) : super(key: key);
  final String? path = Get.arguments?["path"];

  @override
  Widget build(BuildContext context) {
    return FileListScreen(path: path, isRootStack: true);
  }
}
