import 'package:flutter/foundation.dart';

/// Context passed to a task handler when it executes.
@immutable
final class TaskContext {
  /// The registered task name.
  final String taskName;

  /// Unique ID for this task execution.
  final String executionId;

  /// Input data passed when enqueueing.
  final Map<String, dynamic> input;

  /// Current attempt number (1-based).
  final int attempt;

  /// Output from the previous chain step, or null if this is the first step.
  final Map<String, dynamic>? previousOutput;

  /// Callback to report progress.
  final Future<void> Function(double progress)? _reportProgressFn;

  const TaskContext({
    required this.taskName,
    required this.executionId,
    required this.input,
    required this.attempt,
    this.previousOutput,
    Future<void> Function(double progress)? reportProgressFn,
  }) : _reportProgressFn = reportProgressFn;

  /// Reports task progress (0.0–1.0) to be streamed to listeners.
  ///
  /// Call this from within your task handler to update the progress UI.
  /// Progress values outside 0.0–1.0 will be clamped.
  Future<void> reportProgress(double progress) async {
    final clamped = progress.clamp(0.0, 1.0);
    await _reportProgressFn?.call(clamped);
  }
}
