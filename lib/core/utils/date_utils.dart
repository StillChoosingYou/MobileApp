import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final _dayMonthYear = DateFormat('MMM d, y');
  static final _monthYear = DateFormat('MMMM y');
  static final _time = DateFormat('h:mm a');
  static final _dayMonthYearTime = DateFormat('MMM d, y • h:mm a');

  static String date(DateTime d) => _dayMonthYear.format(d);
  static String monthYear(DateTime d) => _monthYear.format(d);
  static String time(DateTime d) => _time.format(d);
  static String dateTime(DateTime d) => _dayMonthYearTime.format(d);

  static String relative(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return date(d);
  }
}
