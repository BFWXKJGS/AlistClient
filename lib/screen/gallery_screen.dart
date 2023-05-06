import 'package:alist/entity/file_info_resp_entity.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen(
      {Key? key, required this.paths, required this.initializedIndex})
      : super(key: key);

  final List<String> paths;
  final int initializedIndex;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _ImagesContainer(paths: paths, initialPage: initializedIndex),
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
  const _ImagesContainer(
      {super.key, required this.paths, required this.initialPage});

  final List<String> paths;
  final int initialPage;

  @override
  State<_ImagesContainer> createState() => _ImagesContainerState();
}

class _ImagesContainerState extends State<_ImagesContainer> {
  late ExtendedPageController controller;
  final Map<String, String> imageUrlMap = {};

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
          path: widget.paths[index],
          imageUrlMap: imageUrlMap,
        );
      },
      controller: controller,
      itemCount: widget.paths.length,
      scrollDirection: Axis.horizontal,
    );
  }
}

class _ImageContainer extends StatefulWidget {
  const _ImageContainer({
    super.key,
    required this.path,
    required this.imageUrlMap,
  });

  final Map<String, String> imageUrlMap;
  final String path;

  @override
  State<_ImageContainer> createState() => _ImageContainerState();
}

class _ImageContainerState extends State<_ImageContainer> {
  late GestureConfig gestureConfig;
  String? imageUrl;
  String? sign;

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
      initialAlignment: InitialAlignment.center,
    );

    String? imageUrl = widget.imageUrlMap[widget.path];
    if (imageUrl != null) {
      this.imageUrl = imageUrl;
    } else {
      requestImageUrl();
    }
  }

  requestImageUrl() async {
    var path = widget.path;
    var body = {
      "path": path,
      "password": "",
    };
    DioUtils.instance.requestNetwork<FileInfoRespEntity>(Method.post, "fs/get",
        params: body, onSuccess: (data) {
      var url = data?.rawUrl;
      if (url != null) {
        widget.imageUrlMap[widget.path] = url;
      }
      setState(() {
        imageUrl = url;
        sign = data?.sign;
      });
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
    );
  }
}
