import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/src/api/retry_policy.dart';
import 'package:taskflow/src/core/retry_engine.dart';

void main() {
  group('RetryEngine', () {
    group('computeDelay', () {
      test('no retry returns zero delay', () {
        final policy = RetryPolicy.none();
        final delay = RetryEngine.computeDelay(policy, 1);
        expect(delay, Duration.zero);
      });

      test('linear retry returns same delay', () {
        final policy = RetryPolicy.linear(
          maxAttempts: 3,
          delay: Duration(seconds: 10),
        );
        expect(RetryEngine.computeDelay(policy, 1), Duration(seconds: 10));
        expect(RetryEngine.computeDelay(policy, 2), Duration(seconds: 10));
      });

      test('exponential retry doubles delay', () {
        final policy = RetryPolicy.exponential(
          maxAttempts: 5,
          initialDelay: Duration(seconds: 1),
          maxDelay: Duration(seconds: 300),
          multiplier: 2.0,
          jitter: 0.0,
        );

        final delay1 = RetryEngine.computeDelay(policy, 1);
        final delay2 = RetryEngine.computeDelay(policy, 2);
        final delay3 = RetryEngine.computeDelay(policy, 3);

        expect(delay1.inSeconds, 1);
        expect(delay2.inSeconds, 2);
        expect(delay3.inSeconds, 4);
      });

      test('exponential respects maxDelay cap', () {
        final policy = RetryPolicy.exponential(
          maxAttempts: 10,
          initialDelay: Duration(seconds: 1),
          maxDelay: Duration(seconds: 60),
          multiplier: 2.0,
          jitter: 0.0,
        );

        // Attempt 7: 1 * 2^6 = 64 seconds, clamped to 60
        final delay = RetryEngine.computeDelay(policy, 7);
        expect(delay.inSeconds, lessThanOrEqualTo(60));
      });
    });

    group('shouldRetry', () {
      test('returns false when maxAttempts exceeded', () {
        final policy = RetryPolicy.linear(
          maxAttempts: 3,
          delay: Duration(seconds: 1),
        );

        expect(RetryEngine.shouldRetry(policy, 1), true);
        expect(RetryEngine.shouldRetry(policy, 2), true);
        expect(RetryEngine.shouldRetry(policy, 3), false);
        expect(RetryEngine.shouldRetry(policy, 4), false);
      });

      test('no retry policy never retries', () {
        final policy = RetryPolicy.none();
        expect(RetryEngine.shouldRetry(policy, 1), false);
      });
    });
  });
}
