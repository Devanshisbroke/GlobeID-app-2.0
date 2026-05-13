import 'package:dio/dio.dart';

import 'fx_adapter.dart';
import 'fx_models.dart';

/// `FrankfurterFxAdapter` — production FX adapter against the
/// ECB-backed `api.frankfurter.app` endpoint.
///
/// Endpoint: `GET https://api.frankfurter.app/latest?from=USD&to=EUR,JPY,...`
/// Response: `{ amount, base, date, rates: { EUR: 0.9170, ... } }`
///
/// Why Frankfurter?
///   • Free, no API key required
///   • ECB-sourced (regulatory-grade reference rates)
///   • Stable JSON contract since 2016
///   • Open-source backend
///
/// The adapter is intentionally narrow — it only knows how to read
/// the latest rates. Historical / time-series queries belong to a
/// future `HistoricalFxAdapter` so this class stays small.
class FrankfurterFxAdapter extends FxAdapter {
  FrankfurterFxAdapter({Dio? dio}) : _dio = dio ?? _defaultDio();

  static Dio _defaultDio() {
    return Dio(BaseOptions(
      baseUrl: 'https://api.frankfurter.app',
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 6),
      headers: {'Accept': 'application/json'},
    ));
  }

  final Dio _dio;
  final Map<FxPair, double> _previous = {};

  @override
  String get source => 'frankfurter';

  @override
  Future<FxQuote> quote(FxPair pair) async {
    final snap = await snapshot([pair]);
    final q = snap[pair];
    if (q == null) {
      throw FxAdapterException(
        'Frankfurter returned no rate for ${pair.handle}',
      );
    }
    return q;
  }

  @override
  Future<FxSnapshot> snapshot(List<FxPair> pairs) async {
    if (pairs.isEmpty) {
      return FxSnapshot(
        quotes: const {},
        fetchedAt: DateTime.now(),
        source: source,
      );
    }
    // Group by base so we can issue one request per base.
    final byBase = <String, List<FxPair>>{};
    for (final p in pairs) {
      byBase.putIfAbsent(p.base, () => []).add(p);
    }
    final results = <FxPair, FxQuote>{};
    final now = DateTime.now();
    for (final base in byBase.keys) {
      final pairList = byBase[base]!;
      final quotes = pairList.map((p) => p.quote).join(',');
      final res = await _dio.get(
        '/latest',
        queryParameters: {'from': base, 'to': quotes},
      );
      final data = res.data;
      if (data is! Map || data['rates'] is! Map) {
        throw FxAdapterException(
          'Frankfurter response malformed: ${data.runtimeType}',
        );
      }
      final rates = (data['rates'] as Map).cast<String, dynamic>();
      for (final p in pairList) {
        final raw = rates[p.quote];
        if (raw is! num) {
          throw FxAdapterException(
            'Frankfurter missing rate for ${p.handle}',
          );
        }
        final rate = raw.toDouble();
        final prev = _previous[p];
        final delta =
            prev == null || prev == 0 ? 0.0 : (rate - prev) / prev;
        _previous[p] = rate;
        results[p] = FxQuote(
          pair: p,
          rate: rate,
          delta: delta,
          fetchedAt: now,
          source: source,
        );
      }
    }
    return FxSnapshot(quotes: results, fetchedAt: now, source: source);
  }
}

/// Adapter-level error. Surfaced into the FX service which decides
/// whether to fall back to the demo adapter or surface the stale
/// chip.
class FxAdapterException implements Exception {
  FxAdapterException(this.message);
  final String message;
  @override
  String toString() => 'FxAdapterException: $message';
}
