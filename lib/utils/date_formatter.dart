import 'package:intl/intl.dart';

String formatDateTime(DateTime dateTime) {
  final formatter = DateFormat('MMM d, y HH:mm');
  return formatter.format(dateTime);
}

String formatDate(DateTime date) {
  final formatter = DateFormat('MMM d, y');
  return formatter.format(date);
}

String formatTime(DateTime time) {
  final formatter = DateFormat('HH:mm');
  return formatter.format(time);
}
