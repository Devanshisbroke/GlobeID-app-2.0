/// Canonical TravelRecord — mirrors `src/store/userStore.ts`.
class TravelRecord {
  TravelRecord({
    required this.id,
    required this.from,
    required this.to,
    required this.date,
    required this.airline,
    required this.duration,
    required this.type,
    this.flightNumber,
    required this.source,
  });

  final String id;
  final String from;
  final String to;
  final String date; // YYYY-MM-DD
  final String airline;
  final String duration;
  final String type; // upcoming | past | current
  final String? flightNumber;
  final String source; // history | planner

  factory TravelRecord.fromJson(Map<String, dynamic> j) => TravelRecord(
        id: j['id'] as String,
        from: j['from'] as String,
        to: j['to'] as String,
        date: j['date'] as String,
        airline: j['airline'] as String,
        duration: j['duration'] as String,
        type: j['type'] as String,
        flightNumber: j['flightNumber'] as String?,
        source: (j['source'] as String?) ?? 'history',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'from': from,
        'to': to,
        'date': date,
        'airline': airline,
        'duration': duration,
        'type': type,
        if (flightNumber != null) 'flightNumber': flightNumber,
        'source': source,
      };

  bool get isUpcoming => type == 'upcoming';
  bool get isPast => type == 'past';
}
