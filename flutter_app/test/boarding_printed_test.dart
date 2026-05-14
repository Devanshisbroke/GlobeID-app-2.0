import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/ceremony/boarding_printed_ceremony.dart';

void main() {
  group('boardingPrintedPhaseFor', () {
    test('0 → idle, 1.0 → presented', () {
      expect(boardingPrintedPhaseFor(0), BoardingPrintedPhase.idle);
      expect(boardingPrintedPhaseFor(1.0), BoardingPrintedPhase.presented);
    });
    test('slot arm 0 → 0.20', () {
      expect(boardingPrintedPhaseFor(0.05), BoardingPrintedPhase.slotArm);
      expect(boardingPrintedPhaseFor(0.19), BoardingPrintedPhase.slotArm);
    });
    test('extrude 0.20 → 0.85', () {
      expect(boardingPrintedPhaseFor(0.30), BoardingPrintedPhase.extrude);
      expect(boardingPrintedPhaseFor(0.84), BoardingPrintedPhase.extrude);
    });
    test('settle 0.85 → 0.95', () {
      expect(boardingPrintedPhaseFor(0.90), BoardingPrintedPhase.settle);
      expect(boardingPrintedPhaseFor(0.94), BoardingPrintedPhase.settle);
    });
    test('ribbon 0.95 → 1.0', () {
      expect(boardingPrintedPhaseFor(0.97), BoardingPrintedPhase.ribbon);
      expect(boardingPrintedPhaseFor(0.99), BoardingPrintedPhase.ribbon);
    });
  });

  group('BoardingPrintedPhase handles', () {
    test('every phase has a MONO-CAP handle', () {
      for (final p in BoardingPrintedPhase.values) {
        expect(p.handle, equals(p.handle.toUpperCase()));
        expect(p.handle, isNotEmpty);
      }
    });
  });

  group('computePassExtrusion', () {
    test('0 below slot arm, 1.0 above settle', () {
      expect(computePassExtrusion(0.0), 0.0);
      expect(computePassExtrusion(0.15), 0.0);
      expect(computePassExtrusion(0.85), 1.0);
      expect(computePassExtrusion(1.0), 1.0);
    });
    test('mid-extrude is monotonic', () {
      final a = computePassExtrusion(0.30);
      final b = computePassExtrusion(0.50);
      final c = computePassExtrusion(0.70);
      expect(b, greaterThan(a));
      expect(c, greaterThan(b));
    });
    test('halfway through extrude is near 0.5 (eased)', () {
      // easeInOutCubic is not perfectly symmetric in Flutter's
      // implementation, so tolerance is widened slightly. The
      // monotonic test above is the strict guarantee.
      final mid = computePassExtrusion(0.20 + 0.65 / 2);
      expect(mid, closeTo(0.5, 0.05));
    });
  });

  group('BoardingPrintedCeremony — host integration', () {
    testWidgets('renders idle when play=false', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: BoardingPrintedCeremony(play: false)),
          ),
        ),
      );
      expect(find.byType(BoardingPrintedCeremony), findsOneWidget);
    });

    testWidgets('plays to completion and fires onPresented', (t) async {
      var presented = false;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: BoardingPrintedCeremony(
                play: true,
                duration: const Duration(milliseconds: 500),
                onPresented: () => presented = true,
              ),
            ),
          ),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      await t.pump(const Duration(milliseconds: 600));
      expect(presented, isTrue);
    });
  });
}
