import '../core/task_registry.dart';
import '../exceptions.dart';
import '../platform/task_flow_platform.dart';
import 'task_chain.dart';
import 'task_constraints.dart';
import 'task_info.dart';
import 'task_priority.dart';
import 'task_result.dart';
import 'task_status.dart';
import 'unique_policy.dart';
import 'retry_policy.dart';

/// Signature for the dispatcher function passed to [TaskFlow.initialize].
typedef TaskFlowDispatcher = Future<TaskResult> Function(
  String taskName,
  Map<String, dynamic> input,
  int attempt,
  String executionId,
);

/// Main API for TaskFlow. All methods are static.
abstract final class TaskFlow {
  static bool _initialized = false;

  /// Initializes TaskFlow.
  ///
  /// Call this once in main() before runApp().
  ///
  /// Optionally pass a [dispatcher] function (top-level, annotated with
  /// @pragma('vm:entry-point')) to handle background task execution when
  /// the app is not in foreground.
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   TaskFlow.registerHandler('syncData', (ctx) async {
  ///     return TaskResult.success();
  ///   });
  ///   await TaskFlow.initialize();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> initialize({
    TaskFlowDispatcher? dispatcher,
  }) async {
    _initialized = true;
    await TaskFlowPlatform.instance.initialize();
  }

  /// Registers a handler for a task name.
  ///
  /// Must be called from within the dispatcher function during initialization.
  /// Example:
  /// ```dart
  /// TaskFlow.registerHandler('syncData', (ctx) async {
  ///   final userId = ctx.input['userId'] as String;
  ///   return TaskResult.success(data: {'synced': 42});
  /// });
  /// ```
  static void registerHandler(String name, TaskHandler handler) {
    TaskRegistry.instance().register(name, handler);
  }

  /// Enqueues a one-off task for execution.
  ///
  /// Returns the execution ID which can be used to monitor or cancel the task.
  /// Example:
  /// ```dart
  /// final id = await TaskFlow.enqueue(
  ///   'syncData',
  ///   input: {'userId': '123'},
  ///   constraints: TaskConstraints(network: NetworkConstraint.connected),
  ///   retry: RetryPolicy.exponential(maxAttempts: 3),
  /// );
  /// ```
  static Future<String> enqueue(
    String name, {
    Map<String, dynamic> input = const {},
    TaskConstraints? constraints,
    RetryPolicy? retry,
    TaskPriority priority = TaskPriority.normal,
    List<String> tags = const [],
    Duration? initialDelay,
    String? uniqueId,
    UniquePolicy? uniquePolicy,
  }) async {
    _ensureInitialized();

    return await TaskFlowPlatform.instance.enqueue(
      name: name,
      input: input,
      constraints: constraints?.toMap(),
      retry: retry?.toMap(),
      priority: priority.name,
      tags: tags,
      initialDelayMs: initialDelay?.inMilliseconds,
      uniqueId: uniqueId,
      uniquePolicy: uniquePolicy?.name,
    );
  }

  /// Starts building a task chain.
  ///
  /// Example:
  /// ```dart
  /// final chainId = await TaskFlow.chain('myChain')
  ///   .then('step1')
  ///   .thenAll(['step2a', 'step2b'])
  ///   .onFailure('handleError')
  ///   .enqueue(input: {'key': 'value'});
  /// ```
  static TaskChain chain(String id) => TaskChain(id);

  /// Schedules a periodic task.
  ///
  /// On Android, the interval must be at least 15 minutes.
  /// On iOS, the system controls actual timing (best-effort).
  /// Returns the schedule ID.
  /// Example:
  /// ```dart
  /// await TaskFlow.schedule(
  ///   'syncData',
  ///   interval: Duration(hours: 1),
  ///   constraints: TaskConstraints(network: NetworkConstraint.unmetered),
  /// );
  /// ```
  static Future<void> schedule(
    String name, {
    required Duration interval,
    Map<String, dynamic> input = const {},
    TaskConstraints? constraints,
    RetryPolicy? retry,
    TaskPriority priority = TaskPriority.normal,
    Duration? initialDelay,
    List<String> tags = const [],
  }) async {
    _ensureInitialized();

    // Enforce 15-minute minimum
    if (interval.inMinutes < 15) {
      throw ArgumentError(
        'Periodic task interval must be at least 15 minutes. Got: ${interval.inMinutes}min',
      );
    }

    await TaskFlowPlatform.instance.schedule(
      name: name,
      intervalMs: interval.inMilliseconds,
      input: input,
      constraints: constraints?.toMap(),
      retry: retry?.toMap(),
      priority: priority.name,
    );
  }

