/// Travel document — passport, visa, boarding-pass, insurance.
class TravelDocument {
  TravelDocument({
    required this.id,
    required this.type,
    required this.label,
    required this.country,
    required this.countryFlag,
    required this.number,
    required this.issueDate,
    required this.expiryDate,
    required this.status,
    this.tripId,
    this.legId,
  });

  final String id;
  final String type; // passport | visa | boarding_pass | travel_insurance
  final String label;
  final String country;
  final String countryFlag;
  final String number;
  final String issueDate;
  final String expiryDate;
  final String status; // active | expired | pending
  final String? tripId;
  final String? legId;

  factory TravelDocument.fromJson(Map<String, dynamic> j) => TravelDocument(
        id: j['id'] as String,
        type: j['type'] as String,
        label: j['label'] as String,
        country: j['country'] as String,
        countryFlag: j['countryFlag'] as String,
        number: j['number'] as String,
        issueDate: j['issueDate'] as String,
        expiryDate: j['expiryDate'] as String,
        status: j['status'] as String,
        tripId: j['tripId'] as String?,
        legId: j['legId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'label': label,
        'country': country,
        'countryFlag': countryFlag,
        'number': number,
        'issueDate': issueDate,
        'expiryDate': expiryDate,
        'status': status,
        if (tripId != null) 'tripId': tripId,
        if (legId != null) 'legId': legId,
      };
}
