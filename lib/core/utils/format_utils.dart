import 'package:intl/intl.dart';

class FormatUtils {
  static final _currencyFormat = NumberFormat.currency(symbol: 'MK', decimalDigits: 0);
  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy HH:mm');

  static String currency(double amount) => _currencyFormat.format(amount);
  static String date(DateTime date) => _dateFormat.format(date);
  static String dateTime(DateTime date) => _dateTimeFormat.format(date);
}
