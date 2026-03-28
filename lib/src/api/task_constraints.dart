import 'package:flutter/foundation.dart';

/// Network requirement constraint for a background task.
enum NetworkConstraint {
  /// Requires any network connectivity (WiFi or mobile).
  connected,

  /// Requires unmetered network (typically WiFi).
  unmetered,
}

/// Constraints that must be satisfied before a background task executes.
@immutable
final class TaskConstraints {
  /// Network requirement. `null` means no network constraint.
  final NetworkConstraint? network;

  /// Task will only run if device battery is not low.
  /// Android: `setRequiresBatteryNotLow(true)`.
  /// iOS: checked in Dart before execution.
  final bool batteryNotLow;

  /// Task will only run if device is charging.
  /// Android: `setRequiresCharging(true)`.
  /// iOS: `requiresExternalPower = true`.
  final bool requiresCharging;

  /// Task will only run when device is idle.
  /// Android: `setRequiresDeviceIdle(true)`.
  /// iOS: **not supported** — logged as warning.
  final bool deviceIdle;

  /// Creates a [TaskConstraints] instance.
  const TaskConstraints({
    this.network,
    this.batteryNotLow = false,
    this.requiresCharging = false,
    this.deviceIdle = false,
  });

  /// Serializes to a map for passing to the platform.
  Map<String, dynamic> toMap() => {
        'network': network?.name,
        'batteryNotLow': batteryNotLow,
        'requiresCharging': requiresCharging,
        'deviceIdle': deviceIdle,
      };

  /// Deserializes from a map (e.g., from platform event).
  factory TaskConstraints.fromMap(Map<String, dynamic> map) => TaskConstraints(
        network: map['network'] != null
            ? NetworkConstraint.values.byName(map['network'] as String)
            : null,
        batteryNotLow: map['batteryNotLow'] as bool? ?? false,
        requiresCharging: map['requiresCharging'] as bool? ?? false,
        deviceIdle: map['deviceIdle'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskConstraints &&
          runtimeType == other.runtimeType &&
          network == other.network &&
          batteryNotLow == other.batteryNotLow &&
          requiresCharging == other.requiresCharging &&
          deviceIdle == other.deviceIdle;

  @override
  int get hashCode =>
      network.hashCode ^
      batteryNotLow.hashCode ^
      requiresCharging.hashCode ^
      deviceIdle.hashCode;
}
