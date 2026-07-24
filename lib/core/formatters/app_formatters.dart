import 'package:intl/intl.dart';

abstract final class AppFormatters {
  static final currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  static final date = DateFormat('dd MMM y', 'en_IN');
  static final time = DateFormat('h:mm a', 'en_IN');
  static final dateTime = DateFormat('dd MMM y, h:mm a', 'en_IN');
}
