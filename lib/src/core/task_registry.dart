import '../api/task_context.dart';
import '../api/task_result.dart';
import '../exceptions.dart';

/// Signature for a task handler function.
typedef TaskHandler = Future<TaskResult> Function(TaskContext context);

/// Registry of task handlers. Singleton.
final class TaskRegistry {
  static final TaskRegistry _instance = TaskRegistry._();

  factory TaskRegistry.instance() => _instance;

  TaskRegistry._();

  final Map<String, TaskHandler> _handlers = {};

  /// Registers a handler for a task name.
  ///
  /// Handlers should be registered in the dispatcher function passed to
  /// [TaskFlow.initialize].
  void register(String name, TaskHandler handler) {
    _handlers[name] = handler;
  }

  /// Looks up a handler by name.
  ///
  /// Throws [TaskHandlerNotFoundException] if not found.
  TaskHandler lookup(String name) {
    final handler = _handlers[name];
    if (handler == null) {
      throw TaskHandlerNotFoundException(name);
    }
    return handler;
  }

  /// Returns true if a handler with [name] is registered.
  bool contains(String name) => _handlers.containsKey(name);

  /// Returns all registered task names.
  Iterable<String> get registeredNames => _handlers.keys;

  /// Clears all registered handlers (used in tests).
  void clear() => _handlers.clear();
}
