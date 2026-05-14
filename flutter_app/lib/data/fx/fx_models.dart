/// Foundation models for the GlobeID FX rate stack.
///
/// `FxPair` — typed (base, quote) currency pair. Used as the
/// canonical key everywhere a rate is requested.
class FxPair {
  const FxPair(this.base, this.quote);
  final String base;
  final String quote;

  String get handle => '$base/$quote';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FxPair && other.base == base && other.quote == quote);

  @override
  int get hashCode => Object.hash(base, quote);

  @override
  String toString() => 'FxPair($handle)';
}

/// A single rate quote. Anatomy:
///   • `rate`     — current spot price (1 base = rate quote)
///   • `delta`    — % move since the previous fetched value (signed)
///   • `fetchedAt`— wall-clock time the value was acquired
///   • `source`   — provider handle, e.g. `frankfurter` or `demo`
class FxQuote {
  const FxQuote({
    required this.pair,
    required this.rate,
    required this.delta,
    required this.fetchedAt,
    required this.source,
  });

  final FxPair pair;
  final double rate;
  final double delta;
  final DateTime fetchedAt;
  final String source;

  /// `true` once the quote is older than [threshold]. Drives the
  /// `STALE · 2h AGO` chip on every Live FX surface.
  bool isStale({Duration threshold = const Duration(minutes: 5)}) =>
      DateTime.now().difference(fetchedAt) > threshold;

  FxQuote copyWith({
    double? rate,
    double? delta,
    DateTime? fetchedAt,
    String? source,
  }) =>
      FxQuote(
        pair: pair,
        rate: rate ?? this.rate,
        delta: delta ?? this.delta,
        fetchedAt: fetchedAt ?? this.fetchedAt,
        source: source ?? this.source,
      );

  @override
  String toString() =>
      'FxQuote(${pair.handle} ${rate.toStringAsFixed(4)} ${delta >= 0 ? '+' : ''}${(delta * 100).toStringAsFixed(2)}% @ $source)';
}

/// Container for a snapshot of every pair the FX service tracks.
class FxSnapshot {
  const FxSnapshot({
    required this.quotes,
    required this.fetchedAt,
    required this.source,
  });

  final Map<FxPair, FxQuote> quotes;
  final DateTime fetchedAt;
  final String source;

  bool isStale({Duration threshold = const Duration(minutes: 5)}) =>
      DateTime.now().difference(fetchedAt) > threshold;

  FxQuote? operator [](FxPair pair) => quotes[pair];
}
