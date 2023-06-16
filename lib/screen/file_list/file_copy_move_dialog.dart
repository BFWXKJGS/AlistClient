import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/database/table/file_password.dart';
import 'package:alist/entity/file_list_resp_entity.dart';
import 'package:alist/entity/copy_move_req.dart';
import 'package:alist/generated/mkdir_req.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/router.dart';
import 'package:alist/screen/file_list/director_password_dialog.dart';
import 'package:alist/screen/file_list/mkdir_dialog.dart';
import 'package:alist/util/file_utils.dart';
import 'package:alist/util/focus_node_utils.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/util/string_utils.dart';
import 'package:alist/util/user_controller.dart';
import 'package:alist/widget/alist_will_pop_scope.dart';
import 'package:alist/widget/file_list_item_view.dart';
import 'package:dio/dio.dart';
import 'package:floor/floor.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class FileCopyMoveDialog extends StatelessWidget {
  FileCopyMoveDialog({
    Key? key,
    required this.originalFolder,
    required this.names,
    required this.isCopy,
  }) : super(key: key);
  final GlobalKey<NavigatorState>? _key =
      Get.nestedKey(AlistRouter.fileListCopyMoveRouterStackId);
  final String originalFolder;
  final List<String> names;
  final bool isCopy;

  @override
  Widget build(BuildContext context) {
    final statusBarHeight =
        MediaQueryData.fromView(View.of(context)).padding.top;
    LogUtil.d("statusBarHeight=$statusBarHeight");
    return SizedBox(
      width: double.infinity,
      height: Get.height - statusBarHeight,
      child: AlistWillPopScope(
        onWillPop: () async {
          if (_key?.currentState != null &&
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
            String? path = arguments?["path"];
            if (path == null || path.isEmpty) {
              path = "/";
            }
            final FileCopyMoveController controller = Get.put(
              FileCopyMoveController(originalFolder, names, isCopy, path),
              tag: path,
            );

            return GetPageRoute(
              page: () => _buildFileListColumn(context, controller, path!),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFileListColumn(
      BuildContext context, FileCopyMoveController controller, String path) {
    String name = "";
    if (path == "/") {
      name = Intl.screenName_fileListRoot.tr;
    } else {
      name = path.substringAfterLast("/")!;
    }

    return Container(
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              leading: BackButton(
                onPressed: () {
                  if (_key?.currentState != null &&
                      _key?.currentState?.canPop() == true) {
                    _key?.currentState?.pop();
                  } else {
                    Get.back();
                  }
                },
              ),
              title: Text(name),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    Intl.fileCopyMoveDialog_cancel.tr,
                    style: TextStyle(fontSize: 16, color: Get.iconColor),
                  ),
                ),
              ],
            ),
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              color: Get.theme.colorScheme.surfaceVariant,
              child: Text(
                "${Intl.fileCopyMoveDialog_targetFolder.tr}${controller.path}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Obx(() => _buildFolderList(controller)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        SmartDialog.show(builder: (context) {
                          TextEditingController textController =
                              TextEditingController();
                          FocusNode focusNode = FocusNode().autoFocus();
                          return MkdirDialog(
                            controller: textController,
                            focusNode: focusNode,
                            onCancel: () => SmartDialog.dismiss(),
                            onConfirm: () {
                              SmartDialog.dismiss();
                              controller.httpMkdir(textController.text.trim());
                            },
                          );
                        });
                      },
                      child: Text(Intl.fileCopyMoveDialog_newFolder.tr),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: FilledButton(
                      onPressed: !controller.canCopyMove
                          ? null
                          : () {
                              LogUtil.d(
                                  "${controller.path} ${controller.originalFolder}");
                              controller.httpCopyMove();
                            },
                      child: Text(
                          '${isCopy ? Intl.fileCopyMoveDialog_copy.tr : Intl.fileCopyMoveDialog_move.tr}(${controller.names.length})'),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFolderList(FileCopyMoveController controller) {
    return RefreshIndicator(
      key: controller.refreshIndicatorKey,
      onRefresh: () => controller.loadFiles(),
      child: ListView.separated(
        itemBuilder: (context, index) {
          final FileListRespContent file = controller.files[index];
          DateTime? modifyTime = file.parseModifiedTime();
          String? modifyTimeStr = file.getReformatModified(modifyTime);

          return FileListItemView(
            icon: file.getFileIcon(),
            fileName: file.name,
            time: modifyTimeStr,
            sizeDesc: file.formatBytes(),
            onTap: () {
              var path = "";
              if (controller.path == "/") {
                path = "/${file.name}";
              } else {
                path = "${controller.path}/${file.name}";
              }
              Get.toNamed(
                NamedRouter.fileList,
                arguments: {"path": path},
                id: AlistRouter.fileListCopyMoveRouterStackId,
              );
            },
          );
        },
        separatorBuilder: (context, index) => const Divider(),
        itemCount: controller.files.length,
      ),
    );
  }
}

class FileCopyMoveController extends GetxController {
  FileCopyMoveController(
    this.originalFolder,
    this.names,
    this.isCopy,
    this.path,
  );

  final String path;
  final String originalFolder;
  final List<String> names;
  final bool isCopy;

  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  CancelToken? _cancelToken;
  final files = <FileListRespContent>[].obs;
  final _userController = Get.find<UserController>();
  final _databaseController = Get.find<AlistDatabaseController>();
  String? _password;
  bool canCopyMove = true;

  bool _passwordRetrying = false;

  @override
  void onInit() {
    super.onInit();
    if (originalFolder == path) {
      canCopyMove = false;
    } else {
      for (var name in names) {
        String folderPath = "";
        if (originalFolder == "/") {
          folderPath = "/$name";
        } else {
          folderPath = "$originalFolder/$name";
        }

        if (path.startsWith(folderPath)) {
          canCopyMove = false;
          break;
        }
      }
    }

    var user = _userController.user.value;
    _loadFilesPrepare(user, path);
  }

  @override
  void onClose() {
    super.onClose();
    _cancelToken?.cancel();
  }

  Future<void> _loadFilesPrepare(User user, String path) async {
    // query file's password from database.
    var filePassword = await _databaseController.filePasswordDao
        .findPasswordByPath(user.serverUrl, user.username, path);
    if (filePassword != null) {
      _password = filePassword.password;
    }
    if (!isClosed) {
      _loadFilesWhileWidgetReady();
    }
  }

  // load files when ui ready
  _loadFilesWhileWidgetReady() async {
    do {
      final currentState = refreshIndicatorKey.currentState;
      if (currentState != null) {
        currentState.show();
        break;
      }
      await Future.delayed(const Duration(milliseconds: 17));
      if (isClosed) {
        break;
      }
    } while (true);
  }

  Future<void> loadFiles() async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    var body = {
      "path": path,
      "password": (_password ?? ""),
      "page": 1,
      "per_page": 0,
      "refresh": false
    };

    return DioUtils.instance.requestNetwork<FileListRespEntity>(
      Method.post,
      "fs/list",
      cancelToken: _cancelToken,
      params: body,
      onSuccess: (data) {
        _passwordRetrying = false;
        data?.content?.removeWhere((element) => !element.isDir);
        files.value = data?.content ?? [];
      },
      onError: (code, msg) {
        if (code == 403) {
          _showDirectorPasswordDialog();
          if (_passwordRetrying) {
            SmartDialog.showToast(msg);
          }
        } else {
          SmartDialog.showToast(msg);
        }
        SmartDialog.showToast(msg);
      },
    );
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
              refreshIndicatorKey.currentState?.show();

              if (remember) {
                rememberPassword(password);
              } else {
                deleteOriginalPassword();
              }
            },
          );
        });
  }

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

  void httpMkdir(String text) {
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
        refreshIndicatorKey.currentState?.show();
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

  void httpCopyMove() {
    CopyMoveReq req = CopyMoveReq();
    req.srcDir = originalFolder;
    req.dstDir = path;
    req.names = names;
    String url = isCopy ? "fs/copy" : "fs/move";

    SmartDialog.showLoading();
    DioUtils.instance.requestNetwork(Method.post, url, params: req.toJson(),
        onSuccess: (data) {
      SmartDialog.dismiss();
      if (isCopy) {
        SmartDialog.showToast(Intl.fileCopyMoveDialog_copySuccess.tr);
      } else {
        SmartDialog.showToast(Intl.fileCopyMoveDialog_moveSuccess.tr);
      }
      Get.back(result: {"result": true});
    }, onError: (code, msg) {
      SmartDialog.showToast(msg);
      SmartDialog.dismiss();
    });
  }
}
