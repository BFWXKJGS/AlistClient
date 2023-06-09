import 'dart:math';

import 'package:alist/entity/file_info_resp_entity.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/util/file_sign_utils.dart';
import 'package:alist/util/log_utils.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class GalleryScreen extends StatelessWidget {
  GalleryScreen({Key? key}) : super(key: key);

  final List<String>? urls = Get.arguments["urls"];
  final List<String>? paths = Get.arguments["paths"];
  final int initializedIndex = Get.arguments["index"];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _ImagesContainer(
            paths: paths, urls: urls, initialPage: initializedIndex),
        Positioned(
            left: 0,
            top: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ),
            ))
      ],
    );
  }
}

class _ImagesContainer extends StatefulWidget {
  const _ImagesContainer({
    super.key,
    required this.paths,
    required this.urls,
    required this.initialPage,
  });

  final List<String>? paths;
  final List<String>? urls;
  final int initialPage;

  @override
  State<_ImagesContainer> createState() => _ImagesContainerState();
}

class _ImagesContainerState extends State<_ImagesContainer> {
  late ExtendedPageController controller;
  final Map<String, FileInfoRespEntity> imageUrlMap = {};

  @override
  void initState() {
    super.initState();
    controller = ExtendedPageController(initialPage: widget.initialPage);
  }

  @override
  Widget build(BuildContext context) {
    return ExtendedImageGesturePageView.builder(
      itemBuilder: (context, index) {
        return _ImageContainer(
          path: widget.paths?[index],
          url: widget.urls?[index],
          imageUrlMap: imageUrlMap,
        );
      },
      controller: controller,
      itemCount: widget.paths?.length ?? widget.urls?.length ?? 0,
      scrollDirection: Axis.horizontal,
      // Using ‘preloadPagesCount’ will cause gesture conflict
      // preloadPagesCount: 1,
    );
  }

  @override
  void dispose() {
    // clearGestureDetailsCache();
    super.dispose();
  }
}

class _ImageContainer extends StatefulWidget {
  const _ImageContainer({
    super.key,
    required this.path,
    required this.url,
    required this.imageUrlMap,
  });

  final Map<String, FileInfoRespEntity> imageUrlMap;
  final String? path;
  final String? url;

  @override
  State<_ImageContainer> createState() => _ImageContainerState();
}

class _ImageContainerState extends State<_ImageContainer> {
  late GestureConfig gestureConfig;
  String? imageUrl;
  String? sign;
  String? thumb;

  @override
  void initState() {
    super.initState();
    gestureConfig = GestureConfig(
      minScale: 1,
      animationMinScale: 0.9,
      maxScale: 3.0,
      animationMaxScale: 3.5,
      speed: 1.0,
      inertialSpeed: 100.0,
      initialScale: 1.0,
      inPageView: true,
      cacheGesture: false,
      initialAlignment: InitialAlignment.center,
    );

    if (widget.path != null) {
      FileInfoRespEntity? fileInfo = widget.imageUrlMap[widget.path];
      if (fileInfo != null) {
        updateCurrentImageInfo(fileInfo);
      } else {
        _requestImageUrl();
      }
    } else {
      imageUrl = widget.url;
    }
  }

  void updateCurrentImageInfo(FileInfoRespEntity fileInfo) {
    imageUrl = fileInfo.rawUrl;
    sign = fileInfo.makeCacheUseSign(widget.path ?? "");
    thumb = fileInfo.thumb;
  }

  _requestImageUrl() async {
    var path = widget.path;
    var body = {
      "path": path,
      "password": "",
    };
    DioUtils.instance.requestNetwork<FileInfoRespEntity>(Method.post, "fs/get",
        params: body, onSuccess: (data) {
      if (data != null) {
        widget.imageUrlMap[widget.path ?? ""] = data;
        setState(() {
          updateCurrentImageInfo(data);
        });
      }
    }, onError: (code, message) {
      print("code:$code,message:$message");
    });
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    debugPrint("imageUrl:$imageUrl");
    return ExtendedImage.network(
      imageUrl!,
      cacheKey: sign,
      fit: BoxFit.contain,
      mode: ExtendedImageMode.gesture,
      initGestureConfigHandler: (state) {
        return gestureConfig;
      },
      onDoubleTap: (ExtendedImageGestureState state) {
        Log.d("currentScale=${state.gestureDetails?.totalScale}");
        var currentScale = state.gestureDetails?.totalScale ?? 1.0;
        if (currentScale >= 2.0) {
          state.handleDoubleTap(scale: 1);
        } else {
          state.handleDoubleTap(scale: min(currentScale + 1, 3));
        }
      },
    );
  }
}
