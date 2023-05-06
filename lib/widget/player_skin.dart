import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:alist/generated/l10n.dart';
import 'package:alist/widget/slider.dart';
import 'package:auto_orientation/auto_orientation.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_aliplayer/flutter_aliplayer.dart';
import 'package:wakelock/wakelock.dart';

/// Default Panel Widget
class AlistPlayerSkin extends StatefulWidget {
  final FlutterAliplayer player;
  final BuildContext buildContext;
  final String videoTitle;
  final VoidCallback retryCallback;

  const AlistPlayerSkin({
    super.key,
    required this.player,
    required this.buildContext,
    required this.videoTitle,
    required this.retryCallback,
  });

  @override
  AlistPlayerSkinState createState() => AlistPlayerSkinState();
}

String _duration2String(Duration duration) {
  if (duration.inMilliseconds < 0) return "-: negtive";

  String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  int inHours = duration.inHours;
  return inHours > 0
      ? "$inHours:$twoDigitMinutes:$twoDigitSeconds"
      : "$twoDigitMinutes:$twoDigitSeconds";
}

class AlistPlayerSkinState extends State<AlistPlayerSkin> {
  static const String tag = "AlistPlayerSkinState";

  FlutterAliplayer get _player => widget.player;

  // Total video length of this
  Duration _duration = const Duration();
  // The current playing time of this video
  Duration _currentPos = const Duration();
  // The current cache length of this video
  Duration _bufferPos = const Duration();

  // is wakelock enable
  bool _wakelockEnable = false;
  // whether the video is playing in full screen
  bool _fullscreen = false;
  bool _playing = false;
  bool _prepared = false;
  String? _exception;

  double _seekPos = -1.0;
  StreamSubscription? _currentPosSubs;
  StreamSubscription? _bufferPosSubs;

  Timer? _hideTimer;
  bool _hideStuff = true;

  double _volume = 1.0;

  final barHeight = 40.0;

  @override
  void initState() {
    super.initState();
    _enableWakelock();

    //开启混音模式
    if (Platform.isIOS) {
      FlutterAliplayer.enableMix(true);
    }
    _player.setOnInfo((infoCode, extraValue, extraMsg, playerId) {
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

    _player.setOnStateChanged((newState, _) async {
      switch (newState) {
        // idle time
        case FlutterAvpdef.AVPStatus_AVPStatusIdle:
          break;
        // initialization completed
        case FlutterAvpdef.AVPStatus_AVPStatusInitialzed:
          _enableWakelock();
          break;
        // ready
        case FlutterAvpdef.AVPStatus_AVPStatusPrepared:
          _player.getMediaInfo().then((value) {
            setState(() {
              _duration = Duration(milliseconds: value['duration']);
            });
          });
          _prepared = true;
          break;
        case FlutterAvpdef.AVPStatus_AVPStatusStarted:
          _setPlaying(true);
          break;
        case FlutterAvpdef.AVPStatus_AVPStatusPaused:
          _setPlaying(false);
          break;
        case FlutterAvpdef.AVPStatus_AVPStatusStopped:
          _setPlaying(false);
          break;
        case FlutterAvpdef.AVPStatus_AVPStatusCompletion:
          _setPlaying(false);
          break;
        case FlutterAvpdef.AVPStatus_AVPStatusError:
          break;
      }
    });

    _player.setOnError((errorCode, errorExtra, errorMsg, playerId) {
      LogUtil.d("errorCode=$errorCode errorMsg=$errorMsg", tag: tag);
      _setPlaying(false, exception: errorMsg);
    });
  }

  void _setPlaying(bool playing, {String? exception}) {
    if (_playing != playing || exception != null) {
      setState(() {
        _playing = playing;
        if (exception != null) {
          _exception = exception;
        }
      });

      if (playing) {
        _enableWakelock();
      } else {
        _disableWakelock();
      }
    }
  }

  void _enableWakelock() {
    if (!_wakelockEnable) {
      Wakelock.enable();
      _wakelockEnable = true;
    }
  }

  void _disableWakelock() {
    if (!_wakelockEnable) {
      Wakelock.disable();
      _wakelockEnable = false;
    }
  }

  void _playOrPause() async {
    if (_playing == true) {
      _player.pause();
    } else {
      if (_duration.inMilliseconds == _currentPos.inMilliseconds) {
        await _player.seekTo(0, FlutterAvpdef.ACCURATE);
      }
      _player.play();
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (Platform.isIOS) {
      FlutterAliplayer.enableMix(true);
    }
    _hideTimer?.cancel();
    _disableWakelock();

    _currentPosSubs?.cancel();
    _bufferPosSubs?.cancel();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _cancelAndRestartTimer() {
    if (_hideStuff == true) {
      _startHideTimer();
    }
    setState(() {
      _hideStuff = !_hideStuff;
    });
  }

  Widget _buildVolumeButton() {
    IconData iconData;
    if (_volume <= 0) {
      iconData = Icons.volume_off;
    } else {
      iconData = Icons.volume_up;
    }
    return IconButton(
      icon: Icon(iconData, color: Colors.white),
      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
      onPressed: () {
        setState(() {
          _volume = _volume > 0 ? 0.0 : 1.0;
          _player.setVolume(_volume);
        });
      },
    );
  }

  AnimatedOpacity _buildBottomBar(BuildContext context) {
    double duration = _duration.inMilliseconds.toDouble();
    double currentValue =
        _seekPos > 0 ? _seekPos : _currentPos.inMilliseconds.toDouble();
    currentValue = min(currentValue, duration);
    currentValue = max(currentValue, 0);
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 0.8,
      duration: const Duration(milliseconds: 400),
      child: SizedBox(
        height: barHeight,
        child: Row(
          children: <Widget>[
            _buildVolumeButton(),
            Padding(
              padding: const EdgeInsets.only(right: 5.0, left: 5),
              child: Text(
                _duration2String(_currentPos),
                style: const TextStyle(fontSize: 14.0, color: Colors.white),
              ),
            ),

            _duration.inMilliseconds == 0
                ? const Expanded(child: Center())
                : Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 0, left: 0),
                      child: FijkSlider(
                        value: currentValue,
                        cacheValue: _bufferPos.inMilliseconds.toDouble(),
                        min: 0.0,
                        max: duration,
                        onChanged: (v) {
                          _startHideTimer();
                          setState(() {
                            _seekPos = v;
                          });
                        },
                        onChangeEnd: (v) {
                          setState(() {
                            _player.seekTo(v.toInt(), FlutterAvpdef.INACCURATE);
                            debugPrint("seek to $v");
                            _currentPos =
                                Duration(milliseconds: _seekPos.toInt());
                            _seekPos = -1;
                          });
                        },
                      ),
                    ),
                  ),

            // duration / position
            _DurationTextWidget(
              duration: _duration,
              prepared: _prepared,
            ),

            IconButton(
              icon: Icon(
                _fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.white,
              ),
              padding: const EdgeInsets.only(left: 10.0, right: 10.0),
              onPressed: () {
                if (_fullscreen) {
                  _exitFullScreen();
                } else {
                  _enterFullScreen();
                }
              },
            )
            //
          ],
        ),
      ),
    );
  }

