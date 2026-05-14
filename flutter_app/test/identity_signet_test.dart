import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/branding/identity_signet.dart';

void main() {
  group('SignetPalette', () {
    test('has palette for every variant', () {
      for (final v in SignetVariant.values) {
        final p = SignetPalette.of(v);
        expect(p.name.isNotEmpty, isTrue);
      }
    });

    test('palettes are distinct per variant', () {
      final s = SignetPalette.of(SignetVariant.standard);
      final a = SignetPalette.of(SignetVariant.atelier);
      final p = SignetPalette.of(SignetVariant.pilot);
      expect(s.substrate, isNot(equals(p.substrate)));
      expect(s.tone, isNot(equals(p.tone)));
      // ATELIER and STANDARD share OLED substrate but tone differs.
      expect(a.substrate, equals(s.substrate));
      expect(a.tone, isNot(equals(s.tone)));
    });

    test('STANDARD palette is the foil-gold flagship', () {
      final s = SignetPalette.of(SignetVariant.standard);
      expect(s.tone, const Color(0xFFD4AF37));
      expect(s.substrate, const Color(0xFF050505));
    });

    test('ATELIER palette is OLED + champagne gold (stealth)', () {
      final a = SignetPalette.of(SignetVariant.atelier);
      expect(a.tone, const Color(0xFFE9C75D));
      expect(a.substrate, const Color(0xFF050505));
    });

    test('PILOT palette is navy + champagne', () {
      final p = SignetPalette.of(SignetVariant.pilot);
      expect(p.substrate, const Color(0xFF0A1426));
    });
  });

  group('IdentitySignet widget', () {
    testWidgets('renders standard variant at default size', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IdentitySignet(variant: SignetVariant.standard),
          ),
        ),
      );
      expect(find.byType(IdentitySignet), findsOneWidget);
      expect(find.text('G·ID'), findsOneWidget);
    });

    testWidgets('renders all three variants without throwing', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                IdentitySignet(variant: SignetVariant.standard, size: 60),
                IdentitySignet(variant: SignetVariant.atelier, size: 60),
                IdentitySignet(variant: SignetVariant.pilot, size: 60),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(IdentitySignet), findsNWidgets(3));
      expect(find.text('G·ID'), findsNWidgets(3));
    });

    testWidgets('accepts custom monogram', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IdentitySignet(
              variant: SignetVariant.standard,
              monogram: 'TEST',
            ),
          ),
        ),
      );
      expect(find.text('TEST'), findsOneWidget);
    });
  });
}
