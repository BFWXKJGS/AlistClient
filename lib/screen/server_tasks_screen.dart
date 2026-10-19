import 'dart:async';

import 'package:alist/entity/server_task.dart';
import 'package:alist/l10n/intl_keys.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/util/file_utils.dart';
import 'package:alist/widget/alist_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class ServerTasksScreen extends StatelessWidget {
  const ServerTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ServerTasksController());
    return AlistScaffold(
      appbarTitle: Text(Intl.serverTasksScreen_title.tr),
      appbarActions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case "retry_failed":
                controller.retryFailed();
                break;
              case "clear_succeeded":
                controller.clearSucceeded();
                break;
              case "clear_done":
                controller.clearDone();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: "retry_failed",
              child: Text(Intl.serverTasksScreen_retryFailed.tr),
            ),
            PopupMenuItem(
              value: "clear_succeeded",
              child: Text(Intl.serverTasksScreen_clearSucceeded.tr),
            ),
            PopupMenuItem(
              value: "clear_done",
              child: Text(Intl.serverTasksScreen_clearDone.tr),
            ),
          ],
        ),
      ],
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: Intl.serverTasksScreen_tabUndone.tr),
                Tab(text: Intl.serverTasksScreen_tabDone.tr),
              ],
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification) {
                    controller.pausePolling();
                  } else if (notification is ScrollEndNotification) {
                    controller.resumePolling();
                  }
                  return false;
                },
                child: TabBarView(
                  children: [
                    _TaskList(
                      controller: controller,
                      tasks: controller.undoneTasks,
                      done: false,
                    ),
                    _TaskList(
                      controller: controller,
                      tasks: controller.doneTasks,
                      done: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.controller,
    required this.tasks,
    required this.done,
  });

  final ServerTasksController controller;
  final RxList<ServerTask> tasks;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loadingError.value != null && tasks.isEmpty) {
        return _ErrorView(
          message: controller.loadingError.value!,
          onRetry: controller.refreshTasks,
        );
      }
      if (tasks.isEmpty) {
        return RefreshIndicator(
          onRefresh: controller.refreshTasks,
          child: ListView(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(child: Text(Intl.serverTasksScreen_empty.tr)),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: controller.refreshTasks,
        child: ListView.separated(
          itemCount: tasks.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) =>
              _TaskItem(task: tasks[index], controller: controller),
        ),
      );
    });
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(Intl.serverTasksScreen_retry.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  const _TaskItem({required this.task, required this.controller});

  final ServerTask task;
  final ServerTasksController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMove = task.type == "move";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isMove
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.secondary)
                      .withAlpha(40),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isMove
                      ? Intl.serverTasksScreen_typeMove.tr
                      : Intl.serverTasksScreen_typeCopy.tr,
                  style: theme.textTheme.labelSmall,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _extractFileName(task.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              if (task.canCancel)
                _ActionButton(
                  icon: Icons.close,
                  tooltip: Intl.serverTasksScreen_cancel.tr,
                  onPressed: () => controller.cancelTask(task),
                )
              else if (task.canRetry)
                _ActionButton(
                  icon: Icons.refresh,
                  tooltip: Intl.serverTasksScreen_retryTask.tr,
                  onPressed: () => controller.retryTask(task),
                ),
              if (task.isDone)
                _ActionButton(
                  icon: Icons.delete_outline,
                  tooltip: Intl.serverTasksScreen_delete.tr,
                  onPressed: () => controller.deleteTask(task),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _StateChip(task: task),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.error.isNotEmpty ? task.error : task.status,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: task.error.isNotEmpty
                        ? theme.colorScheme.error
                        : theme.hintColor,
                  ),
                ),
              ),
            ],
          ),
          if (!task.isDone && task.progressValid) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: task.progress <= 0
                        ? null
                        : task.progress / 100.0,
                    minHeight: 5,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 46,
                  child: Text(
                    "${task.progress.toStringAsFixed(0)}%",
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _buildSubtitle(),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (task.totalBytes > 0) {
      parts.add(FileUtils.formatBytes(task.totalBytes) ?? "");
    }
    final time = task.endTime ?? task.startTime;
    if (time != null) {
      parts.add(
          "${time.year}-${_two(time.month)}-${_two(time.day)} ${_two(time.hour)}:${_two(time.minute)}");
    }
    return parts.join("  ·  ");
  }

  static String _two(int v) => v < 10 ? "0$v" : "$v";

  // Server task name:
  //   copy [/mount](/path/file) to [/mount](/dst)
  //   move [/mount](/path/file) to [/mount](/dst)
  static final RegExp _nameRegExp = RegExp(r'^.*?\((.*?)\)\s+to\s+\[(.*?)\]');

  String _extractFileName(String name) {
    final match = _nameRegExp.firstMatch(name);
    if (match != null) {
      final src = match.group(1) ?? "";
      final idx = src.lastIndexOf("/");
      if (idx >= 0 && idx < src.length - 1) {
        return src.substring(idx + 1);
      }
      return src;
    }
    return name;
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.task});

  final ServerTask task;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String text;
    switch (task.state) {
      case ServerTask.stateRunning:
        color = Colors.blue;
        text = Intl.serverTasksScreen_stateRunning.tr;
        break;
      case ServerTask.stateSucceeded:
        color = Colors.green;
        text = Intl.serverTasksScreen_stateSucceeded.tr;
        break;
      case ServerTask.stateCanceling:
        color = Colors.orange;
        text = Intl.serverTasksScreen_stateCanceling.tr;
        break;
      case ServerTask.stateCanceled:
        color = Colors.grey;
        text = Intl.serverTasksScreen_stateCanceled.tr;
        break;
      case ServerTask.stateFailed:
      case ServerTask.stateFailing:
        color = Colors.red;
        text = Intl.serverTasksScreen_stateFailed.tr;
        break;
      case ServerTask.stateErrored:
      case ServerTask.stateWaitingRetry:
      case ServerTask.stateBeforeRetry:
        color = Colors.orange;
        text = Intl.serverTasksScreen_stateWaitingRetry.tr;
        break;
      default:
        color = Colors.grey;
        text = Intl.serverTasksScreen_statePending.tr;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color),
      ),
    );
  }
}

