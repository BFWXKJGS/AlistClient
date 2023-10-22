import 'dart:async';

import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/database/table/file_viewing_record.dart';
import 'package:alist/entity/file_list_resp_entity.dart';
import 'package:alist/entity/file_search_resp.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/screen/audio_player_screen.dart';
import 'package:alist/screen/file_reader_screen.dart';
import 'package:alist/screen/gallery_screen.dart';
import 'package:alist/screen/pdf_reader_screen.dart';
import 'package:alist/screen/video_player_screen.dart';
import 'package:alist/util/file_type.dart';
import 'package:alist/util/file_utils.dart';
import 'package:alist/util/markdown_utils.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/util/string_utils.dart';
import 'package:alist/util/user_controller.dart';
import 'package:alist/util/widget_utils.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:alist/widget/file_list_item_view.dart';
import 'package:dio/dio.dart';
import 'package:floor/floor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class FileSearchScreen extends StatelessWidget {
  FileSearchScreen({super.key});

  final String _folder = Get.arguments["folder"] ?? "/";

  @override
  Widget build(BuildContext context) {
    FileSearchController controller = Get.put(FileSearchController(_folder));
    final searchBoxBackground = WidgetUtils.isDarkMode(context)
        ? const Color(0xff181818)
        : const Color(0xfff5f5f5);
    final searchIconColor = WidgetUtils.isDarkMode(context)
        ? const Color(0xff5c5c5c)
        : const Color(0xffb1b1b1);
    final searchTextColor = WidgetUtils.isDarkMode(context)
        ? const Color(0xffd0d0d0)
        : const Color(0xff333333);

    return AlistScaffold(
      showAppbar: false,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Row(
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: searchBoxBackground,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(4))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Icon(
                            Icons.search_rounded,
                            color: searchIconColor,
                          ),
                        ),
                        Expanded(
                            child: TextField(
                          focusNode: controller.focusNode,
                          controller: controller.textEditingController,
                          onChanged: (text) {
                            controller.onSearchTextChange(text);
                          },
                          style: TextStyle(color: searchTextColor),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            hintText: Intl.fileSearchScreen_searchHint.tr,
                            hintStyle: TextStyle(color: searchIconColor),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    child: Text(Intl.fileSearchScreen_cancel.tr),
                  ),
                )
              ],
            ),
          ),
          Expanded(child: _buildList(controller)),
        ],
      ),
    );
  }

  Obx _buildList(FileSearchController controller) {
    return Obx(() => ListView.separated(
        itemBuilder: (context, index) {
          var item = controller.list[index];
          var isDir = item.isDir ?? false;
          var sizeDesc = isDir ? null : FileUtils.formatBytes(item.size ?? 0);
          return FileListItemView(
            icon: FileUtils.getFileIcon(isDir, item.name ?? ""),
            fileName: item.name ?? "",
            time: item.parent,
            sizeDesc: sizeDesc,
            thumbnail: null,
            fileNameMaxLines: 100,
            onTap: () {
              controller.onFileTap(context, index);
            },
          );
        },
        separatorBuilder: (context, index) => const Divider(),
        itemCount: controller.list.length));
  }
}

class FileSearchController extends GetxController {
  final String folder;
  final FocusNode focusNode = FocusNode();
  final TextEditingController textEditingController = TextEditingController();
  CancelToken? _cancelToken;
  var list = <FileSearchRespContent>[].obs;
  Timer? _searchDelayTimer;

  FileSearchController(this.folder);

  @override
  void onInit() {
    super.onInit();
    Future.delayed(const Duration(milliseconds: 300))
        .then((value) => focusNode.requestFocus());
  }

  @override
  void onClose() {
    _cancelToken?.cancel();
    _searchDelayTimer?.cancel();
    super.onClose();
  }

  void onSearchTextChange(String text) {
    _searchDelayTimer?.cancel();
    _searchDelayTimer = Timer(const Duration(microseconds: 300), () {
      if (!text.isBlank!) {
        _doSearch(text.trim());
      }
    });
  }

  void _doSearch(String text) {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final body = {
      "parent": folder,
      "keywords": text,
      "scope": 0,
      "page": 1,
      "per_page": 100,
      "password": ""
    };
    DioUtils.instance.requestNetwork<FileSearchResp>(Method.post, "fs/search",
        params: body, onSuccess: (data) {
      if (textEditingController.text.trim() == text) {
        list.value = data?.content ?? [];
      }
    }, cancelToken: _cancelToken);
  }

  void onFileTap(BuildContext context, int index) {
    var file = list[index];
    var isDir = file.isDir ?? false;
    FileType fileType = FileUtils.getFileType(isDir, file.name ?? "");
    var path = "${file.parent}/${file.name}";
    if (path.startsWith("//")) {
      path = path.substring(1);
    }

    switch (fileType) {
      case FileType.folder:
        Get.toNamed(
          NamedRouter.fileList,
          arguments: {
            "path": path,
          },
        );
        break;
      case FileType.video:
        _gotoVideoPlayer(path, file);
        break;
      case FileType.audio:
        _gotoAudioPlayer(path, file);
        break;
      case FileType.image:
        _gotoGalleryScreen(path, file);
        break;
      case FileType.pdf:
        _gotoPdfScreen(path, file);
        break;
      case FileType.markdown:
        _gotoMarkdownScreen(path, file);
        break;
      case FileType.txt:
      case FileType.word:
      case FileType.excel:
      case FileType.ppt:
      case FileType.code:
      case FileType.apk:
      case FileType.compress:
      default:
        _gotoFileReaderScreen(path, file);
        break;
    }
  }

