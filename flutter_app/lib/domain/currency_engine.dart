// Dart port of `src/lib/currencyEngine.ts`. Deterministic pure-function
// currency math: format, convert, snap-amount.
import 'package:decimal/decimal.dart';

/// Static rates (USD-base) — mirrors the seeded set in
/// `server/src/services/exchange.ts`. The wallet API can override
/// these at runtime via [CurrencyEngine.update].
class CurrencyEngine {
  static final Map<String, double> _rates = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'JPY': 156.8,
    'SGD': 1.34,
    'AUD': 1.52,
    'CAD': 1.37,
    'INR': 83.5,
    'CNY': 7.24,
    'AED': 3.67,
    'CHF': 0.91,
    'HKD': 7.81,
    'KRW': 1380.0,
    'MYR': 4.71,
    'THB': 36.4,
    'BRL': 5.12,
    'ZAR': 18.7,
    'MXN': 17.6,
  };

  /// Replace the current rate table (used by `walletStore.hydrate`).
  static void update(Map<String, num> rates) {
    for (final e in rates.entries) {
      _rates[e.key.toUpperCase()] = e.value.toDouble();
    }
  }

  static double rateOf(String code) {
    return _rates[code.toUpperCase()] ?? 1.0;
  }

  /// Convert `amount` from `fromCcy` to `toCcy` using stored USD-base rates.
  static double convert(double amount, String fromCcy, String toCcy) {
    final fromRate = Decimal.parse(rateOf(fromCcy).toString());
    final toRate = Decimal.parse(rateOf(toCcy).toString());
    final amt = Decimal.parse(amount.toString());
    final usd = amt / fromRate;
    final out = usd.toDecimal(scaleOnInfinitePrecision: 8) * toRate;
    return double.parse(out.toString());
  }

  /// Format a numeric amount with a code (e.g. "1,234.50 USD").
  static String format(double amount, String code, {int? decimals}) {
    final dp = decimals ?? (code == 'JPY' || code == 'KRW' ? 0 : 2);
    final fixed = amount.toStringAsFixed(dp);
    final parts = fixed.split('.');
    parts[0] = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '${parts.join('.')} ${code.toUpperCase()}';
  }

  /// "Snap" an amount to a friendly tier: 5/10/20/50/100… for quick-pick UI.
  static List<int> quickAmounts(double base) {
    final round = base <= 10
        ? const [1, 2, 5, 10]
        : base <= 100
            ? const [10, 20, 50, 100]
            : const [50, 100, 200, 500];
    return round;
  }
}
