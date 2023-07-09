import 'dart:async';

import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/database/table/server.dart';
import 'package:alist/generated/images.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/router.dart';
import 'package:alist/util/constant.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/util/user_controller.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlistScaffold(
      appbarTitle: Text(Intl.settingsScreen_item_account.tr),
      appbarActions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: InkWell(
            onTap: () => {Get.toNamed(NamedRouter.login)},
            child: Text(Intl.accountScreen_create.tr),
          ),
        ),
      ],
      body: const _PageContainer(),
    );
  }
}

class _PageContainer extends StatefulWidget {
  const _PageContainer({Key? key}) : super(key: key);

  @override
  State<_PageContainer> createState() => _PageContainerState();
}

class _PageContainerState extends State<_PageContainer> {
  final UserController _userController = Get.find<UserController>();
  final AlistDatabaseController _databaseController = Get.find();
  StreamSubscription? _serverStreamSubscription;

  List<Server>? _accountList;
  bool _loading = true;

  // 当前选中的account
  Server? currentAccount;

  // 当前左滑的account
  int slideIndex = -1;

  // double left = 0;
  double right = 0;

  @override
  void initState() {
    super.initState();
    _queryAccountList();
  }


  @override
  void dispose() {
    _serverStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _queryAccountList() async {
    _serverStreamSubscription = _databaseController.serverDao.serverList().listen((event) {
      setState(() {
        var user = _userController.user.value;
        _accountList = event ?? [];

        if (_accountList!.isEmpty) {
          _insertCurrentAccount();
        } else {
          for (int i = 0; i < _accountList!.length; i++) {
            var account = _accountList![i];
            if (account.userId == user.username &&
                account.serverUrl == user.serverUrl) {
              currentAccount = account;
              break;
            }
          }
          if (currentAccount == null && _accountList!.isNotEmpty) {
            currentAccount = _accountList?.first;
            if (currentAccount != null) {
              _login(currentAccount!);
            }
          }
          _loading = false;
          slideIndex = -1;
        }
      });
    });
  }

  Future<void> _handleDeleteItem(List<Server> list, Server item) async {
    SmartDialog.show(builder: (context) {
      return AlertDialog(
        title: Text("删除账户"),
        content: Text("确定删除账户 ${item.name} 吗？"),
        actions: [
          TextButton(
            onPressed: () {
              SmartDialog.dismiss();
            },
            child: Text("取消"),
          ),
          TextButton(
            onPressed: () {
              SmartDialog.dismiss();
              _deleteAccount(list, item);
            },
            child: Text("确认"),
          ),
        ],
      );
    });
  }

  void _deleteAccount(List<Server> list, Server item) async {
    slideIndex = -1;
    var isLastAccount = list.length == 1;
    var isCurrentItem = item == currentAccount;
    await _databaseController.serverDao.deleteServer(item);
    SmartDialog.showToast(Intl.delete_success.tr);
    if (isLastAccount) {
      _userController.logout();
      Get.offAllNamed(NamedRouter.login);
    } else if (isCurrentItem) {
      // 删除当前账户，默认选中第一个账户
      if (list.first == item) {
        currentAccount = list[1];
      } else {
        currentAccount = list[0];
      }
      _login(currentAccount!);
    }
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LinearProgressIndicator(
        backgroundColor: Colors.transparent,
        minHeight: 2,
      );
    }

    return ListView.builder(
      itemBuilder: (context, index) {
        final Server itemData = _accountList![index];

        return Column(
          children: [
            const SizedBox(
              height: 1,
            ),
            GestureDetector(
              child: InkWell(
                onTap: () {
                  if (currentAccount == itemData) {
                    return;
                  }
                  setState(() {
                    currentAccount = itemData;
                    _login(itemData);
                  });

                  // 文件列表回到根目录
                  Get.until((route) => route.isFirst,
                      id: AlistRouter.fileListRouterStackId);
                },
                child: _ListItem(
                    data: itemData,
                    index: index,
                    slideIndex: slideIndex,
                    currentAccount: currentAccount ?? itemData,
                    right: right,
                    list: _accountList,
                    handleDeleteItem: _handleDeleteItem),
              ),
              onHorizontalDragDown: (DragDownDetails downDetails) {
                //水平方向上按下时触发。
                print('downDetails');
                print(downDetails.globalPosition);
              },
              onHorizontalDragUpdate: (DragUpdateDetails updateDetails) {
                //水平方向上滑动时回调，随着手势滑动一直回调。

                setState(() {
                  right -= updateDetails.delta.dx; //水平滑动取X轴的差值
                  if (right < 0) {
                    right = 0;
                  }
                  if (right >= 64) {
                    right = 64;
                  }
                  slideIndex = index;
                  // itemData.right = right;
                });
                print('updateDetails');
                print(right);
              },
              onHorizontalDragEnd: (DragEndDetails endDetails) {
                //水平方向上滑动结束时回调
                print('endDetails $endDetails');
              },
            )
          ],
        );
      },
      itemCount: _accountList?.length ?? 0,
    );
  }

  void _login(Server itemData) {
    var baseUrl = "${itemData.serverUrl}api/";
    _userController.login(User(
      baseUrl: baseUrl,
      serverUrl: itemData.serverUrl,
      username: itemData.name,
      password: itemData.password,
      token: itemData.token,
      guest: itemData.guest,
    ));
  }

  /// 用户通过旧版本更到此版本时，此时数据库中没有数据，需要将当前用户插入到数据库中
  void _insertCurrentAccount() {
    var user = _userController.user.value;
    if (user.username.isEmpty || user.serverUrl.isEmpty) {
      return;
    }
    if (!user.guest && (user.token == null || user.token!.isEmpty)) {
      return;
    }

    var server = Server(
      userId: user.username,
      serverUrl: user.serverUrl,
      name: user.username,
      password: user.password ?? "",
      token: user.token ?? "",
      ignoreSSLError: SpUtil.getBool(AlistConstant.ignoreSSLError) == true,
      guest: user.guest,
      createTime: DateTime.now().millisecond,
      updateTime: DateTime.now().millisecond,
    );
    _databaseController.serverDao.insertServer(server);
  }
}

class _ListItem extends StatelessWidget {
  const _ListItem({
    Key? key,
    required this.data,
    required this.currentAccount,
    required this.index,
    required this.right,
    required this.slideIndex,
    required this.list,
    required this.handleDeleteItem,
  }) : super(key: key);
  final Server data;

  final Server currentAccount;
  final int slideIndex;
  final int index;
  final double right;
  final List<Server>? list;
  final Function handleDeleteItem;

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      Align(
        //最下层
        alignment: Alignment.centerRight,
        child: InkWell(
          onTap: () {
            print("删除成功");
            print("list,$list");
            handleDeleteItem(list, data);
          },
          child: Container(
            width: slideIndex == index ? right : 0,
            height: 64,
            alignment: Alignment.center,
            color: Colors.red,
            child: Text(Intl.fileList_menu_delete.tr),
          ),
        ),
      ),
      Positioned(
        left: slideIndex == index ? -right : 0,
        right: slideIndex == index ? right : 0,
        child: ListTile(
          leading: ExcludeSemantics(
            child: Image.asset(Images.accountIcon),
          ),
          title: Text(data.serverUrl),
          subtitle: Text(data.name ?? ''),
          trailing: currentAccount.id == data.id
              ? Image.asset(Images.accountIconChoosed)
              : null,
        ),
      )
    ]);
  }
}
