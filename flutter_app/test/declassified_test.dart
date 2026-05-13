import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/ceremony/declassified_ceremony.dart';

void main() {
  group('declassifiedPhaseFor', () {
    test('0 → idle, 1.0 → declassified', () {
      expect(declassifiedPhaseFor(0), DeclassifiedPhase.idle);
      expect(declassifiedPhaseFor(1.0), DeclassifiedPhase.declassified);
    });
    test('cover lift 0 → 0.18', () {
      expect(declassifiedPhaseFor(0.05), DeclassifiedPhase.coverLift);
      expect(declassifiedPhaseFor(0.17), DeclassifiedPhase.coverLift);
    });
    test('stamp one 0.18 → 0.40', () {
      expect(declassifiedPhaseFor(0.25), DeclassifiedPhase.stampOne);
      expect(declassifiedPhaseFor(0.39), DeclassifiedPhase.stampOne);
    });
    test('stamp two 0.40 → 0.55', () {
      expect(declassifiedPhaseFor(0.45), DeclassifiedPhase.stampTwo);
      expect(declassifiedPhaseFor(0.54), DeclassifiedPhase.stampTwo);
    });
    test('stamp three 0.55 → 0.70', () {
      expect(declassifiedPhaseFor(0.60), DeclassifiedPhase.stampThree);
      expect(declassifiedPhaseFor(0.69), DeclassifiedPhase.stampThree);
    });
    test('dossier reveal 0.70 → 1.0', () {
      expect(declassifiedPhaseFor(0.80), DeclassifiedPhase.dossierReveal);
      expect(declassifiedPhaseFor(0.99), DeclassifiedPhase.dossierReveal);
    });
  });

  group('DeclassifiedPhase handles', () {
    test('every phase has a MONO-CAP handle', () {
      for (final p in DeclassifiedPhase.values) {
        expect(p.handle, equals(p.handle.toUpperCase()));
        expect(p.handle, isNotEmpty);
      }
    });
  });

  group('computeCoverLift', () {
    test('0 below lift onset, 1.0 above lift end', () {
      expect(computeCoverLift(0.0), 0.0);
      expect(computeCoverLift(-1.0), 0.0);
      expect(computeCoverLift(0.18), 1.0);
      expect(computeCoverLift(1.0), 1.0);
    });
    test('monotonic across lift range', () {
      expect(computeCoverLift(0.18 * 0.6),
          greaterThan(computeCoverLift(0.18 * 0.3)));
    });
  });

  group('computeStampScale', () {
    test('zero before stamp onset', () {
      expect(computeStampScale(0, 0.10), 0.0);
      expect(computeStampScale(1, 0.30), 0.0);
      expect(computeStampScale(2, 0.40), 0.0);
    });
    test('settles to 1.0 at stamp end', () {
      expect(computeStampScale(0, 0.40), closeTo(1.0, 0.001));
      expect(computeStampScale(1, 0.55), closeTo(1.0, 0.001));
      expect(computeStampScale(2, 0.70), closeTo(1.0, 0.001));
    });
    test('overshoots above 1.0 mid-stamp', () {
      // At ~30% through stamp one, easeOutBack overshoot
      // pushes us above 1.0.
      final mid = computeStampScale(0, 0.20 + 0.20 * 0.40);
      expect(mid, greaterThan(1.0));
    });
  });

  group('DeclassifiedCeremony — host integration', () {
    testWidgets('renders idle when play=false', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: DeclassifiedCeremony(play: false)),
          ),
        ),
      );
      expect(find.byType(DeclassifiedCeremony), findsOneWidget);
    });

    testWidgets('plays to completion and fires onDeclassified', (t) async {
      var called = false;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: DeclassifiedCeremony(
                play: true,
                duration: const Duration(milliseconds: 500),
                onDeclassified: () => called = true,
              ),
            ),
          ),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      await t.pump(const Duration(milliseconds: 600));
      expect(called, isTrue);
    });
  });
}
