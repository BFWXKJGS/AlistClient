import 'dart:io';
import 'dart:math';

import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/util/alist_plugin.dart';
import 'package:alist/util/file_utils.dart';
import 'package:alist/util/string_utils.dart';
import 'package:alist/widget/file_list_item_view.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

typedef OnMenuClickCallback = Function(MenuId menuId);

const menuWidth = 140.0;

class GalleryScreen extends StatelessWidget {
  GalleryScreen({Key? key}) : super(key: key);

  final List<String>? urls = Get.arguments["urls"];
  final List<FileItemVO>? files = Get.arguments["files"];
  final int initializedIndex = Get.arguments["index"];

  // use key to get the more icon's location and size
  final GlobalKey _moreIconKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    GalleryController controller = Get.put(GalleryController(
      urls: urls,
      files: files,
      index: initializedIndex,
    ));
    Widget widget = Stack(
      children: [
        _buildImageViewPager(controller),
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          child: _buildAppBar(controller),
        )
      ],
    );

    return GalleryMenuAnchor(
        controller: controller,
        child: widget,
        onMenuClickCallback: (menuId) {
          switch (menuId) {
            case MenuId.copyLink:
              Clipboard.setData(
                  ClipboardData(text: controller.urls[controller.index.value]));
              SmartDialog.showToast(Intl.galleryScreen_copied.tr);
              break;
            case MenuId.saveToAlbum:
              controller.saveToAlbum(controller.index.value);
              break;
          }
        });
  }

  AppBar _buildAppBar(GalleryController controller) {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      title: controller.files == null
          ? null
          : Obx(() => Text(
                controller.files?[controller.index.value].name ?? "",
                style: const TextStyle(color: Colors.white),
              )),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      actions: [_menuMoreIcon(controller)],
    );
  }

  Widget _buildImageViewPager(GalleryController controller) {
    return Obx(
      () => ExtendedImageGesturePageView.builder(
        itemBuilder: (context, index) {
          return _ImageContainer(
            url: controller.urls[index],
          );
        },
        controller: controller.pageController,
        onPageChanged: (index) {
          controller.updateIndex(index);
        },
        itemCount: controller.urls.length,
        scrollDirection: Axis.horizontal,
      ),
    );
  }

  IconButton _menuMoreIcon(GalleryController controller) {
    return IconButton(
      key: _moreIconKey,
      onPressed: () {
        var menuController = controller.menuController;
        RenderObject? renderObject =
            _moreIconKey.currentContext?.findRenderObject();
        if (renderObject is RenderBox) {
          var position = renderObject.localToGlobal(Offset.zero);
          var size = renderObject.size;
          menuController.open(
              position: Offset(position.dx + size.width - menuWidth - 10,
                  position.dy + size.height));
        }
      },
      icon: const Icon(Icons.more_horiz_rounded),
    );
  }
}

class GalleryController extends GetxController {
  final urls = <String>[].obs;
  final List<FileItemVO>? files;
  final index = 0.obs;
  final isMenuOpen = false.obs;
  late ExtendedPageController pageController;
  final menuController = MenuController();

  GalleryController(
      {required List<String>? urls, required this.files, required int index})
      : super() {
    this.urls.value = urls ?? [];
    this.index.value = index;
    pageController = ExtendedPageController(initialPage: index);
  }

  @override
  void onInit() {
    super.onInit();
    if (files != null && files!.isNotEmpty) {
      _initUrls(files!);
    }
  }

  Future<void> _initUrls(List<FileItemVO> files) async {
    List<String> urls = [];
    for (var file in files) {
      var url = await FileUtils.makeFileLink(file.path, file.sign);
      if (url == null) {
        break;
      }
      urls.add(url);
    }
    this.urls.value = urls;
  }

  void updateIndex(int index) {
    this.index.value = index;
  }

  Future<void> saveToAlbum(int index) async {
    if (Platform.isAndroid &&
        await AlistPlugin.isScopedStorage()) {
      if (!await Permission.storage.isGranted) {
        var storagePermissionStatus = await Permission.storage.request();
        if (!storagePermissionStatus.isGranted) {
          SmartDialog.showToast(Intl.galleryScreen_storagePermissionDenied.tr);
          return;
        }
      }
    }

    var name = files?[index].name;
    var url = urls[index];
    name ??= Uri.parse(url).path.substringAfterLast("/")!;

    var cacheFile = await getCachedImageFile(url);
    if (cacheFile == null) {
      SmartDialog.showToast(Intl.galleryScreen_loadPhotoFailed.tr);
      return;
    }

    if (Platform.isIOS) {
      var copyFile = "${File(cacheFile.path).parent.path}/$name";
      await cacheFile.rename(copyFile);
      await ImageGallerySaver.saveFile(copyFile, name: name);
      await File(copyFile).delete();
    } else {
      var now = DateTime.now().millisecond;
      String extension = "";
      if (name.contains(".")) {
        extension = name.substringAfterLast(".")!;
      }
      if (extension.isEmpty) {
        extension = ".jpg";
      }

      name = "${now}_$extension";
      await ImageGallerySaver.saveFile(cacheFile.path, name: name);
    }
  }
}

class _ImageContainer extends StatelessWidget {
  const _ImageContainer({
    super.key,
    required this.url,
  });

  final String url;

  @override
  Widget build(BuildContext context) {
    var gestureConfig = GestureConfig(
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

    return ExtendedImage.network(
      url,
      fit: BoxFit.contain,
      mode: ExtendedImageMode.gesture,
      initGestureConfigHandler: (state) {
        return gestureConfig;
      },
      onDoubleTap: (ExtendedImageGestureState state) {
        // Log.d("currentScale=${state.gestureDetails?.totalScale}");
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

class GalleryMenuAnchor extends StatelessWidget {
  final GalleryController controller;
  final Widget child;
  final OnMenuClickCallback? onMenuClickCallback;

  const GalleryMenuAnchor({
    super.key,
    required this.controller,
    required this.child,
    this.onMenuClickCallback,
  });

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: const MenuStyle(
          fixedSize: MaterialStatePropertyAll(Size.fromWidth(menuWidth))),
      controller: controller.menuController,
      anchorTapClosesMenu: true,
      onOpen: () {
        controller.isMenuOpen.value = true;
      },
      onClose: () {
        controller.isMenuOpen.value = false;
      },
      menuChildren: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: _buildMenus(
            menuWidth,
            onMenuClickCallback,
          ),
        ),
      ],
      child: Obx(
        () => AbsorbPointer(
          absorbing: controller.isMenuOpen.value,
          child: child,
        ),
      ),
    );
  }

  List<Widget> _buildMenus(
      double menuWidth, OnMenuClickCallback? onMenuClickCallback) {
    var copyButton = MenuItemButton(
        child: Text(Intl.galleryScreen_menu_copyLink.tr),
        onPressed: () => onMenuClickCallback?.call(MenuId.copyLink));
    var saveButton = MenuItemButton(
        child: Text(Intl.galleryScreen_menu_saveToAlbum.tr),
        onPressed: () => onMenuClickCallback?.call(MenuId.saveToAlbum));
    return [
      SizedBox(
        width: menuWidth,
      ),
      copyButton,
      saveButton,
    ];
  }
}

enum MenuId { copyLink, saveToAlbum }
