import 'package:intl/intl.dart';

/// El backend manda los precios como enteros en céntimos de colón.
/// Toda la conversión a texto pasa por acá, nunca en los widgets.
class Formato {
  const Formato._();

  static final NumberFormat _colones = NumberFormat.currency(
    locale: 'es_CR',
    symbol: '₡',
    decimalDigits: 0,
  );

  static String precio(int centimos) => _colones.format(centimos / 100);
}
