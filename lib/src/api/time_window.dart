/// Time window constraint for when tasks can run.
///
/// Restrict task execution to specific hours of the day.
/// Useful for syncing only during off-peak hours or specific business hours.
///
/// Example:
/// ```dart
/// // Only sync between 2am-5am (off-peak)
/// final window = TimeWindow(
///   startHour: 2,
///   endHour: 5,
/// );
///
/// await TaskFlow.enqueue('sync', window: window);
/// ```
class TimeWindow {
  /// Start hour (0-23)
  final int startHour;

  /// End hour (0-23)
  final int endHour;

  /// Days of week when window applies (0=Sun, 1=Mon, etc.)
  /// null = all days
  final List<int>? daysOfWeek;

  TimeWindow({
    required this.startHour,
    required this.endHour,
    this.daysOfWeek,
  }) : assert(
    startHour >= 0 && startHour < 24,
    'startHour must be 0-23',
  ), assert(
    endHour >= 0 && endHour < 24,
    'endHour must be 0-23',
  );

  /// Check if current time is within window
  bool isNow() {
    final now = DateTime.now();
    final hour = now.hour;

    // Check hour
    bool inHourWindow = startHour < endHour
        ? hour >= startHour && hour < endHour
        : hour >= startHour || hour < endHour;

    if (!inHourWindow) return false;

    // Check day of week if specified
    if (daysOfWeek != null) {
      return daysOfWeek!.contains(now.weekday % 7);
    }

    return true;
  }

  /// Convert to map
  Map<String, dynamic> toMap() => {
    'startHour': startHour,
    'endHour': endHour,
    'daysOfWeek': daysOfWeek,
  };

  /// Common presets
  static final TimeWindow nightOnly = TimeWindow(
    startHour: 22,
    endHour: 6,
  );

  static final TimeWindow offPeak = TimeWindow(
    startHour: 2,
    endHour: 5,
  );

  static final TimeWindow businessHours = TimeWindow(
    startHour: 9,
    endHour: 17,
  );

  static final TimeWindow weekdaysOffPeak = TimeWindow(
    startHour: 2,
    endHour: 5,
    daysOfWeek: [1, 2, 3, 4, 5], // Mon-Fri
  );
}
