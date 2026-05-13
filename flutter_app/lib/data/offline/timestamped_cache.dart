import 'dart:async';

/// `TimestampedCache<K, V>` — generic offline-first cache.
///
/// Stores per-key values with an acquisition timestamp so the UI
/// can render a STALE chip when the value is older than the
/// configured threshold.
///
/// Notably:
///   • `get(k)` returns the value even if stale — the UI decides
///     what to do with it
///   • `isStale(k, threshold)` flips when wall-clock passes the
///     threshold against the stored timestamp
///   • `watch(k)` is a broadcast stream of typed updates; multiple
///     observers can listen without coupling
///   • `clear()` empties the store; `forget(k)` removes one key
///
/// This is the offline-first floor every Live surface stands on —
/// boarding pass, FX rate, visa rule, flight status, etc. The
/// cache lives in-memory only; persistence is layered on top by
/// the surface that needs it (preferences, file, sqlite).
class TimestampedCache<K, V> {
  TimestampedCache({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  final _store = <K, _Entry<V>>{};
  final _streams = <K, StreamController<V>>{};

  /// Number of entries currently cached.
  int get length => _store.length;
  bool get isEmpty => _store.isEmpty;
  bool get isNotEmpty => _store.isNotEmpty;

  /// All cached keys in insertion order (Dart Map iteration order).
  Iterable<K> get keys => _store.keys;

  void put(K key, V value, {DateTime? at}) {
    final ts = at ?? _now();
    _store[key] = _Entry(value, ts);
    final stream = _streams[key];
    if (stream != null && !stream.isClosed) stream.add(value);
  }

  V? get(K key) => _store[key]?.value;

  DateTime? timestamp(K key) => _store[key]?.timestamp;

  bool contains(K key) => _store.containsKey(key);

  Duration? age(K key) {
    final ts = _store[key]?.timestamp;
    if (ts == null) return null;
    return _now().difference(ts);
  }

  bool isStale(K key, Duration threshold) {
    final a = age(key);
    if (a == null) return false;
    return a > threshold;
  }

  void forget(K key) {
    _store.remove(key);
  }

  void clear() {
    _store.clear();
  }

  /// Broadcast stream of value updates for a single key. Stream is
  /// shared across all listeners for the same key.
  Stream<V> watch(K key) {
    final existing = _streams[key];
    if (existing != null && !existing.isClosed) return existing.stream;
    final c = StreamController<V>.broadcast(
      onCancel: () {
        // Don't close the controller; another listener might come back.
      },
    );
    _streams[key] = c;
    return c.stream;
  }

  Future<void> dispose() async {
    for (final c in _streams.values) {
      if (!c.isClosed) await c.close();
    }
    _streams.clear();
    _store.clear();
  }
}

class _Entry<V> {
  const _Entry(this.value, this.timestamp);
  final V value;
  final DateTime timestamp;
}
