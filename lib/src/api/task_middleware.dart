import 'task_context.dart';
import 'task_result.dart';

/// Signature for middleware that wraps task execution.
///
/// Middleware runs before and after every task handler.
/// Use for logging, auth token refresh, analytics, error tracking.
///
/// Example:
/// ```dart
/// class LoggingMiddleware extends TaskMiddleware {
///   @override
///   Future<TaskResult> execute(
///     String taskName,
///     TaskContext ctx,
///     Future<TaskResult> Function() next,
///   ) async {
///     print('📋 Task started: $taskName');
///     try {
///       final result = await next();
///       print('✅ Task completed: $taskName');
///       return result;
///     } catch (e) {
///       print('❌ Task failed: $taskName - $e');
///       rethrow;
///     }
///   }
/// }
///
/// // Register
/// TaskFlow.use(LoggingMiddleware());
/// ```
abstract class TaskMiddleware {
  /// Executes middleware around task handler.
  ///
  /// [taskName] — Name of the task being executed
  /// [ctx] — Task execution context (input, executionId, etc)
  /// [next] — Callback to the next middleware or actual handler
  ///
  /// Return the result from [next()] or modify it.
  Future<TaskResult> execute(
    String taskName,
    TaskContext ctx,
    Future<TaskResult> Function() next,
  );
}
