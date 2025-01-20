import 'package:flutter_timezone/flutter_timezone.dart';

class TimezoneUtils {
  /// Converts a datetime from source timezone to local timezone using UTC offset
  static DateTime convertToLocalTime(DateTime dateTime) {
    try {
     

      final localTime = dateTime.add(DateTime.now().timeZoneOffset);
      
      return localTime;
    } catch (e) {
      return dateTime; // Fallback to original time if conversion fails
    }
  }

  static Future<String> getLocalTimezone() async {
    try {
      return await FlutterTimezone.getLocalTimezone();
    } catch (e) {
      return 'UTC';
    }
  }
} 