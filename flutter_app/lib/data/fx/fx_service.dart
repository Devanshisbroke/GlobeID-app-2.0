import 'dart:async';

import 'fx_adapter.dart';
import 'fx_models.dart';

/// `FxService` — wraps an [FxAdapter] with:
///   • last-known-good cache (so STALE chip can render the last
///     rate while a refresh is in flight)
///   • automatic refresh cadence (default 60s, configurable)
///   • single-flight semantics (concurrent reads share one call)
///   • optional fallback adapter when the primary throws
///
/// The service is intentionally async; UIs subscribe to [stream]
/// and reflect the latest snapshot.
class FxService {
  FxService({
    required this.adapter,
    this.fallback,
    this.refreshInterval = const Duration(seconds: 60),
    this.staleThreshold = const Duration(minutes: 5),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final FxAdapter adapter;
  final FxAdapter? fallback;
  final Duration refreshInterval;
  final Duration staleThreshold;
  final DateTime Function() _now;

  final _controller = StreamController<FxSnapshot>.broadcast();
  FxSnapshot? _last;
  Timer? _timer;
  Completer<FxSnapshot>? _inflight;
  List<FxPair>? _trackedPairs;

  Stream<FxSnapshot> get stream => _controller.stream;
  FxSnapshot? get last => _last;

  /// `true` iff there's at least one snapshot and it's beyond the
  /// staleness threshold.
  bool get isStale =>
      _last != null && _now().difference(_last!.fetchedAt) > staleThreshold;

  /// Begin tracking [pairs]. Issues one immediate fetch + sets up
  /// the periodic refresher.
  Future<FxSnapshot> track(List<FxPair> pairs) async {
    _trackedPairs = List.unmodifiable(pairs);
    _timer?.cancel();
    final first = await refresh();
    _timer = Timer.periodic(refreshInterval, (_) => refresh());
    return first;
  }

  /// Force a refresh of the tracked pairs.
  Future<FxSnapshot> refresh() async {
    if (_inflight != null) return _inflight!.future;
    final pairs = _trackedPairs;
    if (pairs == null) {
      throw StateError('FxService.refresh called before track()');
    }
    final completer = Completer<FxSnapshot>();
    // Mark the completer's future as expected — concurrent callers
    // listen to it, the originating caller listens to the
    // returned Future below. The `.ignore()` keeps an error on the
    // completer's future from becoming an unhandled async error
    // when nobody else is listening.
    completer.future.ignore();
    _inflight = completer;
    try {
      FxSnapshot snap;
      try {
        snap = await adapter.snapshot(pairs);
      } catch (e) {
        if (fallback == null) rethrow;
        final fb = await fallback!.snapshot(pairs);
        snap = FxSnapshot(
          quotes: fb.quotes,
          fetchedAt: fb.fetchedAt,
          source: '${fallback!.source}+fallback',
        );
      }
      _last = snap;
      _controller.add(snap);
      completer.complete(snap);
      return snap;
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _inflight = null;
    }
  }

  /// Release timers + streams. Call from any UI host that owns the
  /// service lifecycle.
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
