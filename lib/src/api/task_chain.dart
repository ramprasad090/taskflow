import '../core/chain_resolver.dart';
import '../core/task_registry.dart';
import 'task_constraints.dart';
import 'retry_policy.dart';

/// Represents a raw chain step as built by TaskChain builder.
class _RawChainStep {
  final String? taskName;
  final List<String>? taskNames;

  _RawChainStep.single(this.taskName) : taskNames = null;
  _RawChainStep.parallel(this.taskNames) : taskName = null;
}

/// Fluent builder for task chains.
///
/// Example:
/// ```dart
/// final chainId = await TaskFlow.chain('my-chain')
///   .then('step1')
///   .then('step2')
///   .thenAll(['step3a', 'step3b'])
///   .onFailure('handleError')
///   .enqueue(input: {'key': 'value'});
/// ```
final class TaskChain {
  final String id;
  final List<_RawChainStep> _steps = [];
  TaskConstraints? constraints;
  RetryPolicy? retry;
  String? failureName;

  TaskChain(this.id);

  /// Adds a sequential task to the chain.
  ///
  /// This task will receive the output of the previous step (if any)
  /// in [TaskContext.previousOutput].
  TaskChain then(String taskName) {
    _steps.add(_RawChainStep.single(taskName));
    return this;
  }

  /// Adds multiple tasks to run in parallel.
  ///
  /// All tasks in the list will receive the same input as previous step.
  /// The chain waits for all parallel tasks to complete before proceeding
  /// to the next sequential step.
  TaskChain thenAll(List<String> taskNames) {
    _steps.add(_RawChainStep.parallel(taskNames));
    return this;
  }

  /// Registers a failure handler for this chain.
  ///
  /// If any step fails after exhausting retries, this handler will be invoked
  /// with information about the failure.
  TaskChain onFailure(String handlerName) {
    failureName = handlerName;
    return this;
  }

  /// Sets constraints for all steps in the chain.
  ///
  /// Can be overridden per-step if needed.
  TaskChain withConstraints(TaskConstraints constraints) {
    this.constraints = constraints;
    return this;
  }

  /// Sets retry policy for all steps in the chain.
  TaskChain withRetry(RetryPolicy retry) {
    this.retry = retry;
    return this;
  }

  /// Enqueues the chain for execution.
  ///
  /// Validates all task names and returns the chain ID.
  Future<String> enqueue({
    Map<String, dynamic> input = const {},
  }) async {
    // Build map for platform
    final stepsMap = _steps.map((step) {
      if (step.taskNames != null) {
        return {
          'parallel': true,
          'names': step.taskNames,
        };
      } else {
        return {
          'parallel': false,
          'taskName': step.taskName,
        };
      }
    }).toList();

    // Validate all task names
    ChainResolver.validate(stepsMap, TaskRegistry.instance());

    // TODO: Call platform via TaskFlowPlatform.instance
    // For now, return a dummy ID
    return 'chain-${DateTime.now().millisecondsSinceEpoch}';
  }
}
