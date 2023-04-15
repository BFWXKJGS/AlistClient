import 'dart:convert';

import 'package:alist/entity/file_info_resp_entity.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPage extends StatefulWidget {
  final String path;

  const VideoPage({super.key, required this.path});

  @override
  State createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    var path = widget.path;
    var body = {
      "path": path,
      "password": "",
    };
    DioUtils.instance.requestNetwork<FileInfoRespEntity>(Method.post, "fs/get",
        params: body, onSuccess: (data) {
      var url = data?.rawUrl ?? "";
      _controller = VideoPlayerController.network(url)
        ..initialize().then((_) {
          // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
          setState(() {
            _controller?.play();
          });
        });
    }, onError: (code, message) {
      print("code:$code,message:$message");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Demo',
      home: Scaffold(
        body: PlayerContainer(controller: _controller),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller?.dispose();
  }
}

class PlayerContainer extends StatelessWidget {
  const PlayerContainer({
    super.key,
    required VideoPlayerController? controller,
  }) : _controller = controller;

  final VideoPlayerController? _controller;

  @override
  Widget build(BuildContext context) {
    return buildPlayerContainer();
  }

  Center buildPlayerContainer() {
    var controller = _controller;
    if (controller == null) {
      return const Center(
        child: Text('No video'),
      );
    }

    return Center(
      child: controller.value.isInitialized
          ? AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            )
          : Container(),
    );
  }
}
