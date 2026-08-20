import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _compactNumber = NumberFormat.compact();

  static String formatCurrency(double amount) {
    if (amount == 0.0) return 'Free';
    return _currencyFormat.format(amount);
  }

  static String formatCount(int count) {
    return _compactNumber.format(count);
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String formatDuration(String durationStr) {
    return durationStr;
  }
}
