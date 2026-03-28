/// Concurrency control to limit parallel task executions.
///
/// Prevent overwhelming servers or hitting rate limits by limiting how many
/// tasks can run in parallel.
///
/// Example:
/// ```dart
/// // Max 3 uploads at once
/// await TaskFlow.enqueue(
///   'uploadFile',
///   concurrency: 3,
/// );
/// ```
class ConcurrencyControl {
  /// Maximum number of tasks that can run in parallel
  final int maxConcurrent;

  /// Priority queue strategy (default: FIFO)
  final ConcurrencyStrategy strategy;

  const ConcurrencyControl({
    required this.maxConcurrent,
    this.strategy = ConcurrencyStrategy.fifo,
  }) : assert(maxConcurrent > 0, 'maxConcurrent must be > 0');

  /// Convert to map
  Map<String, dynamic> toMap() => {
    'maxConcurrent': maxConcurrent,
    'strategy': strategy.name,
  };

  /// Common presets
  static const ConcurrencyControl single = ConcurrencyControl(maxConcurrent: 1);
  static const ConcurrencyControl limited = ConcurrencyControl(maxConcurrent: 3);
  static const ConcurrencyControl moderate = ConcurrencyControl(maxConcurrent: 5);
  static const ConcurrencyControl liberal = ConcurrencyControl(maxConcurrent: 10);
}

/// Strategy for selecting which tasks to execute when at concurrency limit
enum ConcurrencyStrategy {
  /// First in, first out (default)
  fifo,

  /// Last in, first out
  lifo,

  /// Random
  random,

  /// By priority (high priority tasks execute first)
  byPriority,
}
