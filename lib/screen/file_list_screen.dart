import 'dart:io';

import 'package:alist/entity/file_list_resp_entity.dart';
import 'package:alist/generated/images.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/router.dart';
import 'package:alist/util/file_type.dart';
import 'package:alist/util/file_type_utils.dart';
import 'package:alist/util/log_utils.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/util/widget_utils.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:alist/widget/alist_will_pop_scope.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

typedef FileItemClickCallback = Function(
  BuildContext context,
  List<FileListRespContent> files,
  FileListRespContent file,
);

typedef DirectorPasswordCallback = Function(
  String password,
);

class FileListScreen extends StatefulWidget {
  const FileListScreen({super.key, this.path});

  final String? path;

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen>
    with AutomaticKeepAliveClientMixin {
  static const String tag = "_FileListScreenState";
  FileListRespEntity? _data;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final CancelToken _cancelToken = CancelToken();
  String? _pageName;
  String? _password;
  bool _passwordRetrying = false;

  @override
  void initState() {
    super.initState();
    Log.d("1111 ${Get.arguments}");
    final path = widget.path;
    if (isRootPath(path)) {
      _pageName == null;
    } else {
      _pageName = path!.substring(path.lastIndexOf('/') + 1);
    }
    Log.d("path=$path pageName=$_pageName}", tag: tag);

    _loadFilesDelay();
    Log.d("initState", tag: tag);
  }

  bool isRootPath(String? path) => path == '/' || path == null || path == '';

  // load files when ui ready
  _loadFilesDelay() async {
    do {
      await Future.delayed(const Duration(milliseconds: 17));
      final currentState = _refreshIndicatorKey.currentState;
      if (currentState != null) {
        Log.d("start load file", tag: tag);
        currentState.show();
        break;
      }
      Log.d("ignore load file", tag: tag);
      if (!mounted) {
        break;
      }
    } while (true);
  }

  Future<void> _loadFiles() async {
    var path = widget.path ?? "/";
    var body = {
      "path": path,
      "password": _password ?? "",
      "page": 1,
      "per_page": 0,
      "refresh": false
    };

    return DioUtils.instance.requestNetwork<FileListRespEntity>(
        Method.post, "fs/list", cancelToken: _cancelToken, params: body,
        onSuccess: (data) {
      setState(
        () {
          _data = data;
        },
      );
    }, onError: (code, msg) {
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
            directorPasswordCallback: (password) {
              _password = password;
              _passwordRetrying = true;
              _refreshIndicatorKey.currentState?.show();
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
    final files = _data?.content ?? [];
    return AlistScaffold(
      appbarTitle: Text(_pageName ?? Intl.screenName_fileListRoot.tr),
      onLeadingDoubleTap: () =>
          Navigator.of(context).popUntil((route) => route.isFirst),
      body: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: () => _loadFiles(),
          child: _FileListView(
            path: widget.path,
            readme: _data?.readme,
            files: files,
            onFileItemClick: _onFileTap,
          )),
    );
  }

  void _onFileTap(
    BuildContext context,
    List<FileListRespContent> files,
    FileListRespContent file,
  ) async {
    FileType fileType = file.getFileType();
    if (fileType == FileType.apk &&
        Platform.isAndroid &&
        !await Permission.requestInstallPackages.isGranted) {
      var permissionResult = Permission.requestInstallPackages.request();
      if (await permissionResult.isGranted) {
        if (mounted) {
          _onFileTap(context, files, file);
        }
      } else {
        SmartDialog.showToast("No permission to install apk");
      }
      return;
    }

    if (!mounted) {
      return;
    }

    switch (fileType) {
      case FileType.folder:
        Get.toNamed(NamedRouter.fileList,
            arguments: {"path": file.getCompletePath(widget.path)},
            preventDuplicates: false,
            id: AlistRouter.fileListRouterStackId);
        break;
      case FileType.video:
        Get.toNamed(
          NamedRouter.videoPlayer,
          arguments: {"path": file.getCompletePath(widget.path)},
        );
        break;
      case FileType.audio:
        Get.toNamed(
          NamedRouter.audioPlayer,
          arguments: {"path": file.getCompletePath(widget.path)},
        );
        break;
      case FileType.image:
        List<String> paths = [];
        final currentPath = file.getCompletePath(widget.path);
        for (var element in files) {
          if (element.getFileType() == FileType.image) {
            paths.add(element.getCompletePath(widget.path));
          }
        }
        final index = paths.indexOf(currentPath);

        Get.toNamed(
          NamedRouter.gallery,
          arguments: {"paths": paths, "index": index},
        );
        break;
      case FileType.txt:
      case FileType.word:
      case FileType.excel:
      case FileType.ppt:
      case FileType.pdf:
      case FileType.code:
      case FileType.apk:
      case FileType.compress:
        Get.toNamed(
          NamedRouter.fileReader,
          arguments: {
            "path": file.getCompletePath(widget.path),
            "fileType": fileType
          },
        );
        break;
      case FileType.markdown:
        Get.toNamed(
          NamedRouter.markdownReader,
          arguments: {"markdownPath": file.getCompletePath(widget.path), "title": file.name},
        );
        break;
      default:
        break;
    }
  }

  @override
  bool get wantKeepAlive => isRootPath(widget.path);
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
  final List<FileListRespContent> files;
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
          return _FileListItem(
            icon: Images.fileTypeMd,
            fileName: "README.md",
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
          return _FileListItem(
            icon: file.getFileIcon(),
            fileName: file.name,
            onTap: () => onFileItemClick(context, files, file),
          );
        }
      },
    );
  }
}

