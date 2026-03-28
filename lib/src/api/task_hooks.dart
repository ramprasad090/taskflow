import 'task_history.dart';

/// Global lifecycle hooks for task execution.
///
/// Register callbacks to track all task events:
/// - When a task starts
/// - When a task completes successfully
/// - When a task fails
/// - When a chain completes
///
/// Perfect for:
/// - Sentry/Crashlytics error reporting
/// - Analytics and metrics
/// - Logging and debugging
/// - Custom notifications
///
/// Example:
/// ```dart
/// TaskFlow.onTaskFailed((entry) {
///   Sentry.captureException(
///     Exception(entry.error),
///     stackTrace: entry.stackTrace,
///   );
/// });
///
/// TaskFlow.onTaskComplete((entry) {
///   print('Task ${entry.taskName} took ${entry.durationMs}ms');
/// });
/// ```
abstract class TaskHooks {
  /// Called when a task starts execution
  static final List<void Function(TaskHistoryEntry)> _onTaskStart = [];

  /// Called when a task completes successfully
  static final List<void Function(TaskHistoryEntry)> _onTaskComplete = [];

  /// Called when a task fails (after all retries exhausted)
  static final List<void Function(TaskHistoryEntry)> _onTaskFailed = [];

  /// Called when a task chain completes (all steps done or first failure)
  static final List<void Function(String chainId, String status)> _onChainComplete = [];

  /// Register callback for task start
  static void onTaskStart(void Function(TaskHistoryEntry) callback) {
    _onTaskStart.add(callback);
  }

  /// Register callback for task completion
  static void onTaskComplete(void Function(TaskHistoryEntry) callback) {
    _onTaskComplete.add(callback);
  }

  /// Register callback for task failure
  static void onTaskFailed(void Function(TaskHistoryEntry) callback) {
    _onTaskFailed.add(callback);
  }

  /// Register callback for chain completion
  static void onChainComplete(void Function(String chainId, String status) callback) {
    _onChainComplete.add(callback);
  }

  /// Internal: fire onTaskStart
  /// Called by platform layer when task execution starts
  @pragma('vm:entry-point')
  static void _fireOnTaskStart(TaskHistoryEntry entry) {
    for (final callback in _onTaskStart) {
      try {
        callback(entry);
      } catch (e) {
        print('Error in onTaskStart hook: $e');
      }
    }
  }

  /// Internal: fire onTaskComplete
  /// Called by platform layer when task execution completes
  @pragma('vm:entry-point')
  static void _fireOnTaskComplete(TaskHistoryEntry entry) {
    for (final callback in _onTaskComplete) {
      try {
        callback(entry);
      } catch (e) {
        print('Error in onTaskComplete hook: $e');
      }
    }
  }

  /// Internal: fire onTaskFailed
  /// Called by platform layer when task execution fails
  @pragma('vm:entry-point')
  static void _fireOnTaskFailed(TaskHistoryEntry entry) {
    for (final callback in _onTaskFailed) {
      try {
        callback(entry);
      } catch (e) {
        print('Error in onTaskFailed hook: $e');
      }
    }
  }

  /// Internal: fire onChainComplete
  /// Called by platform layer when task chain completes
  @pragma('vm:entry-point')
  static void _fireOnChainComplete(String chainId, String status) {
    for (final callback in _onChainComplete) {
      try {
        callback(chainId, status);
      } catch (e) {
        print('Error in onChainComplete hook: $e');
      }
    }
  }

  /// Clear all hooks
  static void clear() {
    _onTaskStart.clear();
    _onTaskComplete.clear();
    _onTaskFailed.clear();
    _onChainComplete.clear();
  }
}
