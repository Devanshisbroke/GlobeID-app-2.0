import '../data/models/lifecycle.dart';

enum ServiceTab {
  visa,
  insurance,
  esim,
  exchange,
  hotels,
  rides,
  food,
  local,
}

class ServiceRanking {
  const ServiceRanking({
    required this.tab,
    required this.score,
    required this.reason,
  });

  final ServiceTab tab;
  final int score;
  final String reason;
}

class ServiceInput {
  const ServiceInput({
    required this.activeCountryIso2,
    required this.nextDestinationIso2,
    required this.daysToNextTrip,
    required this.overBudgetCategoryCount,
  });

  final String? activeCountryIso2;
  final String? nextDestinationIso2;
  final int daysToNextTrip;
  final int overBudgetCategoryCount;
}

List<ServiceRanking> rankServices(ServiceInput input) {
  final ranks = <ServiceTab, _RankAccumulator>{
    for (final tab in ServiceTab.values) tab: _RankAccumulator(),
  };

  final isForeignTrip = input.nextDestinationIso2 != null &&
      input.activeCountryIso2 != null &&
      input.nextDestinationIso2 != input.activeCountryIso2;

  if (isForeignTrip && input.daysToNextTrip <= 30) {
    ranks[ServiceTab.visa]!.bump(4, 'Upcoming foreign trip: verify visa.');
    ranks[ServiceTab.insurance]!
        .bump(4, 'Upcoming foreign trip: quote insurance.');
    ranks[ServiceTab.esim]!.bump(3, 'Pre-trip: set up data plan.');
    ranks[ServiceTab.exchange]!.bump(3, 'Pre-trip: convert currency.');
  }

  if (input.daysToNextTrip <= 7) {
    ranks[ServiceTab.hotels]!.bump(3, 'Trip this week: finalise stay.');
    ranks[ServiceTab.rides]!.bump(2, 'Trip this week: plan airport transfer.');
  }

  if (input.daysToNextTrip <= 2) {
    ranks[ServiceTab.rides]!.bump(4, 'Trip imminent: book the ride.');
    ranks[ServiceTab.food]!.bump(2, 'Plan first meal at the destination.');
    ranks[ServiceTab.local]!
        .bump(2, 'Quick reference for embassies and SIM stores.');
  }

  if (input.activeCountryIso2 != null && input.daysToNextTrip > 30) {
    ranks[ServiceTab.local]!
        .bump(3, 'Discover ${input.activeCountryIso2} services nearby.');
    ranks[ServiceTab.food]!.bump(2, 'Local restaurants and cuisines.');
  }

  if (input.overBudgetCategoryCount > 0) {
    ranks[ServiceTab.food]!.score -= 1;
    ranks[ServiceTab.hotels]!.score -= 1;
    ranks[ServiceTab.exchange]!
        .bump(1, 'Over budget: review FX before spending.');
  }

  final ordered = [
    for (final entry in ranks.entries)
      ServiceRanking(
        tab: entry.key,
        score: entry.value.score,
        reason: entry.value.reason ?? 'Browse and compare.',
      ),
  ]..sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      return a.tab.index.compareTo(b.tab.index);
    });
  return ordered;
}

TripLifecycle? nextActionableTrip(List<TripLifecycle> trips, {DateTime? now}) {
  if (trips.isEmpty) return null;
  final reference = now ?? DateTime.now();
  final candidates = [
    for (final trip in trips)
      if (trip.stage != 'past') trip,
  ];
  final pool = candidates.isEmpty ? trips : candidates;
  pool.sort((a, b) {
    final aDate = _tripDate(a) ?? reference.add(const Duration(days: 3650));
    final bDate = _tripDate(b) ?? reference.add(const Duration(days: 3650));
    return aDate.compareTo(bDate);
  });
  return pool.first;
}

int daysUntilTrip(TripLifecycle? trip, {DateTime? now}) {
  if (trip == null) return 9999;
  final date = _tripDate(trip);
  if (date == null) return 9999;
  final reference = now ?? DateTime.now();
  return date.difference(reference).inDays.clamp(0, 9999);
}

String? destinationCountryIso2ForTrip(TripLifecycle? trip) {
  if (trip == null || trip.legs.isEmpty) return null;
  return airportCountryIso2(trip.legs.first.to);
}

String? destinationCurrencyForTrip(TripLifecycle? trip) {
  final country = destinationCountryIso2ForTrip(trip);
  if (country == null) return null;
  return currencyForCountryIso2(country);
}

String? airportCountryIso2(String? airportCode) {
  if (airportCode == null || airportCode.trim().isEmpty) return null;
  return _airportCountry[airportCode.trim().toUpperCase()];
}

String? currencyForCountryIso2(String? countryIso2) {
  if (countryIso2 == null || countryIso2.trim().isEmpty) return null;
  return _countryCurrency[countryIso2.trim().toUpperCase()];
}

DateTime? _tripDate(TripLifecycle trip) {
  final raw = trip.startDate ??
      (trip.legs.isNotEmpty ? trip.legs.first.scheduled : null);
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

class _RankAccumulator {
  int score = 1;
  String? reason;
  int _reasonPriority = 0;

  void bump(int amount, String message) {
    score += amount;
    if (amount >= _reasonPriority) {
      reason = message;
      _reasonPriority = amount;
    }
  }
}

const _airportCountry = <String, String>{
  'ATL': 'US',
  'BOS': 'US',
  'DFW': 'US',
  'EWR': 'US',
  'JFK': 'US',
  'LAX': 'US',
  'MIA': 'US',
  'ORD': 'US',
  'SFO': 'US',
  'SEA': 'US',
  'YYZ': 'CA',
  'YVR': 'CA',
  'MEX': 'MX',
  'GRU': 'BR',
  'LHR': 'GB',
  'LGW': 'GB',
  'MAN': 'GB',
  'CDG': 'FR',
  'ORY': 'FR',
  'AMS': 'NL',
  'FRA': 'DE',
  'MUC': 'DE',
  'ZRH': 'CH',
  'MAD': 'ES',
  'BCN': 'ES',
  'FCO': 'IT',
  'DXB': 'AE',
  'AUH': 'AE',
  'DOH': 'QA',
  'IST': 'TR',
  'DEL': 'IN',
  'BOM': 'IN',
  'BLR': 'IN',
  'MAA': 'IN',
  'SIN': 'SG',
  'HND': 'JP',
  'NRT': 'JP',
  'KIX': 'JP',
  'ICN': 'KR',
  'BKK': 'TH',
  'HKT': 'TH',
  'KUL': 'MY',
  'HKG': 'HK',
  'PEK': 'CN',
  'PVG': 'CN',
  'SYD': 'AU',
  'MEL': 'AU',
  'AKL': 'NZ',
  'CPT': 'ZA',
  'JNB': 'ZA',
};

const _countryCurrency = <String, String>{
  'AE': 'AED',
  'AU': 'AUD',
  'BR': 'BRL',
  'CA': 'CAD',
  'CH': 'CHF',
  'CN': 'CNY',
  'DE': 'EUR',
  'ES': 'EUR',
  'FR': 'EUR',
  'GB': 'GBP',
  'HK': 'HKD',
  'IN': 'INR',
  'IT': 'EUR',
  'JP': 'JPY',
  'KR': 'KRW',
  'MX': 'MXN',
  'MY': 'MYR',
  'NL': 'EUR',
  'NZ': 'NZD',
  'QA': 'QAR',
  'SG': 'SGD',
  'TH': 'THB',
  'TR': 'TRY',
  'US': 'USD',
  'ZA': 'ZAR',
};
