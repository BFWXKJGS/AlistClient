import 'package:alist/widget/alist_scaffold.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:alist/generated/l10n.dart';

class DonateScreen extends StatelessWidget {
  const DonateScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlistScaffold(
      appbarTitle: Text(S.of(context).screenName_donate),
      body: _PageContainer(),
    );
  }
}

class _PageContainer extends StatelessWidget {
  const _PageContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemDataList = [
      _DonateItemData(
          name: S.of(context).wechat,
          image:
              "https://img0.baidu.com/it/u=304503446,1584310435&fm=253&fmt=auto&app=138&f=GIF?w=500&h=508"),
      _DonateItemData(
          name: S.of(context).alipay,
          image:
              "https://img0.baidu.com/it/u=304503446,1584310435&fm=253&fmt=auto&app=138&f=GIF?w=500&h=508"),
    ];

    return ListView.builder(
      itemBuilder: (context, index) {
        final itemData = itemDataList[index];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 24,
            ),
            SizedBox(
              width: 202,
              height: 202,
              child: ExtendedImage.network(
                itemData.image,
              ),
            ),
            const SizedBox(
              height: 28,
            ),
            Text(itemData.name),
          ],
        );
      },
      itemCount: itemDataList.length,
    );
  }
}

class _DonateItemData {
  final String name;
  final String image;

  const _DonateItemData({required this.name, required this.image});
}
