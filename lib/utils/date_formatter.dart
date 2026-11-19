import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return 'Tanggal tidak tersedia';
    return DateFormat('MMM d, yyyy, HH:mm', 'en_US').format(date.toLocal());
  }
}
