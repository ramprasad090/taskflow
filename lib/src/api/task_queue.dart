/// Named task queues with weighted priority.
///
/// Different queues are processed at different rates:
/// - critical: highest priority (100x weight)
/// - high: higher priority (10x weight)
/// - default: normal priority (1x weight)
/// - low: lower priority (0.1x weight)
///
/// Useful for ensuring payment tasks complete before analytics tasks.
///
/// Example:
/// ```dart
/// // Payment completes before analytics
/// await TaskFlow.enqueue('processPayment', queue: 'critical');
/// await TaskFlow.enqueue('trackAnalytics', queue: 'low');
/// ```
enum TaskQueue {
  /// Highest priority (100x execution weight)
  /// Use for: payments, critical operations, user-facing requests
  critical(weight: 100),

  /// High priority (10x execution weight)
  /// Use for: uploads, downloads, user data sync
  high(weight: 10),

  /// Normal priority (1x execution weight - default)
  /// Use for: routine syncs, background updates
  default_(weight: 1),

  /// Low priority (0.1x execution weight)
  /// Use for: analytics, logging, reporting, batch operations
  low(weight: 0.1);

  /// Relative execution weight (higher = executes more often)
  final double weight;

  const TaskQueue({required this.weight});

  /// Get queue name
  String get name {
    switch (this) {
      case TaskQueue.critical:
        return 'critical';
      case TaskQueue.high:
        return 'high';
      case TaskQueue.default_:
        return 'default';
      case TaskQueue.low:
        return 'low';
    }
  }

  /// Parse from string
  static TaskQueue fromString(String value) {
    return TaskQueue.values.firstWhere(
      (q) => q.name == value,
      orElse: () => TaskQueue.default_,
    );
  }
}
