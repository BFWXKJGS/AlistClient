import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/database/table/video_viewing_record.dart';
import 'package:alist/util/download_utils.dart';
import 'package:alist/util/file_utils.dart';
import 'package:alist/util/log_utils.dart';
import 'package:alist/util/string_utils.dart';
import 'package:alist/util/user_controller.dart';
import 'package:alist/widget/file_list_item_view.dart';
import 'package:alist/widget/player_skin.dart';
import 'package:dio/dio.dart';
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
  final List<FileItemVO> videos = Get.arguments["videos"];
  int index = Get.arguments["index"] ?? 0;
  final CancelToken _cancelToken = CancelToken();
  final FlutterAliplayer _fAliplayer =
      FlutterAliPlayerFactory.createAliPlayer();
  String? _videoTitle;
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
        SmartDialog.showToast("将自动播放下一个");
        _playNext();
      }
    });
    LogUtil.d("currentIndex=$index");

    var currentVideo = videos[index];
    _videoTitle = currentVideo.name.substringBeforeLast(".");
    _playWithProxyUrl(currentVideo);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  void _playWithProxyUrl(FileItemVO file) async {
    var cacheDir = await DownloadUtils.findDownloadDir("video");
    FlutterAliplayer.enableLocalCache(
        true, "${1024 * 100}", cacheDir.path, DocTypeForIOS.caches);
    LogUtil.d("cacheDir=$cacheDir");

    var target = await FileUtils.makeFileLink(file.path, file.sign);
    if (target != null) {
      var url = target.toString();
      var config = AVPConfig();
      if (file.provider == "BaiduNetdisk") {
        config.userAgent = "pan.baidu.com";
      }
      config.enableProjection = true;
      _fAliplayer.setPlayConfig(config);
      _fAliplayer.setUrl(url);

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
    return Container(
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
              if (currentPos < 10 * 1000 || (currentPos / 1000) % 10 != 0) {
                _currentPos = currentPos;
                _duration = duration;
              } else {
                _saveViewingRecord(currentPos, duration);
              }
            },
          )
        ],
      ),
    );
  }

  Future<void> _findAndCacheViewingRecord(FileItemVO file) async {
    final userId = _userController.user().username;
    final baseUrl = _userController.user().baseUrl;
    var record = await _database.videoViewingRecordDao
        .findRecordByPath(baseUrl, userId, file.path);
    if (record != null) {
      Log.d("findAndCacheViewingRecord");
      _videoViewingRecord = record;
      _fAliplayer.seekTo(record.videoCurrentPosition, FlutterAvpdef.ACCURATE);
    } else {
      Log.d("no findAndCacheViewingRecord");
    }
    _fAliplayer.prepare();
  }

  Future<void> _saveViewingRecord(int currentPos, int duration) async {
    final userId = _userController.user().username;
    final baseUrl = _userController.user().baseUrl;
    final sign = videos[index].sign;
    final path = videos[index].path;

    var record = _videoViewingRecord;
    Log.d(
        "record = ${record?.id} ${record?.videoSign} ${record?.videoCurrentPosition} ${record?.videoDuration}");
    if (record == null) {
      var videoViewingRecord = VideoViewingRecord(
          serverUrl: baseUrl,
          userId: userId,
          videoSign: sign,
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
        videoSign: sign,
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

  _playNext() {
    LogUtil.d("_playNext");
    if (index < videos.length - 1) {
      index++;
      _videoTitle = videos[index].name.substringBeforeLast(".");
      _playWithProxyUrl(videos[index]);
      setState(() {});
    }
  }
}
