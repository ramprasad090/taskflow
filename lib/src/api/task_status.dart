import 'package:flutter/foundation.dart';

/// Status of a task execution. Sealed for exhaustive pattern matching.
sealed class TaskStatus {
  /// Unique ID for this task execution.
  final String executionId;

  /// Name of the registered task.
  final String taskName;

  const TaskStatus({
    required this.executionId,
    required this.taskName,
  });

  /// Deserializes from an event map (from platform EventChannel).
  static TaskStatus fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String?;
    final executionId = map['executionId'] as String? ?? '';
    final taskName = map['taskName'] as String? ?? '';

    Map<String, dynamic>? _castData(dynamic data) {
      if (data is Map) {
        return Map<String, dynamic>.from(data.cast<String, dynamic>());
      }
      return null;
    }

    return switch (type) {
      'queued' => TaskQueued(
          executionId: executionId,
          taskName: taskName,
        ),
      'running' => TaskRunning(
          executionId: executionId,
          taskName: taskName,
          progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
        ),
      'succeeded' => TaskSucceeded(
          executionId: executionId,
          taskName: taskName,
          data: _castData(map['data']),
        ),
      'failed' => TaskFailed(
          executionId: executionId,
          taskName: taskName,
          error: map['error'] as String?,
          attempt: map['attempt'] as int? ?? 0,
          maxAttempts: map['maxAttempts'] as int? ?? 0,
        ),
      'retrying' => TaskRetrying(
          executionId: executionId,
          taskName: taskName,
          attempt: map['attempt'] as int? ?? 0,
          nextAttempt: map['nextAttempt'] != null
              ? DateTime.parse(map['nextAttempt'] as String)
              : DateTime.now(),
        ),
      'cancelled' => TaskCancelled(
          executionId: executionId,
          taskName: taskName,
        ),
      _ => TaskQueued(
          executionId: executionId,
          taskName: taskName,
        ),
    };
  }
}

/// Task has been queued but not yet executed.
@immutable
final class TaskQueued extends TaskStatus {
  const TaskQueued({
    required super.executionId,
    required super.taskName,
  });
}

/// Task is currently running.
@immutable
final class TaskRunning extends TaskStatus {
  /// Progress 0.0–1.0 reported by the task handler.
  final double progress;

  const TaskRunning({
    required super.executionId,
    required super.taskName,
    required this.progress,
  });
}

/// Task completed successfully.
@immutable
final class TaskSucceeded extends TaskStatus {
  /// Output data returned by the task handler.
  final Map<String, dynamic>? data;

  const TaskSucceeded({
    required super.executionId,
    required super.taskName,
    this.data,
  });
}

/// Task failed after exhausting retries.
@immutable
final class TaskFailed extends TaskStatus {
  /// Error message if any.
  final String? error;

  /// The attempt number that failed.
  final int attempt;

  /// Maximum retries configured.
  final int maxAttempts;

  const TaskFailed({
    required super.executionId,
    required super.taskName,
    this.error,
    required this.attempt,
    required this.maxAttempts,
  });
}

/// Task failed but will retry after [nextAttempt].
@immutable
final class TaskRetrying extends TaskStatus {
  /// When the next attempt will be scheduled.
  final DateTime nextAttempt;

  /// Current attempt number.
  final int attempt;

  const TaskRetrying({
    required super.executionId,
    required super.taskName,
    required this.nextAttempt,
    required this.attempt,
  });
}

/// Task was cancelled by user request.
@immutable
final class TaskCancelled extends TaskStatus {
  const TaskCancelled({
    required super.executionId,
    required super.taskName,
  });
}
