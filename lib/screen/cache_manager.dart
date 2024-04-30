import 'dart:async';
import 'dart:io';

import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/util/download/download_manager.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class CacheManagerScreen extends StatelessWidget {
  const CacheManagerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(CacheManagerController());
    return AlistScaffold(
      appbarTitle: Text(Intl.screenName_cacheManagement.tr),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: Text(Intl.cacheManagement_imageCache.tr),
              subtitle: Obx(() => Text(controller.imageCacheSizeStr.value)),
              onTap: () {
                controller.clearImageCache();
              },
            ),
            const Divider(),
            ListTile(
              title: Text(Intl.cacheManagement_audioCache.tr),
              subtitle: Obx(() => Text(controller.audioCacheSizeStr.value)),
              onTap: () {
                controller.clearAudioCache();
              },
            ),
            const Divider(),
            ListTile(
              title: Text(Intl.cacheManagement_otherCache.tr),
              subtitle: Obx(() => Text(controller.otherCacheSizeStr.value)),
              onTap: () {
                controller.clearOtherCache();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CacheManagerController extends GetxController {
  var _imageCacheSize = 0;
  var _audioCacheSize = 0;
  var _otherCacheSize = 0;
  var imageCacheSizeStr = "0 B".obs;
  var audioCacheSizeStr = "0 B".obs;
  var otherCacheSizeStr = "0 B".obs;

  final Set<String> _imageCachePaths = {};
  final Set<String> _audioCachePaths = {};
  String _downloadDir = "";

  @override
  void onInit() {
    super.onInit();
    _calculateCacheFilesSize();
  }

  void _calculateCacheFilesSize() async {
    var temporaryDirectory = await getTemporaryDirectory();
    _downloadDir = (await DownloadManager.acquireDownloadDirectory()).path;
    if (isClosed) {
      return;
    }
    _imageCachePaths.add(path.join(temporaryDirectory.path, "cacheimage"));
    _imageCachePaths
        .add(path.join(temporaryDirectory.path, "libCachedImageData"));
    _audioCachePaths
        .add(path.join(temporaryDirectory.path, "just_audio_cache"));

    await _calculateDirectoryFilesSize(temporaryDirectory);
  }

  Future<void> _calculateDirectoryFilesSize(Directory directory) async {
    if (isClosed) {
      return;
    }

    final completer = Completer<void>();

    late final StreamSubscription<FileSystemEntity> subscription;
    subscription = directory.list().listen((entity) async {
      subscription.pause();
      if (entity is File) {
        var path = entity.path;
        var filesSize = await entity.length();
        if (_checkIsImagePath(path)) {
          _imageCacheSize += filesSize;
          imageCacheSizeStr.value = _formatBytes(_imageCacheSize);
        } else if (_checkIsAudioPath(path)) {
          _audioCacheSize += filesSize;
          audioCacheSizeStr.value = _formatBytes(_audioCacheSize);
        } else if (path.startsWith(_downloadDir)) {
          // do nothing
        } else {
          _otherCacheSize += filesSize;
          debugPrint(entity.path);
          otherCacheSizeStr.value = _formatBytes(_otherCacheSize);
        }
      } else if (entity is Directory) {
        await _calculateDirectoryFilesSize(entity);
      }
      subscription.resume();
    }, onDone: () {
      completer.complete();
    });

    return completer.future;
  }

  bool _checkIsImagePath(String path) {
    for (var value in _imageCachePaths) {
      if (path.startsWith(value)) {
        return true;
      }
    }
    return false;
  }

  bool _checkIsAudioPath(String path) {
    for (var value in _audioCachePaths) {
      if (path.startsWith(value)) {
        return true;
      }
    }
    return false;
  }

  String _formatBytes(int bytes) {
    const int kilobyte = 1024;
    const int megabyte = kilobyte * 1024;
    const int gigabyte = megabyte * 1024;

    String format(double value) {
      if (value.truncate() == value) {
        // 是整数，不保留小数
        return value.toInt().toString();
      } else {
        // 保留一位小数
        return value.toStringAsFixed(1);
      }
    }

    if (bytes < kilobyte) {
      return '${format(bytes.toDouble())} B';
    } else if (bytes < megabyte) {
      return '${format(bytes / kilobyte)} KB';
    } else if (bytes < gigabyte) {
      return '${format(bytes / megabyte)} MB';
    } else {
      return '${format(bytes / gigabyte)} GB';
    }
  }

  Future<void> _deleteFilesByDirectory(Directory directory,
      {List<String>? excludePaths}) async {
    if (excludePaths != null) {
      for (var value in excludePaths) {
        if (directory.path.startsWith(value)) {
          return;
        }
      }
    }

    final completer = Completer<void>();

    late final StreamSubscription<FileSystemEntity> subscription;
    subscription = directory.list().listen((entity) async {
      subscription.pause();
      if (entity is File) {
        await entity.delete();
      } else if (entity is Directory) {
        await _deleteFilesByDirectory(entity, excludePaths: excludePaths);
      }
      subscription.resume();
    }, onDone: () {
      completer.complete();
    });

    return completer.future;
  }

  void clearImageCache() async {
    SmartDialog.showLoading(msg: Intl.cacheManagement_tips_clearing_cache.tr);
    for (var path in _imageCachePaths) {
      await _deleteFilesByDirectory(Directory(path));
    }
    _imageCacheSize = 0;
    imageCacheSizeStr.value = "0 B";
    SmartDialog.dismiss();
  }

  void clearAudioCache() async {
    SmartDialog.showLoading(msg: Intl.cacheManagement_tips_clearing_cache.tr);
    for (var path in _audioCachePaths) {
      await _deleteFilesByDirectory(Directory(path));
    }
    _audioCacheSize = 0;
    audioCacheSizeStr.value = "0 B";
    SmartDialog.dismiss();
  }

  void clearOtherCache() async {
    SmartDialog.showLoading(msg: Intl.cacheManagement_tips_clearing_cache.tr);
    var temporaryDirectory = await getTemporaryDirectory();
    var excludePaths = <String>[];
    excludePaths.addAll(_imageCachePaths);
    excludePaths.addAll(_audioCachePaths);
    excludePaths.add(_downloadDir);
    await _deleteFilesByDirectory(temporaryDirectory,
        excludePaths: excludePaths);

    _otherCacheSize = 0;
    otherCacheSizeStr.value = "0 B";
    SmartDialog.dismiss();
  }
}
