/// Task timeout configuration with soft and hard limits.
///
/// - **Soft timeout**: Calls a warning callback but doesn't kill the task
/// - **Hard timeout**: Forces task termination after the limit
///
/// Example:
/// ```dart
/// final timeout = TaskTimeout(
///   soft: Duration(seconds: 30),  // warn at 30s
///   hard: Duration(minutes: 1),   // kill at 60s
///   onSoftTimeout: (executionId) {
///     print('Task taking too long: $executionId');
///   },
/// );
///
/// await TaskFlow.enqueue('longTask', timeout: timeout);
/// ```
class TaskTimeout {
  /// Duration before soft timeout warning
  final Duration? soft;

  /// Duration before hard timeout (force kill)
  final Duration hard;

  /// Callback when soft timeout is reached
  final void Function(String executionId)? onSoftTimeout;

  TaskTimeout({
    this.soft,
    required this.hard,
    this.onSoftTimeout,
  }) {
    if (soft != null && soft!.inMilliseconds >= hard.inMilliseconds) {
      throw ArgumentError('Hard timeout must be greater than soft timeout');
    }
  }

  /// Convert to map for platform channel
  Map<String, dynamic> toMap() => {
    'soft': soft?.inMilliseconds,
    'hard': hard.inMilliseconds,
  };

  /// Parse from map
  static TaskTimeout fromMap(Map<String, dynamic> map) {
    return TaskTimeout(
      soft: map['soft'] != null ? Duration(milliseconds: map['soft'] as int) : null,
      hard: Duration(milliseconds: map['hard'] as int),
    );
  }

  /// Preset: 5 minute hard timeout (typical for background tasks)
  static final TaskTimeout moderate = TaskTimeout(
    soft: Duration(minutes: 4),
    hard: Duration(minutes: 5),
  );

  /// Preset: 1 minute hard timeout (API calls, quick operations)
  static final TaskTimeout quick = TaskTimeout(
    soft: Duration(seconds: 45),
    hard: Duration(minutes: 1),
  );

  /// Preset: 30 minute hard timeout (long-running operations)
  static final TaskTimeout extended = TaskTimeout(
    soft: Duration(minutes: 25),
    hard: Duration(minutes: 30),
  );
}
