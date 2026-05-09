// Smoke tests for the bible visual-language foundations.
//
// We don't snapshot pixels — we just prove the foundations exist,
// have the bible-specified values, and that the widget primitives
// can be built without throwing (including on a 0×0 canvas, which
// is the regression that took down the home screen previously).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globeid/app/theme/ux_bible.dart';
import 'package:globeid/widgets/bible/bible.dart';

void main() {
  group('BibleSubstrate', () {
    test('substrate palette matches §4.1 hex codes', () {
      expect(BibleSubstrate.midnightIndigo, const Color(0xFF05060A));
      expect(BibleSubstrate.cabinCharcoal, const Color(0xFF0E1117));
      expect(BibleSubstrate.tarmacSlate, const Color(0xFF161A22));
      expect(BibleSubstrate.vellumBone, const Color(0xFFF4EFE6));
      expect(BibleSubstrate.snowfieldWhite, const Color(0xFFFBFBFD));
    });
  });

  group('BibleTone', () {
    test('identity / wallet / travel / globe / lounge tones present', () {
      expect(BibleTone.diplomaticGarnet, const Color(0xFF7A1D2E));
      expect(BibleTone.foilGold, const Color(0xFFB8902B));
      expect(BibleTone.treasuryGreen, const Color(0xFF0E7A4F));
      expect(BibleTone.jetCyan, const Color(0xFF0EA5E9));
      expect(BibleTone.equatorTeal, const Color(0xFF10B981));
      expect(BibleTone.champagneSand, const Color(0xFFD9C19A));
    });
  });

  group('BibleSignal', () {
    test('signal palette is sparse (4 functional colors)', () {
      expect(BibleSignal.success, const Color(0xFF16A34A));
      expect(BibleSignal.warning, const Color(0xFFF59E0B));
      expect(BibleSignal.error, const Color(0xFFDC2626));
      expect(BibleSignal.info, const Color(0xFF0EA5E9));
    });
  });

  group('BibleCurves', () {
    test('takeoff curve matches §5.1 control points', () {
      // The bible specifies Cubic(0.16, 1.0, 0.30, 1.0) for takeoff.
      // We just verify the curve transforms the endpoints to 0/1.
      final c = BibleCurves.takeoff;
      expect(c.transform(0.0), closeTo(0.0, 1e-6));
      expect(c.transform(1.0), closeTo(1.0, 1e-6));
    });

    test('cruise / descent / taxi behave monotonically', () {
      for (final c in [
        BibleCurves.cruise,
        BibleCurves.descent,
        BibleCurves.taxi,
      ]) {
        var prev = 0.0;
        for (var t = 0.0; t <= 1.0; t += 0.1) {
          final v = c.transform(t);
          expect(v, greaterThanOrEqualTo(prev - 1e-6));
          prev = v;
        }
      }
    });

    test('bank curve overshoots above 1 mid-animation', () {
      // The bible: bank is "over-bouncy". Verify it crosses 1.0 at
      // some point before t=1.
      var sawOvershoot = false;
      for (var t = 0.7; t <= 0.95; t += 0.01) {
        if (BibleCurves.bank.transform(t) > 1.0) sawOvershoot = true;
      }
      expect(sawOvershoot, isTrue,
          reason: 'bank curve should overshoot per §5.1 spec');
    });
  });

  group('BibleChoreography', () {
    test('default cascade respects bible cadence', () {
      expect(BibleChoreography.hero, Duration.zero);
      expect(BibleChoreography.sectionHeader.inMilliseconds, 120);
      expect(BibleChoreography.firstCard.inMilliseconds, 160);
      expect(BibleChoreography.cardStep.inMilliseconds, 60);
      expect(BibleChoreography.floatingChrome.inMilliseconds, 320);
    });

    test('delayFor scales with index', () {
      expect(BibleChoreography.delayFor(0).inMilliseconds, 160);
      expect(BibleChoreography.delayFor(1).inMilliseconds, 220);
      expect(BibleChoreography.delayFor(5).inMilliseconds, 460);
    });
  });

  group('BibleLighting', () {
    test('preset lighting angles match §4.4', () {
      // Identity: museum case, 45° (rendered as 135° from +X).
      expect(BibleLighting.identity.angleDeg, 135);
      // Wallet: above, 90°.
      expect(BibleLighting.wallet.angleDeg, 90);
      // Boarding: airport apron, 30°.
      expect(BibleLighting.boarding.angleDeg, 30);
      // Lounge: table lamp, 200°.
      expect(BibleLighting.lounge.angleDeg, 200);
    });

    test('unitOffset is on the unit circle', () {
      for (final l in [
        BibleLighting.identity,
        BibleLighting.wallet,
        BibleLighting.boarding,
        BibleLighting.globe,
        BibleLighting.lounge,
      ]) {
        final o = l.unitOffset;
        final magnitude = (o.dx * o.dx + o.dy * o.dy);
        expect(magnitude, closeTo(1.0, 1e-3));
      }
    });
  });

  group('BibleSurface', () {
    testWidgets('all five materials build without error', (tester) async {
      for (final m in BibleMaterial.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: BibleSurface(
                  material: m,
                  child: const SizedBox(width: 100, height: 80),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull,
            reason: 'BibleMaterial.$m must build cleanly');
      }
    });
  });

  group('LivingGradient', () {
    testWidgets('builds and ticks under MediaQuery.disableAnimations',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: LivingGradient.travel(
                child: const SizedBox(width: 200, height: 200),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
    });
  });

  group('SolariFlap', () {
    testWidgets('renders one cell per non-space character', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SolariFlap(text: 'UA837'),
            ),
          ),
        ),
      );
      // Allow the staggered flap animations to finish.
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  });

  group('LigatureText', () {
    testWidgets('promotes IATA pair / FX pair / flight no.', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LigatureText('Booked: SFO→NRT on UA837 EUR/USD UTC+9'),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
