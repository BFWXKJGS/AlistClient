import 'dart:async';
import 'dart:ui';

import 'package:alist/database/alist_database_controller.dart';
import 'package:alist/entity/file_info_resp_entity.dart';
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
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class AudioPlayerScreen extends StatelessWidget {
  AudioPlayerScreen({Key? key}) : super(key: key);
  final List<FileItemVO> _audios = Get.arguments["audios"] ?? [];
  final int _index = Get.arguments["index"] ?? 0;
  final String? _path = Get.arguments["path"];

  @override
  Widget build(BuildContext context) {
    final AudioPlayerScreenController controller =
        Get.put(AudioPlayerScreenController(
      audios: _audios,
      index: _index,
      path: _path,
    ));
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
      max: duration,
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
  final String? _path;
  final RxList<FileItemVO> _audios;
  List<FileItemVO> _audioListShuffle = [];
  int _index;
  final _playMode = PlayMode.list.obs;

  AudioPlayerScreenController(
      {required List<FileItemVO> audios,
      required int index,
      required String? path})
      : _audios = audios.obs,
        _index = index,
        _path = path {
    if (_audios.isNotEmpty) {
      _name.value = _audios[_index].name;
    }
  }

  final _audioPlayer = AudioPlayer();
  final CancelToken _cancelToken = CancelToken();
  final _name = "".obs;

  final _duration = const Duration().obs;
  final _currentPos = const Duration().obs;

  final _playing = false.obs;
  final _prepared = false.obs;
  final _audioUrl = "".obs;

  final _seekPos = (-1.0).obs;
  StreamSubscription? _currentPosSubs;
  StreamSubscription? _bufferPosSubs;

  @override
  void onInit() {
    super.onInit();
    if (_index < 0 || _index >= _audios.length) {
      _index = 0;
    }

    if (_path != null && _path!.isNotEmpty) {
      _requestPlayListAndPlay(_path!);
    } else {
      var audio = _audios[_index];
      _startPlay(audio);
    }

    _audioPlayer.setAudioContext(const AudioContext(
        iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: [
        AVAudioSessionOptions.mixWithOthers,
      ],
    )));
    _audioPlayer.onDurationChanged.listen((Duration d) {
      LogUtil.d("duration=${d.inMilliseconds}s");
      _duration.value = d;
    });
    _audioPlayer.onPositionChanged.listen((Duration p) {
      if (p.inMilliseconds > _duration.value.inMilliseconds) {
        _duration.value = p;
      }
      _currentPos.value = p;
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      _playNext();
    });

    _audioPlayer.onPlayerStateChanged.listen((PlayerState s) {
      if (s == PlayerState.playing) {
        LogUtil.d("playing");
        _prepared.value = true;
        _playing.value = true;
      } else {
        _playing.value = false;
      }
    });
  }

  void _playNext() {
    _currentPos.value = const Duration(milliseconds: 0);
    switch (_playMode.value) {
      case PlayMode.list:
        _index = (_index + 1) % _audios.length;
        break;
      case PlayMode.random:
        var indexShuffle = _audioListShuffle.indexOf(_audios[_index]);
        var nextIndexShuffle = (indexShuffle + 1) % _audioListShuffle.length;
        _index = _audios.indexOf(_audioListShuffle[nextIndexShuffle]);
        break;
      case PlayMode.single:
        break;
    }

    var path = _audios[_index];
    _startPlay(path);
  }

  void _playPrevious() {
    _currentPos.value = const Duration(milliseconds: 0);
    if (_playMode.value == PlayMode.random) {
      var indexShuffle = _audioListShuffle.indexOf(_audios[_index]);
      if (indexShuffle == 0 && _audioListShuffle.length == 1) {
        var nextIndexShuffle = _audioListShuffle.length - 1;
        _index = _audios.indexOf(_audioListShuffle[nextIndexShuffle]);
      } else {
        var nextIndexShuffle = (indexShuffle - 1) % _audioListShuffle.length;
        _index = _audios.indexOf(_audioListShuffle[nextIndexShuffle]);
      }
    } else {
      if (_index == 0) {
        _index = _audios.length - 1;
      } else {
        _index = (_index - 1) % _audios.length;
      }
    }
    var path = _audios[_index];
    _startPlay(path);
  }

  void _startPlay(FileItemVO audio) async {
    _name.value = audio.name;
    _requestAudioUrlAndPlay(audio.path);
  }

  void _requestAudioUrlAndPlay(String path, {int retryTimes = 0}) {
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
          _name.value = data?.name ?? "";
          _audioUrl.value = url ?? "";
          _playWithUrl(url);
        }
      },
      onError: (code, message) {
        if (retryTimes < 2) {
          Future.delayed(const Duration(milliseconds: 200), () {
            _requestAudioUrlAndPlay(path, retryTimes: retryTimes + 1);
          });
        } else {
          SmartDialog.showToast(message);
          _playNext();
        }
        debugPrint("code:$code,message:$message");
      },
    );
  }

  void _playWithUrl(String? url, {int retryTimes = 0}) {
    _audioPlayer.play(UrlSource(url ?? "")).catchError((e) {
      if (retryTimes < 2) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _playWithUrl(url, retryTimes: retryTimes + 1);
        });
      } else {
        _playNext();
      }
    });
  }

  void _playOrPause() async {
    if (_playing.value == true) {
      await _audioPlayer.pause();
    } else {
      if (_duration.value.inMilliseconds <= _currentPos.value.inMilliseconds) {
        if (_audioUrl.value.isNotEmpty) {
          await _audioPlayer.play(UrlSource(_audioUrl.value));
        }
      } else {
        await _audioPlayer.resume();
      }
    }
  }

  @override
  void onClose() {
    super.onClose();
    _cancelToken.cancel();
    _releasePlayer();

    _currentPosSubs?.cancel();
    _bufferPosSubs?.cancel();
  }

  void _releasePlayer() async {
    await _audioPlayer.stop();
    await _audioPlayer.dispose();
  }

  void _play(int index) {
    _index = index;
    _currentPos.value = const Duration(milliseconds: 0);
    var file = _audios[_index];
    _startPlay(file);
  }

  void _remove(int index) {
    if (_audios.length <= 1) {
      SmartDialog.showToast(Intl.audioPlayListDialog_tips_deleteTheLast.tr);
      return;
    }

    _audioListShuffle.remove(_audios[index]);
    _audios.removeAt(index);
    if (_index == index) {
      _currentPos.value = const Duration(milliseconds: 0);

      if (index >= _audios.length) {
        _index = _audios.length - 1;
      }
      var file = _audios[_index];
      _startPlay(file);
    }
  }

  void _changePlayMode() {
    if (_playMode.value == PlayMode.single) {
      _playMode.value = PlayMode.list;
      SmartDialog.showToast(Intl.audioPlayerScreen_btn_sequence.tr);
    } else if (_playMode.value == PlayMode.list) {
      _playMode.value = PlayMode.random;
      SmartDialog.showToast(Intl.audioPlayerScreen_btn_shuffle.tr);
      _audioListShuffle = _audios.toList();
      _audioListShuffle.shuffle();
    } else if (_playMode.value == PlayMode.random) {
      _playMode.value = PlayMode.single;
      SmartDialog.showToast(Intl.audioPlayerScreen_btn_repeatOne.tr);
    }
  }

  void _requestPlayListAndPlay(String path) {
    _requestAudioUrlAndPlay(path);
    _loadAudiosPrepare(path.substringBeforeLast("/")!, path);
  }

  Future<void> _loadAudiosPrepare(String folderPath, String filePath) async {
    final userController = Get.find<UserController>();
    final databaseController = Get.find<AlistDatabaseController>();
    final user = userController.user.value;

    // query file's password from database.
    var filePassword = await databaseController.filePasswordDao
        .findPasswordByPath(user.serverUrl, user.username, folderPath);
    String? password;
    if (filePassword != null) {
      password = filePassword.password;
    }
    if (!isClosed) {
      _loadAudios(folderPath, filePath, password);
    }
  }

  Future<void> _loadAudios(
      String folderPath, String filePath, String? password) async {
    var body = {
      "path": folderPath,
      "password": password ?? "",
      "page": 1,
      "per_page": 0,
      "refresh": false
    };

    return DioUtils.instance.requestNetwork<FileListRespEntity>(
        Method.post, "fs/list", cancelToken: _cancelToken, params: body,
        onSuccess: (data) {
      var audios = data?.content
          ?.map((e) => _fileResp2VO(folderPath, data.provider, e))
          .where((element) => element.type == FileType.audio)
          .toList();
      audios?.sort((a, b) => a.name.compareTo(b.name));
      var index = audios?.indexWhere((element) => element.path == filePath);
      if (index != null && index >= 0) {
        _index = index;
      }
      _audios.value = audios ?? [];
      LogUtil.d("index=$_index audios=${_audios.length}");
    }, onError: (code, msg) {
      SmartDialog.showToast(msg);
      debugPrint(msg);
    });
  }

  FileItemVO _fileResp2VO(
      String path, String provider, FileListRespContent resp) {
    DateTime? modifyTime = resp.parseModifiedTime();
    String? modifyTimeStr = resp.getReformatModified(modifyTime);

    return FileItemVO(
      name: resp.name,
      path: resp.getCompletePath(path),
      size: resp.isDir ? null : resp.size,
      sizeDesc: resp.formatBytes(),
      isDir: resp.isDir,
      modified: modifyTimeStr,
      typeInt: resp.type,
      type: resp.getFileType(),
      thumb: resp.thumb,
      sign: resp.sign,
      icon: resp.getFileIcon(),
      modifiedMilliseconds: modifyTime?.millisecondsSinceEpoch ?? -1,
      provider: provider,
    );
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
