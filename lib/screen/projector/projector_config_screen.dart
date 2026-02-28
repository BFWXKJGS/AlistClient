import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/screen/projector/projector_models.dart';
import 'package:alist/util/named_router.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class ProjectorConfigScreen extends StatefulWidget {
  const ProjectorConfigScreen({super.key});

  @override
  State<ProjectorConfigScreen> createState() => _ProjectorConfigScreenState();
}

class _ProjectorConfigScreenState extends State<ProjectorConfigScreen> {
  late final TextEditingController _imageStayController;
  late final TextEditingController _videoStayController;
  late final TextEditingController _audioStayController;
  late final TextEditingController _preloadController;
  late final FocusNode _modeFocusNode;

  late final String _path;
  late final String _backupPassword;
  late ProjectorTraversalMode _traversalMode;
  late bool _imageOnly;
  late bool _videoStayInfinite;
  late bool _audioStayInfinite;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map?;
    _path = (args?["path"] as String?)?.trim().isNotEmpty == true
        ? (args?["path"] as String)
        : "/";
    _backupPassword = (args?["backupPassword"] as String?) ?? "";

    final config = ProjectorConfigStore.load();
    _traversalMode = config.traversalMode;
    _imageOnly = config.imageOnly;
    _videoStayInfinite = config.videoStayInfinite;
    _audioStayInfinite = config.audioStayInfinite;
    _imageStayController =
        TextEditingController(text: config.imageStaySeconds.toString());
    _videoStayController =
        TextEditingController(text: config.videoStaySeconds.toString());
    _audioStayController =
        TextEditingController(text: config.audioStaySeconds.toString());
    _preloadController =
        TextEditingController(text: config.preloadCount.toString());
    _modeFocusNode = FocusNode();
    if (defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _modeFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _imageStayController.dispose();
    _videoStayController.dispose();
    _audioStayController.dispose();
    _preloadController.dispose();
    _modeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlistScaffold(
      appbarTitle: Text(Intl.projectorConfig_title.tr),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(Intl.projectorConfig_path.tr),
              subtitle: Text(_path),
            ),
            const SizedBox(height: 12),
            _buildModeSelector(),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(Intl.projectorConfig_imageOnly.tr),
              value: _imageOnly,
              onChanged: (value) {
                setState(() {
                  _imageOnly = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildSecondsInput(
              label: Intl.projectorConfig_imageStaySeconds.tr,
              controller: _imageStayController,
              enabled: true,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(Intl.projectorConfig_videoStayInfinite.tr),
              value: _videoStayInfinite,
              onChanged: (value) {
                setState(() {
                  _videoStayInfinite = value;
                });
              },
            ),
            _buildSecondsInput(
              label: Intl.projectorConfig_videoStaySeconds.tr,
              controller: _videoStayController,
              enabled: !_videoStayInfinite,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(Intl.projectorConfig_audioStayInfinite.tr),
              value: _audioStayInfinite,
              onChanged: (value) {
                setState(() {
                  _audioStayInfinite = value;
                });
              },
            ),
            _buildSecondsInput(
              label: Intl.projectorConfig_audioStaySeconds.tr,
              controller: _audioStayController,
              enabled: !_audioStayInfinite,
            ),
            const SizedBox(height: 12),
            _buildSecondsInput(
              label: Intl.projectorConfig_preloadCount.tr,
              controller: _preloadController,
              enabled: true,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _startProjector,
              child: Text(Intl.projectorConfig_start.tr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return DropdownButtonFormField<ProjectorTraversalMode>(
      value: _traversalMode,
      focusNode: _modeFocusNode,
      decoration: InputDecoration(
        labelText: Intl.projectorConfig_mode.tr,
        border: const OutlineInputBorder(),
      ),
      items: ProjectorTraversalMode.values
          .map((mode) => DropdownMenuItem(
                value: mode,
                child: Text(_modeLabel(mode)),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _traversalMode = value;
          });
        }
      },
    );
  }

  Widget _buildSecondsInput({
    required String label,
    required TextEditingController controller,
    required bool enabled,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  String _modeLabel(ProjectorTraversalMode mode) {
    switch (mode) {
      case ProjectorTraversalMode.orderedDfs:
        return Intl.projectorConfig_mode_orderedDfs.tr;
      case ProjectorTraversalMode.randomWalk:
        return Intl.projectorConfig_mode_randomWalk.tr;
      case ProjectorTraversalMode.randomAllTree:
        return Intl.projectorConfig_mode_randomAll.tr;
    }
  }

  int? _parseSeconds(String value) {
    final result = int.tryParse(value.trim());
    if (result == null || result <= 0) {
      return null;
    }
    return result;
  }

  int? _parsePreloadCount(String value) {
    final result = int.tryParse(value.trim());
    if (result == null || result < 0) {
      return null;
    }
    return result.clamp(0, ProjectorConfig.maxPreloadCount).toInt();
  }

  Future<void> _startProjector() async {
    final imageStaySeconds = _parseSeconds(_imageStayController.text);
    if (imageStaySeconds == null) {
      SmartDialog.showToast(Intl.projectorConfig_invalidSeconds.tr);
      return;
    }

    final videoStaySeconds = _parseSeconds(_videoStayController.text);
    if (videoStaySeconds == null) {
      SmartDialog.showToast(Intl.projectorConfig_invalidSeconds.tr);
      return;
    }

    final audioStaySeconds = _parseSeconds(_audioStayController.text);
    if (audioStaySeconds == null) {
      SmartDialog.showToast(Intl.projectorConfig_invalidSeconds.tr);
      return;
    }

    final preloadCount = _parsePreloadCount(_preloadController.text);
    if (preloadCount == null) {
      SmartDialog.showToast(Intl.projectorConfig_invalidPreloadCount.tr);
      return;
    }

    final config = ProjectorConfig(
      traversalMode: _traversalMode,
      imageOnly: _imageOnly,
      imageStaySeconds: imageStaySeconds,
      videoStaySeconds: videoStaySeconds,
      audioStaySeconds: audioStaySeconds,
      preloadCount: preloadCount,
      videoStayInfinite: _videoStayInfinite,
      audioStayInfinite: _audioStayInfinite,
    );
    await ProjectorConfigStore.save(config);

    Get.toNamed(
      NamedRouter.projectorPlayer,
      arguments: {
        "path": _path,
        "backupPassword": _backupPassword,
        "config": config.toArgs(),
      },
      preventDuplicates: false,
    );
  }
}