class ServerTasksController extends GetxController {
  final undoneTasks = <ServerTask>[].obs;
  final doneTasks = <ServerTask>[].obs;
  final loadingError = RxnString();

  Timer? _pollTimer;
  bool _paused = false;
  bool _disposed = false;
  int _requestSeq = 0;
  // New AList exposes task APIs for non-admin users under /api/task, while
  // older AList / OpenList only have /api/admin/task. Null means not probed
  // yet; whichever path answers first wins and is reused afterwards.
  String? _taskBase;
  // Whether the server has a "move" task manager (OpenList yes, classic
  // AList no). Probed lazily so we don't log 404s every 3 seconds.
  bool? _moveSupported;

  @override
  void onInit() {
    super.onInit();
    refreshTasks();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _poll(false));
  }

  @override
  void onClose() {
    _disposed = true;
    _pollTimer?.cancel();
    super.onClose();
  }

  void pausePolling() => _paused = true;

  void resumePolling() {
    _paused = false;
    _poll(false);
  }

  Future<void> refreshTasks() => _poll(true);

  Future<void> _poll(bool manual) async {
    if (_disposed || (_paused && !manual)) {
      return;
    }
    final seq = ++_requestSeq;
    final types = <String>[
      "copy",
      if (_moveSupported != false) "move",
    ];
    final undone = <ServerTask>[];
    final done = <ServerTask>[];
    final errors = <String>{};

    for (final type in types) {
      final u = await _fetchTasks(type, false);
      if (_disposed || seq != _requestSeq) return;
      if (u.error != null) {
        if (u.statusCode == 404 && type == "move") {
          _moveSupported = false;
        } else if (u.statusCode != 404) {
          errors.add(u.error!);
        }
      } else {
        undone.addAll(u.tasks);
      }
      final d = await _fetchTasks(type, true);
      if (_disposed || seq != _requestSeq) return;
      if (d.error != null) {
        if (d.statusCode != 404) errors.add(d.error!);
      } else {
        done.addAll(d.tasks);
      }
    }

    undone.sort((a, b) =>
        (b.startTime ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.startTime ?? DateTime.fromMillisecondsSinceEpoch(0)));
    done.sort((a, b) =>
        (b.endTime ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.endTime ?? DateTime.fromMillisecondsSinceEpoch(0)));

    undoneTasks.value = undone;
    doneTasks.value = done;
    // Older AList has no "move" task manager and answers 404; that is normal.
    loadingError.value = errors.isEmpty ? null : errors.first;
  }

  static const String _adminBase = "admin/task";
  static const String _userBase = "task";

  List<String> get _bases =>
      _taskBase == null ? const [_adminBase, _userBase] : [_taskBase!];

  Future<_TaskFetchResult> _fetchTasks(String type, bool done) async {
    final suffix = "$type/${done ? "done" : "undone"}";
    _TaskFetchResult? last;
    for (final base in _bases) {
      final r = await _rawGet("$base/$suffix", type);
      if (r.error == null) {
        _taskBase ??= base;
        if (type == "move") _moveSupported = true;
        return r;
      }
      last = r;
      // 403: non-admin on the /admin path -> try the /task path.
      // 404: path prefix or task manager missing -> try next base.
      if (r.statusCode != 403 && r.statusCode != 404) break;
    }
    return last!;
  }

  Future<_TaskFetchResult> _rawGet(String url, String type) {
    final completer = Completer<_TaskFetchResult>();
    DioUtils.instance.requestNetwork<dynamic>(
      Method.get,
      url,
      onSuccess: (data) {
        final list = (data as List?)
                ?.whereType<Map>()
                .map((e) =>
                    ServerTask.fromJson(type, e.cast<String, dynamic>()))
                .toList() ??
            [];
        completer.complete(_TaskFetchResult(list, null, 200));
      },
      onError: (code, msg) {
        completer.complete(_TaskFetchResult(const [], "$code $msg", code));
      },
    );
    return completer.future;
  }

  void cancelTask(ServerTask task) => _postTaskAction(task, "cancel");

  void retryTask(ServerTask task) => _postTaskAction(task, "retry");

  void deleteTask(ServerTask task) => _postTaskAction(task, "delete");

  Future<void> _postTaskAction(ServerTask task, String action) async {
    SmartDialog.showLoading();
    final r = await _postWithFallback("${task.type}/$action", tid: task.id);
    SmartDialog.dismiss();
    if (r.ok) {
      refreshTasks();
    } else {
      SmartDialog.showToast(r.msg);
    }
  }

  Future<_PostResult> _postWithFallback(String suffix,
      {String? tid, Map<String, dynamic>? body}) async {
    _PostResult? last;
    for (final base in _bases) {
      final url = tid == null
          ? "$base/$suffix"
          : "$base/$suffix?tid=${Uri.encodeQueryComponent(tid)}";
      final r = await _rawPost(url, body);
      if (r.ok) {
        _taskBase ??= base;
        return r;
      }
      last = r;
      if (r.code != 403 && r.code != 404) break;
    }
    return last!;
  }

  Future<_PostResult> _rawPost(String url, Map<String, dynamic>? body) {
    final completer = Completer<_PostResult>();
    DioUtils.instance.requestNetwork<dynamic>(
      Method.post,
      url,
      params: body,
      onSuccess: (_) => completer.complete(_PostResult.ok()),
      onError: (code, msg) =>
          completer.complete(_PostResult.error(code, msg)),
    );
    return completer.future;
  }

  void retryFailed() => _runBatch("retry_failed");

  void clearSucceeded() => _runBatch("clear_succeeded");

  void clearDone() => _runBatch("clear_done");

  Future<void> _runBatch(String action) async {
    SmartDialog.showLoading();
    final bases = _bases;
    final types = <String>[
      "copy",
      if (_moveSupported != false) "move",
    ];
    for (final type in types) {
      for (var i = 0; i < bases.length; i++) {
        final base = bases[i];
        final r = await _rawPost("$base/$type/$action", null);
        if (r.ok) {
          _taskBase ??= base;
          break;
        }
        if (r.code == 404) {
          if (type == "move") _moveSupported = false;
          // Classic AList: move manager missing. Other base won't help.
          break;
        }
        if (r.code == 403 && i < bases.length - 1) continue;
        SmartDialog.showToast(r.msg);
        break;
      }
    }
    SmartDialog.dismiss();
    refreshTasks();
  }
}

class _TaskFetchResult {
  final List<ServerTask> tasks;
  final String? error;
  final int statusCode;

  _TaskFetchResult(this.tasks, this.error, this.statusCode);
}

class _PostResult {
  final bool ok;
  final int code;
  final String msg;

  _PostResult.ok()
      : ok = true,
        code = 200,
        msg = "";

  _PostResult.error(this.code, this.msg) : ok = false;
}

