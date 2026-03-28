/// Rate limiting configuration.
///
/// Throttle background jobs to avoid overwhelming external resources.
/// Excess tasks are queued and drained when the time window resets.
///
/// Example:
/// ```dart
/// // Max 10 API calls per minute
/// const limit = RateLimit(
///   maxExecutions: 10,
///   window: Duration(minutes: 1),
/// );
///
/// await TaskFlow.enqueue(
///   'apiCall',
///   rateLimit: limit,
/// );
/// ```
class RateLimit {
  /// Maximum executions allowed per window
  final int maxExecutions;

  /// Time window
  final Duration window;

  const RateLimit({
    required this.maxExecutions,
    required this.window,
  }) : assert(maxExecutions > 0, 'maxExecutions must be > 0');

  /// Convert to map
  Map<String, dynamic> toMap() => {
    'maxExecutions': maxExecutions,
    'windowMs': window.inMilliseconds,
  };

  /// Common presets
  static const RateLimit conservative = RateLimit(
    maxExecutions: 5,
    window: Duration(minutes: 1),
  );

  static const RateLimit moderate = RateLimit(
    maxExecutions: 10,
    window: Duration(minutes: 1),
  );

  static const RateLimit aggressive = RateLimit(
    maxExecutions: 50,
    window: Duration(minutes: 1),
  );

  static const RateLimit hourly = RateLimit(
    maxExecutions: 100,
    window: Duration(hours: 1),
  );
}
