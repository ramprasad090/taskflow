import 'package:flutter/foundation.dart';

/// Base class for retry policies. Defines when and how to retry a failed task.
@immutable
sealed class RetryPolicy {
  /// Creates a no-retry policy.
  const factory RetryPolicy.none() = _NoRetry;

  /// Creates a linear backoff policy.
  /// Retries with the same [delay] between attempts.
  const factory RetryPolicy.linear({
    required int maxAttempts,
    required Duration delay,
  }) = _LinearRetry;

  /// Creates an exponential backoff policy.
  /// Delay doubles (or multiplies) each attempt with optional jitter.
  /// Default: maxDelay = 5 hours, multiplier = 2.0, jitter = 0.15 (±15%)
  const factory RetryPolicy.exponential({
    required int maxAttempts,
    required Duration initialDelay,
    Duration? maxDelay,
    double? multiplier,
    double? jitter,
  }) = _ExponentialRetry;

  /// Creates a custom backoff policy.
  /// The [delayForAttempt] function is called with the attempt number (1-based)
  /// and should return the delay before that attempt.
  const factory RetryPolicy.custom({
    required int maxAttempts,
    required Duration Function(int attempt) delayForAttempt,
  }) = _CustomRetry;

  const RetryPolicy._();

  /// Maximum number of attempts (including the initial one).
  int get maxAttempts;

  /// Serializes to a map for passing to the platform.
  Map<String, dynamic> toMap();
}

/// No retry policy.
@immutable
final class _NoRetry extends RetryPolicy {
  const _NoRetry() : super._();

  @override
  int get maxAttempts => 1;

  @override
  Map<String, dynamic> toMap() => {'type': 'none'};
}

/// Linear backoff policy.
@immutable
final class _LinearRetry extends RetryPolicy {
  /// Delay between attempts.
  final Duration delay;

  @override
  final int maxAttempts;

  const _LinearRetry({
    required this.maxAttempts,
    required this.delay,
  }) : super._();

  @override
  Map<String, dynamic> toMap() => {
        'type': 'linear',
        'maxAttempts': maxAttempts,
        'delayMs': delay.inMilliseconds,
      };
}

/// Exponential backoff policy.
@immutable
final class _ExponentialRetry extends RetryPolicy {
  /// Initial delay for the first retry.
  final Duration initialDelay;

  /// Maximum delay cap.
  final Duration maxDelay;

  /// Multiplier for exponential growth.
  final double multiplier;

  /// Jitter factor (±percentage of delay). E.g., 0.15 = ±15%.
  final double jitter;

  @override
  final int maxAttempts;

  const _ExponentialRetry({
    required this.maxAttempts,
    required this.initialDelay,
    Duration? maxDelay,
    double? multiplier,
    double? jitter,
  })  : maxDelay = maxDelay ?? const Duration(hours: 5),
        multiplier = multiplier ?? 2.0,
        jitter = jitter ?? 0.15,
        super._();

  @override
  Map<String, dynamic> toMap() => {
        'type': 'exponential',
        'maxAttempts': maxAttempts,
        'initialDelayMs': initialDelay.inMilliseconds,
        'maxDelayMs': maxDelay.inMilliseconds,
        'multiplier': multiplier,
        'jitter': jitter,
      };
}

/// Custom backoff policy.
@immutable
final class _CustomRetry extends RetryPolicy {
  /// Function that computes delay for a given attempt.
  final Duration Function(int attempt) delayForAttempt;

  @override
  final int maxAttempts;

  const _CustomRetry({
    required this.maxAttempts,
    required this.delayForAttempt,
  }) : super._();

  @override
  Map<String, dynamic> toMap() {
    final delays = <int>[];
    for (int i = 1; i <= maxAttempts; i++) {
      delays.add(delayForAttempt(i).inMilliseconds);
    }
    return {
      'type': 'custom',
      'maxAttempts': maxAttempts,
      'delaysMs': delays,
    };
  }
}
