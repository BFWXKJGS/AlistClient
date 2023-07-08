import 'package:alist/entity/donate_config_entity.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/util/global.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:alist/widget/file_details_dialog.dart';
import 'package:alist/widget/file_list_item_view.dart';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:alist/generated/images.dart';
import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/database/dao/server_dao.dart';
import 'package:get/get.dart';
import 'package:alist/database/table/server.dart';

import 'package:alist/util/user_controller.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/router.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return AlistScaffold(
      appbarTitle: Text(Intl.settingsScreen_item_account.tr),
      onLeadingDoubleTap: () =>
          Get.until((route) => route.isFirst, id: AlistRouter.fileListRouterStackId),
      appbarActions:[
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: InkWell(
            onTap: () => {
              Get.offNamed(NamedRouter.login)
            },
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
  // final UserController _userController = Get.find();
  final userController = Get.find<UserController>();
  final AlistDatabaseController _databaseController = Get.find();
  // final CancelToken _cancelToken = CancelToken();
  List<Server>? accountList;
  bool _loading = true;
  Server? currentAccount; // 当前选中的account
  dynamic slideIndex = '';// 当前左滑的account
  // double left = 0;
  double right = 0;
  // List<Map<String, dynamic>> dataList =  [{'id':22,'name':'clinet','serverUrl':'http:shhsh','userId':'ww', 'password':'jjw', 'guest':true,'ignoreSSLError':true,'createTime':122,'updateTime':3663}];



  @override
  void initState() {
    super.initState();
    SmartDialog.showLoading();
    _queryAccountList();
    // _loadDonateConfig();
  }

  @override
  void dispose() {
    // _cancelToken.cancel();
    super.dispose();
  }

  Future<void>  _queryAccountList() async {
    // var user = _userController.user.value;
    var list = await _databaseController.serverDao.serverList();
    print('queryList:$list');
    List<Server> uniqueServers = [];
    list?.forEach((server) {
      // 根据自定义的去重条件判断是否已存在于uniqueServers中,地址+一样的用户名就去重
      if (!uniqueServers.any((uniqueServer) => uniqueServer.serverUrl == server.serverUrl && uniqueServer.name == server.name)) {
        uniqueServers.add(server);
      }
    });
    setState(() {
      accountList = uniqueServers; // dataList; //
      currentAccount = uniqueServers?[0];
      _loading = false;
      slideIndex = '';
    });
    SmartDialog.dismiss();
  }
  void _deleteCount(Server item) {
    _databaseController.serverDao.deleteServer(item);
  }


  Future<void> _handleDeleteItem(List<Server> list, Server? item) async {
      // list?.removeWhere((item) => item.name == item.name);
    SmartDialog.showLoading();
    if(list!.length > 1) { // 多于1个时候才能删除
      _deleteCount(item!);
      SmartDialog.showToast(Intl.delete_success.tr);
    } else {
      SmartDialog.showToast(Intl.delete_disable.tr);
      setState(() {
        slideIndex = '';
      });
    }
    _queryAccountList();
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
        final Server itemData = accountList![index];
        // final List<String> imageUrls =
            // accountList?.map((e) => e.image).toList() ?? [];

        return Column(
          children: [
            SizedBox(
              height: 1,
            ),
            GestureDetector(
              child:InkWell(
                onTap: () {
                  // itemData['checked']=true
                  setState(() {
                    currentAccount = itemData;
                    // accountList![index]!['checked'] = true;
                    // _loading = false;
                    var baseUrl = "${itemData.serverUrl}api/";
                    userController.login(User(
                      baseUrl: baseUrl,
                      serverUrl: itemData.serverUrl,
                      username: itemData.name,
                      password: itemData.password,
                      // token: data!.token,
                      guest: itemData.guest,
                    ));
                  });
                },
                child: _ListItem(
                  data: itemData,
                  index: index,
                  slideIndex: slideIndex,
                  currentAccount: currentAccount ?? itemData,
                  right:right,
                  list:accountList,
                  handleDeleteItem:_handleDeleteItem
                ),
              ),
              onHorizontalDragDown:(DragDownDetails downDetails){
                //水平方向上按下时触发。
                print('downDetails');
                print(downDetails.globalPosition);
              },
              onHorizontalDragUpdate:(DragUpdateDetails updateDetails){
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
              onHorizontalDragEnd:(DragEndDetails endDetails){
                //水平方向上滑动结束时回调
                print('endDetails $endDetails');
              },
            )
          ],
        );
      },
      itemCount: accountList?.length ?? 0,
    );
  }
}

class _ListItem extends StatelessWidget {
  const _ListItem({Key? key, required this.data, required this.currentAccount, required this.index, required this.right, required this.slideIndex, required this.list, required this.handleDeleteItem}) : super(key: key);
  final Server data;

  final Server currentAccount;
  final dynamic slideIndex;
  final int index;
  final double right;
  final List<Server>? list;
  final Function handleDeleteItem;
  @override
  Widget build(BuildContext context) {
    return Stack(
        children:<Widget>[
          Align(//最下层
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                print("删除成功");
                print("list,$list");
                // if(list!.length > 1) { // 多于1个时候才能删除
                  handleDeleteItem(list, data);
                //   SmartDialog.showToast(Intl.delete_success.tr);
                // } else {
                //   SmartDialog.showToast(Intl.delete_disable.tr);
                // }
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
            child:ListTile(
              leading: ExcludeSemantics(
                child: Image.asset(Images.accountIcon),
              ),
              title: Text(data.serverUrl),
              subtitle: Text(data.name ?? ''),
              trailing:currentAccount.id == data.id ? Image.asset(Images.accountIconChoosed) : null,
            ),
            // height: 100,
            left:slideIndex == index ? -right : 0,
            right: slideIndex == index ? right : 0,
          )
        ]);
  }
}



// class Server {
//   final String name;
//   final String image;
//   final String imageSmall;
//   // final bool checked;
//
//   const Server(
//       {required this.name, required this.image, required this.imageSmall});
//
//
// }
