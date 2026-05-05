// Dart port of `src/lib/connectionDetector.ts`. Detects tight
// connections between consecutive flight legs.
import '../data/models/lifecycle.dart';

class ConnectionAlert {
  const ConnectionAlert({
    required this.fromLegId,
    required this.toLegId,
    required this.minutes,
    required this.severity,
  });

  final String fromLegId;
  final String toLegId;
  final int minutes;
  final String severity; // tight | warning | comfortable
}

List<ConnectionAlert> detectConnections(List<FlightLeg> legs) {
  final alerts = <ConnectionAlert>[];
  for (var i = 0; i < legs.length - 1; i++) {
    final cur = legs[i];
    final nxt = legs[i + 1];
    if (cur.scheduled.isEmpty || nxt.scheduled.isEmpty) continue;
    if (cur.to != nxt.from) continue; // different airport — not a connection
    try {
      final t1 = DateTime.parse(cur.scheduled);
      final t2 = DateTime.parse(nxt.scheduled);
      final diff = t2.difference(t1).inMinutes;
      if (diff <= 0) continue;
      String sev;
      if (diff < 60) {
        sev = 'tight';
      } else if (diff < 120) {
        sev = 'warning';
      } else {
        sev = 'comfortable';
      }
      alerts.add(ConnectionAlert(
        fromLegId: cur.id,
        toLegId: nxt.id,
        minutes: diff,
        severity: sev,
      ));
    } catch (_) {/* skip */}
  }
  return alerts;
}
