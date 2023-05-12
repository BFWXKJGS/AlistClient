import 'dart:async';
import 'dart:io';

import 'package:alist/entity/file_info_resp_entity.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/util/string_utils.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:alist/widget/slider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_aliplayer/flutter_aliplayer.dart';
import 'package:flutter_aliplayer/flutter_aliplayer_factory.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({Key? key}) : super(key: key);

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen>{
  final String path = Get.arguments["path"];
  final FlutterAliplayer _audioPlayer =
      FlutterAliPlayerFactory.createAliPlayer();
  final CancelToken _cancelToken = CancelToken();
  String? _name;

  Duration _duration = const Duration();
  Duration _currentPos = const Duration();
  Duration _bufferPos = const Duration();

  bool _playing = false;
  bool _prepared = false;
  String? _exception;

  double _seekPos = -1.0;
  StreamSubscription? _currentPosSubs;
  StreamSubscription? _bufferPosSubs;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setAutoPlay(true);
    var path = this.path;
    _requestAudioUrlAndPlay(path);
    if (Platform.isIOS) {
      FlutterAliplayer.enableMix(true);
    }

    _audioPlayer.setOnInfo((infoCode, extraValue, extraMsg, playerId) {
      if (infoCode == FlutterAvpdef.CURRENTPOSITION) {
        setState(() {
          _currentPos = Duration(milliseconds: extraValue!);
        });
      } else if (infoCode == FlutterAvpdef.BUFFEREDPOSITION) {
        setState(() {
          _bufferPos = Duration(milliseconds: extraValue!);
        });
      }
    });
    _audioPlayer.setOnStateChanged((newState, _) async {
      switch (newState) {
        // idle time
        case FlutterAvpdef.AVPStatus_AVPStatusIdle:
          break;
        // initialization completed
        case FlutterAvpdef.AVPStatus_AVPStatusInitialzed:
          break;
        // ready
        case FlutterAvpdef.AVPStatus_AVPStatusPrepared:
          dynamic mediaInfo = await _audioPlayer.getMediaInfo();
          setState(() {
            _duration = Duration(milliseconds: mediaInfo['duration']);
            _prepared = true;
          });
          break;
        case FlutterAvpdef.AVPStatus_AVPStatusStarted:
          setState(() {
            _playing = true;
          });
          break;
        case FlutterAvpdef.AVPStatus_AVPStatusPaused:
          setState(() {
            _playing = false;
          });
          break;
        case FlutterAvpdef.AVPStatus_AVPStatusStopped:
          setState(() {
            _playing = false;
          });
          break;
        case FlutterAvpdef.AVPStatus_AVPStatusCompletion:
          setState(() {
            _playing = false;
          });
          break;
        case FlutterAvpdef.AVPStatus_AVPStatusError:
          setState(() {
            _exception = newState.toString();
            _playing = false;
          });
          break;
      }
    });
  }

  void _requestAudioUrlAndPlay(String path) {
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
        if (!_cancelToken.isCancelled) {
          String cacheKey = data?.sign ?? path.md5String();
          cacheKey = "${cacheKey}_${data?.size ?? 0}";

          var url = data?.rawUrl;
          _name = data?.name;
          _audioPlayer.setUrl(url!);
          _audioPlayer.prepare();
          setState(() {});
        }
      },
      onError: (code, message) {
        SmartDialog.showToast(message);
        debugPrint("code:$code,message:$message");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double duration = _duration.inMilliseconds.toDouble();
    double currentValue =
        _seekPos > 0 ? _seekPos : _currentPos.inMilliseconds.toDouble();

    return AlistScaffold(
      appbarTitle: const SizedBox(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 30, bottom: 10),
              child: Text(_name ?? ""),
            ),
            Container(
              width: double.infinity,
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: _buildFijkSlider(currentValue, duration),
            ),
            _PlayButton(playing: _playing, onPressed: _playOrPause),
          ],
        ),
      ),
    );
  }

  Widget _buildFijkSlider(double currentValue, double duration) {
    if (!_prepared) {
      return const SizedBox();
    }

    return FijkSlider(
      value: currentValue,
      cacheValue: _bufferPos.inMilliseconds.toDouble(),
      min: 0.0,
      max: duration,
      onChanged: (v) {
        // _startHideTimer();
        setState(() {
          _seekPos = v;
        });
      },
      onChangeEnd: (v) {
        setState(() {
          _audioPlayer.seekTo(v.toInt(), FlutterAvpdef.ACCURATE);
          debugPrint("seek to $v");
          _currentPos = Duration(milliseconds: _seekPos.toInt());
          _seekPos = -1;
        });
      },
    );
  }

  void _playOrPause() async {
    if (_playing == true) {
      _audioPlayer.pause();
    } else {
      if (_duration.inMilliseconds == _currentPos.inMilliseconds) {
        await _audioPlayer.seekTo(0, FlutterAvpdef.ACCURATE);
      }
      _audioPlayer.play();
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (Platform.isIOS) {
      FlutterAliplayer.enableMix(true);
    }
    _cancelToken.cancel();
    _releasePlayer();

    _currentPosSubs?.cancel();
    _bufferPosSubs?.cancel();
  }

  void _releasePlayer() async {
    _audioPlayer.stop();
    _audioPlayer.destroy();
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({Key? key, required this.playing, required this.onPressed})
      : super(key: key);
  final VoidCallback onPressed;

  final bool playing;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 50,
      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
      onPressed: onPressed,
    );
  }
}
