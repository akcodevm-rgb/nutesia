import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dateKey = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayDate = DateFormat('MMM d, yyyy');
  static final DateFormat _displayDateShort = DateFormat('MMM d');
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _weekday = DateFormat('EEEE');

  /// Returns date string key for storage (yyyy-MM-dd)
  static String toKey(DateTime date) => _dateKey.format(date);

  /// Returns "Apr 14, 2026"
  static String toDisplay(DateTime date) => _displayDate.format(date);

  /// Returns "Apr 14"
  static String toShort(DateTime date) => _displayDateShort.format(date);

  /// Returns "9:30 AM"
  static String toTime(DateTime date) => _time.format(date);

  /// Returns "Monday"
  static String toWeekday(DateTime date) => _weekday.format(date);

  /// Returns "Today", "Yesterday" or formatted date
  static String toRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return toShort(date);
  }

  static String todayKey() => toKey(DateTime.now());
}
