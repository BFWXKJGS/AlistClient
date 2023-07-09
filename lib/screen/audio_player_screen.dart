import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/database/table/file_viewing_record.dart';
import 'package:alist/entity/file_list_resp_entity.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/util/file_type.dart';
import 'package:alist/util/file_utils.dart';
import 'package:alist/util/string_utils.dart';
import 'package:alist/util/user_controller.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:alist/widget/file_list_item_view.dart';
import 'package:alist/widget/slider.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class AudioPlayerScreen extends StatelessWidget {
  AudioPlayerScreen({Key? key}) : super(key: key);
  final List<FileItemVO> _audios = Get.arguments["audios"] ?? [];
  final int _index = Get.arguments["index"] ?? 0;

  @override
  Widget build(BuildContext context) {
    final AudioPlayerScreenController controller =
        Get.put(AudioPlayerScreenController(audios: _audios, index: _index));
    return AlistScaffold(
      appbarTitle: const SizedBox(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 30, bottom: 10),
              child: Obx(() => Text(controller._name.value)),
            ),
            Container(
              width: double.infinity,
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Obx(() => _buildFijkSlider(controller)),
            ),
            _buildButtons(controller, context),
          ],
        ),
      ),
    );
  }

  Row _buildButtons(
      AudioPlayerScreenController controller, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: IconButton(
            iconSize: 40,
            icon: Obx(() {
              if (controller._playMode.value == PlayMode.list) {
                return const Icon(Icons.repeat);
              } else if (controller._playMode.value == PlayMode.single) {
                return const Icon(Icons.repeat_one);
              } else {
                return const Icon(Icons.shuffle);
              }
            }),
            onPressed: () {
              controller._changePlayMode();
            },
          ),
        ),
        Obx(() => IconButton(
              iconSize: 50,
              icon: const Icon(Icons.skip_previous),
              onPressed: controller._playMode.value == PlayMode.single ||
                      controller._audios.length <= 1
                  ? null
                  : () {
                      controller._playPrevious();
                    },
            )),
        Obx(
          () => _PlayButton(
            playing: controller._playing.value,
            onPressed: controller._playOrPause,
          ),
        ),
        Obx(() => IconButton(
              iconSize: 50,
              icon: const Icon(Icons.skip_next),
              onPressed: controller._playMode.value == PlayMode.single ||
                      controller._audios.length <= 1
                  ? null
                  : () {
                      controller._playNext();
                    },
            )),
        IconButton(
          iconSize: 50,
          icon: const Icon(Icons.playlist_play_rounded),
          onPressed: () {
            _showPlayerList(context, controller);
          },
        ),
      ],
    );
  }

  Widget _buildFijkSlider(AudioPlayerScreenController controller) {
    if (!controller._prepared.value) {
      return const SizedBox();
    }

    double duration = controller._duration.value.inMilliseconds.toDouble();
    double currentValue = controller._seekPos.value > 0
        ? controller._seekPos.value
        : controller._currentPos.value.inMilliseconds.toDouble();
    Widget slider = FijkSlider(
      value: currentValue,
      cacheValue: currentValue,
      min: 0.0,
      max: max(duration, 1),
      onChanged: (v) {
        controller._seekPos.value = v;
      },
      onChangeEnd: (v) {
        controller._currentPos.value = Duration(milliseconds: v.toInt());
        controller._audioPlayer.seek(controller._currentPos.value);
        debugPrint("seek to $v duration=$duration");
        controller._seekPos.value = -1;
      },
    );
    return Row(
      children: [
        Text(
          _duration2String(controller._seekPos.value > 0
              ? Duration(milliseconds: controller._seekPos.value.toInt())
              : controller._currentPos.value),
          style: const TextStyle(
            fontSize: 12,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Expanded(
            child: Padding(
          padding: const EdgeInsets.only(left: 7.5, right: 10),
          child: slider,
        )),
        Text(
          _duration2String(controller._duration.value),
          style: const TextStyle(
            fontSize: 12,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        )
      ],
    );
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

  void _showPlayerList(
      BuildContext context, AudioPlayerScreenController controller) {
    if (controller._audios.isEmpty) return;
    var scrollController = AutoScrollController();
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  "${Intl.audioPlayListDialog_title.tr}(${controller._audios.length})",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                  child: Obx(() => _playList(scrollController, controller))),
            ],
          );
        });

    Future.delayed(const Duration(milliseconds: 200)).then((value) {
      scrollController.scrollToIndex(controller._index,
          duration: const Duration(milliseconds: 50),
          preferPosition: AutoScrollPosition.begin);
    });
  }

  ListView _playList(AutoScrollController scrollController,
      AudioPlayerScreenController controller) {
    return ListView.separated(
      controller: scrollController,
      itemBuilder: (context, index) {
        return _buildPlayListItem(scrollController, controller, context, index);
      },
      separatorBuilder: (context, index) => const Divider(),
      itemCount: controller._audios.length,
    );
  }

  Widget _buildPlayListItem(AutoScrollController scrollController,
      AudioPlayerScreenController controller, BuildContext context, int index) {
    var isPlayingIndex = controller._index == index;
    return AutoScrollTag(
      key: ValueKey(controller._audios[index]),
      controller: scrollController,
      index: index,
      child: ListTile(
        title: Text(controller._audios[index].name,
            style: isPlayingIndex
                ? TextStyle(color: Theme.of(context).colorScheme.primary)
                : const TextStyle()),
        onTap: () {
          Navigator.pop(context);
          if (controller._index == index) {
            controller._playOrPause();
          } else {
            controller._play(index);
          }
        },
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            controller._remove(index);
          },
        ),
      ),
    );
  }
}

