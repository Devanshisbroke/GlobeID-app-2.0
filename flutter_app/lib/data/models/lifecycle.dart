/// Trip lifecycle / leg types — mirror `shared/types/lifecycle.ts`.
class FlightLeg {
  FlightLeg({
    required this.id,
    required this.from,
    required this.to,
    required this.airline,
    required this.flightNumber,
    required this.scheduled,
    this.gate,
    this.terminal,
    this.seat,
    this.boarding,
  });

  final String id;
  final String from;
  final String to;
  final String airline;
  final String flightNumber;
  final String scheduled; // ISO datetime
  final String? gate;
  final String? terminal;
  final String? seat;
  final String? boarding; // ISO datetime

  factory FlightLeg.fromJson(Map<String, dynamic> j) => FlightLeg(
        id: j['id'] as String,
        from: j['from'] as String,
        to: j['to'] as String,
        airline: (j['airline'] as String?) ?? '',
        flightNumber: (j['flightNumber'] as String?) ?? '',
        scheduled: (j['scheduled'] as String?) ?? '',
        gate: j['gate'] as String?,
        terminal: j['terminal'] as String?,
        seat: j['seat'] as String?,
        boarding: j['boarding'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'from': from,
        'to': to,
        'airline': airline,
        'flightNumber': flightNumber,
        'scheduled': scheduled,
        if (gate != null) 'gate': gate,
        if (terminal != null) 'terminal': terminal,
        if (seat != null) 'seat': seat,
        if (boarding != null) 'boarding': boarding,
      };
}

class TripLifecycle {
  TripLifecycle({
    required this.id,
    required this.name,
    required this.stage,
    required this.legs,
    this.startDate,
    this.endDate,
    this.budget,
  });

  final String id;
  final String name;
  final String stage; // upcoming | active | past
  final List<FlightLeg> legs;
  final String? startDate;
  final String? endDate;
  final double? budget;

  factory TripLifecycle.fromJson(Map<String, dynamic> j) => TripLifecycle(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? 'Trip',
        stage: (j['stage'] as String?) ?? 'upcoming',
        legs: ((j['legs'] as List?) ?? const [])
            .map((e) => FlightLeg.fromJson(e as Map<String, dynamic>))
            .toList(),
        startDate: j['startDate'] as String?,
        endDate: j['endDate'] as String?,
        budget: (j['budget'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'stage': stage,
        'legs': legs.map((e) => e.toJson()).toList(),
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (budget != null) 'budget': budget,
      };
}
