import 'dart:io';

import 'package:alist/entity/file_list_resp_entity.dart';
import 'package:alist/generated/images.dart';
import 'package:alist/generated/l10n.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/util/file_type.dart';
import 'package:alist/util/file_type_utils.dart';
import 'package:alist/util/global.dart';
import 'package:alist/util/log_utils.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/net/net_error_getter.dart';
import 'package:alist/util/widget_utils.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';
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
  final String? path;

  const FileListScreen({super.key, required this.path});

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen>
    with AutomaticKeepAliveClientMixin, NetErrorGetterMixin {
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
    var body = {
      "path": widget.path,
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
    }, onError: (code, msg, error) {
      if (code != null && code == 403) {
        _showDirectorPasswordDialog();
        if(_passwordRetrying){
          SmartDialog.showToast(msg ?? netErrorToMessage(error));
        }
      } else {
        SmartDialog.showToast(msg ?? netErrorToMessage(error));
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
      appbarTitle: Text(_pageName ?? S.of(context).screenName_fileListRoot),
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
        context.pushNamed(
          NamedRouter.fileList,
          queryParameters: {"path": file.getCompletePath(widget.path)},
        );
        break;
      case FileType.video:
        context.pushNamed(
          NamedRouter.videoPlayer,
          queryParameters: {"path": file.getCompletePath(widget.path)},
        );
        break;
      case FileType.audio:
        context.pushNamed(
          NamedRouter.audioPlayer,
          queryParameters: {"path": file.getCompletePath(widget.path)},
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

        context.pushNamed(
          NamedRouter.gallery,
          extra: {"paths": paths, "index": index},
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
        context.pushNamed(
          NamedRouter.fileReader,
          queryParameters: {"path": file.getCompletePath(widget.path)},
          extra: {"fileType": fileType},
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
          String readMeUrl = Uri(
              scheme: "https",
              host: Global.configServerHost,
              path: "alist_h5/showMarkDown",
              queryParameters: {
                "markdownUrl": readme,
                "title": "README.md",
              }).toString();
          return _FileListItem(
            icon: Images.fileTypeMd,
            fileName: "README.md",
            onTap: () => context.pushNamed(
              NamedRouter.web,
              queryParameters: {"url": readMeUrl, "title": "README.md"},
            ),
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
      title: Text(S.of(context).directoryPasswordDialog_title),
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
              S.of(context).directoryPasswordDialog_btn_cancel,
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            )),
        TextButton(
            onPressed: () {
              _onConfirm(context);
            },
            child: Text(
              S.of(context).directoryPasswordDialog_btn_ok,
            ))
      ],
    );
  }

  void _onConfirm(BuildContext context) {
    String password = _controller.text;
    if (password.isEmpty) {
      SmartDialog.showToast(
          S.of(context).directoryPasswordDialog_tips_passwordEmpty);
      return;
    }
    widget.directorPasswordCallback(password);
    SmartDialog.dismiss();
  }
}
