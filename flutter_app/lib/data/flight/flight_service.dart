import 'dart:async';

import 'flight_adapter.dart';
import 'flight_models.dart';

/// `FlightService` — wraps a [FlightAdapter] with:
///   • single-flight semantics per handle
///   • last-known-good cache (drives STALE chip)
///   • optional fallback adapter on error
///   • broadcast stream so multiple surfaces can observe a handle
class FlightService {
  FlightService({
    required this.adapter,
    this.fallback,
    this.staleThreshold = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final FlightAdapter adapter;
  final FlightAdapter? fallback;
  final Duration staleThreshold;
  final DateTime Function() _now;

  final _cache = <FlightHandle, FlightQuote>{};
  final _streams = <FlightHandle, StreamController<FlightQuote>>{};
  final _inflight = <FlightHandle, Completer<FlightQuote>>{};

  /// Latest cached quote (may be stale).
  FlightQuote? cached(FlightHandle handle) => _cache[handle];

  bool isStale(FlightHandle handle) {
    final q = _cache[handle];
    if (q == null) return false;
    return _now().difference(q.fetchedAt) > staleThreshold;
  }

  /// Stream of every quote update for [handle]. Multiple listeners
  /// share the underlying controller.
  Stream<FlightQuote> watch(FlightHandle handle) {
    return _streams
        .putIfAbsent(
          handle,
          () => StreamController<FlightQuote>.broadcast(),
        )
        .stream;
  }

  /// Force a fresh fetch. Concurrent calls for the same handle
  /// share one in-flight request.
  Future<FlightQuote> refresh(FlightHandle handle) async {
    final inflight = _inflight[handle];
    if (inflight != null) return inflight.future;

    final completer = Completer<FlightQuote>();
    completer.future.ignore();
    _inflight[handle] = completer;

    try {
      FlightQuote q;
      try {
        q = await adapter.quote(handle);
      } catch (e) {
        if (fallback == null) rethrow;
        final fb = await fallback!.quote(handle);
        q = fb.copyWith(source: '${fallback!.source}+fallback');
      }
      _cache[handle] = q;
      final stream = _streams[handle];
      stream?.add(q);
      completer.complete(q);
      return q;
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _inflight.remove(handle);
    }
  }

  void dispose() {
    for (final c in _streams.values) {
      c.close();
    }
    _streams.clear();
  }
}
