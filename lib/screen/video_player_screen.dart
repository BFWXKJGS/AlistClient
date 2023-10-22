import 'dart:io';

import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/database/table/file_viewing_record.dart';
import 'package:alist/database/table/video_viewing_record.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/util/download/download_manager.dart';
import 'package:alist/util/file_utils.dart';
import 'package:alist/util/log_utils.dart';
import 'package:alist/util/proxy.dart';
import 'package:alist/util/string_utils.dart';
import 'package:alist/util/user_controller.dart';
import 'package:alist/widget/player_skin.dart';
import 'package:dio/dio.dart';
import 'package:floor/floor.dart';
import 'package:flustars/flustars.dart';
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
  final List<VideoItem> videos = Get.arguments["videos"];
  int index = Get.arguments["index"] ?? 0;
  final CancelToken _cancelToken = CancelToken();
  final FlutterAliplayer _fAliplayer =
      FlutterAliPlayerFactory.createAliPlayer();
  String? _videoTitle;
  final ProxyServer _proxyServer = Get.find();
  final AlistDatabaseController _database = Get.find();
  final UserController _userController = Get.find();
  VideoViewingRecord? _videoViewingRecord;
  int _currentPos = 0;
  int _duration = 0;

  @override
  void initState() {
    super.initState();
    _fAliplayer.setAutoPlay(true);
    _fAliplayer.setOnCompletion((playerId) {
      if (index < videos.length - 1) {
        SmartDialog.showToast(Intl.videoPlayerScreen_tips_playNext.tr);
        _playNext();
      }
    });
    LogUtil.d("currentIndex=$index");

    var currentVideo = videos[index];
    _videoTitle = currentVideo.name.substringBeforeLast(".");
    _playWithProxyUrl(currentVideo);
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  void _playWithProxyUrl(VideoItem file) async {
    var cacheDir = await DownloadManager.findDownloadDir("video");
    FlutterAliplayer.enableLocalCache(
        true, "${1024 * 100}", cacheDir.path, DocTypeForIOS.caches);
    LogUtil.d("cacheDir=$cacheDir");
    if (Platform.isAndroid) {
      await _fAliplayer
          .setScalingMode(FlutterAvpdef.AVP_SCALINGMODE_SCALETOFILL);
    }

    if (file.localPath == null || file.localPath!.isEmpty) {
      // find local path from database
      final user = _userController.user();
      var record = await _database.downloadRecordRecordDao
          .findRecordByRemotePath(
              user.serverUrl, user.username, file.remotePath);
      if (record != null && File(record.localPath).existsSync()) {
        file.localPath = record.localPath;
      }
    }
    LogUtil.d("localPath=${file.localPath}");
    if (file.localPath?.isNotEmpty == true) {
      await _fAliplayer.setUrl(file.localPath!);
      _findAndCacheViewingRecord(file);
      return;
    }

    var target = await FileUtils.makeFileLink(file.remotePath, file.sign);
    if (target != null) {
      var url = target.toString();
      LogUtil.d("provider=${file.provider}");
      if (file.provider == "BaiduNetdisk") {
        await _proxyServer.start();
        var uri = _proxyServer.makeProxyUrl(url,
            headers: {HttpHeaders.userAgentHeader: "pan.baidu.com"});
        await _fAliplayer.setUrl(uri.toString());
      } else {
        await _fAliplayer.setUrl(url);
      }

      _findAndCacheViewingRecord(file);
    }
  }

  void onViewPlayerCreated(viewId) async {
    /// bind player view
    _fAliplayer.setPlayerView(viewId);
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
    return AnnotatedRegion(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          color: Colors.black,
          width: width,
          height: height,
          child: Stack(
            children: [
              aliPlayerView,
              AlistPlayerSkin(
                player: _fAliplayer,
                buildContext: context,
                videoTitle: _videoTitle ?? "",
                playPreviousCallback: index == 0 ? null : () => _playPrevious(),
                playNextCallback:
                    index == videos.length - 1 ? null : () => _playNext(),
                onPlayProgressChange: (currentPos, duration) {
                  if (_currentPos >= duration - 1000) {
                    _deleteViewingRecord();
                  } else if (currentPos < 10 * 1000 ||
                      (currentPos / 1000) % 10 != 0) {
                    _currentPos = currentPos;
                    _duration = duration;
                  } else {
                    _saveViewingRecord(currentPos, duration);
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _findAndCacheViewingRecord(VideoItem file) async {
    final userId = _userController.user().username;
    final baseUrl = _userController.user().baseUrl;
    var record = await _database.videoViewingRecordDao
        .findRecordByPath(baseUrl, userId, file.remotePath);
    if (record != null) {
      Log.d("findAndCacheViewingRecord");
      _videoViewingRecord = record;
      _fAliplayer.seekTo(record.videoCurrentPosition, FlutterAvpdef.ACCURATE);
    } else {
      Log.d("no findAndCacheViewingRecord");
    }
    _fAliplayer.prepare();
  }

  void _deleteViewingRecord() async {
    final userId = _userController.user().username;
    final baseUrl = _userController.user().baseUrl;
    final path = videos[index].remotePath;
    var record = await _database.videoViewingRecordDao
        .findRecordByPath(baseUrl, userId, path);
    if (record != null) {
      await _database.videoViewingRecordDao.deleteRecord(record);
    }
  }

  Future<void> _saveViewingRecord(int currentPos, int duration) async {
    final userId = _userController.user().username;
    final baseUrl = _userController.user().baseUrl;
    final sign = videos[index].sign;
    final path = videos[index].remotePath;

    var record = _videoViewingRecord;
    Log.d(
        "record = ${record?.id} ${record?.videoSign} ${record?.videoCurrentPosition} ${record?.videoDuration}");
    if (record == null) {
      var videoViewingRecord = VideoViewingRecord(
          serverUrl: baseUrl,
          userId: userId,
          videoSign: sign ?? "",
          path: path,
          videoCurrentPosition: currentPos,
          videoDuration: duration);
      _database.videoViewingRecordDao
          .insertRecord(videoViewingRecord)
          .then((id) {
        Log.d("insert record id=$id");
        _videoViewingRecord = VideoViewingRecord(
          id: id,
          serverUrl: videoViewingRecord.serverUrl,
          userId: videoViewingRecord.userId,
          videoSign: videoViewingRecord.videoSign,
          path: videoViewingRecord.path,
          videoCurrentPosition: videoViewingRecord.videoCurrentPosition,
          videoDuration: videoViewingRecord.videoDuration,
        );
      });
    } else {
      Log.d("update record");
      _database.videoViewingRecordDao.updateRecord(VideoViewingRecord(
        id: record.id,
        serverUrl: baseUrl,
        userId: userId,
        videoSign: sign ?? "",
        path: path,
        videoCurrentPosition: currentPos,
        videoDuration: duration,
      ));
    }
  }

  @override
  void dispose() {
    _releasePlayer();
    _cancelToken.cancel();
    if (_duration > 0) {
      _saveViewingRecord(_currentPos, _duration);
    }
    _proxyServer.stop();
    super.dispose();
  }

  void _releasePlayer() {
    _fAliplayer.destroy();
  }

  _playPrevious() {
    LogUtil.d("_playPrevious");
    if (index > 0) {
      index--;
      _videoTitle = videos[index].name.substringBeforeLast(".");
      _playWithProxyUrl(videos[index]);
      setState(() {});
    }
  }

  _playNext() async {
    LogUtil.d("_playNext");
    if (index < videos.length - 1) {
      index++;
      _videoTitle = videos[index].name.substringBeforeLast(".");
      _playWithProxyUrl(videos[index]);
      _fileViewingRecord(videos[index]);
      setState(() {});
    }
  }

  @transaction
  Future<void> _fileViewingRecord(VideoItem file) async {
    var user = _userController.user.value;
    AlistDatabaseController databaseController =
        Get.find<AlistDatabaseController>();
    var recordData = databaseController.fileViewingRecordDao;
    await recordData.deleteByPath(
        user.serverUrl, user.username, file.remotePath);
    await recordData.insertRecord(FileViewingRecord(
      serverUrl: user.serverUrl,
      userId: user.username,
      remotePath: file.remotePath,
      name: file.name,
      path: file.remotePath,
      size: file.size ?? 0,
      sign: file.sign,
      thumb: file.thumb,
      modified: file.modifiedMilliseconds ?? 0,
      provider: file.provider ?? "",
      createTime: DateTime.now().millisecondsSinceEpoch,
    ));
  }
}

class VideoItem {
  final String name;
  String? localPath;
  final String remotePath;
  final String? sign;
  final String? provider;
  final String? thumb;
  final int? size;
  final int? modifiedMilliseconds;

  VideoItem({
    required this.name,
    this.localPath,
    required this.remotePath,
    this.sign,
    this.provider,
    required this.thumb,
    required this.size,
    required this.modifiedMilliseconds,
  });
}
