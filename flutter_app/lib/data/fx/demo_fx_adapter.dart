import 'dart:math' as math;

import 'fx_adapter.dart';
import 'fx_models.dart';

/// `DemoFxAdapter` — deterministic, drift-driven FX adapter that
/// powers the cinematic demo state without hitting the network.
///
/// Each pair has a base rate; on every call a per-pair seeded RNG
/// nudges the rate by ±0.6 % so consecutive snapshots feel "alive"
/// without random noise breaking goldens. The drift is bounded so
/// the rate never escapes the ±2 % envelope around the base.
class DemoFxAdapter extends FxAdapter {
  DemoFxAdapter({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<FxPair, double> _state = {};

  /// Canonical USD-anchored base rates used in the existing
  /// `DemoData` seed. Kept in sync so the new adapter is a 1:1
  /// replacement for any callsite still reading the legacy seed.
  static const Map<String, double> _baseRates = {
    'EUR': 0.9170,
    'GBP': 0.7910,
    'JPY': 149.83,
    'INR': 83.21,
    'AED': 3.6725,
    'CHF': 0.8835,
    'CAD': 1.3712,
    'AUD': 1.5402,
    'SGD': 1.3401,
    'HKD': 7.8202,
  };

  @override
  String get source => 'demo';

  double _baseFor(FxPair pair) {
    if (pair.base == 'USD' && _baseRates.containsKey(pair.quote)) {
      return _baseRates[pair.quote]!;
    }
    if (pair.quote == 'USD' && _baseRates.containsKey(pair.base)) {
      return 1.0 / _baseRates[pair.base]!;
    }
    // Cross rate via USD.
    final baseToUsd = pair.base == 'USD' ? 1.0 : 1.0 / _baseRates[pair.base]!;
    final quoteFromUsd = pair.quote == 'USD' ? 1.0 : _baseRates[pair.quote]!;
    return baseToUsd * quoteFromUsd;
  }

  @override
  Future<FxQuote> quote(FxPair pair) async {
    final base = _baseFor(pair);
    final prev = _state[pair] ?? base;
    final seed = pair.handle.codeUnits.fold<int>(0, (a, b) => a + b) +
        _now().minute;
    final rng = math.Random(seed);
    // Drift = -0.6 % .. +0.6 %, biased to mean-revert toward the
    // base rate so the demo doesn't wander indefinitely.
    final drift = (rng.nextDouble() - 0.5) * 0.012;
    final reversion = (base - prev) / base * 0.4;
    final next = prev * (1 + drift + reversion);
    final clamped =
        next.clamp(base * 0.98, base * 1.02); // ±2 % envelope
    final delta = prev == 0 ? 0.0 : (clamped - prev) / prev;
    _state[pair] = clamped;
    return FxQuote(
      pair: pair,
      rate: clamped,
      delta: delta,
      fetchedAt: _now(),
      source: source,
    );
  }
}
