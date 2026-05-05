import 'dart:math' as math;

/// Static airport directory ported from `shared/data/airports.ts`. Used by
/// the map, timeline, services, and wallet for IATA → city/country/lat/lng
/// resolution.
class Airport {
  const Airport({
    required this.iata,
    required this.name,
    required this.city,
    required this.country,
    required this.lat,
    required this.lng,
  });

  final String iata;
  final String name;
  final String city;
  final String country;
  final double lat;
  final double lng;
}

const List<Airport> kAirports = [
  // North America
  Airport(
      iata: 'SFO',
      name: 'San Francisco International',
      city: 'San Francisco',
      country: 'United States',
      lat: 37.6213,
      lng: -122.379),
  Airport(
      iata: 'LAX',
      name: 'Los Angeles International',
      city: 'Los Angeles',
      country: 'United States',
      lat: 33.9425,
      lng: -118.408),
  Airport(
      iata: 'JFK',
      name: 'John F. Kennedy International',
      city: 'New York',
      country: 'United States',
      lat: 40.6413,
      lng: -73.7781),
  Airport(
      iata: 'ORD',
      name: "Chicago O'Hare International",
      city: 'Chicago',
      country: 'United States',
      lat: 41.9742,
      lng: -87.9073),
  Airport(
      iata: 'MIA',
      name: 'Miami International',
      city: 'Miami',
      country: 'United States',
      lat: 25.7959,
      lng: -80.287),
  Airport(
      iata: 'DFW',
      name: 'Dallas/Fort Worth International',
      city: 'Dallas',
      country: 'United States',
      lat: 32.8998,
      lng: -97.0403),
  Airport(
      iata: 'SEA',
      name: 'Seattle-Tacoma International',
      city: 'Seattle',
      country: 'United States',
      lat: 47.4502,
      lng: -122.3088),
  Airport(
      iata: 'YYZ',
      name: 'Toronto Pearson International',
      city: 'Toronto',
      country: 'Canada',
      lat: 43.6777,
      lng: -79.6248),
  Airport(
      iata: 'CUN',
      name: 'Cancún International',
      city: 'Cancún',
      country: 'Mexico',
      lat: 21.0365,
      lng: -86.8771),
  // Europe
  Airport(
      iata: 'LHR',
      name: 'London Heathrow',
      city: 'London',
      country: 'United Kingdom',
      lat: 51.47,
      lng: -0.4543),
  Airport(
      iata: 'CDG',
      name: 'Paris Charles de Gaulle',
      city: 'Paris',
      country: 'France',
      lat: 49.0097,
      lng: 2.5479),
  Airport(
      iata: 'FRA',
      name: 'Frankfurt Airport',
      city: 'Frankfurt',
      country: 'Germany',
      lat: 50.0379,
      lng: 8.5622),
  Airport(
      iata: 'AMS',
      name: 'Amsterdam Schiphol',
      city: 'Amsterdam',
      country: 'Netherlands',
      lat: 52.3105,
      lng: 4.7683),
  Airport(
      iata: 'MAD',
      name: 'Madrid Barajas',
      city: 'Madrid',
      country: 'Spain',
      lat: 40.4983,
      lng: -3.5676),
  Airport(
      iata: 'IST',
      name: 'Istanbul Airport',
      city: 'Istanbul',
      country: 'Turkey',
      lat: 41.2753,
      lng: 28.7519),
  Airport(
      iata: 'ZRH',
      name: 'Zurich Airport',
      city: 'Zurich',
      country: 'Switzerland',
      lat: 47.4647,
      lng: 8.5492),
  // Asia
  Airport(
      iata: 'SIN',
      name: 'Singapore Changi',
      city: 'Singapore',
      country: 'Singapore',
      lat: 1.3644,
      lng: 103.9915),
  Airport(
      iata: 'NRT',
      name: 'Tokyo Narita',
      city: 'Tokyo',
      country: 'Japan',
      lat: 35.7647,
      lng: 140.3864),
  Airport(
      iata: 'HND',
      name: 'Tokyo Haneda',
      city: 'Tokyo',
      country: 'Japan',
      lat: 35.5494,
      lng: 139.7798),
  Airport(
      iata: 'HKG',
      name: 'Hong Kong International',
      city: 'Hong Kong',
      country: 'China',
      lat: 22.308,
      lng: 113.9185),
  Airport(
      iata: 'PVG',
      name: 'Shanghai Pudong',
      city: 'Shanghai',
      country: 'China',
      lat: 31.1443,
      lng: 121.8083),
  Airport(
      iata: 'PEK',
      name: 'Beijing Capital',
      city: 'Beijing',
      country: 'China',
      lat: 40.0799,
      lng: 116.6031),
  Airport(
      iata: 'ICN',
      name: 'Seoul Incheon',
      city: 'Seoul',
      country: 'South Korea',
      lat: 37.4602,
      lng: 126.4407),
  Airport(
      iata: 'BKK',
      name: 'Bangkok Suvarnabhumi',
      city: 'Bangkok',
      country: 'Thailand',
      lat: 13.69,
      lng: 100.7501),
  Airport(
      iata: 'DEL',
      name: 'Indira Gandhi International',
      city: 'New Delhi',
      country: 'India',
      lat: 28.5562,
      lng: 77.1),
  Airport(
      iata: 'BOM',
      name: 'Chhatrapati Shivaji Maharaj International',
      city: 'Mumbai',
      country: 'India',
      lat: 19.0896,
      lng: 72.8656),
  Airport(
      iata: 'KUL',
      name: 'Kuala Lumpur International',
      city: 'Kuala Lumpur',
      country: 'Malaysia',
      lat: 2.7456,
      lng: 101.71),
  // Middle East
  Airport(
      iata: 'DXB',
      name: 'Dubai International',
      city: 'Dubai',
      country: 'UAE',
      lat: 25.2532,
      lng: 55.3657),
  Airport(
      iata: 'AUH',
      name: 'Abu Dhabi International',
      city: 'Abu Dhabi',
      country: 'UAE',
      lat: 24.4331,
      lng: 54.6511),
  Airport(
      iata: 'DOH',
      name: 'Hamad International',
      city: 'Doha',
      country: 'Qatar',
      lat: 25.2731,
      lng: 51.6081),
  // Oceania
  Airport(
      iata: 'SYD',
      name: 'Sydney Kingsford Smith',
      city: 'Sydney',
      country: 'Australia',
      lat: -33.9461,
      lng: 151.177),
  Airport(
      iata: 'MEL',
      name: 'Melbourne Airport',
      city: 'Melbourne',
      country: 'Australia',
      lat: -37.6733,
      lng: 144.8433),
  Airport(
      iata: 'AKL',
      name: 'Auckland Airport',
      city: 'Auckland',
      country: 'New Zealand',
      lat: -37.0082,
      lng: 174.792),
  // South America
  Airport(
      iata: 'GRU',
      name: 'São Paulo–Guarulhos',
      city: 'São Paulo',
      country: 'Brazil',
      lat: -23.4356,
      lng: -46.4731),
  Airport(
      iata: 'BOG',
      name: 'El Dorado International',
      city: 'Bogotá',
      country: 'Colombia',
      lat: 4.7016,
      lng: -74.1469),
  Airport(
      iata: 'LIM',
      name: 'Jorge Chávez International',
      city: 'Lima',
      country: 'Peru',
      lat: -12.0219,
      lng: -77.1143),
  // Africa
  Airport(
      iata: 'JNB',
      name: 'O. R. Tambo International',
      city: 'Johannesburg',
      country: 'South Africa',
      lat: -26.1392,
      lng: 28.246),
  Airport(
      iata: 'CAI',
      name: 'Cairo International',
      city: 'Cairo',
      country: 'Egypt',
      lat: 30.1219,
      lng: 31.4056),
  Airport(
      iata: 'NBO',
      name: 'Jomo Kenyatta International',
      city: 'Nairobi',
      country: 'Kenya',
      lat: -1.3192,
      lng: 36.9278),
];

final Map<String, Airport> _byIata = {
  for (final a in kAirports) a.iata: a,
};

Airport? getAirport(String? iata) =>
    iata == null ? null : _byIata[iata.toUpperCase()];

/// Great-circle distance in km via the haversine formula.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * r * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}
