import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/util/log_utils.dart';
import 'package:alist/widget/slider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_aliplayer/flutter_aliplayer.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:wakelock/wakelock.dart';

typedef OnPlayProgressChange = Function(int currentPostion, int duration);
typedef PlayNextCallback = Function();
typedef PlayPreviousCallback = Function();
typedef OnRateMenuTap = Function(Rate);

/// Default Panel Widget
class AlistPlayerSkin extends StatefulWidget {
  final FlutterAliplayer player;
  final BuildContext buildContext;
  final String videoTitle;
  final OnPlayProgressChange onPlayProgressChange;
  final PlayNextCallback? playNextCallback;
  final PlayPreviousCallback? playPreviousCallback;

  const AlistPlayerSkin({
    super.key,
    required this.player,
    required this.buildContext,
    required this.videoTitle,
    required this.onPlayProgressChange,
    required this.playNextCallback,
    required this.playPreviousCallback,
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

final _rateList = [
  const Rate("0.5x", 0.5),
  const Rate("0.75x", 0.75),
  const Rate("1.0x", 1.0),
  const Rate("1.25x", 1.25),
  const Rate("1.5x", 1.5),
  const Rate("2.0x", 2.0),
];

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

  bool _isPad = false;

  VerticalDragType? _verticalDragType;
  bool _verticalDragging = false;
  double _systemVolumeListenValue = 0;
  double _systemVolumeDragStartValue = 0;
  double _systemVolumeDragIndicatorValue = 0;
  double _systemBrightnessListenValue = 0;
  double _systemBrightnessDragStartValue = 0;
  double _screenWidth = 0;
  double _screenHeight = 0;
  double _verticalDragStartY = 0;

  bool _horizontalDragging = false;
  double _horizontalDragStartX = 0;
  Duration? _dragStartPosition;
  Duration _dragCurrentPosition = const Duration();

  // whether the video is playing in full screen
  bool _fullscreen = false;
  bool _playing = false;
  bool _prepared = false;
  bool _loading = false;
  String? _exception;
  bool _locked = false;
  double _rate = 1.0;
  String _rateStr = "1.0x";

  double _seekPos = -1.0;
  StreamSubscription? _currentPosSubs;
  StreamSubscription? _bufferPosSubs;
  StreamSubscription? _volumeSubscription;

  Timer? _hideTimer;
  bool _hideStuff = false;

  double _volume = 1.0;

  final barHeight = 40.0;

  void _readIfIpad() async {
    final iosInfo = await DeviceInfoPlugin().iosInfo;
    _isPad = iosInfo.model.contains("iPad");
  }

  @override
  void initState() {
    super.initState();
    _enableWakelock();

    //开启混音模式
    if (Platform.isIOS) {
      FlutterAliplayer.setAudioSessionTypeForIOS(
          AliPlayerAudioSesstionType.mix);
      _readIfIpad();
    } else if (Platform.isAndroid) {
      var shortestSide = MediaQuery.of(Get.context!).size.shortestSide;
      _isPad = shortestSide > 600;
    }
    _player.setOnInfo((infoCode, extraValue, extraMsg, playerId) {
      Log.d(
          "OnInfo infoCode=$infoCode extraValue=$extraValue extraMsg=$extraMsg",
          tag: tag);
      if (infoCode == FlutterAvpdef.CURRENTPOSITION) {
        setState(() {
          _currentPos = Duration(milliseconds: extraValue!);
          if (_duration.inMilliseconds > 0) {
            widget.onPlayProgressChange(
                _currentPos.inMilliseconds, _duration.inMilliseconds);
          }
        });
      } else if (infoCode == FlutterAvpdef.BUFFEREDPOSITION) {
        setState(() {
          _bufferPos = Duration(milliseconds: extraValue!);
        });
      }
    });

    _player.setOnVideoSizeChanged((width, height, rotation, playerId) {
      Log.d("width=$width height=$height rotation=$rotation", tag: tag);
    });

    _player.setOnLoadingStatusListener(
      loadingBegin: (String playerId) {
        Log.d("loadingBegin", tag: tag);
        setState(() {
          _loading = true;
        });
      },
      loadingProgress: (int percent, double? netSpeed, String playerId) {
        Log.d("loadingBegin percent=$percent netSpeed=$netSpeed", tag: tag);
      },
      loadingEnd: (String playerId) {
        setState(() {
          _loading = false;
        });
        Log.d("loadingEnd", tag: tag);
      },
    );

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
          _startHideTimer();
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
      Log.d("errorCode=$errorCode errorMsg=$errorMsg", tag: tag);
      _setPlaying(false, exception: errorMsg);
    });

    _volumeSubscription = VolumeController().listener((volume) {
      setState(() {
        Log.d("VolumeController listener volume $volume");
        _systemVolumeListenValue = volume;
      });
    });
    ScreenBrightness()
        .current
        .then((value) => _systemBrightnessListenValue = value);
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
        _loading = false;
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
    if (_locked) {
      return;
    }
    if (_playing == true) {
      _player.pause();
    } else {
      if (_duration.inMilliseconds <= _currentPos.inMilliseconds) {
        await _player.seekTo(0, FlutterAvpdef.ACCURATE);
      }
      _player.play();
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (Platform.isIOS) {
      FlutterAliplayer.setAudioSessionTypeForIOS(
          AliPlayerAudioSesstionType.sdkDefault);
    }
    _hideTimer?.cancel();
    _disableWakelock();

    ScreenBrightness().resetScreenBrightness();
    VolumeController().removeListener();
    _currentPosSubs?.cancel();
    _bufferPosSubs?.cancel();
    _volumeSubscription?.cancel();
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
        if (_locked) {
          return;
        }
        setState(() {
          _volume = _volume > 0 ? 0.0 : 1.0;
          _player.setVolume(_volume);
        });
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    double duration = _duration.inMilliseconds.toDouble();
    double currentValue =
        _seekPos > 0 ? _seekPos : _currentPos.inMilliseconds.toDouble();
    currentValue = min(currentValue, duration);
    currentValue = max(currentValue, 0);
    var screenSize = MediaQuery.of(context).size;
    _screenWidth = screenSize.width;
    _screenHeight = screenSize.height;
    // use 'MediaQuery.of(context).orientation' or OrientationBuilder is not work for ios
    _fullscreen = screenSize.width > screenSize.height;

    return AnimatedOpacity(
      opacity: (_hideStuff || _locked) ? 0.0 : 0.7,
      duration: const Duration(milliseconds: 400),
      child: SizedBox(
        height: barHeight,
        child: Row(
          children: <Widget>[
            _buildVolumeButton(),
            _prepared
                ? Padding(
                    padding: const EdgeInsets.only(right: 5.0, left: 5),
                    child: Text(
                      _duration2String(_currentPos),
                      style:
                          const TextStyle(fontSize: 14.0, color: Colors.white),
                    ),
                  )
                : const SizedBox(),

            _duration.inMilliseconds == 0
                ? const Expanded(child: Center())
                : Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 0, left: 0),
                      child: FijkSlider(
                        value: currentValue,
                        enable: !_locked,
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
              onPressed: () {
                if (_locked) {
                  return;
                }
                _hideTimer?.cancel();
                Widget dialog;
                onMenuTap(element) {
                  if (_rate != element.rate) {
                    _rate = element.rate;
                    _rateStr = element.name;
                    _player.setRate(_rate);
                    setState(() {});
                  }
                  SmartDialog.dismiss();
                }

                if (_fullscreen) {
                  dialog = VerticalRateMenuDialog(
                    rate: _rate,
                    onMenuTap: onMenuTap,
                  );
                } else {
                  dialog = HorizontalRateMenuDialog(
                    rate: _rate,
                    onMenuTap: onMenuTap,
                  );
                }
                SmartDialog.show(
                  builder: (context) => dialog,
                  alignment: _fullscreen
                      ? Alignment.centerRight
                      : Alignment.bottomCenter,
                  onDismiss: () => _startHideTimer(),
                );
              },
              icon: Text(
                _rateStr,
                style: const TextStyle(color: Colors.white),
              ),
            ),

            IconButton(
              icon: Icon(
                _fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.white,
              ),
              padding: const EdgeInsets.only(left: 10.0, right: 10.0),
              onPressed: () {
                if (_locked) {
                  return;
                }
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
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: []);
    setState(() {
      _fullscreen = true;
    });
  }

  void _exitFullScreen() async {
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    setState(() {
      _fullscreen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: !_locked && (!_fullscreen || _isPad)
          ? null
          : () async {
              if (_fullscreen && !_isPad) {
                _exitFullScreen();
                return false;
              }
              if (_locked) {
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
        _buildAppbar(context),
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
                    setState(() {
                      _exception = null;
                      _playing = true;
                    });
                    _player.reload();
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
                child: Text(
                  Intl.playerSkin_tips_playVideoFailed.tr,
                  style: const TextStyle(color: Colors.black),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  AppBar _buildAppbar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      title: Text(
        widget.videoTitle,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Theme.of(context).colorScheme.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  Widget _buildContainer(BuildContext context) {
    Widget widget = GestureDetector(
      onTap: _cancelAndRestartTimer,
      onDoubleTap: _onDoubleTap(),
      onVerticalDragDown: _onVerticalDragDown(),
      onVerticalDragStart: _onVerticalDragStart(),
      onVerticalDragUpdate: _onVerticalDragUpdate(),
      onVerticalDragEnd: _onVerticalDragEnd(),
      onVerticalDragCancel: _onVerticalDragCancel(),
      onHorizontalDragDown: _onHorizontalDragDown(),
      onHorizontalDragStart: _onHorizontalDragStart(),
      onHorizontalDragUpdate: _onHorizontalDragUpdate(),
      onHorizontalDragEnd: _onHorizontalDragEnd(),
      onHorizontalDragCancel: _onHorizontalDragCancel(),
      child: AbsorbPointer(
        absorbing: _hideStuff,
        child: Column(
          children: <Widget>[
            AnimatedOpacity(
              opacity: (_hideStuff || _locked) ? 0.0 : 0.7,
              duration: const Duration(milliseconds: 400),
              child: _buildAppbar(context),
            ),
            Expanded(child: _buildContainerWithoutAppbar(context)),
          ],
        ),
      ),
    );
    return Stack(
      // alignment: Alignment.topCenter,
      children: [
        widget,
        Positioned(
          left: 0,
          right: 0,
          top: 50,
          child: VerticalDragIndicator(
            verticalDragging: _verticalDragging,
            verticalDragType: _verticalDragType,
            volumeIndicatorValue: _systemVolumeDragIndicatorValue,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 50,
          child: HorizontalDragIndicator(
            horizontalDragging: _horizontalDragging,
            dragCurrentPos: _dragCurrentPosition,
            duration: _duration,
          ),
        ),
      ],
    );
  }

  GestureTapCallback? _onDoubleTap() {
    return _locked
        ? null
        : () {
            _playOrPause();
          };
  }

  GestureDragCancelCallback? _onHorizontalDragCancel() {
    return _locked
        ? null
        : () {
            _startHideTimer();
            setState(() {
              _horizontalDragging = false;
            });
          };
  }

  GestureDragEndCallback? _onHorizontalDragEnd() {
    return _locked
        ? null
        : (dragDetails) {
            setState(() {
              _horizontalDragging = false;
            });
            _startHideTimer();
            _player.seekTo(
                _dragCurrentPosition.inMilliseconds, FlutterAvpdef.INACCURATE);
          };
  }

  GestureDragUpdateCallback? _onHorizontalDragUpdate() {
    return _locked
        ? null
        : (dragDetails) {
            final dragStartX = _horizontalDragStartX;
            final currentY = dragDetails.localPosition.dx;
            final ratio = (currentY - dragStartX) / _screenWidth.toDouble();
            var durationMilliseconds = _duration.inMilliseconds;
            durationMilliseconds = min(durationMilliseconds, 1000 * 60 * 30);

            int newPosition = ((ratio * durationMilliseconds) +
                    _dragStartPosition!.inMilliseconds)
                .round();
            if (newPosition < 0) {
              newPosition = 0;
            } else if (newPosition > _duration.inMilliseconds) {
              newPosition = _duration.inMilliseconds;
            }

            setState(() {
              _dragCurrentPosition = Duration(milliseconds: newPosition);
            });
          };
  }

  GestureDragDownCallback? _onHorizontalDragDown() {
    return _locked ? null : (dragDetails) {};
  }

  GestureDragStartCallback? _onHorizontalDragStart() {
    return _locked
        ? null
        : (dragDetails) {
            _hideTimer?.cancel();
            setState(() {
              _horizontalDragStartX = dragDetails.localPosition.dx;
              _dragStartPosition = _currentPos;
              setState(() {
                _hideStuff = false;
                _horizontalDragging = true;
              });
            });
          };
  }

  GestureDragCancelCallback? _onVerticalDragCancel() {
    return (_locked)
        ? null
        : () {
            if (!_fullscreen) {
              return;
            }
            setState(() {
              _verticalDragging = false;
            });
            Log.d("onVerticalDragCancel", tag: tag);
          };
  }

  GestureDragEndCallback? _onVerticalDragEnd() {
    return (_locked)
        ? null
        : (dragDetails) {
            if (!_fullscreen) {
              return;
            }
            setState(() {
              _verticalDragging = false;
            });
            Log.d("onVerticalDragEnd ${dragDetails.velocity}", tag: tag);
          };
  }

  GestureDragDownCallback? _onVerticalDragDown() {
    return _locked
        ? null
        : (dragDetails) {
            Log.d("onVerticalDragDown ${dragDetails.localPosition.dy}",
                tag: tag);
          };
  }

  GestureDragUpdateCallback? _onVerticalDragUpdate() {
    return _locked
        ? null
        : (dragDetails) {
            if (!_fullscreen) {
              return;
            }
            Log.d("onVerticalDragUpdate ${dragDetails.localPosition.dy}",
                tag: tag);
            final dragStartY = _verticalDragStartY;
            final currentY = dragDetails.localPosition.dy;
            final ratio = (currentY - dragStartY) / _screenHeight.toDouble();

            if (_verticalDragType == VerticalDragType.volume) {
              _updateCurrentVolume(ratio);
            } else {
              _updateCurrentBrightness(ratio);
            }
          };
  }

  GestureDragStartCallback? _onVerticalDragStart() {
    return (_locked)
        ? null
        : (dragDetails) {
            if (!_fullscreen) {
              return;
            }
            Log.d("onVerticalDragStart ${dragDetails.localPosition.dy}",
                tag: tag);
            var dx = dragDetails.globalPosition.dx;
            if (dx > _screenWidth / 2) {
              _verticalDragType = VerticalDragType.volume;
              _systemVolumeDragStartValue = _systemVolumeListenValue;
              _systemVolumeDragIndicatorValue = _systemVolumeListenValue;
            } else {
              _verticalDragType = VerticalDragType.brightness;
              _systemBrightnessDragStartValue = _systemBrightnessListenValue;
            }
            setState(() {
              _verticalDragging = true;
            });

            _verticalDragStartY = dragDetails.localPosition.dy;
          };
  }

  void _updateCurrentVolume(double ratio) {
    final newVolumeValue =
        min(max(_systemVolumeDragStartValue - ratio, 0.0), 1.0);
    Log.d(
        "lastVolume=$_systemVolumeDragStartValue ratio=$ratio _volume=$newVolumeValue",
        tag: tag);
    setState(() {
      _systemVolumeDragIndicatorValue = newVolumeValue;
    });
    VolumeController().setVolume(newVolumeValue, showSystemUI: false);
  }

  void _updateCurrentBrightness(double ratio) {
    final newBrightnessValue =
        min(max(_systemBrightnessDragStartValue - ratio, 0.0), 1.0);
    Log.d(
        "lastBrightness=$_systemBrightnessDragStartValue ratio=$ratio _brightness=$newBrightnessValue",
        tag: tag);
    ScreenBrightness().setScreenBrightness(newBrightnessValue);
    _systemBrightnessListenValue = newBrightnessValue;
  }

  Widget _buildContainerWithoutAppbar(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              _cancelAndRestartTimer();
            },
            child: _buildCenter(),
          ),
        ),
        _buildBottomBar(context)
      ],
    );
  }

  Widget _buildCenter() {
    Color previousIconColor = Colors.white;
    if (widget.playPreviousCallback == null) {
      previousIconColor = Colors.white.withAlpha(80);
    }

    Color nextIconColor = Colors.white;
    if (widget.playNextCallback == null) {
      nextIconColor = Colors.white.withAlpha(80);
    }

    final Widget centerWidgetWithoutLock = Center(
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
                    opacity: (_hideStuff || _locked) ? 0.0 : 0.7,
                    duration: const Duration(milliseconds: 400),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          iconSize: 60,
                          icon: Icon(Icons.skip_previous_rounded,
                              color: previousIconColor),
                          padding:
                              const EdgeInsets.only(left: 10.0, right: 10.0),
                          onPressed: widget.playPreviousCallback,
                        ),
                        if (!_loading)
                          IconButton(
                            iconSize: 60,
                            icon: Icon(
                                _playing ? Icons.pause : Icons.play_arrow,
                                color: Colors.white),
                            padding:
                                const EdgeInsets.only(left: 10.0, right: 10.0),
                            onPressed: _playOrPause,
                          )
                        else
                          const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.grey)),
                        IconButton(
                          iconSize: 60,
                          icon: Icon(
                            Icons.skip_next_rounded,
                            color: nextIconColor,
                          ),
                          padding:
                              const EdgeInsets.only(left: 10.0, right: 10.0),
                          onPressed: widget.playNextCallback,
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    width: barHeight,
                    height: barHeight,
                    child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white)),
                  ));

    return Container(
      color: Colors.transparent,
      height: double.infinity,
      width: double.infinity,
      child: _VideoLockWrapper(
        locked: _locked,
        hideStuff: _hideStuff,
        child: centerWidgetWithoutLock,
        onTap: () {
          setState(() {
            _locked = !_locked;
          });
        },
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

class _VideoLockWrapper extends StatelessWidget {
  const _VideoLockWrapper(
      {Key? key,
      required this.locked,
      required this.hideStuff,
      required this.child,
      required this.onTap})
      : super(key: key);
  final bool locked;
  final bool hideStuff;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    IconData lockIcon = locked ? Icons.lock_outline : Icons.lock_open;
    Widget lockBtn = AnimatedOpacity(
      opacity: hideStuff ? 0.0 : 0.7,
      duration: const Duration(milliseconds: 400),
      child: IconButton(
        style: const ButtonStyle(
          backgroundColor: MaterialStatePropertyAll<Color?>(Color(0x70333333)),
        ),
        color: Colors.white,
        onPressed: onTap,
        icon: Icon(lockIcon),
      ),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        Positioned(
          left: 15,
          child: lockBtn,
        )
      ],
    );
  }
}

enum VerticalDragType { brightness, volume }

class VerticalDragIndicator extends StatelessWidget {
  const VerticalDragIndicator({
    Key? key,
    required this.verticalDragging,
    required this.verticalDragType,
    required this.volumeIndicatorValue,
  }) : super(key: key);
  final VerticalDragType? verticalDragType;
  final double volumeIndicatorValue;
  final bool verticalDragging;

  @override
  Widget build(BuildContext context) {
    Widget indicator;
    if (verticalDragType == VerticalDragType.brightness) {
      indicator = StreamBuilder<double>(
          stream: ScreenBrightness().onCurrentBrightnessChanged,
          builder: (context, snapshot) {
            return LinearProgressIndicator(
              minHeight: 2,
              value: snapshot.data ?? 0,
            );
          });
    } else {
      indicator = LinearProgressIndicator(
        minHeight: 2,
        value: volumeIndicatorValue,
      );
    }

    final icon = verticalDragType == VerticalDragType.volume
        ? Icons.volume_up_rounded
        : Icons.brightness_7;

    return Center(
      child: AnimatedOpacity(
        opacity: verticalDragging ? 0.7 : 0,
        duration: const Duration(milliseconds: 400),
        child: Container(
          width: 150,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: const BoxDecoration(
              color: Color(0xff000000),
              borderRadius: BorderRadius.all(Radius.circular(4))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(
                  icon,
                  color: Colors.white,
                ),
              ),
              Expanded(child: indicator)
            ],
          ),
        ),
      ),
    );
  }
}

class HorizontalDragIndicator extends StatelessWidget {
  const HorizontalDragIndicator({
    Key? key,
    required this.horizontalDragging,
    required this.dragCurrentPos,
    required this.duration,
  }) : super(key: key);
  final bool horizontalDragging;
  final Duration dragCurrentPos;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    var durationStr = _duration2String(duration);
    var currentPosStr = _duration2String(dragCurrentPos);
    var ratio = 0.0;
    if (duration.inMilliseconds != 0) {
      ratio =
          dragCurrentPos.inMilliseconds.toDouble() / duration.inMilliseconds;
    }

    return Center(
      child: AnimatedOpacity(
        opacity: horizontalDragging ? 0.7 : 0,
        duration: const Duration(milliseconds: 400),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          decoration: const BoxDecoration(
              color: Color(0xff000000),
              borderRadius: BorderRadius.all(Radius.circular(4))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("$currentPosStr / $durationStr",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white)),
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: SizedBox(
                  width: 145,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    value: ratio,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class RatioMenuItem extends StatelessWidget {
  const RatioMenuItem(
      {Key? key,
      required this.text,
      this.check = false,
      required this.direction,
      this.onTap})
      : super(key: key);
  final String text;
  final GestureTapCallback? onTap;
  final bool check;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Flex(
          direction: direction,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                  color: check
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class Rate {
  final String name;
  final double rate;

  const Rate(this.name, this.rate);
}

class VerticalRateMenuDialog extends StatelessWidget {
  const VerticalRateMenuDialog({Key? key, required this.rate, this.onMenuTap})
      : super(key: key);
  final double rate;
  final OnRateMenuTap? onMenuTap;

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [
      RatioMenuItem(text: Intl.playerSkin_rate.tr, direction: Axis.horizontal)
    ];
    for (var element in _rateList) {
      widgets.add(RatioMenuItem(
        text: element.name,
        check: rate == element.rate,
        direction: Axis.horizontal,
        onTap: () {
          onMenuTap?.call(element);
        },
      ));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: const Color(0xff777777),
      child: SafeArea(
        left: false,
        child: Column(
          children: widgets,
        ),
      ),
    );
  }
}

class HorizontalRateMenuDialog extends StatelessWidget {
  const HorizontalRateMenuDialog({Key? key, required this.rate, this.onMenuTap})
      : super(key: key);
  final double rate;
  final OnRateMenuTap? onMenuTap;

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    for (var element in _rateList) {
      widgets.add(RatioMenuItem(
        text: element.name,
        direction: Axis.vertical,
        check: rate == element.rate,
        onTap: () {
          onMenuTap?.call(element);
        },
      ));
    }
    return Container(
      color: const Color(0xff777777),
      padding: const EdgeInsets.symmetric(vertical: 17),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: Text(
                Intl.playerSkin_rate.tr,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Row(children: widgets)
          ],
        ),
      ),
    );
  }
}
