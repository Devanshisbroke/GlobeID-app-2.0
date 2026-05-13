/// Foundation models for the GlobeID flight data stack.
///
/// `FlightHandle` — IATA carrier code + flight number, the
/// canonical key for every flight lookup. Examples: `LH 401`,
/// `AA 100`, `EK 215`.
class FlightHandle {
  const FlightHandle(this.carrier, this.number);
  final String carrier;
  final String number;

  String get handle => '$carrier$number';
  String get display => '$carrier $number';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlightHandle &&
          other.carrier == carrier &&
          other.number == number);

  @override
  int get hashCode => Object.hash(carrier, number);

  @override
  String toString() => 'FlightHandle($display)';
}

/// Phase enum — drives every brightness / haptic / colour shift
/// across the Live Boarding + Trip Timeline surfaces. Kept
/// independent of any specific carrier vocabulary.
enum FlightPhase {
  scheduled,
  checkIn,
  boarding,
  closed,
  pushback,
  inAir,
  approach,
  landed,
  cancelled,
}

extension FlightPhaseX on FlightPhase {
  String get handle => switch (this) {
        FlightPhase.scheduled => 'SCHEDULED',
        FlightPhase.checkIn => 'CHECK · IN',
        FlightPhase.boarding => 'BOARDING',
        FlightPhase.closed => 'GATE · CLOSED',
        FlightPhase.pushback => 'PUSHBACK',
        FlightPhase.inAir => 'IN · AIR',
        FlightPhase.approach => 'APPROACH',
        FlightPhase.landed => 'LANDED',
        FlightPhase.cancelled => 'CANCELLED',
      };

  bool get isAirborne =>
      this == FlightPhase.inAir || this == FlightPhase.approach;
  bool get isTerminal =>
      this == FlightPhase.landed || this == FlightPhase.cancelled;
}

/// A single flight status quote. Anatomy:
///   • `handle`        — carrier + number
///   • `phase`         — current FlightPhase
///   • `gate`          — assigned gate string (may change)
///   • `terminal`      — terminal label (`T1`, `T3`)
///   • `origin/destination` — IATA codes (`MUC`, `JFK`)
///   • `scheduledOut`  — original off-block time
///   • `estimatedOut`  — latest expected off-block (may drift)
///   • `delayMinutes`  — signed minutes from schedule (negative = early)
///   • `fetchedAt`     — wall-clock time the value was acquired
///   • `source`        — provider handle (`aeroapi`, `demo`)
class FlightQuote {
  const FlightQuote({
    required this.handle,
    required this.phase,
    required this.origin,
    required this.destination,
    required this.scheduledOut,
    required this.fetchedAt,
    required this.source,
    this.gate,
    this.terminal,
    this.estimatedOut,
    this.delayMinutes = 0,
  });

  final FlightHandle handle;
  final FlightPhase phase;
  final String origin;
  final String destination;
  final DateTime scheduledOut;
  final DateTime? estimatedOut;
  final int delayMinutes;
  final String? gate;
  final String? terminal;
  final DateTime fetchedAt;
  final String source;

  bool get isDelayed => delayMinutes > 5;
  bool get isEarly => delayMinutes < -2;

  bool isStale({Duration threshold = const Duration(minutes: 2)}) =>
      DateTime.now().difference(fetchedAt) > threshold;

  FlightQuote copyWith({
    FlightPhase? phase,
    String? gate,
    String? terminal,
    DateTime? estimatedOut,
    int? delayMinutes,
    DateTime? fetchedAt,
    String? source,
  }) =>
      FlightQuote(
        handle: handle,
        origin: origin,
        destination: destination,
        scheduledOut: scheduledOut,
        phase: phase ?? this.phase,
        gate: gate ?? this.gate,
        terminal: terminal ?? this.terminal,
        estimatedOut: estimatedOut ?? this.estimatedOut,
        delayMinutes: delayMinutes ?? this.delayMinutes,
        fetchedAt: fetchedAt ?? this.fetchedAt,
        source: source ?? this.source,
      );

  @override
  String toString() =>
      'FlightQuote(${handle.display} ${phase.handle} '
      '$origin→$destination gate=$gate delay=${delayMinutes}m @ $source)';
}
