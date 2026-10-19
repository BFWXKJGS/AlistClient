/// A server-side background task reported by AList / OpenList.
///
/// Endpoints:
///   GET  /api/admin/task/{copy|move}/undone
///   GET  /api/admin/task/{copy|move}/done
/// Newer AList also exposes the same endpoints under /api/task/...
/// without the admin prefix (regular users can see their own tasks).
///
/// Copy and move between two different storages run as background tasks;
/// operations inside the same storage complete immediately and never appear
/// here. OpenList registers both a "copy" and a "move" task manager, while
/// AList only has "copy" (cross-storage move is not supported there).
class ServerTask {
  /// tache.State enum value:
  /// 0 pending, 1 running, 2 succeeded, 3 canceling, 4 canceled,
  /// 5 errored (will retry), 6 failing, 7 failed, 8 waiting retry,
  /// 9 before retry
  static const int statePending = 0;
  static const int stateRunning = 1;
  static const int stateSucceeded = 2;
  static const int stateCanceling = 3;
  static const int stateCanceled = 4;
  static const int stateErrored = 5;
  static const int stateFailing = 6;
  static const int stateFailed = 7;
  static const int stateWaitingRetry = 8;
  static const int stateBeforeRetry = 9;

  ServerTask({
    required this.type,
    required this.id,
    required this.name,
    this.creator = "",
    this.creatorRole = 0,
    this.state = statePending,
    this.status = "",
    this.progress = 0,
    this.startTime,
    this.endTime,
    this.totalBytes = 0,
    this.error = "",
  });

  /// "copy" or "move" - filled in by the client from the requested endpoint.
  String type;
  String id;
  String name;
  String creator;
  int creatorRole;
  int state;
  String status;
  double progress;
  DateTime? startTime;
  DateTime? endTime;
  int totalBytes;
  String error;

  bool get isDone =>
      state == stateSucceeded ||
      state == stateCanceled ||
      state == stateFailed;

  bool get canCancel =>
      state == statePending ||
      state == stateRunning ||
      state == stateErrored ||
      state == stateWaitingRetry ||
      state == stateBeforeRetry;

  bool get canRetry => state == stateFailed || state == stateCanceled;

  /// A copy of a directory spawns one task per child object; the parent task
  /// itself never transfers bytes and the server reports progress as NaN.
  bool get progressValid => progress >= 0 && progress <= 100;

  factory ServerTask.fromJson(String type, Map<String, dynamic> json) {
    return ServerTask(
      type: type,
      id: (json["id"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      creator: (json["creator"] ?? "").toString(),
      creatorRole: (json["creator_role"] as num?)?.toInt() ?? 0,
      state: (json["state"] as num?)?.toInt() ?? statePending,
      status: (json["status"] ?? "").toString(),
      progress: (json["progress"] as num?)?.toDouble() ?? 0,
      startTime: _parseTime(json["start_time"]),
      endTime: _parseTime(json["end_time"]),
      totalBytes: (json["total_bytes"] as num?)?.toInt() ?? 0,
      error: (json["error"] ?? "").toString(),
    );
  }

  static DateTime? _parseTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }
}
