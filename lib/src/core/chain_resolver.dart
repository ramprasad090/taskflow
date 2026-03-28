import '../exceptions.dart';
import 'task_registry.dart';

/// Represents one step in a resolved task chain.
final class ChainStep {
  /// Name of the task to execute.
  final String taskName;

  /// If true, this step contains multiple tasks to run in parallel.
  final bool parallel;

  /// Names of tasks to run in parallel (only populated if [parallel] is true).
  final List<String> names;

  // ignore: unused_element
  const ChainStep._sequential(this.taskName)
      : parallel = false,
        names = const [];

  // ignore: unused_element
  const ChainStep._parallel(this.names)
      : taskName = '',
        parallel = true;
}

/// Resolves task chains into an ordered list of executable steps.
final class ChainResolver {
  ChainResolver._();

  /// Validates that all task names in the steps are registered.
  ///
  /// Throws [TaskHandlerNotFoundException] if any step references
  /// an unregistered handler.
  static void validate(List<Map<String, dynamic>> steps, TaskRegistry registry) {
    for (final step in steps) {
      final parallel = step['parallel'] as bool? ?? false;
      if (parallel) {
        final names = step['names'] as List?;
        if (names != null) {
          for (final name in names.cast<String>()) {
            if (!registry.contains(name)) {
              throw TaskHandlerNotFoundException(name);
            }
          }
        }
      } else {
        final name = step['taskName'] as String?;
        if (name != null && !registry.contains(name)) {
          throw TaskHandlerNotFoundException(name);
        }
      }
    }
  }
}
