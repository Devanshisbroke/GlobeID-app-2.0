import 'fx_models.dart';

/// Contract every FX rate source must satisfy.
///
/// Two production adapters ship with GlobeID:
///   • `FrankfurterFxAdapter`  — calls api.frankfurter.app (ECB-
///     backed, free, no API key)
///   • `DemoFxAdapter`         — deterministic drift used in demo
///     mode and in the test suite
abstract class FxAdapter {
  /// Canonical handle for telemetry / UI surfaces (e.g.
  /// `frankfurter`, `demo`, `cache`).
  String get source;

  /// Fetch a single rate.
  Future<FxQuote> quote(FxPair pair);

  /// Fetch a batched snapshot. Adapters that have a multi-quote
  /// endpoint should override; the default implementation issues
  /// one [quote] call per pair in parallel.
  Future<FxSnapshot> snapshot(List<FxPair> pairs) async {
    final results = await Future.wait(pairs.map(quote));
    final map = <FxPair, FxQuote>{
      for (final q in results) q.pair: q,
    };
    return FxSnapshot(
      quotes: map,
      fetchedAt: DateTime.now(),
      source: source,
    );
  }
}
