import '../api/task_constraints.dart';

/// Utility for serializing and deserializing task constraints.
final class ConstraintMapper {
  ConstraintMapper._();

  /// Converts constraints to a map for platform communication.
  static Map<String, dynamic> toMap(TaskConstraints? constraints) {
    if (constraints == null) {
      return <String, dynamic>{};
    }
    return constraints.toMap();
  }

  /// Converts a map back to constraints.
  static TaskConstraints fromMap(Map<String, dynamic> map) {
    return TaskConstraints.fromMap(map);
  }
}
