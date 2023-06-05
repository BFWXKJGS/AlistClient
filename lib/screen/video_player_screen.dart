import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/database/table/video_viewing_record.dart';
import 'package:alist/entity/file_info_resp_entity.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/util/file_sign_utils.dart';
import 'package:alist/util/log_utils.dart';
import 'package:alist/util/string_utils.dart';
import 'package:alist/util/user_controller.dart';
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
  final FlutterAliplayer _fAliplayer =
      FlutterAliPlayerFactory.createAliPlayer();
  String? _videoTitle;
  String? _sign;
  final AlistDatabaseController _database = Get.find();
  final UserController _userController = Get.find();
  VideoViewingRecord? _videoViewingRecord;
  int _currentPos = 0;
  int _duration = 0;

  @override
  void initState() {
    super.initState();
    _fAliplayer.setAutoPlay(true);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _findAndCacheViewingRecord(path);
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
        _fAliplayer.setUrl(url);
        if (_videoViewingRecord != null &&
            _videoViewingRecord!.videoSign == data?.makeCacheUseSign(path)) {
          Log.d(
              "Aliplayer seek to ${_videoViewingRecord!.videoCurrentPosition}");
          _fAliplayer.seekTo(_videoViewingRecord!.videoCurrentPosition,
              FlutterAvpdef.ACCURATE);
        } else {
          // invalid cache.
        }
        _fAliplayer.prepare();

        setState(() {
          _videoTitle = data?.name.substringBeforeLast(".") ?? "";
          _sign = data?.makeCacheUseSign(path);
        });
      },
      onError: (code, message) {
        SmartDialog.showToast(message);
      },
    );
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

  Future<void> _findAndCacheViewingRecord(String path) async {
    final userId = _userController.user().username;
    final baseUrl = _userController.user().baseUrl;
    var record =
        await _database.videoViewingRecordDao.findRecordByPath(baseUrl, userId, path);
    if (record != null) {
      Log.d("findAndCacheViewingRecord");
      _videoViewingRecord = record;
    } else {
      Log.d("no findAndCacheViewingRecord");
    }
  }

  Future<void> _saveViewingRecord(int currentPos, int duration) async {
    final userId = _userController.user().username;
    final baseUrl = _userController.user().baseUrl;
    var sign = _sign;
    if (sign != null) {
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
        _database.videoViewingRecordDao.insertRecord(videoViewingRecord).then((id) {
          Log.d("insert record id=$id");
          _videoViewingRecord = VideoViewingRecord(
              id: id,
              serverUrl: videoViewingRecord.serverUrl,
              userId: videoViewingRecord.userId,
              videoSign: videoViewingRecord.videoSign,
              path: videoViewingRecord.path,
              videoCurrentPosition: videoViewingRecord.videoCurrentPosition,
              videoDuration: videoViewingRecord.videoDuration);
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
}
