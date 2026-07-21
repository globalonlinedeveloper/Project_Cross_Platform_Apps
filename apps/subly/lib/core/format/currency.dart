import 'package:intl/intl.dart';

/// Currency formatting with the design's demo FX conversion (so the currency
/// switcher in Settings visibly changes every figure).
class Currency {
  const Currency(this.symbol);
  final String symbol;

  static const Map<String, double> rates = <String, double>{
    r'$': 1.0,
    '€': 0.92,
    '£': 0.79,
    '₹': 83.0,
  };

  static final NumberFormat _f2 = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _f0 = NumberFormat('#,##0', 'en_US');

  double _c(double n) => n * (rates[symbol] ?? 1.0);

  String fmt(double n) => '$symbol${_f2.format(_c(n))}';
  String fmt0(double n) => '$symbol${_f0.format(_c(n))}';
}
