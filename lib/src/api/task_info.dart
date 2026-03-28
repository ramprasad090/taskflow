import 'package:flutter/foundation.dart';
import 'task_status.dart';

/// Information about a registered or queued task.
@immutable
final class TaskInfo {
  /// The registered task name.
  final String name;

  /// Unique execution ID.
  final String executionId;

  /// Current status.
  final TaskStatus status;

  /// Tags associated with this task.
  final List<String> tags;

  /// Priority of this task.
  final String priority; // 'high', 'normal', 'low'

  /// When the task is/was scheduled to run, or null if not scheduled yet.
  final DateTime? scheduledAt;

  const TaskInfo({
    required this.name,
    required this.executionId,
    required this.status,
    this.tags = const [],
    this.priority = 'normal',
    this.scheduledAt,
  });

  /// Deserializes from a map (e.g., from platform getStatus result).
  factory TaskInfo.fromMap(Map<String, dynamic> map) => TaskInfo(
        name: map['name'] as String? ?? '',
        executionId: map['executionId'] as String? ?? '',
        status: TaskStatus.fromMap(
            map['status'] as Map<String, dynamic>? ?? <String, dynamic>{}),
        tags: List<String>.from(map['tags'] as List? ?? []),
        priority: map['priority'] as String? ?? 'normal',
        scheduledAt: map['scheduledAt'] != null
            ? DateTime.parse(map['scheduledAt'] as String)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          executionId == other.executionId;

  @override
  int get hashCode => name.hashCode ^ executionId.hashCode;
}
