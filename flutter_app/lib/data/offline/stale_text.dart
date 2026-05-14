/// Formats a [Duration] into the canonical GlobeID "STALE · …" chip
/// text. All output is MONO-CAP, deliberately small footprint:
///   • `< 60s`   → `STALE · 0s · AGO`
///   • `< 60m`   → `STALE · 14m · AGO`
///   • `< 24h`   → `STALE · 2h · AGO`
///   • `< 30d`   → `STALE · 3d · AGO`
///   • `≥ 30d`   → `STALE · 1mo · AGO`
String staleHandle(Duration age) {
  final s = age.inSeconds;
  if (s < 60) return 'STALE · ${s}s · AGO';
  final m = age.inMinutes;
  if (m < 60) return 'STALE · ${m}m · AGO';
  final h = age.inHours;
  if (h < 24) return 'STALE · ${h}h · AGO';
  final d = age.inDays;
  if (d < 30) return 'STALE · ${d}d · AGO';
  final mo = (d / 30).floor();
  return 'STALE · ${mo}mo · AGO';
}

/// Returns true when [age] crosses any of the canonical "warning"
/// thresholds: >5m, >1h, >24h. Useful for switching the chip from
/// gold → amber → red.
StaleSeverity staleSeverity(Duration age) {
  if (age > const Duration(hours: 24)) return StaleSeverity.danger;
  if (age > const Duration(hours: 1)) return StaleSeverity.warning;
  if (age > const Duration(minutes: 5)) return StaleSeverity.notice;
  return StaleSeverity.fresh;
}

enum StaleSeverity { fresh, notice, warning, danger }

extension StaleSeverityX on StaleSeverity {
  int get tone => switch (this) {
        StaleSeverity.fresh => 0xFF6CE0A8,
        StaleSeverity.notice => 0xFFD4AF37,
        StaleSeverity.warning => 0xFFFFB347,
        StaleSeverity.danger => 0xFFFF6A6A,
      };
}
