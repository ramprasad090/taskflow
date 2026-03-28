import 'dart:math';

import '../api/retry_policy.dart';

/// Computes retry delays and determines whether to retry.
final class RetryEngine {
  RetryEngine._();

  /// Computes the delay before the given [attempt] for the [policy].
  ///
  /// The returned duration is the time to wait before retrying.
  /// Returns [Duration.zero] for no-retry policies.
  static Duration computeDelay(
    RetryPolicy policy,
    int attempt,
  ) {
    final map = policy.toMap();
    final type = map['type'] as String;

    return switch (type) {
      'none' => Duration.zero,
      'linear' => Duration(milliseconds: map['delayMs'] as int),
      'exponential' => _exponentialDelay(
          initialDelayMs: map['initialDelayMs'] as int,
          maxDelayMs: map['maxDelayMs'] as int,
          multiplier: map['multiplier'] as double,
          jitter: map['jitter'] as double,
          attempt: attempt,
        ),
      'custom' => Duration(
          milliseconds: (map['delaysMs'] as List)[attempt - 1] as int),
      _ => Duration.zero,
    };
  }

  /// Determines if a retry should be attempted.
  ///
  /// Returns true if [attempt] < maxAttempts for the policy.
  static bool shouldRetry(RetryPolicy policy, int attempt) {
    return attempt < policy.maxAttempts;
  }

  /// Computes exponential backoff delay with optional jitter.
  static Duration _exponentialDelay({
    required int initialDelayMs,
    required int maxDelayMs,
    required double multiplier,
    required double jitter,
    required int attempt,
  }) {
    // Compute base delay: initialDelay * (multiplier ^ (attempt - 1))
    final exponent = attempt - 1;
    final baseMs = initialDelayMs * pow(multiplier, exponent).toDouble();

    // Apply jitter: ±(jitter * baseMs)
    var delayMs = baseMs;
    if (jitter > 0) {
      // Random value in [-jitter, +jitter]
      final jitterFactor = (Random().nextDouble() * 2 - 1) * jitter;
      final jitterMs = jitterFactor * baseMs;
      delayMs = baseMs + jitterMs;
    }

    // Clamp to maxDelay
    delayMs = delayMs.clamp(0, maxDelayMs.toDouble());

    return Duration(milliseconds: delayMs.toInt());
  }
}
