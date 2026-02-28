import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:alist/entity/file_list_resp_entity.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/screen/projector/projector_models.dart';
import 'package:alist/util/alist_plugin.dart';
import 'package:alist/util/constant.dart';
import 'package:alist/util/download/download_manager.dart';
import 'package:alist/util/file_password_helper.dart';
import 'package:alist/util/file_type.dart';
import 'package:alist/util/file_utils.dart';
import 'package:alist/util/nature_sort.dart';
import 'package:alist/util/proxy.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_aliplayer/flutter_aliplayer.dart';
import 'package:flutter_aliplayer/flutter_aliplayer_factory.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock/wakelock.dart';

class ProjectorPlayerScreen extends StatefulWidget {
  const ProjectorPlayerScreen({super.key});

  @override
  State<ProjectorPlayerScreen> createState() => _ProjectorPlayerScreenState();
}

class _ProjectorPlayerScreenState extends State<ProjectorPlayerScreen>
    with WidgetsBindingObserver {
  late final FlutterAliplayer _videoPlayer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ProxyServer _proxyServer = Get.find();
  final FocusNode _pageFocusNode = FocusNode();
  final FocusNode _closeButtonFocusNode = FocusNode();
  final FocusNode _nextButtonFocusNode = FocusNode();

  late final String _rootPath;
  late final String _backupPassword;
  late final ProjectorConfig _config;
  late final _ProjectorRepository _repository;
  late final _ProjectorTraversalSource _source;

  final Map<String, String> _unsupportedErrors = {};
  final Queue<_PreparedProjectorMedia> _preparedQueue =
      Queue<_PreparedProjectorMedia>();
  StreamSubscription<PlayerState>? _audioStateSubscription;
  Timer? _countdownTimer;
  Completer<void>? _preloadFillCompleter;

  _ProjectorMediaItem? _currentItem;
  String? _currentUrl;
  String _sourcePathHint = "/";
  bool _loading = true;
  bool _advancing = false;
  bool _preloadFilling = false;
  bool _preloadSourceExhausted = false;
  bool _showOverlay = false;
  int _countdownSeconds = 0;
  bool _imageFailedScheduled = false;
  int _activeRenderGeneration = 0;
  int _imageCountdownStartedGeneration = -1;
  int _timedCountdownStartedGeneration = -1;
  String? _errorText;
  DateTime _ignoreVideoErrorsUntil = DateTime.fromMillisecondsSinceEpoch(0);
  bool _awaitingAndroidNativeVideoReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _videoPlayer = FlutterAliPlayerFactory.createAliPlayer();
    _initArgs();
    _repository = _ProjectorRepository(
      backupPassword: _backupPassword,
      imageOnly: _config.imageOnly,
    );
    _source = _createSource(_config.traversalMode);
    if (defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _pageFocusNode.requestFocus();
      });
    }

    _initPlayerAndStart();
  }

  Future<void> _initPlayerAndStart() async {
    debugPrint("Projector: _initPlayerAndStart begin");
    try {
      await _initPlayerCallbacks();
    } catch (e) {
      debugPrint("Projector: _initPlayerCallbacks failed: $e");
    }
    debugPrint("Projector: _initPlayerCallbacks done");

    try {
      await _enableImmersiveMode();
    } catch (e) {
      debugPrint("Projector: _enableImmersiveMode failed: $e");
    }

    unawaited(_fillPreparedQueue());
    _nextMedia();
  }

  void _initArgs() {
    final args = Get.arguments as Map?;
    _rootPath = (args?["path"] as String?)?.trim().isNotEmpty == true
        ? (args?["path"] as String)
        : "/";
    _backupPassword = (args?["backupPassword"] as String?) ?? "";
    final configArgs = (args?["config"] as Map?)?.cast<String, dynamic>();
    _config = configArgs == null
        ? const ProjectorConfig.defaults()
        : ProjectorConfig.fromArgs(configArgs);
  }

  _ProjectorTraversalSource _createSource(ProjectorTraversalMode mode) {
    switch (mode) {
      case ProjectorTraversalMode.orderedDfs:
        return _OrderedDfsTraversalSource(_repository, _rootPath);
      case ProjectorTraversalMode.randomWalk:
        return _RandomWalkTraversalSource(_repository, _rootPath);
      case ProjectorTraversalMode.randomAllTree:
        return _RandomAllTreeTraversalSource(_repository, _rootPath);
    }
  }

  Future<void> _initPlayerCallbacks() async {
    _videoPlayer.setAutoPlay(true);
    if (Platform.isAndroid) {
      try {
        await _videoPlayer
            .setScalingMode(FlutterAvpdef.AVP_SCALINGMODE_SCALETOFILL)
            .timeout(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint("Projector: setScalingMode failed/timeout: $e");
      }
    }

    try {
      var cacheDir = await DownloadManager.findDownloadDir("video");
      FlutterAliplayer.enableLocalCache(
          true, "${1024 * 100}", cacheDir.path, DocTypeForIOS.caches);
    } catch (e) {
      debugPrint("Projector init cache failed: $e");
    }

    _videoPlayer.setOnCompletion((playerId) {
      _onCurrentMediaCompleted();
    });
    _videoPlayer.setOnError((errorCode, errorExtra, errorMsg, playerId) {
      if (DateTime.now().isBefore(_ignoreVideoErrorsUntil)) {
        debugPrint("Projector: ignore transient video error during transition, "
            "code=$errorCode extra=$errorExtra msg=$errorMsg");
        return;
      }
      if (_currentItem?.mediaType != _ProjectorMediaType.video) {
        return;
      }
      _skipCurrentAsUnsupported(
        reason:
            "Video player callback error: code=$errorCode, extra=$errorExtra, msg=$errorMsg",
      );
    });
    _videoPlayer.setOnStateChanged((newState, playerId) {
      if (!mounted || _currentItem?.mediaType != _ProjectorMediaType.video) {
        return;
      }
      if (newState == FlutterAvpdef.AVPStatus_AVPStatusPrepared ||
          newState == FlutterAvpdef.AVPStatus_AVPStatusStarted ||
          newState == FlutterAvpdef.AVPStatus_AVPStatusPaused) {
        _startTimedCountdownIfNeeded(
          mediaType: _ProjectorMediaType.video,
          enabled: !_config.videoStayInfinite,
          seconds: _config.videoStaySeconds,
        );
        if (_loading) {
          setState(() {
            _loading = false;
          });
        }
      }
    });

    _audioStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted || _currentItem?.mediaType != _ProjectorMediaType.audio) {
        return;
      }

      if (state.processingState == ProcessingState.ready) {
        _startTimedCountdownIfNeeded(
          mediaType: _ProjectorMediaType.audio,
          enabled: !_config.audioStayInfinite,
          seconds: _config.audioStaySeconds,
        );
        if (_loading) {
          setState(() {
            _loading = false;
          });
        }
      }
      if (state.processingState == ProcessingState.completed) {
        _onCurrentMediaCompleted();
      }
    });
  }

  Future<void> _enableImmersiveMode() async {
    await Wakelock.enable();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _disableImmersiveMode() async {
    await Wakelock.disable();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ignoreVideoErrorsUntil = DateTime.now().add(const Duration(days: 1));
    _awaitingAndroidNativeVideoReturn = false;
    _countdownTimer?.cancel();
    _audioStateSubscription?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _videoPlayer.stop().catchError((e) {
      debugPrint("Ignored FlutterAliplayer.stop exception: $e");
    });
    _videoPlayer.destroy();
    _repository.dispose();
    _proxyServer.stop();
    _pageFocusNode.dispose();
    _closeButtonFocusNode.dispose();
    _nextButtonFocusNode.dispose();
    _disableImmersiveMode();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed ||
        !_awaitingAndroidNativeVideoReturn) {
      return;
    }
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted || !_awaitingAndroidNativeVideoReturn) {
        return;
      }
      final completed =
          SpUtil.getBool(AlistConstant.projectorNativePlayerCompleted) ?? false;
      SpUtil.remove(AlistConstant.projectorNativePlayerCompleted);
      _awaitingAndroidNativeVideoReturn = false;
      if (_currentItem?.mediaType != _ProjectorMediaType.video) {
        return;
      }
      if (completed) {
        _nextMedia();
      } else {
        Get.back();
      }
    });
  }

  String _getDebugDump() {
    final buffer = StringBuffer();
    buffer.writeln("=== Debug Info ===");
    buffer.writeln("Unsupported Paths (${_unsupportedErrors.length}):");
    for (final entry in _unsupportedErrors.entries) {
      buffer.writeln("  - ${entry.key}");
      buffer.writeln("    Error: ${entry.value}");
    }
    buffer.writeln(
        "Prepared Queue: ${_preparedQueue.length}/$_targetPreparedQueueSize");
    buffer.writeln(_repository.getDebugInfo());
    return buffer.toString();
  }

  int get _targetPreparedQueueSize {
    return (_config.preloadCount + 1)
        .clamp(1, ProjectorConfig.maxPreloadCount + 1)
        .toInt();
  }

  Future<void> _fillPreparedQueue() async {
    if (_preloadSourceExhausted || !mounted) {
      return;
    }
    if (_preloadFilling) {
      final running = _preloadFillCompleter;
      if (running != null) {
        await running.future;
      }
      return;
    }
    _preloadFilling = true;
    final startedWithEmptyQueue = _preparedQueue.isEmpty;
    final targetSize = startedWithEmptyQueue ? 1 : _targetPreparedQueueSize;
    final completer = Completer<void>();
    _preloadFillCompleter = completer;
    try {
      while (mounted &&
          !_preloadSourceExhausted &&
          _preparedQueue.length < targetSize) {
        final prepared = await _prepareNextPlayableItem();
        if (prepared == null) {
          break;
        }
        _preparedQueue.add(prepared);
      }
    } catch (e, s) {
      debugPrint("Projector preload fill error: $e\n$s");
    } finally {
      _preloadFilling = false;
      if (!completer.isCompleted) {
        completer.complete();
      }
      if (identical(_preloadFillCompleter, completer)) {
        _preloadFillCompleter = null;
      }
      if (startedWithEmptyQueue &&
          mounted &&
          !_preloadSourceExhausted &&
          _preparedQueue.isNotEmpty) {
        unawaited(_fillPreparedQueue());
      }
    }
  }

  Future<_PreparedProjectorMedia?> _prepareNextPlayableItem() async {
    const int maxAttempts = 400;
    for (int i = 0; i < maxAttempts; i++) {
      final nextItem = await _source.next();
      if (nextItem == null) {
        _preloadSourceExhausted = true;
        return null;
      }
      final pathHint = _source.currentPathHint ?? _rootPath;

      if (_unsupportedErrors.containsKey(nextItem.path)) {
        continue;
      }

      if (nextItem.name.startsWith("._")) {
        _unsupportedErrors[nextItem.path] = "MacOS metadata file";
        continue;
      }

      final url = await FileUtils.makeFileLink(nextItem.path, nextItem.sign,
          toastShowTips: false);
      if (url == null || url.isEmpty) {
        _unsupportedErrors[nextItem.path] =
            "URL generation failed (empty or null)";
        continue;
      }

      final imagePrecached = await _precacheImageIfNeeded(nextItem, url);
      return _PreparedProjectorMedia(
        item: nextItem,
        pathHint: pathHint,
        url: url,
        imagePrecached: imagePrecached,
      );
    }
    _preloadSourceExhausted = true;
    return null;
  }

  Future<bool> _precacheImageIfNeeded(
      _ProjectorMediaItem item, String url) async {
    if (!mounted || item.mediaType != _ProjectorMediaType.image) {
      return false;
    }
    try {
      await precacheImage(NetworkImage(url), context);
      return true;
    } catch (e) {
      debugPrint("Projector image preload failed: ${item.path}, error: $e");
      return false;
    }
  }

  Future<_PreparedProjectorMedia?> _takeNextPreparedItem() async {
    if (_preparedQueue.isEmpty) {
      await _fillPreparedQueue();
    }
    if (_preparedQueue.isEmpty) {
      return null;
    }
    final prepared = _preparedQueue.removeFirst();
    unawaited(_fillPreparedQueue());
    return prepared;
  }

  void _showNoPlayableMediaError([Object? error]) {
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _currentItem = null;
      _currentUrl = null;
      _errorText = error == null
          ? "${Intl.projectorPlayer_noMedia.tr}\n\n${_getDebugDump()}"
          : "${Intl.projectorPlayer_noMedia.tr}\n$error\n\n${_getDebugDump()}";
    });
  }

  Future<void> _nextMedia() async {
    debugPrint("Projector: _nextMedia called");
    if (_advancing) {
      debugPrint("Projector: _nextMedia skipped (already advancing)");
      return;
    }
    _advancing = true;
    _cancelCountdown();

    try {
      debugPrint("Projector: consume prepared queue");
      for (int i = 0; i < 400; i++) {
        final prepared = await _takeNextPreparedItem();
        if (prepared == null) {
          debugPrint("Projector: prepared queue exhausted");
          _showNoPlayableMediaError();
          return;
        }
        _sourcePathHint = prepared.pathHint;

        debugPrint("Projector: trying to play ${prepared.item.path}");
        final shouldSkipLoading =
            prepared.item.mediaType == _ProjectorMediaType.image &&
                prepared.imagePrecached;
        final error = await _playItem(
          prepared.item,
          resolvedUrl: prepared.url,
          skipLoadingIndicator: shouldSkipLoading,
        );
        if (error == null) {
          debugPrint("Projector: play success ${prepared.item.path}");
          return;
        }

        debugPrint("Projector: play failed ${prepared.item.path}: $error");
        _unsupportedErrors[prepared.item.path] = error;
      }

      _showNoPlayableMediaError();
    } catch (e, s) {
      debugPrint("Projector _nextMedia error: $e\n$s");
      _showNoPlayableMediaError(e);
    } finally {
      _advancing = false;
    }
  }

  Future<String?> _playItem(
    _ProjectorMediaItem item, {
    String? resolvedUrl,
    bool skipLoadingIndicator = false,
  }) async {
    debugPrint("Projector: _playItem start: ${item.path}");
    final url = resolvedUrl ??
        await FileUtils.makeFileLink(item.path, item.sign,
            toastShowTips: false);
    if (url == null || url.isEmpty) {
      debugPrint("Projector skip: url is empty for ${item.path}");
      return "URL generation failed (empty or null)";
    }

    _imageFailedScheduled = false;
    _activeRenderGeneration += 1;
    _imageCountdownStartedGeneration = -1;
    _timedCountdownStartedGeneration = -1;
    _cancelCountdown();
    _ignoreVideoErrorsUntil =
        DateTime.now().add(const Duration(milliseconds: 800));

    debugPrint("Projector: stopping audio player");
    await _audioPlayer.stop();

    debugPrint("Projector: stopping video player");
    try {
      // Use timeout to prevent hanging if plugin is unresponsive
      await _videoPlayer.stop().timeout(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint("Ignored FlutterAliplayer.stop exception: $e");
    }

    if (!mounted) {
      debugPrint("Projector: _playItem context unmounted");
      return "Context unmounted";
    }

    debugPrint("Projector: setting state loading=${!skipLoadingIndicator}");
    setState(() {
      _currentItem = item;
      _currentUrl = url;
      _loading = !skipLoadingIndicator;
      _errorText = null;
    });

    switch (item.mediaType) {
      case _ProjectorMediaType.image:
        debugPrint("Projector: type is image");
        return null;
      case _ProjectorMediaType.video:
        return _playVideo(item, url);
      case _ProjectorMediaType.audio:
        return _playAudio(item, url);
    }
  }

  void _onCurrentImageFrameAvailable() {
    if (!mounted) {
      return;
    }
    final currentItem = _currentItem;
    if (currentItem == null ||
        currentItem.mediaType != _ProjectorMediaType.image) {
      return;
    }
    final generation = _activeRenderGeneration;
    if (_imageCountdownStartedGeneration == generation) {
      return;
    }
    _imageCountdownStartedGeneration = generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final activeItem = _currentItem;
      if (activeItem == null ||
          activeItem.mediaType != _ProjectorMediaType.image) {
        return;
      }
      if (_activeRenderGeneration != generation ||
          _imageCountdownStartedGeneration != generation) {
        return;
      }
      if (_loading) {
        setState(() {
          _loading = false;
        });
      }
      _startCountdown(_config.imageStaySeconds);
    });
  }

  void _startTimedCountdownIfNeeded({
    required _ProjectorMediaType mediaType,
    required bool enabled,
    required int seconds,
  }) {
    if (!enabled) {
      return;
    }
    final currentItem = _currentItem;
    if (currentItem == null || currentItem.mediaType != mediaType) {
      return;
    }
    final generation = _activeRenderGeneration;
    if (_timedCountdownStartedGeneration == generation) {
      return;
    }
    _timedCountdownStartedGeneration = generation;
    _startCountdown(seconds);
  }

  Future<String?> _playVideo(_ProjectorMediaItem item, String url) async {
    if (Platform.isAndroid) {
      return _playVideoWithAndroidNativePlayer(item, url);
    }
    try {
      String playUrl = url;
      if (item.provider == "BaiduNetdisk") {
        await _proxyServer.start();
        playUrl = _proxyServer.makeProxyUrl(url,
            headers: {HttpHeaders.userAgentHeader: "pan.baidu.com"}).toString();
      }
      debugPrint("Projector playing video: ${item.path}, url=$playUrl");
      await _videoPlayer.setUrl(playUrl);
      await _videoPlayer.prepare();
      return null;
    } catch (e) {
      debugPrint("Projector video play failed: $e");
      return "Video player error: $e";
    }
  }

  Future<String?> _playVideoWithAndroidNativePlayer(
      _ProjectorMediaItem item, String url) async {
    try {
      final headers = <String, String>{};
      if (item.provider == "BaiduNetdisk") {
        headers[HttpHeaders.userAgentHeader] = "pan.baidu.com";
      }
      final playerType = SpUtil.getString(AlistConstant.playerType);
      await SpUtil.remove(AlistConstant.projectorNativePlayerCompleted);
      _awaitingAndroidNativeVideoReturn = true;
      await AlistPlugin.playVideoWithInternalPlayer(
        [
          {
            "name": item.name,
            "localPath": null,
            "remotePath": item.path,
            "sign": item.sign,
            "provider": item.provider,
            "thumb": null,
            "url": url,
            "modifiedMilliseconds": null,
            "size": null,
          }
        ],
        0,
        headers.isEmpty ? null : headers,
        playerType,
        finishOnComplete: true,
        autoCloseAfterSeconds:
            _config.videoStayInfinite ? null : _config.videoStaySeconds,
      );
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return null;
    } catch (e) {
      _awaitingAndroidNativeVideoReturn = false;
      debugPrint("Projector Android native video play failed: $e");
      return "Android video player error: $e";
    }
  }

  Future<String?> _playAudio(_ProjectorMediaItem item, String url) async {
    try {
      final headers = <String, String>{};
      if (item.provider == "BaiduNetdisk") {
        headers[HttpHeaders.userAgentHeader] = "pan.baidu.com";
      }
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          headers: headers,
        ),
      );
      await _audioPlayer.play();
      return null;
    } catch (e) {
      debugPrint("Projector audio play failed: $e");
      return "Audio player error: $e";
    }
  }

  void _onCurrentMediaCompleted() {
    _nextMedia();
  }

  void _skipCurrentAsUnsupported({String? reason}) {
    if (_currentItem != null) {
      _unsupportedErrors[_currentItem!.path] =
          reason ?? "Skipped by user or player error";
    }
    SmartDialog.showToast(Intl.projectorPlayer_skipUnsupported.tr);
    _nextMedia();
  }

  void _startCountdown(int seconds) {
    _cancelCountdown();
    if (seconds <= 0) {
      return;
    }
    if (mounted) {
      setState(() {
        _countdownSeconds = seconds;
      });
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _countdownSeconds = 0;
        });
        _nextMedia();
        return;
      }
      setState(() {
        _countdownSeconds -= 1;
      });
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (_countdownSeconds != 0 && mounted) {
      setState(() {
        _countdownSeconds = 0;
      });
    } else {
      _countdownSeconds = 0;
    }
  }

  void _onVideoViewCreated(int viewId) {
    _videoPlayer.setPlayerView(viewId);
  }

  bool _isInfiniteCurrent() {
    final mediaType = _currentItem?.mediaType;
    if (mediaType == _ProjectorMediaType.video) {
      return _config.videoStayInfinite;
    }
    if (mediaType == _ProjectorMediaType.audio) {
      return _config.audioStayInfinite;
    }
    return false;
  }

  String _currentModeLabel() {
    switch (_config.traversalMode) {
      case ProjectorTraversalMode.orderedDfs:
        return Intl.projectorConfig_mode_orderedDfs.tr;
      case ProjectorTraversalMode.randomWalk:
        return Intl.projectorConfig_mode_randomWalk.tr;
      case ProjectorTraversalMode.randomAllTree:
        return Intl.projectorConfig_mode_randomAll.tr;
    }
  }

  bool _isActivateKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space;
  }

  bool _isDirectionalKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight;
  }

  void _setOverlayVisible(bool visible, {bool requestActionFocus = false}) {
    if (!mounted) {
      return;
    }
    if (_showOverlay == visible) {
      if (visible && requestActionFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _closeButtonFocusNode.requestFocus();
        });
      }
      return;
    }
    setState(() {
      _showOverlay = visible;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (visible && requestActionFocus) {
        _closeButtonFocusNode.requestFocus();
      } else if (!visible) {
        _pageFocusNode.requestFocus();
      }
    });
  }

  KeyEventResult _handlePlayerKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;

    if (!_showOverlay && (_isActivateKey(key) || _isDirectionalKey(key))) {
      _setOverlayVisible(true, requestActionFocus: true);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<bool> _onWillPop() async {
    if (_showOverlay) {
      _setOverlayVisible(false);
      return false;
    }
    return true;
  }

  void _copyErrorText() {
    if (_errorText == null || _errorText!.isEmpty) {
      return;
    }
    Clipboard.setData(ClipboardData(text: _errorText!));
    SmartDialog.showToast(Intl.tips_link_copied.tr);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _pageFocusNode,
      autofocus: true,
      onKeyEvent: _handlePlayerKeyEvent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _setOverlayVisible(!_showOverlay, requestActionFocus: !_showOverlay);
        },
        child: WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Positioned.fill(child: _buildMediaBody(context)),
                if (_showOverlay) _buildTopOverlay(),
                if (_showOverlay) _buildBottomOverlay(),
                if (_loading)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          Intl.projectorPlayer_loading.tr,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaBody(BuildContext context) {
    if (_errorText != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorText!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _copyErrorText,
                child: Text(Intl.fileList_menu_copyLink.tr),
              ),
            ],
          ),
        ),
      );
    }
    final currentItem = _currentItem;
    final currentUrl = _currentUrl;
    if (currentItem == null || currentUrl == null) {
      return const SizedBox.expand();
    }

    switch (currentItem.mediaType) {
      case _ProjectorMediaType.image:
        return _buildImage(currentUrl);
      case _ProjectorMediaType.video:
        if (Platform.isAndroid) {
          return _buildAndroidVideoPlaceholder();
        }
        final size = MediaQuery.of(context).size;
        return AliPlayerView(
          onCreated: _onVideoViewCreated,
          x: 0,
          y: 0,
          width: size.width,
          height: size.height,
        );
      case _ProjectorMediaType.audio:
        return _buildAudio();
    }
  }

  Widget _buildImage(String url) {
    return Center(
      child: Image.network(
        url,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            _onCurrentImageFrameAvailable();
          }
          return child;
        },
        errorBuilder: (context, error, stackTrace) {
          if (!_imageFailedScheduled) {
            _imageFailedScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _skipCurrentAsUnsupported();
            });
          }
          return const Icon(
            Icons.broken_image_outlined,
            size: 56,
            color: Colors.white,
          );
        },
      ),
    );
  }

  Widget _buildAudio() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.music_note_rounded, color: Colors.white, size: 72),
          const SizedBox(height: 12),
          Text(
            _currentItem?.name ?? "",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidVideoPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.ondemand_video_rounded,
              color: Colors.white, size: 72),
          const SizedBox(height: 12),
          Text(
            _currentItem?.name ?? "",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTopOverlay() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(
              focusNode: _closeButtonFocusNode,
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
            Expanded(
              child: Text(
                _currentItem?.name ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              focusNode: _nextButtonFocusNode,
              onPressed: _nextMedia,
              icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    final footerLines = <String>[
      _currentModeLabel(),
      _sourcePathHint,
    ];
    if (_source.isScanning) {
      footerLines.add(Intl.projectorPlayer_scanning.tr);
    }
    if (_countdownSeconds > 0) {
      footerLines
          .add("${Intl.projectorPlayer_countdown.tr}: ${_countdownSeconds}s");
    } else if (_isInfiniteCurrent()) {
      footerLines.add(Intl.projectorPlayer_autoNextOnComplete.tr);
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          color: Colors.black45,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: footerLines
                .map((line) => Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

enum _ProjectorMediaType {
  image,
  video,
  audio,
}

class _ProjectorMediaItem {
  final String name;
  final String path;
  final String? sign;
  final String? provider;
  final _ProjectorMediaType mediaType;

  _ProjectorMediaItem({
    required this.name,
    required this.path,
    required this.sign,
    required this.provider,
    required this.mediaType,
  });
}

class _PreparedProjectorMedia {
  final _ProjectorMediaItem item;
  final String pathHint;
  final String url;
  final bool imagePrecached;

  _PreparedProjectorMedia({
    required this.item,
    required this.pathHint,
    required this.url,
    required this.imagePrecached,
  });
}

class _ProjectorDirectorySnapshot {
  final List<_ProjectorMediaItem> medias;
  final List<String> childFolders;

  _ProjectorDirectorySnapshot({
    required this.medias,
    required this.childFolders,
  });
}

class _ProjectorRepository {
  _ProjectorRepository({
    required this.backupPassword,
    required this.imageOnly,
  });

  final String backupPassword;
  final bool imageOnly;
  final CancelToken _cancelToken = CancelToken();
  final Map<String, _ProjectorDirectorySnapshot?> _cache = {};
  final Map<String, Future<_ProjectorDirectorySnapshot?>> _inflight = {};

  Future<_ProjectorDirectorySnapshot?> listDirectory(String path) {
    if (_cache.containsKey(path)) {
      return Future.value(_cache[path]);
    }
    final exist = _inflight[path];
    if (exist != null) {
      return exist;
    }
    final future = _requestDirectory(path);
    _inflight[path] = future;
    future.whenComplete(() {
      _inflight.remove(path);
    });
    return future;
  }

  Future<_ProjectorDirectorySnapshot?> _requestDirectory(String path) async {
    final completer = Completer<_ProjectorDirectorySnapshot?>();
    try {
      final password = await FilePasswordHelper()
          .fastFindPassword(path, backupPassword: backupPassword);
      final body = {
        "path": path,
        "password": password ?? "",
        "page": 1,
        "per_page": 0,
        "refresh": false,
      };
      DioUtils.instance.requestNetwork<FileListRespEntity>(
        Method.post,
        "fs/list",
        cancelToken: _cancelToken,
        params: body,
        onSuccess: (data) {
          try {
            final medias = <_ProjectorMediaItem>[];
            final childFolders = <String>[];
            final provider = data?.provider;
            for (final file in data?.content ?? <FileListRespContent>[]) {
              final completePath = file.getCompletePath(path);
              if (file.isDir) {
                childFolders.add(completePath);
              } else {
                final mediaType = _mapFileType(file.getFileType());
                if (mediaType != null) {
                  medias.add(_ProjectorMediaItem(
                    name: file.name,
                    path: completePath,
                    sign: file.sign,
                    provider: provider,
                    mediaType: mediaType,
                  ));
                }
              }
            }
            medias.sort((a, b) => NaturalSort.compare(a.name, b.name));
            childFolders.sort((a, b) => NaturalSort.compare(a, b));

            final snapshot = _ProjectorDirectorySnapshot(
              medias: medias,
              childFolders: childFolders,
            );
            _cache[path] = snapshot;
            completer.complete(snapshot);
          } catch (e, s) {
            debugPrint("Projector parse directory failed: $e\n$s");
            _cache[path] = null;
            completer.complete(null);
          }
        },
        onError: (code, msg) {
          debugPrint("Projector list directory failed: path=$path, msg=$msg");
          _cache[path] = null;
          completer.complete(null);
        },
      );
    } catch (e, s) {
      debugPrint("Projector request directory error: $e\n$s");
      completer.complete(null);
    }
    return completer.future;
  }

  _ProjectorMediaType? _mapFileType(FileType fileType) {
    switch (fileType) {
      case FileType.image:
        return _ProjectorMediaType.image;
      case FileType.video:
        return imageOnly ? null : _ProjectorMediaType.video;
      case FileType.audio:
        return imageOnly ? null : _ProjectorMediaType.audio;
      default:
        return null;
    }
  }

  void dispose() {
    _cancelToken.cancel();
  }

  String getDebugInfo() {
    final buffer = StringBuffer();
    buffer.writeln("Cache dump:");
    for (final entry in _cache.entries) {
      buffer.writeln("Path: ${entry.key}");
      final snapshot = entry.value;
      if (snapshot == null) {
        buffer.writeln("  <Failed or Loading>");
      } else {
        buffer.writeln("  Medias (${snapshot.medias.length}):");
        for (final m in snapshot.medias) {
          buffer.writeln("    - ${m.name} (${m.mediaType})");
        }
        buffer.writeln("  Folders (${snapshot.childFolders.length}):");
        for (final f in snapshot.childFolders) {
          buffer.writeln("    - $f");
        }
      }
    }
    return buffer.toString();
  }
}

abstract class _ProjectorTraversalSource {
  Future<_ProjectorMediaItem?> next();

  String? get currentPathHint;

  bool get isScanning;
}

class _OrderedDfsTraversalSource implements _ProjectorTraversalSource {
  _OrderedDfsTraversalSource(this._repository, this._rootPath);

  final _ProjectorRepository _repository;
  final String _rootPath;
  final List<_OrderedDfsFrame> _stack = [];
  String? _currentPathHint;

  @override
  String? get currentPathHint => _currentPathHint;

  @override
  bool get isScanning => false;

  @override
  Future<_ProjectorMediaItem?> next() async {
    int iterations = 0;
    const int maxIterations = 1000;

    while (true) {
      if (iterations++ > maxIterations) {
        return null;
      }
      if (_stack.isEmpty) {
        _stack.add(_OrderedDfsFrame(_rootPath));
      }
      final frame = _stack.last;
      frame.snapshot ??= await _repository.listDirectory(frame.path);
      final snapshot = frame.snapshot;
      if (snapshot == null) {
        _stack.removeLast();
        continue;
      }

      if (frame.mediaIndex < snapshot.medias.length) {
        _currentPathHint = frame.path;
        return snapshot.medias[frame.mediaIndex++];
      }
      if (frame.childIndex < snapshot.childFolders.length) {
        _stack.add(_OrderedDfsFrame(snapshot.childFolders[frame.childIndex++]));
        continue;
      }

      _stack.removeLast();
    }
  }
}

class _OrderedDfsFrame {
  _OrderedDfsFrame(this.path);

  final String path;
  _ProjectorDirectorySnapshot? snapshot;
  int mediaIndex = 0;
  int childIndex = 0;
}

class _RandomWalkTraversalSource implements _ProjectorTraversalSource {
  _RandomWalkTraversalSource(this._repository, this._rootPath);

  final _ProjectorRepository _repository;
  final String _rootPath;
  final Random _random = Random();
  final List<String> _pathStack = [];
  final Map<String, _RandomWalkCursor> _cursors = {};
  String? _currentPathHint;

  @override
  String? get currentPathHint => _currentPathHint;

  @override
  bool get isScanning => false;

  @override
  Future<_ProjectorMediaItem?> next() async {
    int iterations = 0;
    const int maxIterations = 1000;

    while (true) {
      if (iterations++ > maxIterations) {
        return null;
      }
      if (_pathStack.isEmpty) {
        _pathStack.add(_rootPath);
      }

      final currentPath = _pathStack.last;
      final cursor = await _cursorForPath(currentPath);
      if (cursor == null) {
        if (_pathStack.length > 1) {
          _pathStack.removeLast();
          continue;
        } else {
          return null;
        }
      }

      if (!cursor.hasRemainingItems) {
        if (_pathStack.length > 1) {
          _pathStack.removeLast();
          continue;
        }
        _resetAllCursors();
        continue;
      }

      final canJumpToParent = _pathStack.length > 1;
      if (canJumpToParent && _shouldJumpToParent(cursor.currentDirFileCount)) {
        _pathStack.removeLast();
        continue;
      }

      final canChooseMedia = cursor.hasRemainingMedias;
      final canChooseChild = cursor.hasRemainingChildren;
      if (canChooseMedia && canChooseChild) {
        if (_random.nextBool()) {
          final media = cursor.takeMedia();
          if (media != null) {
            _currentPathHint = currentPath;
            return media;
          }
        }
      } else if (canChooseMedia) {
        final media = cursor.takeMedia();
        if (media != null) {
          _currentPathHint = currentPath;
          return media;
        }
      }

      final child = cursor.takeChild();
      if (child == null) {
        if (canJumpToParent) {
          _pathStack.removeLast();
          continue;
        }
        _resetAllCursors();
        continue;
      }
      _pathStack.add(child);
    }
  }

  Future<_RandomWalkCursor?> _cursorForPath(String path) async {
    final existing = _cursors[path];
    if (existing != null) {
      return existing;
    }
    final snapshot = await _repository.listDirectory(path);
    if (snapshot == null) {
      return null;
    }
    final cursor = _RandomWalkCursor(snapshot, _random);
    _cursors[path] = cursor;
    return cursor;
  }

  void _resetAllCursors() {
    for (final cursor in _cursors.values) {
      cursor.reset(_random);
    }
  }

  bool _shouldJumpToParent(int currentDirFileCount) {
    final normalizedCount = max(0, currentDirFileCount);
    final jumpProbability = 1.0 / (normalizedCount + 1);
    return _random.nextDouble() < jumpProbability;
  }
}

class _RandomWalkCursor {
  _RandomWalkCursor(this.snapshot, Random random) {
    reset(random);
  }

  final _ProjectorDirectorySnapshot snapshot;
  final List<_ProjectorMediaItem> _remainingMedias = [];
  final List<String> _remainingChildren = [];

  bool get hasRemainingMedias => _remainingMedias.isNotEmpty;

  bool get hasRemainingChildren => _remainingChildren.isNotEmpty;

  bool get hasRemainingItems => hasRemainingMedias || hasRemainingChildren;

  int get currentDirFileCount => snapshot.medias.length + snapshot.childFolders.length;

  void reset(Random random) {
    _remainingMedias
      ..clear()
      ..addAll(snapshot.medias)
      ..shuffle(random);
    _remainingChildren
      ..clear()
      ..addAll(snapshot.childFolders)
      ..shuffle(random);
  }

  _ProjectorMediaItem? takeMedia() {
    if (_remainingMedias.isEmpty) {
      return null;
    }
    return _remainingMedias.removeLast();
  }

  String? takeChild() {
    if (_remainingChildren.isEmpty) {
      return null;
    }
    return _remainingChildren.removeLast();
  }
}

class _RandomAllTreeTraversalSource implements _ProjectorTraversalSource {
  _RandomAllTreeTraversalSource(this._repository, this._rootPath) {
    _seenDirs.add(_rootPath);
    _pendingDirs.add(_rootPath);
  }

  final _ProjectorRepository _repository;
  final String _rootPath;
  final Random _random = Random();
  final Queue<String> _pendingDirs = Queue<String>();
  final Set<String> _seenDirs = <String>{};
  final List<_ProjectorMediaItem> _allMedias = <_ProjectorMediaItem>[];
  List<int> _shuffledIndexQueue = <int>[];
  String? _currentPathHint;
  bool _scanning = false;
  bool _scanFinished = false;

  @override
  String? get currentPathHint => _currentPathHint;

  @override
  bool get isScanning => !_scanFinished;

  @override
  Future<_ProjectorMediaItem?> next() async {
    await _ensureReady();
    if (_allMedias.isEmpty) {
      return null;
    }

    if (!_scanFinished) {
      unawaited(_scanBatch());
      final item = _allMedias[_random.nextInt(_allMedias.length)];
      _currentPathHint = item.path;
      return item;
    }

    if (_shuffledIndexQueue.isEmpty) {
      _shuffledIndexQueue = List<int>.generate(_allMedias.length, (i) => i)
        ..shuffle(_random);
    }
    final index = _shuffledIndexQueue.removeLast();
    final item = _allMedias[index];
    _currentPathHint = item.path;
    return item;
  }

  Future<void> _ensureReady() async {
    while (_allMedias.isEmpty && !_scanFinished) {
      await _scanBatch();
    }
    if (!_scanFinished) {
      unawaited(_scanBatch());
    }
  }

  Future<void> _scanBatch() async {
    if (_scanning || _scanFinished) {
      return;
    }
    _scanning = true;
    try {
      var scanned = 0;
      while (_pendingDirs.isNotEmpty && scanned < 8) {
        final currentDir = _pendingDirs.removeFirst();
        _currentPathHint = currentDir;
        final snapshot = await _repository.listDirectory(currentDir);
        if (snapshot != null) {
          _allMedias.addAll(snapshot.medias);
          for (final child in snapshot.childFolders) {
            if (_seenDirs.add(child)) {
              _pendingDirs.add(child);
            }
          }
        }
        scanned++;
      }
      if (_pendingDirs.isEmpty) {
        _scanFinished = true;
      }
    } finally {
      _scanning = false;
    }
  }
}