  void _enterFullScreen() async {
    await AutoOrientation.landscapeAutoMode();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    setState(() {
      _fullscreen = true;
    });
  }

  void _exitFullScreen() async {
    await AutoOrientation.portraitAutoMode();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]).then((value) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    });
    setState(() {
      _fullscreen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_fullscreen) {
          _exitFullScreen();
          return false;
        }
        return true;
      },
      child: SafeArea(
        child: _exception == null
            ? _buildContainer(context)
            : _buildErrorContainer(context),
      ),
    );
  }

  Widget _buildErrorContainer(BuildContext context) {
    return Column(
      children: [
        _buildAppbar(),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _exception ?? "",
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(
                height: 20,
              ),
              FilledButton(
                onPressed: () {
                  if (!_playing) {
                    _exception = null;
                    widget.retryCallback();
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
                child: Text(
                  S.of(context).playerSkin_tips_playVideoFailed,
                  style: const TextStyle(color: Colors.black),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContainer(BuildContext context) {
    return Stack(
      children: [
        buildContentWithoutAppbar(context),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: AnimatedOpacity(
            opacity: _hideStuff ? 0.0 : 0.8,
            duration: const Duration(milliseconds: 400),
            child: _buildAppbar(),
          ),
        )
      ],
    );
  }

  AppBar _buildAppbar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      title: Text(
        widget.videoTitle,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }

  GestureDetector buildContentWithoutAppbar(BuildContext context) {
    return GestureDetector(
      onTap: _cancelAndRestartTimer,
      child: AbsorbPointer(
        absorbing: _hideStuff,
        child: Column(
          children: <Widget>[
            Container(height: barHeight),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _cancelAndRestartTimer();
                },
                child: Container(
                  color: Colors.transparent,
                  height: double.infinity,
                  width: double.infinity,
                  child: Center(
                      child: _exception != null
                          ? Text(
                              _exception!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                              ),
                            )
                          : (_prepared)
                              ? AnimatedOpacity(
                                  opacity: _hideStuff ? 0.0 : 0.7,
                                  duration: const Duration(milliseconds: 400),
                                  child: IconButton(
                                      iconSize: barHeight * 2,
                                      icon: Icon(
                                          _playing
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.white),
                                      padding: const EdgeInsets.only(
                                          left: 10.0, right: 10.0),
                                      onPressed: _playOrPause))
                              : SizedBox(
                                  width: barHeight * 1.5,
                                  height: barHeight * 1.5,
                                  child: const CircularProgressIndicator(
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white)),
                                )),
                ),
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }
}

class _DurationTextWidget extends StatelessWidget {
  const _DurationTextWidget({
    Key? key,
    required this.duration,
    required this.prepared,
  }) : super(key: key);
  final Duration duration;
  final bool prepared;

  @override
  Widget build(BuildContext context) {
    if (!prepared) {
      return const SizedBox();
    } else if (duration.inMilliseconds == 0) {
      return const Text(
        "LIVE",
        style: TextStyle(
          fontSize: 14.0,
          color: Colors.white,
        ),
      );
    } else {
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            _duration2String(duration),
            style: const TextStyle(
              fontSize: 14.0,
              color: Colors.white,
            ),
          ));
    }
  }
}
