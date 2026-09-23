import 'package:intl/intl.dart';

/// The backend sends prices as integers in colón cents.
/// All conversion to text goes through here, never in widgets.
class Format {
  const Format._();

  static final NumberFormat _colones = NumberFormat.currency(
    locale: 'es_CR',
    symbol: '₡',
    decimalDigits: 0,
  );

  static String price(int cents) => _colones.format(cents / 100);
}
