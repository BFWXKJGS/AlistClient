import 'package:alist/entity/donate_config_entity.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/net/net_error_getter.dart';
import 'package:alist/util/global.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:alist/generated/l10n.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';

class DonateScreen extends StatelessWidget {
  const DonateScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlistScaffold(
      appbarTitle: Text(S.of(context).screenName_donate),
      body: const _PageContainer(),
    );
  }
}

class _PageContainer extends StatefulWidget {
  const _PageContainer({Key? key}) : super(key: key);

  @override
  State<_PageContainer> createState() => _PageContainerState();
}

class _PageContainerState extends State<_PageContainer>
    with NetErrorGetterMixin {
  final CancelToken _cancelToken = CancelToken();
  List<_DonateItemData>? _donateConfig;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDonateConfig();
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    super.dispose();
  }

  _loadDonateConfig() {
    // Locale currentLocal = Localizations.localeOf(context);
    String configUrl = "https://${Global.configServerHost}/qrcode/config.json";

    DioUtils.instance.requestNetwork<DonateConfigEntity>(
      Method.get,
      configUrl,
      cancelToken: _cancelToken,
      onSuccess: (data) {
        List<_DonateItemData> list = [];
        if (data?.alipay != null && data?.alipay.isNotEmpty == true) {
          list.add(
            _DonateItemData(
                name: S.of(context).alipay,
                image: data?.alipay ?? "",
                imageSmall: data?.alipaySmall ?? ""),
          );
        }
        if (data?.wechat != null && data?.wechat.isNotEmpty == true) {
          list.add(
            _DonateItemData(
                name: S.of(context).wechat,
                image: data?.wechat ?? "",
                imageSmall: data?.wechatSmall ?? ""),
          );
        }
        setState(() {
          _donateConfig = list;
          _loading = false;
        });
      },
      onError: (code, message, error) {
        SmartDialog.showToast(message ?? netErrorToMessage(error));
        setState(() {
          _loading = false;
        });
      },
    );
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
        final itemData = _donateConfig![index];
        final List<String> imageUrls =
            _donateConfig?.map((e) => e.image).toList() ?? [];

        return InkWell(
          onTap: () {
            context.pushNamed(
              NamedRouter.gallery,
              extra: {"urls": imageUrls, "index": index},
            );
          },
          child: _ListItem(
            data: itemData,
          ),
        );
      },
      itemCount: _donateConfig?.length ?? 0,
    );
  }
}

class _ListItem extends StatelessWidget {
  const _ListItem({Key? key, required this.data}) : super(key: key);
  final _DonateItemData data;

  @override
  Widget build(BuildContext context) {
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
            data.imageSmall,
          ),
        ),
        const SizedBox(
          height: 28,
        ),
        Text(data.name),
      ],
    );
  }
}

class _DonateItemData {
  final String name;
  final String image;
  final String imageSmall;

  const _DonateItemData(
      {required this.name, required this.image, required this.imageSmall});
}