class AudioPlayerScreenController extends GetxController {
  final RxList<FileItemVO> _audios;
  int _index;
  final _playMode = PlayMode.list.obs;

  AudioPlayerScreenController(
      {required List<FileItemVO> audios, required int index})
      : _audios = audios.obs,
        _index = index {
    if (_audios.isNotEmpty) {
      _name.value = _audios[_index].name;
    }
  }

  final _audioPlayer = AudioPlayer();
  final CancelToken _cancelToken = CancelToken();
  final _name = "".obs;
  late ConcatenatingAudioSource _playList;

  final _duration = const Duration().obs;
  final _currentPos = const Duration().obs;

  final _playing = false.obs;
  final _prepared = false.obs;

  final _seekPos = (-1.0).obs;
  List<StreamSubscription> streamSubscriptions = [];

  @override
  void onInit() {
    super.onInit();
    if (_index < 0 || _index >= _audios.length) {
      _index = 0;
    }
    _createPlayListAndPlay();

    var durationStreamSubscription =
        _audioPlayer.durationStream.listen((event) {
      if (event != null) {
        _duration.value = event;
      }
    });
    streamSubscriptions.add(durationStreamSubscription);
    var positionStreamSubscription =
        _audioPlayer.positionStream.listen((event) {
      _currentPos.value = event;
      if (_duration.value.inMilliseconds < _currentPos.value.inMilliseconds) {
        _currentPos.value = _duration.value;
      }
    });
    streamSubscriptions.add(positionStreamSubscription);
    var sequenceStreamSubscription =
        _audioPlayer.sequenceStateStream.listen((event) {
      if (event != null && _audios.isNotEmpty) {
        _index = event.currentIndex;
        var item = event.currentSource?.tag as MediaItem?;
        LogUtil.d("itemId=${item?.id}");
        if (item?.id == _audios[_index].path) {
          _name.value = _audios[_index].name;
        }
      }
    });
    streamSubscriptions.add(sequenceStreamSubscription);
    var stateStreamSubscription =
        _audioPlayer.playerStateStream.listen((state) {
      if (state.playing) {
        _prepared.value = true;
        _playing.value = true;
      } else {
        _playing.value = false;
      }
      if (state.processingState == ProcessingState.completed) {
        _playNext();
      }
    });
    streamSubscriptions.add(stateStreamSubscription);
    // _audioPlayer.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace st) {
    //   _playNext();
    // });
  }

