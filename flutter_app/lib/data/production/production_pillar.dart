/// Production reliability pillar — one row in the readiness hub.
///
/// Each pillar maps to a concrete production concern (live data
/// adapter, telemetry sink, offline-first cache, crash reporting,
/// performance instrumentation, etc.) and reports a status the
/// reviewer can read at a glance.
///
/// The hub itself is a pure presentation surface; the service
/// layer produces the [ProductionReadinessReport] that feeds it.
class ProductionPillar {
  const ProductionPillar({
    required this.handle,
    required this.sub,
    required this.status,
    required this.lastChecked,
    this.detail,
  });

  /// MONO-CAP handle that titles the row, e.g. `FX · LIVE · ADAPTER`.
  final String handle;

  /// Sentence-case sub line, e.g. `Frankfurter ECB feed`.
  final String sub;

  final ProductionStatus status;

  /// When the service last checked this pillar's status.
  final DateTime lastChecked;

  /// Optional integration / configuration detail line that renders
  /// in mono-cap small under the headline. Useful for surfacing a
  /// DSN hint, an adapter version, a cache key count, etc.
  final String? detail;
}

enum ProductionStatus {
  /// Pillar is wired against a live production source.
  live,

  /// Pillar is operating in demo / fixture mode (default in dev).
  demo,

  /// Pillar is wired but currently idle (e.g. Sentry DSN missing).
  idle,

  /// Pillar tripped an error during last health check.
  error,

  /// Pillar is not yet implemented or wired.
  missing,
}

extension ProductionStatusX on ProductionStatus {
  String get handle => switch (this) {
        ProductionStatus.live => 'LIVE',
        ProductionStatus.demo => 'DEMO',
        ProductionStatus.idle => 'IDLE',
        ProductionStatus.error => 'ERROR',
        ProductionStatus.missing => 'MISSING',
      };

  int get tone => switch (this) {
        ProductionStatus.live => 0xFF6CE0A8,
        ProductionStatus.demo => 0xFFD4AF37,
        ProductionStatus.idle => 0xFF8B96A6,
        ProductionStatus.error => 0xFFFF6A6A,
        ProductionStatus.missing => 0xFFFFB347,
      };

  bool get isCritical =>
      this == ProductionStatus.error || this == ProductionStatus.missing;
}

class ProductionReadinessReport {
  const ProductionReadinessReport({
    required this.pillars,
    required this.generatedAt,
  });

  final List<ProductionPillar> pillars;
  final DateTime generatedAt;

  int get total => pillars.length;
  int get live =>
      pillars.where((p) => p.status == ProductionStatus.live).length;
  int get demo =>
      pillars.where((p) => p.status == ProductionStatus.demo).length;
  int get idle =>
      pillars.where((p) => p.status == ProductionStatus.idle).length;
  int get error =>
      pillars.where((p) => p.status == ProductionStatus.error).length;
  int get missing =>
      pillars.where((p) => p.status == ProductionStatus.missing).length;

  /// Tier on the readiness ladder. green: zero critical, ≥80% live.
  /// gold: zero critical, 50–80% live (mostly demo). amber: zero
  /// critical, <50% live (mostly demo / idle). red: any critical.
  ReadinessTier get tier {
    if (error + missing > 0) return ReadinessTier.red;
    if (total == 0) return ReadinessTier.amber;
    final liveShare = live / total;
    if (liveShare >= 0.8) return ReadinessTier.green;
    if (liveShare >= 0.5) return ReadinessTier.gold;
    return ReadinessTier.amber;
  }
}

enum ReadinessTier { green, gold, amber, red }

extension ReadinessTierX on ReadinessTier {
  String get handle => switch (this) {
        ReadinessTier.green => 'GREEN · PRODUCTION',
        ReadinessTier.gold => 'GOLD · DEMO · DOMINANT',
        ReadinessTier.amber => 'AMBER · ATTENTION',
        ReadinessTier.red => 'RED · ACTION · REQUIRED',
      };

  int get tone => switch (this) {
        ReadinessTier.green => 0xFF6CE0A8,
        ReadinessTier.gold => 0xFFD4AF37,
        ReadinessTier.amber => 0xFFFFB347,
        ReadinessTier.red => 0xFFFF6A6A,
      };
}
