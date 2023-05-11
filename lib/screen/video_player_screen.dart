import 'package:alist/entity/file_info_resp_entity.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/util/string_utils.dart';
import 'package:alist/widget/player_skin.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_aliplayer/flutter_aliplayer.dart';
import 'package:flutter_aliplayer/flutter_aliplayer_factory.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class VideoPlayerScreen extends StatefulWidget {

  const VideoPlayerScreen({super.key});

  @override
  State createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final String path = Get.arguments["path"];
  final CancelToken _cancelToken = CancelToken();
  final FlutterAliplayer fAliplayer = FlutterAliPlayerFactory.createAliPlayer();
  String? _videoTitle;

  @override
  void initState() {
    super.initState();
    fAliplayer.setAutoPlay(true);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _loadVideoInfoAndPlay();
  }

  // 1、 load video download url from AList server
  // 2、 use this url to play video
  void _loadVideoInfoAndPlay() {
    var path = this.path;
    var body = {
      "path": path,
      "password": "",
    };
    DioUtils.instance.requestNetwork<FileInfoRespEntity>(
      Method.post,
      cancelToken: _cancelToken,
      "fs/get",
      params: body,
      onSuccess: (data) async {
        var url = "${data?.rawUrl}";
        fAliplayer.setUrl(url);
        fAliplayer.prepare();

        setState(() {
          _videoTitle = data?.name.substringBeforeLast(".") ?? "";
        });
      },
      onError: (code, message) {
        SmartDialog.showToast(message);
      },
    );
  }

  void onViewPlayerCreated(viewId) async {
    /// bind player view
    fAliplayer.setPlayerView(viewId);
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var width = screenSize.width;
    var height = screenSize.height;

    AliPlayerView aliPlayerView = AliPlayerView(
      onCreated: onViewPlayerCreated,
      x: 0,
      y: 0,
      width: width,
      height: height,
    );
    return Container(
      color: Colors.black,
      width: width,
      height: height,
      child: Stack(
        children: [
          aliPlayerView,
          AlistPlayerSkin(
            player: fAliplayer,
            buildContext: context,
            videoTitle: _videoTitle ?? "",
            retryCallback: () => _loadVideoInfoAndPlay,
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _releasePlayer();
    _cancelToken.cancel();
    super.dispose();
  }

  void _releasePlayer() {
    fAliplayer.destroy();
  }
}