  void _createPlayListAndPlay() async {
    var sources = <AudioSource>[];
    for (var audio in _audios) {
      var uri = await FileUtils.makeFileLink(audio.path, audio.sign);
      if (uri != null) {
        sources.add(
          _audioToUri(uri, audio),
        );
      }
    }

    _playList = ConcatenatingAudioSource(
      useLazyPreparation: true,
      shuffleOrder: DefaultShuffleOrder(),
      children: sources,
    );
    _audioPlayer.setAudioSource(_playList, initialIndex: _index);
    _audioPlayer.play();
  }

  UriAudioSource _audioToUri(String uri, FileItemVO audio) {
    var headers = <String, String>{};
    if (audio.provider == "BaiduNetdisk") {
      headers["User-Agent"] = "pan.baidu.com";
    }
    return AudioSource.uri(
      Uri.parse(uri),
      headers: headers,
      tag: MediaItem(
        id: audio.path,
        title: audio.name,
        artUri: Uri.parse("https://alistc.geektang.cn/ic_music_head.png"),
      ),
    );
  }

  void _playNext() {
    _currentPos.value = const Duration(milliseconds: 0);
    _audioPlayer.seekToNext();
  }

  void _playPrevious() {
    _currentPos.value = const Duration(milliseconds: 0);
    _audioPlayer.seekToPrevious();
  }

  void _playOrPause() async {
    if (_playing.value == true) {
      LogUtil.d("pause");
      await _audioPlayer.pause();
    } else {
      LogUtil.d("play");
      if (_duration.value.inMilliseconds <= _currentPos.value.inMilliseconds) {
        LogUtil.d("play3");
        await _audioPlayer.seek(const Duration(milliseconds: 0));
        LogUtil.d("play4");
        await _audioPlayer.play();
        LogUtil.d("play1");
      } else {
        LogUtil.d("play2");
        await _audioPlayer.play();
      }
    }
  }

  @override
  void onClose() {
    super.onClose();
    _cancelToken.cancel();
    _releasePlayer();

    for (var element in streamSubscriptions) {
      element.cancel();
    }
    streamSubscriptions = [];
  }

  void _releasePlayer() async {
    await _audioPlayer.stop();
    await _audioPlayer.dispose();
  }

  void _play(int index) {
    _index = index;
    _currentPos.value = const Duration(milliseconds: 0);
    _audioPlayer.seek(Duration.zero, index: index);
  }

  void _remove(int index) {
    if (_audios.length <= 1) {
      SmartDialog.showToast(Intl.audioPlayListDialog_tips_deleteTheLast.tr);
      return;
    }

    if (_index == index) {
      _playNext();
    }
    _playList.removeAt(index);
    _audios.removeAt(index);
  }

  void _changePlayMode() {
    if (_playMode.value == PlayMode.single) {
      _playMode.value = PlayMode.list;
      SmartDialog.showToast(Intl.audioPlayerScreen_btn_sequence.tr);
      _audioPlayer.setLoopMode(LoopMode.all);
      _audioPlayer.setShuffleModeEnabled(false);
    } else if (_playMode.value == PlayMode.list) {
      _playMode.value = PlayMode.random;
      SmartDialog.showToast(Intl.audioPlayerScreen_btn_shuffle.tr);
      _audioPlayer.setLoopMode(LoopMode.all);
      _audioPlayer.setShuffleModeEnabled(true);
    } else if (_playMode.value == PlayMode.random) {
      _playMode.value = PlayMode.single;
      _audioPlayer.setLoopMode(LoopMode.one);
      SmartDialog.showToast(Intl.audioPlayerScreen_btn_repeatOne.tr);
    }
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

enum PlayMode {
  single,
  list,
  random,
}
