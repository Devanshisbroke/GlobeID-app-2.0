import 'package:flutter/material.dart';

/// Dart port of `src/lib/airlineBrand.ts`. Maps IATA / common airline
/// codes to a brand-accurate three-stop gradient. Used by the wallet
/// pass card so every pass has its airline's identity rather than a
/// generic sky-blue gradient.
class AirlineBrand {
  const AirlineBrand({
    required this.iata,
    required this.name,
    required this.colors,
  });

  final String iata;
  final String name;

  /// 3-stop gradient (start → mid → end) in primary order.
  final List<Color> colors;

  Color get primary => colors.first;

  LinearGradient gradient(
          {Alignment begin = Alignment.topLeft,
          Alignment end = Alignment.bottomRight}) =>
      LinearGradient(begin: begin, end: end, colors: colors);
}

const _slate900 = Color(0xFF0F172A);
const _slate800 = Color(0xFF1E293B);

const Map<String, AirlineBrand> _palette = {
  // North America
  'AA': AirlineBrand(
      iata: 'AA',
      name: 'American Airlines',
      colors: [Color(0xFFB91C1C), Color(0xFF991B1B), _slate900]),
  'UA': AirlineBrand(
      iata: 'UA',
      name: 'United Airlines',
      colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF), _slate900]),
  'DL': AirlineBrand(
      iata: 'DL',
      name: 'Delta Air Lines',
      colors: [Color(0xFFB91C1C), Color(0xFF1E3A8A), _slate900]),
  'AC': AirlineBrand(
      iata: 'AC',
      name: 'Air Canada',
      colors: [Color(0xFFDC2626), Color(0xFFBE123C), _slate900]),
  'WN': AirlineBrand(
      iata: 'WN',
      name: 'Southwest',
      colors: [Color(0xFF1D4ED8), Color(0xFFD97706), _slate900]),
  'B6': AirlineBrand(
      iata: 'B6',
      name: 'JetBlue',
      colors: [Color(0xFF1D4ED8), Color(0xFF1E3A8A), _slate900]),
  // Europe
  'BA': AirlineBrand(
      iata: 'BA',
      name: 'British Airways',
      colors: [Color(0xFF0EA5E9), Color(0xFF1E3A8A), _slate900]),
  'AF': AirlineBrand(
      iata: 'AF',
      name: 'Air France',
      colors: [Color(0xFF1E40AF), Color(0xFF1E3A8A), _slate900]),
  'LH': AirlineBrand(
      iata: 'LH',
      name: 'Lufthansa',
      colors: [Color(0xFFFBBF24), Color(0xFFCA8A04), _slate800]),
  'KL': AirlineBrand(
      iata: 'KL',
      name: 'KLM',
      colors: [Color(0xFF38BDF8), Color(0xFF0284C7), _slate900]),
  'IB': AirlineBrand(
      iata: 'IB',
      name: 'Iberia',
      colors: [Color(0xFFEF4444), Color(0xFFB91C1C), _slate900]),
  'VS': AirlineBrand(
      iata: 'VS',
      name: 'Virgin Atlantic',
      colors: [Color(0xFFE11D48), Color(0xFFB91C1C), _slate900]),
  // Middle East
  'EK': AirlineBrand(
      iata: 'EK',
      name: 'Emirates',
      colors: [Color(0xFFDC2626), Color(0xFF991B1B), _slate900]),
  'EY': AirlineBrand(
      iata: 'EY',
      name: 'Etihad',
      colors: [Color(0xFFCA8A04), Color(0xFF92400E), _slate900]),
  'QR': AirlineBrand(
      iata: 'QR',
      name: 'Qatar Airways',
      colors: [Color(0xFF7E22CE), Color(0xFF581C87), _slate900]),
  // Asia / Pacific
  'SQ': AirlineBrand(
      iata: 'SQ',
      name: 'Singapore Airlines',
      colors: [Color(0xFF1E3A8A), Color(0xFFCA8A04), _slate900]),
  'NH': AirlineBrand(
      iata: 'NH',
      name: 'ANA',
      colors: [Color(0xFF1D4ED8), Color(0xFF312E81), _slate900]),
  'JL': AirlineBrand(
      iata: 'JL',
      name: 'Japan Airlines',
      colors: [Color(0xFFDC2626), Color(0xFF7F1D1D), _slate900]),
  'CX': AirlineBrand(
      iata: 'CX',
      name: 'Cathay Pacific',
      colors: [Color(0xFF059669), Color(0xFF065F46), _slate900]),
  'AI': AirlineBrand(
      iata: 'AI',
      name: 'Air India',
      colors: [Color(0xFFEA580C), Color(0xFF9A3412), _slate900]),
  'TG': AirlineBrand(
      iata: 'TG',
      name: 'Thai Airways',
      colors: [Color(0xFF7E22CE), Color(0xFFCA8A04), _slate900]),
  'QF': AirlineBrand(
      iata: 'QF',
      name: 'Qantas',
      colors: [Color(0xFFDC2626), Color(0xFFFFFFFF), _slate900]),
};

const _fallbackBrands = <AirlineBrand>[
  AirlineBrand(
      iata: '__1',
      name: '',
      colors: [Color(0xFF0EA5E9), Color(0xFF1E40AF), _slate900]),
  AirlineBrand(
      iata: '__2',
      name: '',
      colors: [Color(0xFF7E22CE), Color(0xFF1E1B4B), _slate900]),
  AirlineBrand(
      iata: '__3',
      name: '',
      colors: [Color(0xFF059669), Color(0xFF064E3B), _slate900]),
  AirlineBrand(
      iata: '__4',
      name: '',
      colors: [Color(0xFFEA580C), Color(0xFF7C2D12), _slate900]),
  AirlineBrand(
      iata: '__5',
      name: '',
      colors: [Color(0xFF6366F1), Color(0xFF312E81), _slate900]),
];

AirlineBrand resolveAirlineBrand(String? input) {
  if (input == null || input.isEmpty) return _fallbackBrands.first;
  final upper = input.toUpperCase();
  // Direct IATA
  if (_palette.containsKey(upper)) return _palette[upper]!;
  // Flight number prefix, e.g. "SQ 31"
  final m = RegExp(r'^([A-Z0-9]{2})').firstMatch(upper);
  if (m != null && _palette.containsKey(m.group(1))) {
    return _palette[m.group(1)]!;
  }
  // Name match
  for (final brand in _palette.values) {
    if (brand.name.isNotEmpty && upper.contains(brand.name.toUpperCase())) {
      return brand;
    }
  }
  // Deterministic fallback by string hash.
  var h = 0;
  for (final c in input.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return _fallbackBrands[h % _fallbackBrands.length];
}
