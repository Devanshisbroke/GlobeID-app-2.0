import 'flight_adapter.dart';
import 'flight_models.dart';

/// `DemoFlightAdapter` — deterministic flight state machine.
///
/// The demo flight (`LH 401`) departs MUC → JFK. Phase advances
/// every two minutes of wall-clock time so the demo state walks
/// realistically through SCHEDULED → CHECK·IN → BOARDING →
/// GATE·CLOSED → PUSHBACK → IN·AIR → APPROACH → LANDED without
/// any backing service.
///
/// A small set of canonical flights (LH 401, AA 100, EK 215) is
/// seeded; unknown handles fall back to a generic SCHEDULED
/// snapshot anchored 90 minutes in the future.
class DemoFlightAdapter extends FlightAdapter {
  DemoFlightAdapter({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  static final _seed = <FlightHandle, _Seed>{
    const FlightHandle('LH', '401'): _Seed(
      origin: 'MUC',
      destination: 'JFK',
      gate: 'B27',
      terminal: 'T2',
      durationMinutes: 540,
    ),
    const FlightHandle('AA', '100'): _Seed(
      origin: 'JFK',
      destination: 'LHR',
      gate: '7',
      terminal: 'T8',
      durationMinutes: 415,
    ),
    const FlightHandle('EK', '215'): _Seed(
      origin: 'DXB',
      destination: 'LAX',
      gate: 'A22',
      terminal: 'T3',
      durationMinutes: 960,
    ),
  };

  @override
  String get source => 'demo';

  @override
  Future<FlightQuote> quote(FlightHandle handle) async {
    final seed = _seed[handle];
    if (seed == null) {
      // Generic SCHEDULED stub for unknown handles.
      final now = _now();
      return FlightQuote(
        handle: handle,
        phase: FlightPhase.scheduled,
        origin: '???',
        destination: '???',
        scheduledOut: now.add(const Duration(minutes: 90)),
        fetchedAt: now,
        source: source,
      );
    }
    return _advance(handle, seed);
  }

  FlightQuote _advance(FlightHandle handle, _Seed seed) {
    final now = _now();
    // Schedule the demo flight to be "0 minutes out" exactly on the
    // hour every 2 hours so the phase walks every replay.
    final cycleStart = DateTime(now.year, now.month, now.day, now.hour);
    final scheduled = cycleStart.add(const Duration(minutes: 30));

    final secondsIntoCycle = now.difference(cycleStart).inSeconds;
    // 7 phases × 2 minutes each → 14-minute walk. Beyond that the
    // flight reads as LANDED until the next cycle.
    final stepIndex = (secondsIntoCycle / 120).floor();
    final phase = switch (stepIndex) {
      0 => FlightPhase.scheduled,
      1 => FlightPhase.checkIn,
      2 => FlightPhase.boarding,
      3 => FlightPhase.closed,
      4 => FlightPhase.pushback,
      5 => FlightPhase.inAir,
      6 => FlightPhase.approach,
      _ => FlightPhase.landed,
    };

    // Demo delay drifts gently across the cycle: +0 at scheduled,
    // up to +8 minutes as boarding progresses, back to +3 once
    // airborne so the timeline feels lived-in.
    final delay = switch (phase) {
      FlightPhase.scheduled => 0,
      FlightPhase.checkIn => 2,
      FlightPhase.boarding => 5,
      FlightPhase.closed => 8,
      FlightPhase.pushback => 7,
      FlightPhase.inAir => 4,
      FlightPhase.approach => 3,
      FlightPhase.landed => 3,
      FlightPhase.cancelled => 0,
    };

    final estimatedOut = scheduled.add(Duration(minutes: delay));

    return FlightQuote(
      handle: handle,
      phase: phase,
      origin: seed.origin,
      destination: seed.destination,
      scheduledOut: scheduled,
      estimatedOut: estimatedOut,
      delayMinutes: delay,
      gate: seed.gate,
      terminal: seed.terminal,
      fetchedAt: now,
      source: source,
    );
  }
}

class _Seed {
  const _Seed({
    required this.origin,
    required this.destination,
    required this.gate,
    required this.terminal,
    required this.durationMinutes,
  });
  final String origin;
  final String destination;
  final String gate;
  final String terminal;
  final int durationMinutes;
}