class _FileListItem extends StatelessWidget {
  const _FileListItem({
    Key? key,
    required this.icon,
    required this.fileName,
    required this.onTap,
  }) : super(key: key);
  final GestureTapCallback onTap;
  final String icon;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = WidgetUtils.isDarkMode(context);
    return ListTile(
      horizontalTitleGap: 6,
      minVerticalPadding: 12,
      leading: Image.asset(icon),
      trailing: Image.asset(
        Images.iconArrowRight,
        color: isDarkMode ? Colors.white : null,
      ),
      title: Text(
        fileName,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      onTap: onTap,
    );
  }
}

class DirectorPasswordDialog extends StatefulWidget {
  const DirectorPasswordDialog(
      {Key? key, required this.directorPasswordCallback})
      : super(key: key);
  final DirectorPasswordCallback directorPasswordCallback;

  @override
  State<DirectorPasswordDialog> createState() => _DirectorPasswordDialogState();
}

class _DirectorPasswordDialogState extends State<DirectorPasswordDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(Intl.directoryPasswordDialog_title.tr),
      content: TextField(
        controller: _controller,
        obscureText: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isCollapsed: true,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 11, vertical: 12),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () {
              SmartDialog.dismiss();
            },
            child: Text(
              Intl.directoryPasswordDialog_btn_cancel.tr,
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            )),
        TextButton(
            onPressed: () {
              _onConfirm(context);
            },
            child: Text(
              Intl.directoryPasswordDialog_btn_ok.tr,
            ))
      ],
    );
  }

  void _onConfirm(BuildContext context) {
    String password = _controller.text;
    if (password.isEmpty) {
      SmartDialog.showToast(Intl.directoryPasswordDialog_tips_passwordEmpty.tr);
      return;
    }
    widget.directorPasswordCallback(password);
    SmartDialog.dismiss();
  }
}

class FileListNavigator extends StatefulWidget {
  const FileListNavigator({Key? key, required this.isInFileListStack})
      : super(key: key);
  final bool isInFileListStack;

  @override
  State<FileListNavigator> createState() => _FileListNavigatorState();
}

class _FileListNavigatorState extends State<FileListNavigator>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<NavigatorState>? _key =
      Get.nestedKey(AlistRouter.fileListRouterStackId);

  @override
  Widget build(BuildContext context) {
    return AlistWillPopScope(
      onWillPop: () async {
        if (widget.isInFileListStack &&
            _key?.currentState != null &&
            _key?.currentState?.canPop() == true) {
          _key?.currentState?.pop();
          return false;
        }
        return true;
      },
      child: Navigator(
        key: _key,
        onGenerateRoute: (settings) {
          dynamic arguments = settings.arguments;
          return GetPageRoute(
            page: () => FileListScreen(
              path: arguments?["path"],
            ),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
