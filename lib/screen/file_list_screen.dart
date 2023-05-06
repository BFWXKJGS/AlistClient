import 'dart:io';

import 'package:alist/entity/file_list_resp_entity.dart';
import 'package:alist/generated/images.dart';
import 'package:alist/generated/l10n.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/util/file_type.dart';
import 'package:alist/util/file_type_utils.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/util/widget_utils.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

typedef FileItemClickCallback = Function(
  BuildContext context,
  List<FileListRespContent> files,
  FileListRespContent file,
);

class FileListScreen extends StatefulWidget {
  final String? path;

  const FileListScreen({super.key, required this.path});

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen>
    with AutomaticKeepAliveClientMixin {
  FileListRespEntity? data;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final CancelToken _cancelToken = CancelToken();
  String? pageName;

  @override
  void initState() {
    super.initState();
    final path = widget.path;
    if (isRootPath(path)) {
      pageName == null;
    } else {
      pageName = path!.substring(path.lastIndexOf('/') + 1);
    }
    LogUtil.d("path=$path pageName=$pageName}", tag: "FileListPage");

    loadData();
    LogUtil.d("initState", tag: "FileListPage");
  }

  bool isRootPath(String? path) => path == '/' || path == null || path == '';

  Future<void> loadData() async {
    var body = {
      "path": widget.path,
      "password": "",
      "page": 1,
      "per_page": 0,
      "refresh": false
    };
    Future.delayed(const Duration(milliseconds: 50)).then((value) {
      if (data == null && !_cancelToken.isCancelled) {
        _refreshIndicatorKey.currentState?.show();
        LogUtil.d(
            "_refreshIndicatorKey.currentState=${_refreshIndicatorKey.currentState}");
      }
    });
    return DioUtils.instance.requestNetwork<FileListRespEntity>(
        Method.post, "fs/list", cancelToken: _cancelToken, params: body,
        onSuccess: (data) {
      setState(() {
        this.data = data;
      });
    }, onError: (code, msg) {
      SmartDialog.showToast(msg);
      debugPrint(msg);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _cancelToken.cancel();
    LogUtil.d("dispose", tag: "FileListPage");
  }

  @override
  Widget build(BuildContext context) {
    final files = data?.content ?? [];

    return AlistScaffold(
      appbarTitle: Text(pageName ?? S.of(context).screenName_fileListRoot),
      body: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: () => loadData(),
          child: _FileListView(
            path: widget.path,
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
    required this.onFileItemClick,
  }) : super(key: key);
  final String? path;
  final List<FileListRespContent> files;
  final FileItemClickCallback onFileItemClick;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: files.length,
      separatorBuilder: (context, index) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18), child: Divider()),
      itemBuilder: (context, index) {
        final file = files[index];
        return _FileListItem(
          file: file,
          onTap: () => onFileItemClick(context, files, file),
        );
      },
    );
  }
}

class _FileListItem extends StatelessWidget {
  const _FileListItem({Key? key, required this.file, required this.onTap})
      : super(key: key);
  final GestureTapCallback onTap;
  final FileListRespContent file;

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = WidgetUtils.isDarkMode(context);
    return ListTile(
      horizontalTitleGap: 6,
      minVerticalPadding: 12,
      leading: Image.asset(
        file.getFileIcon(),
      ),
      trailing: Image.asset(
        Images.iconArrowRight,
        color: isDarkMode ? Colors.white : null,
      ),
      title: Text(
        file.name,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      onTap: onTap,
    );
  }
}
