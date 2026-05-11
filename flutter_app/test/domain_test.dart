import 'package:flutter_test/flutter_test.dart';
import 'package:globeid/domain/airline_brand.dart';
import 'package:globeid/domain/airports.dart';
import 'package:globeid/domain/identity_tier.dart';

void main() {
  group('airline brand', () {
    test('resolves direct IATA code', () {
      final brand = resolveAirlineBrand('AA');
      expect(brand.name, contains('American'));
    });

    test('extracts IATA from flight number', () {
      final brand = resolveAirlineBrand('SQ 31');
      expect(brand.name, contains('Singapore'));
    });

    test('falls back deterministically on unknown input', () {
      final a = resolveAirlineBrand('UNKNOWN-XYZ');
      final b = resolveAirlineBrand('UNKNOWN-XYZ');
      expect(a.name, b.name);
    });
  });

  group('airports', () {
    test('looks up SFO', () {
      final ap = getAirport('SFO');
      expect(ap, isNotNull);
      expect(ap!.city, 'San Francisco');
    });

    test('returns null for unknown', () {
      expect(getAirport('XYZ'), isNull);
    });
  });

  group('identity tier', () {
    test('maps score → tier', () {
      expect(IdentityTier.forScore(100).label, 'Wanderer');
      expect(IdentityTier.forScore(600).label, 'Voyager');
      expect(IdentityTier.forScore(800).label, 'Globetrotter');
      expect(IdentityTier.forScore(950).label, 'Aviator');
    });
  });
}
