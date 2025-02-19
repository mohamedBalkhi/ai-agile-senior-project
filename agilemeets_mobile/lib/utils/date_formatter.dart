import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _shortDateFormat = DateFormat('MMM d');
  static final DateFormat _fullFormat = DateFormat('MMM d, yyyy h:mm a');

  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatDateCompact(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year) {
      return _shortDateFormat.format(date);
    }
    return _dateFormat.format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return _fullFormat.format(dateTime);
  }

  static String formatTimeRange(DateTime start, DateTime end) {
    final isSameDay = start.year == end.year && 
                     start.month == end.month && 
                     start.day == end.day;

    if (isSameDay) {
      return '${formatDateCompact(start)} ${formatTime(start)} - ${formatTime(end)}';
    }

    // For different days, show a more compact format
    return '${formatTime(start)} ${formatDateCompact(start)} - ${formatTime(end)} ${formatDateCompact(end)}';
  }
} 