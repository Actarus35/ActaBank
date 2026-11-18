import 'package:intl/intl.dart';

final _amountFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 2);
final _roundedFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 0);

String formatAmount(double value, {bool signed = false, bool rounded = false}) {
  final text = (rounded ? _roundedFormat : _amountFormat).format(value.abs());
  if (!signed || value == 0) return text;
  return value > 0 ? '+$text' : '−$text';
}

String formatDate(DateTime d) => DateFormat('dd/MM/yyyy', 'fr_FR').format(d);

String formatDayHeader(DateTime d) {
  final now = DateTime.now();
  final day = DateTime(d.year, d.month, d.day);
  if (day == DateTime(now.year, now.month, now.day)) return "AUJOURD'HUI";
  if (day == DateTime(now.year, now.month, now.day - 1)) return 'HIER';
  final pattern = d.year == now.year ? 'EEEE d MMMM' : 'EEEE d MMMM yyyy';
  return DateFormat(pattern, 'fr_FR').format(d).toUpperCase();
}

String formatMonthYear(DateTime d) {
  final text = DateFormat('MMMM yyyy', 'fr_FR').format(d);
  return text[0].toUpperCase() + text.substring(1);
}