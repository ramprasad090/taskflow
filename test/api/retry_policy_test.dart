import 'package:flutter_test/flutter_test.dart';
import 'package:bg_orchestrator/src/api/retry_policy.dart';

void main() {
  group('RetryPolicy', () {
    test('none factory creates no-retry policy with maxAttempts=1', () {
      final policy = RetryPolicy.none();
      expect(policy.maxAttempts, 1);
    });

    test('linear factory creates linear policy', () {
      final policy = RetryPolicy.linear(
        maxAttempts: 3,
        delay: Duration(seconds: 10),
      );
      expect(policy.maxAttempts, 3);
    });

    test('exponential factory creates exponential policy with defaults', () {
      final policy = RetryPolicy.exponential(
        maxAttempts: 5,
        initialDelay: Duration(seconds: 1),
      );
      expect(policy.maxAttempts, 5);
    });

    test('custom factory creates custom policy', () {
      final policy = RetryPolicy.custom(
        maxAttempts: 4,
        delayForAttempt: (attempt) => Duration(seconds: attempt * 5),
      );
      expect(policy.maxAttempts, 4);
    });

    test('none toMap returns correct structure', () {
      final policy = RetryPolicy.none();
      final map = policy.toMap();
      expect(map['type'], 'none');
    });

    test('linear toMap returns correct structure', () {
      final policy = RetryPolicy.linear(
        maxAttempts: 3,
        delay: Duration(seconds: 10),
      );
      final map = policy.toMap();
      expect(map['type'], 'linear');
      expect(map['maxAttempts'], 3);
      expect(map['delayMs'], 10000);
    });

    test('exponential toMap returns correct structure', () {
      final policy = RetryPolicy.exponential(
        maxAttempts: 5,
        initialDelay: Duration(seconds: 1),
        maxDelay: Duration(hours: 1),
      );
      final map = policy.toMap();
      expect(map['type'], 'exponential');
      expect(map['maxAttempts'], 5);
      expect(map['initialDelayMs'], 1000);
      expect(map['maxDelayMs'], 3600000);
    });

    test('custom toMap returns delay list', () {
      final policy = RetryPolicy.custom(
        maxAttempts: 3,
        delayForAttempt: (attempt) => Duration(seconds: attempt * 10),
      );
      final map = policy.toMap();
      expect(map['type'], 'custom');
      expect(map['maxAttempts'], 3);
      expect((map['delaysMs'] as List).length, 3);
    });
  });
}
