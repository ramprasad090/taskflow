import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/src/api/task_constraints.dart';

void main() {
  group('TaskConstraints', () {
    test('default constructor creates empty constraints', () {
      final constraints = TaskConstraints();
      expect(constraints.network, isNull);
      expect(constraints.batteryNotLow, false);
      expect(constraints.requiresCharging, false);
      expect(constraints.deviceIdle, false);
    });

    test('toMap serializes correctly', () {
      final constraints = TaskConstraints(
        network: NetworkConstraint.connected,
        batteryNotLow: true,
        requiresCharging: true,
        deviceIdle: false,
      );

      final map = constraints.toMap();
      expect(map['network'], 'connected');
      expect(map['batteryNotLow'], true);
      expect(map['requiresCharging'], true);
      expect(map['deviceIdle'], false);
    });

    test('fromMap deserializes correctly', () {
      final map = {
        'network': 'unmetered',
        'batteryNotLow': true,
        'requiresCharging': false,
        'deviceIdle': true,
      };

      final constraints = TaskConstraints.fromMap(map);
      expect(constraints.network, NetworkConstraint.unmetered);
      expect(constraints.batteryNotLow, true);
      expect(constraints.requiresCharging, false);
      expect(constraints.deviceIdle, true);
    });

    test('round-trip serialization works', () {
      final original = TaskConstraints(
        network: NetworkConstraint.connected,
        batteryNotLow: true,
      );

      final map = original.toMap();
      final restored = TaskConstraints.fromMap(map);

      expect(restored, original);
    });

    test('equality comparison works', () {
      final c1 = TaskConstraints(network: NetworkConstraint.connected);
      final c2 = TaskConstraints(network: NetworkConstraint.connected);
      final c3 = TaskConstraints(network: NetworkConstraint.unmetered);

      expect(c1, c2);
      expect(c1, isNot(c3));
    });
  });
}
