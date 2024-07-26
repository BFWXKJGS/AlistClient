import 'package:alist/router.dart';
import 'package:alist/screen/file_list/file_list_screen.dart';
import 'package:alist/widget/alist_will_pop_scope.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    super.build(context);
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
              sortBy: arguments?["sortBy"],
              sortByUp: arguments?["sortByUp"],
              backupPassword: arguments?["backupPassword"],
              isRootStack: false,
            ),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
