import 'package:alist/generated/images.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:alist/generated/l10n.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlistScaffold(
      appbarTitle: Text(S.of(context).screenName_about),
      body: const _AboutPageContainer(),
    );
  }
}

class _AboutPageContainer extends StatefulWidget {
  const _AboutPageContainer({Key? key}) : super(key: key);

  @override
  State<_AboutPageContainer> createState() => _AboutPageContainerState();
}

class _AboutPageContainerState extends State<_AboutPageContainer> {
  PackageInfo? packageInfo;

  @override
  void initState() {
    super.initState();
    initPackageInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Image.asset(Images.logo),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              S.of(context).appName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text("v${packageInfo?.version ?? ""}"),
          ),
        ],
      ),
    );
  }

  initPackageInfo() async {
    packageInfo = await PackageInfo.fromPlatform();
    setState(() {});
  }
}
