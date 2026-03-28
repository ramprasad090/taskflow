/// Record of a single task execution.
class TaskHistoryEntry {
  /// Unique execution ID
  final String executionId;

  /// Name of the task
  final String taskName;

  /// When execution started
  final DateTime startTime;

  /// When execution finished (null if still running)
  final DateTime? endTime;

  /// Status: 'queued', 'running', 'succeeded', 'failed', 'retrying', 'cancelled'
  final String status;

  /// Attempt number (1 for first, 2+ if retried)
  final int attempt;

  /// Max retries configured
  final int maxAttempts;

  /// Error message if failed
  final String? error;

  /// Stack trace if failed
  final String? stackTrace;

  /// Input data passed to task
  final Map<String, dynamic>? input;

  /// Output data returned by task (if succeeded)
  final Map<String, dynamic>? output;

  /// Execution duration in milliseconds
  int? get durationMs {
    if (endTime == null) return null;
    return endTime!.difference(startTime).inMilliseconds;
  }

  /// Whether task is still running
  bool get isRunning => endTime == null;

  /// Whether task succeeded
  bool get isSuccess => status == 'succeeded';

  /// Whether task failed
  bool get isFailed => status == 'failed';

  const TaskHistoryEntry({
    required this.executionId,
    required this.taskName,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.attempt,
    required this.maxAttempts,
    this.error,
    this.stackTrace,
    this.input,
    this.output,
  });

  /// Serialize to JSON for storage
  Map<String, dynamic> toMap() => {
    'executionId': executionId,
    'taskName': taskName,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'status': status,
    'attempt': attempt,
    'maxAttempts': maxAttempts,
    'error': error,
    'stackTrace': stackTrace,
    'input': input,
    'output': output,
    'durationMs': durationMs,
  };

  /// Deserialize from JSON
  static TaskHistoryEntry fromMap(Map<String, dynamic> map) {
    return TaskHistoryEntry(
      executionId: map['executionId'] as String,
      taskName: map['taskName'] as String,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null,
      status: map['status'] as String,
      attempt: map['attempt'] as int,
      maxAttempts: map['maxAttempts'] as int,
      error: map['error'] as String?,
      stackTrace: map['stackTrace'] as String?,
      input: map['input'] as Map<String, dynamic>?,
      output: map['output'] as Map<String, dynamic>?,
    );
  }
}
