/// Cron-style scheduling for periodic tasks.
///
/// Supports standard 5-field cron expressions:
/// `minute hour day-of-month month day-of-week`
///
/// Examples:
/// - "0 9 * * MON" → Every Monday at 9:00 AM
/// - "0 */6 * * *" → Every 6 hours
/// - "0 0 1 * *" → First day of every month at midnight
/// - "*/15 * * * *" → Every 15 minutes
/// - "0 9-17 * * 1-5" → Every hour from 9am-5pm on weekdays
///
/// Field meanings:
/// 1. Minute (0-59)
/// 2. Hour (0-23)
/// 3. Day of month (1-31)
/// 4. Month (1-12 or JAN-DEC)
/// 5. Day of week (0-6 where 0=Sunday, or SUN-SAT)
///
/// Special characters:
/// - `*` = any value
/// - `,` = multiple values (e.g., MON,WED,FRI)
/// - `-` = range (e.g., 9-17)
/// - `/` = step (e.g., */5 = every 5 units)
class CronSchedule {
  final String expression;

  const CronSchedule(this.expression);

  /// Builder: Every N minutes
  /// Example: `CronSchedule.everyNMinutes(5)` → Every 5 minutes
  factory CronSchedule.everyNMinutes(int minutes) {
    if (minutes < 1 || minutes > 59) {
      throw ArgumentError('Minutes must be between 1 and 59');
    }
    return CronSchedule('*/$minutes * * * *');
  }

  /// Builder: Every N hours
  /// Example: `CronSchedule.everyNHours(6)` → Every 6 hours
  factory CronSchedule.everyNHours(int hours) {
    if (hours < 1 || hours > 23) {
      throw ArgumentError('Hours must be between 1 and 23');
    }
    return CronSchedule('0 */$hours * * *');
  }

  /// Builder: At specific time daily
  /// Example: `CronSchedule.dailyAt(hour: 9, minute: 30)` → 9:30 AM daily
  factory CronSchedule.dailyAt({required int hour, int minute = 0}) {
    if (hour < 0 || hour > 23) throw ArgumentError('Hour must be 0-23');
    if (minute < 0 || minute > 59) throw ArgumentError('Minute must be 0-59');
    return CronSchedule('$minute $hour * * *');
  }

  /// Builder: Specific days at specific time
  /// Example: `CronSchedule.onDaysAt(days: ['MON', 'WED', 'FRI'], hour: 9)` → 9 AM on Mon/Wed/Fri
  factory CronSchedule.onDaysAt({
    required List<String> days,
    required int hour,
    int minute = 0,
  }) {
    if (hour < 0 || hour > 23) throw ArgumentError('Hour must be 0-23');
    if (minute < 0 || minute > 59) throw ArgumentError('Minute must be 0-59');
    final dayStr = days.join(',');
    return CronSchedule('$minute $hour * * $dayStr');
  }

  /// Builder: Weekdays at specific time
  /// Example: `CronSchedule.weekdaysAt(hour: 9)` → 9 AM Mon-Fri
  factory CronSchedule.weekdaysAt({required int hour, int minute = 0}) {
    if (hour < 0 || hour > 23) throw ArgumentError('Hour must be 0-23');
    if (minute < 0 || minute > 59) throw ArgumentError('Minute must be 0-59');
    return CronSchedule('$minute $hour * * 1-5');
  }

  /// Builder: Weekends at specific time
  /// Example: `CronSchedule.weekendAt(hour: 10)` → 10 AM on Sat/Sun
  factory CronSchedule.weekendAt({required int hour, int minute = 0}) {
    if (hour < 0 || hour > 23) throw ArgumentError('Hour must be 0-23');
    if (minute < 0 || minute > 59) throw ArgumentError('Minute must be 0-59');
    return CronSchedule('$minute $hour * * 0,6');
  }

  /// Builder: Monthly at specific date and time
  /// Example: `CronSchedule.monthlyAt(day: 1, hour: 9)` → 1st of month at 9 AM
  factory CronSchedule.monthlyAt({required int day, required int hour, int minute = 0}) {
    if (day < 1 || day > 31) throw ArgumentError('Day must be 1-31');
    if (hour < 0 || hour > 23) throw ArgumentError('Hour must be 0-23');
    if (minute < 0 || minute > 59) throw ArgumentError('Minute must be 0-59');
    return CronSchedule('$minute $hour $day * *');
  }

  /// Parse and validate cron expression
  bool isValid() {
    try {
      _parseCron();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Internal: parse cron expression
  List<String> _parseCron() {
    final parts = expression.trim().split(RegExp(r'\s+'));
    if (parts.length != 5) {
      throw FormatException('Cron expression must have 5 fields, got ${parts.length}');
    }
    return parts;
  }

  /// Common presets
  static const CronSchedule everyMinute = CronSchedule('* * * * *');
  static const CronSchedule every5Minutes = CronSchedule('*/5 * * * *');
  static const CronSchedule every15Minutes = CronSchedule('*/15 * * * *');
  static const CronSchedule every30Minutes = CronSchedule('*/30 * * * *');
  static const CronSchedule hourly = CronSchedule('0 * * * *');
  static const CronSchedule daily = CronSchedule('0 0 * * *');
  static const CronSchedule dailyAt9am = CronSchedule('0 9 * * *');
  static const CronSchedule weeklyMonday = CronSchedule('0 0 * * MON');
  static const CronSchedule monthly = CronSchedule('0 0 1 * *');

  @override
  String toString() => expression;
}
