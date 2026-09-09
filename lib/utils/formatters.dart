import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat numberFormat = NumberFormat('#,##0.##');

  static String formatCurrency(num value) => currencyFormat.format(value);

  static String formatLitres(num value) => '${numberFormat.format(value)} L';

  static String formatDate(DateTime date) =>
      DateFormat('dd MMM yyyy').format(date);

  static String formatMonth(DateTime date) =>
      DateFormat('MMMM yyyy').format(date);
}
