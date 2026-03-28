import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../taskflow_method_channel.dart';

/// Platform interface for TaskFlow.
abstract class TaskFlowPlatform extends PlatformInterface {
  /// Constructs a TaskFlowPlatform.
  TaskFlowPlatform() : super(token: _token);

  static final Object _token = Object();

  static TaskFlowPlatform? _instance;

  /// The default instance of [TaskFlowPlatform] to use.
  static TaskFlowPlatform get instance {
    _instance ??= MethodChannelTaskFlow();
    return _instance!;
  }

  /// Platform-specific implementations should set this.
  static set instance(TaskFlowPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initializes the platform with the dispatcher entry point.
  Future<void> initialize() {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Enqueues a one-off task.
  Future<String> enqueue({
    required String name,
    required Map<String, dynamic> input,
    Map<String, dynamic>? constraints,
    Map<String, dynamic>? retry,
    required String priority,
    required List<String> tags,
    int? initialDelayMs,
    String? uniqueId,
    String? uniquePolicy,
  }) {
    throw UnimplementedError('enqueue() has not been implemented.');
  }

  /// Enqueues a chain of tasks.
  Future<String> enqueueChain({
    required List<Map<String, dynamic>> steps,
    required Map<String, dynamic> input,
    Map<String, dynamic>? constraints,
  }) {
    throw UnimplementedError('enqueueChain() has not been implemented.');
  }

  /// Schedules a periodic task.
  Future<void> schedule({
    required String name,
    required int intervalMs,
    required Map<String, dynamic> input,
    Map<String, dynamic>? constraints,
    Map<String, dynamic>? retry,
    required String priority,
  }) {
    throw UnimplementedError('schedule() has not been implemented.');
  }

  /// Reschedules a periodic task.
  Future<void> reschedule({
    required String name,
    required int intervalMs,
  }) {
    throw UnimplementedError('reschedule() has not been implemented.');
  }

  /// Stops a periodic task.
  Future<void> unschedule(String name) {
    throw UnimplementedError('unschedule() has not been implemented.');
  }

  /// Starts a persistent background service with foreground notification.
  Future<void> startService({
    required String name,
    required String notificationTitle,
    required String notificationBody,
    String? notificationIconName,
    int notificationId = 1001,
    int? updateIntervalMs,
  }) {
    throw UnimplementedError('startService() has not been implemented.');
  }

  /// Stops a persistent background service.
  Future<void> stopService(String name) {
    throw UnimplementedError('stopService() has not been implemented.');
  }

  /// Cancels all executions of a task by name.
  Future<void> cancel(String name) {
    throw UnimplementedError('cancel() has not been implemented.');
  }

  /// Cancels a specific task execution.
  Future<void> cancelExecution(String executionId) {
    throw UnimplementedError('cancelExecution() has not been implemented.');
  }

  /// Cancels an entire task chain.
  Future<void> cancelChain(String chainId) {
    throw UnimplementedError('cancelChain() has not been implemented.');
  }

  /// Cancels all tasks with a given tag.
  Future<void> cancelByTag(String tag) {
    throw UnimplementedError('cancelByTag() has not been implemented.');
  }

  /// Cancels all tasks.
  Future<void> cancelAll() {
    throw UnimplementedError('cancelAll() has not been implemented.');
  }

  /// Gets the current status of a task.
  Future<Map<String, dynamic>?> getStatus(String name) {
    throw UnimplementedError('getStatus() has not been implemented.');
  }

  /// Gets all registered tasks.
  Future<List<Map<String, dynamic>>> getAllTasks() {
    throw UnimplementedError('getAllTasks() has not been implemented.');
  }

  /// Gets all tasks with a given tag.
  Future<List<Map<String, dynamic>>> getTasksByTag(String tag) {
    throw UnimplementedError('getTasksByTag() has not been implemented.');
  }

  /// Reports progress for a running task.
  Future<void> reportProgress({
    required String executionId,
    required double progress,
  }) {
    throw UnimplementedError('reportProgress() has not been implemented.');
  }

  /// Stream of task status events.
  Stream<Map<String, dynamic>> get taskEvents {
    throw UnimplementedError('taskEvents getter has not been implemented.');
  }
}
