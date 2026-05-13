import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/ceremony/visa_stamp_ceremony.dart';

void main() {
  group('visaPhaseFor', () {
    test('0 → idle, 1.0 → committed', () {
      expect(visaPhaseFor(0), VisaStampPhase.idle);
      expect(visaPhaseFor(-0.5), VisaStampPhase.idle);
      expect(visaPhaseFor(1.0), VisaStampPhase.committed);
      expect(visaPhaseFor(1.5), VisaStampPhase.committed);
    });
    test('ink load 0 → 0.23', () {
      expect(visaPhaseFor(0.05), VisaStampPhase.inkLoad);
      expect(visaPhaseFor(0.22), VisaStampPhase.inkLoad);
    });
    test('arc swing 0.23 → 0.53', () {
      expect(visaPhaseFor(0.30), VisaStampPhase.arcSwing);
      expect(visaPhaseFor(0.52), VisaStampPhase.arcSwing);
    });
    test('press flash 0.53 → 0.65', () {
      expect(visaPhaseFor(0.55), VisaStampPhase.pressFlash);
      expect(visaPhaseFor(0.64), VisaStampPhase.pressFlash);
    });
    test('bleed settle 0.65 → 1.0', () {
      expect(visaPhaseFor(0.70), VisaStampPhase.bleedSettle);
      expect(visaPhaseFor(0.99), VisaStampPhase.bleedSettle);
    });
  });

  group('VisaStampPhase handles', () {
    test('every phase has a MONO-CAP handle', () {
      for (final p in VisaStampPhase.values) {
        expect(p.handle, equals(p.handle.toUpperCase()));
        expect(p.handle, isNotEmpty);
      }
    });
  });

  group('Stamp choreography (pure)', () {
    test('stamp dy lifts from -90 (load) → 0 (press)', () {
      // At t=0 in load, dy should be -90 (high above page).
      expect(computeStampDy(0.0), closeTo(-90, 0.5));
      // At t=0.53 (press onset), dy should be ~+2 (just past
      // the page surface from the press settle nudge).
      expect(computeStampDy(0.53), greaterThanOrEqualTo(-2));
      expect(computeStampDy(0.53), lessThanOrEqualTo(4));
    });
    test('stamp rotation eases to 0 at swing end', () {
      // At load start, rotation is approximately -0.21.
      expect(computeStampRotation(0.0), closeTo(-0.21, 0.001));
      // At swing end (0.53), rotation has eased to 0.
      expect(computeStampRotation(0.53), closeTo(0.0, 0.001));
    });
  });

  group('VisaStampCeremony — host integration', () {
    testWidgets('renders idle when play=false', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: VisaStampCeremony(play: false)),
          ),
        ),
      );
      expect(find.byType(VisaStampCeremony), findsOneWidget);
    });

    testWidgets('plays to completion and fires onCommitted', (t) async {
      var committed = false;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: VisaStampCeremony(
                play: true,
                duration: const Duration(milliseconds: 600),
                onCommitted: () => committed = true,
              ),
            ),
          ),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      await t.pump(const Duration(milliseconds: 700));
      expect(committed, isTrue);
    });
  });
}
