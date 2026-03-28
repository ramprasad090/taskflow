import 'package:flutter/foundation.dart';

/// Result of executing a background task handler.
///
/// Sealed so callers must handle all cases exhaustively.
sealed class TaskResult {
  const TaskResult();

  /// Task completed successfully.
  ///
  /// Optional [data] is passed to the next step in a chain, or stored for
  /// later retrieval via [TaskFlow.getStatus].
  const factory TaskResult.success({Map<String, dynamic>? data}) =
      TaskSuccess;

  /// Task failed permanently.
  ///
  /// The task will be retried according to the [RetryPolicy], and if all
  /// retries are exhausted, the chain (if any) will fail and invoke the
  /// failure handler.
  const factory TaskResult.failure({
    String? message,
    Object? error,
  }) = TaskFailure;

  /// Task needs to retry after a custom delay.
  ///
  /// Ignores the [RetryPolicy] and reschedules the task after [delay].
  /// Useful for rate-limiting or server-side backoff instructions.
  const factory TaskResult.retryLater(
    Duration delay, {
    Map<String, dynamic>? data,
  }) = TaskRetryLater;
}

/// Task completed successfully.
@immutable
final class TaskSuccess extends TaskResult {
  /// Output data passed to next chain step.
  final Map<String, dynamic>? data;

  const TaskSuccess({this.data});
}

/// Task failed.
@immutable
final class TaskFailure extends TaskResult {
  /// Optional error message.
  final String? message;

  /// Optional exception object.
  final Object? error;

  const TaskFailure({
    this.message,
    this.error,
  });
}

/// Task should retry after a custom delay.
@immutable
final class TaskRetryLater extends TaskResult {
  /// How long to wait before retrying.
  final Duration delay;

  /// Optional output data passed to next step (if this is a chain).
  final Map<String, dynamic>? data;

  const TaskRetryLater(
    this.delay, {
    this.data,
  });
}
