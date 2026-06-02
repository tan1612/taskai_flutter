import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _date = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTime = DateFormat('HH:mm - dd/MM/yyyy');
  static final DateFormat _time = DateFormat('HH:mm');

  static String date(DateTime value) => _date.format(value);

  static String dateTime(DateTime value) => _dateTime.format(value);

  static String time(DateTime value) => _time.format(value);

  static bool isSameDayOnly(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime endOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59);
  }
}
