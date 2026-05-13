import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/identity/selective_disclosure.dart';

void main() {
  group('DisclosurePolicy', () {
    test('defaults reveal sensible sets per audience', () {
      final p = DisclosurePolicy.defaults();
      // Airline sees passport + DOB + photo.
      expect(
        p.isVisible(DisclosureAudience.airline, DisclosureField.passportNumber),
        isTrue,
      );
      expect(
        p.isVisible(DisclosureAudience.airline, DisclosureField.dateOfBirth),
        isTrue,
      );
      // Airline does NOT see address or tax residence by default.
      expect(
        p.isVisible(DisclosureAudience.airline, DisclosureField.address),
        isFalse,
      );
      expect(
        p.isVisible(DisclosureAudience.airline, DisclosureField.taxResidence),
        isFalse,
      );
      // Hotel sees name + age + nationality + photo only.
      expect(
        p.isVisible(DisclosureAudience.hotel, DisclosureField.age),
        isTrue,
      );
      expect(
        p.isVisible(DisclosureAudience.hotel, DisclosureField.passportNumber),
        isFalse,
      );
    });

    test('locked policy reveals nothing to anyone', () {
      final p = DisclosurePolicy.locked();
      for (final a in DisclosureAudience.values) {
        for (final f in DisclosureField.values) {
          expect(p.isVisible(a, f), isFalse, reason: '${a.label} / ${f.label}');
        }
        expect(p.revealedCount(a), 0);
      }
    });

    test('toggle flips a single audience+field bit', () {
      final base = DisclosurePolicy.locked();
      final next = base.toggle(
        DisclosureAudience.bank,
        DisclosureField.trustScore,
      );
      expect(
        next.isVisible(DisclosureAudience.bank, DisclosureField.trustScore),
        isTrue,
      );
      // Other audiences unchanged.
      expect(
        next.isVisible(DisclosureAudience.airline, DisclosureField.trustScore),
        isFalse,
      );
      // Toggle again removes it.
      final back = next.toggle(
        DisclosureAudience.bank,
        DisclosureField.trustScore,
      );
      expect(
        back.isVisible(DisclosureAudience.bank, DisclosureField.trustScore),
        isFalse,
      );
    });

    test('toggle is non-mutating (returns new instance)', () {
      final a = DisclosurePolicy.locked();
      final b = a.toggle(
        DisclosureAudience.bank,
        DisclosureField.trustScore,
      );
      // Original unchanged.
      expect(
        a.isVisible(DisclosureAudience.bank, DisclosureField.trustScore),
        isFalse,
      );
      expect(
        b.isVisible(DisclosureAudience.bank, DisclosureField.trustScore),
        isTrue,
      );
    });

    test('lockSensitive removes only high-sensitivity fields', () {
      final defaults = DisclosurePolicy.defaults();
      final locked = defaults.lockSensitive();
      // Airline keeps name + nationality + photo (low/medium).
      expect(
        locked.isVisible(DisclosureAudience.airline, DisclosureField.fullName),
        isTrue,
      );
      expect(
        locked.isVisible(DisclosureAudience.airline, DisclosureField.nationality),
        isTrue,
      );
      // Airline loses passport number + DOB (both high).
      expect(
        locked.isVisible(DisclosureAudience.airline, DisclosureField.passportNumber),
        isFalse,
      );
      expect(
        locked.isVisible(DisclosureAudience.airline, DisclosureField.dateOfBirth),
        isFalse,
      );
    });

    test('totalFields matches DisclosureField count', () {
      expect(
        DisclosurePolicy.totalFields,
        DisclosureField.values.length,
      );
    });

    test('revealedCount returns per-audience visible-field count', () {
      final p = DisclosurePolicy.defaults();
      expect(
        p.revealedCount(DisclosureAudience.airline),
        p.visibility[DisclosureAudience.airline]!.length,
      );
    });
  });

  group('Sensitivity helpers', () {
    test('every field maps to a tone + tag', () {
      for (final f in DisclosureField.values) {
        expect(sensitivityTone(f), isNotNull);
        expect(sensitivityTag(f), isIn(['LOW', 'MED', 'HIGH']));
      }
    });

    test('passport number + DOB + address are HIGH sensitivity', () {
      expect(sensitivityTag(DisclosureField.passportNumber), 'HIGH');
      expect(sensitivityTag(DisclosureField.dateOfBirth), 'HIGH');
      expect(sensitivityTag(DisclosureField.address), 'HIGH');
    });

    test('full name + nationality + age are LOW sensitivity', () {
      expect(sensitivityTag(DisclosureField.fullName), 'LOW');
      expect(sensitivityTag(DisclosureField.nationality), 'LOW');
      expect(sensitivityTag(DisclosureField.age), 'LOW');
    });
  });
}