  /// Reschedules a periodic task with a new interval.
  static Future<void> reschedule(
    String name, {
    required Duration interval,
  }) async {
    _ensureInitialized();

    if (interval.inMinutes < 15) {
      throw ArgumentError(
        'Periodic task interval must be at least 15 minutes. Got: ${interval.inMinutes}min',
      );
    }

    await TaskFlowPlatform.instance.reschedule(
      name: name,
      intervalMs: interval.inMilliseconds,
    );
  }

  /// Stops a periodic task from running.
  static Future<void> unschedule(String name) async {
    _ensureInitialized();
    await TaskFlowPlatform.instance.unschedule(name);
  }

  /// Starts a persistent background service with foreground notification.
  ///
  /// On Android: Requires foreground notification to prevent app kill.
  /// On iOS: Limited to ~15 minutes of background execution (system constraint).
  ///
  /// Use this for:
  /// - GPS tracking (ride-hailing, delivery)
  /// - Real-time messaging (chat, notifications)
  /// - WebSocket connections
  /// - BLE scanning/communication
  ///
  /// Example:
  /// ```dart
  /// await TaskFlow.startService(
  ///   'liveTracking',
  ///   notificationTitle: 'Tracking Active',
  ///   notificationBody: 'Your location is being shared',
  ///   handlers: {
  ///     'updateLocation': (ctx) async {
  ///       final lat = ctx.input['lat'] as double?;
  ///       final lng = ctx.input['lng'] as double?;
  ///       return TaskResult.success();
  ///     },
  ///   },
  /// );
  /// ```
  static Future<void> startService(
    String name, {
    required String notificationTitle,
    required String notificationBody,
    String? notificationIconName,
    int notificationId = 1001,
    Duration? updateInterval,
  }) async {
    _ensureInitialized();
    await TaskFlowPlatform.instance.startService(
      name: name,
      notificationTitle: notificationTitle,
      notificationBody: notificationBody,
      notificationIconName: notificationIconName,
      notificationId: notificationId,
      updateIntervalMs: updateInterval?.inMilliseconds,
    );
  }

  /// Stops a persistent background service.
  static Future<void> stopService(String name) async {
    _ensureInitialized();
    await TaskFlowPlatform.instance.stopService(name);
  }

  /// Monitors the status of a task by name.
  ///
  /// Returns a stream of [TaskStatus] updates.
  /// Example:
  /// ```dart
  /// TaskFlow.monitor('syncData').listen((status) {
  ///   if (status is TaskRunning) {
  ///     print('Progress: ${status.progress}');
  ///   }
  /// });
  /// ```
  static Stream<TaskStatus> monitor(String name) {
    return TaskFlowPlatform.instance.taskEvents
        .where((event) => event['taskName'] == name)
        .map((event) => TaskStatus.fromMap(event));
  }

  /// Monitors the status of a specific task execution.
  static Stream<TaskStatus> monitorExecution(String executionId) {
    return TaskFlowPlatform.instance.taskEvents
        .where((event) => event['executionId'] == executionId)
        .map((event) => TaskStatus.fromMap(event));
  }

  /// Cancels all executions of a task by name.
  static Future<void> cancel(String name) async {
    _ensureInitialized();
    await TaskFlowPlatform.instance.cancel(name);
  }

  /// Cancels a specific task execution.
  static Future<void> cancelExecution(String executionId) async {
    _ensureInitialized();
    await TaskFlowPlatform.instance.cancelExecution(executionId);
  }

  /// Cancels an entire task chain.
  static Future<void> cancelChain(String chainId) async {
    _ensureInitialized();
    await TaskFlowPlatform.instance.cancelChain(chainId);
  }

  /// Cancels all tasks with a given tag.
  static Future<void> cancelByTag(String tag) async {
    _ensureInitialized();
    await TaskFlowPlatform.instance.cancelByTag(tag);
  }

  /// Cancels all tasks.
  static Future<void> cancelAll() async {
    _ensureInitialized();
    await TaskFlowPlatform.instance.cancelAll();
  }

  /// Gets the current status of a task by name.
  static Future<TaskStatus?> getStatus(String name) async {
    _ensureInitialized();
    final map = await TaskFlowPlatform.instance.getStatus(name);
    return map != null ? TaskStatus.fromMap(map) : null;
  }

  /// Gets all registered tasks.
  static Future<List<TaskInfo>> getAllTasks() async {
    _ensureInitialized();
    final maps = await TaskFlowPlatform.instance.getAllTasks();
    return maps.map((m) => TaskInfo.fromMap(m)).toList();
  }

  /// Gets all tasks with a given tag.
  static Future<List<TaskInfo>> getTasksByTag(String tag) async {
    _ensureInitialized();
    final maps = await TaskFlowPlatform.instance.getTasksByTag(tag);
    return maps.map((m) => TaskInfo.fromMap(m)).toList();
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      throw TaskFlowNotInitializedException();
    }
  }
}