  Future<List<FileItemVO>?> _loadFilesPrepare(
    String folderPath,
    String filePath,
    FileType? fileType,
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
    FileType? fileType,
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
          .where((element) => (fileType == null || element.type == fileType))
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

  void _gotoVideoPlayer(String path, FileSearchRespContent file) async {
    SmartDialog.showLoading();
    var files = await _loadFilesPrepare(
        path.substringBeforeLast("/")!, path, FileType.video);
    SmartDialog.dismiss();
    if (files == null) {
      return;
    }

    var index = files.lastIndexWhere((element) => element.path == path);
    if (index == -1) {
      index = 0;
    }
    _fileViewingRecord(files[index]);
    var videos = files
        .map(
          (e) => VideoItem(
            name: e.name,
            remotePath: e.path,
            sign: e.sign,
            provider: e.provider,
            thumb: e.thumb,
            size: e.size,
            modifiedMilliseconds: e.modifiedMilliseconds,
          ),
        )
        .toList();
    Get.toNamed(
      NamedRouter.videoPlayer,
      arguments: {
        "videos": videos,
        "index": index,
      },
    );
  }

  void _gotoAudioPlayer(String path, FileSearchRespContent file) async {
    SmartDialog.showLoading();
    var files = await _loadFilesPrepare(
        path.substringBeforeLast("/")!, path, FileType.audio);
    SmartDialog.dismiss();
    if (files == null) {
      return;
    }

    var index = files.lastIndexWhere((element) => element.path == path);
    if (index == -1) {
      index = 0;
    }

    _fileViewingRecord(files[index]);
    var audios = files
        .map(
          (e) => AudioItem(
            name: e.name,
            remotePath: e.path,
            sign: e.sign,
            provider: e.provider,
          ),
        )
        .toList();
    Get.toNamed(
      NamedRouter.audioPlayer,
      arguments: {
        "audios": audios,
        "index": index,
      },
    );
  }

  void _gotoGalleryScreen(String path, FileSearchRespContent file) async {
    SmartDialog.showLoading();
    var files = await _loadFilesPrepare(
        path.substringBeforeLast("/")!, path, FileType.image);
    SmartDialog.dismiss();
    if (files == null) {
      return;
    }

    var index = files.lastIndexWhere((element) => element.path == path);
    if (index == -1) {
      index = 0;
    }
    _fileViewingRecord(files[index]);
    var photos = files
        .map(
          (e) => PhotoItem(
            name: e.name,
            remotePath: e.path,
            sign: e.sign,
            provider: e.provider,
          ),
        )
        .toList();
    Get.toNamed(
      NamedRouter.gallery,
      arguments: {
        "files": photos,
        "index": index,
      },
    );
  }

  void _gotoPdfScreen(String path, FileSearchRespContent file) async {
    SmartDialog.showLoading();
    var files = await _loadFilesPrepare(
        path.substringBeforeLast("/")!, path, FileType.pdf);
    SmartDialog.dismiss();
    if (files == null) {
      return;
    }

    var index = files.lastIndexWhere((element) => element.path == path);
    if (index == -1) {
      index = 0;
    }
    var file = files[index];
    _fileViewingRecord(file);
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
  }

  void _gotoMarkdownScreen(String path, FileSearchRespContent file) async {
    SmartDialog.showLoading();
    var files = await _loadFilesPrepare(
        path.substringBeforeLast("/")!, path, FileType.markdown);
    SmartDialog.dismiss();
    if (files == null) {
      return;
    }

    var index = files.lastIndexWhere((element) => element.path == path);
    if (index == -1) {
      index = 0;
    }
    var file = files[index];
    _fileViewingRecord(file);
    var fileLink = await FileUtils.makeFileLink(path, file.sign);
    if (fileLink != null) {
      Get.toNamed(NamedRouter.web, arguments: {
        "url": MarkdownUtil.makePreviewUrl(fileLink),
        "title": file.name
      });
    }
  }

  void _gotoFileReaderScreen(String path, FileSearchRespContent file) async {
    SmartDialog.showLoading();
    var files = await _loadFilesPrepare(
        path.substringBeforeLast("/")!, path, FileType.markdown);
    SmartDialog.dismiss();
    if (files == null) {
      return;
    }

    var index = files.lastIndexWhere((element) => element.path == path);
    if (index == -1) {
      index = 0;
    }
    var file = files[index];
    _fileViewingRecord(file);
    var fileReaderItem = FileReaderItem(
      name: file.name,
      remotePath: file.path,
      sign: file.sign,
      provider: file.provider,
      thumb: file.thumb,
      fileType: FileUtils.getFileType(false, file.name),
    );
    Get.toNamed(
      NamedRouter.fileReader,
      arguments: {"fileReaderItem": fileReaderItem},
    );
  }

  @transaction
  Future<void> _fileViewingRecord(FileItemVO file) async {
    final userController = Get.find<UserController>();
    final databaseController = Get.find<AlistDatabaseController>();
    var user = userController.user.value;
    var recordData = databaseController.fileViewingRecordDao;
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
}
