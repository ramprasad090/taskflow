import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/src/api/task_status.dart';

void main() {
  group('TaskStatus', () {
    test('fromMap creates TaskQueued', () {
      final map = {
        'type': 'queued',
        'executionId': 'exec-1',
        'taskName': 'syncData',
      };

      final status = TaskStatus.fromMap(map);
      expect(status, isA<TaskQueued>());
      expect((status as TaskQueued).executionId, 'exec-1');
      expect(status.taskName, 'syncData');
    });

    test('fromMap creates TaskRunning with progress', () {
      final map = {
        'type': 'running',
        'executionId': 'exec-1',
        'taskName': 'uploadFile',
        'progress': 0.5,
      };

      final status = TaskStatus.fromMap(map);
      expect(status, isA<TaskRunning>());
      expect((status as TaskRunning).progress, 0.5);
    });

    test('fromMap creates TaskSucceeded with data', () {
      final map = {
        'type': 'succeeded',
        'executionId': 'exec-1',
        'taskName': 'syncData',
        'data': {'count': 42},
      };

      final status = TaskStatus.fromMap(map);
      expect(status, isA<TaskSucceeded>());
      expect((status as TaskSucceeded).data?['count'], 42);
    });

    test('fromMap creates TaskFailed', () {
      final map = {
        'type': 'failed',
        'executionId': 'exec-1',
        'taskName': 'syncData',
        'error': 'Network timeout',
        'attempt': 3,
        'maxAttempts': 5,
      };

      final status = TaskStatus.fromMap(map);
      expect(status, isA<TaskFailed>());
      final failed = status as TaskFailed;
      expect(failed.error, 'Network timeout');
      expect(failed.attempt, 3);
      expect(failed.maxAttempts, 5);
    });

    test('fromMap creates TaskRetrying', () {
      final now = DateTime.now();
      final map = {
        'type': 'retrying',
        'executionId': 'exec-1',
        'taskName': 'syncData',
        'nextAttempt': now.toIso8601String(),
        'attempt': 2,
      };

      final status = TaskStatus.fromMap(map);
      expect(status, isA<TaskRetrying>());
      expect((status as TaskRetrying).attempt, 2);
    });

    test('fromMap creates TaskCancelled', () {
      final map = {
        'type': 'cancelled',
        'executionId': 'exec-1',
        'taskName': 'syncData',
      };

      final status = TaskStatus.fromMap(map);
      expect(status, isA<TaskCancelled>());
    });
  });
}
