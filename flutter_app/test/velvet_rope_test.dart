import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/ceremony/velvet_rope_ceremony.dart';

void main() {
  group('velvetRopePhaseFor', () {
    test('0 → closed, 1.0 → admitted', () {
      expect(velvetRopePhaseFor(0), VelvetRopePhase.closed);
      expect(velvetRopePhaseFor(1.0), VelvetRopePhase.admitted);
    });
    test('brass arm 0 → 0.16', () {
      expect(velvetRopePhaseFor(0.05), VelvetRopePhase.brassArm);
      expect(velvetRopePhaseFor(0.15), VelvetRopePhase.brassArm);
    });
    test('rope lift 0.16 → 0.55', () {
      expect(velvetRopePhaseFor(0.20), VelvetRopePhase.ropeLift);
      expect(velvetRopePhaseFor(0.54), VelvetRopePhase.ropeLift);
    });
    test('world dim 0.55 → 0.75', () {
      expect(velvetRopePhaseFor(0.60), VelvetRopePhase.worldDim);
      expect(velvetRopePhaseFor(0.74), VelvetRopePhase.worldDim);
    });
    test('member reveal 0.75 → 1.0', () {
      expect(velvetRopePhaseFor(0.80), VelvetRopePhase.memberReveal);
      expect(velvetRopePhaseFor(0.99), VelvetRopePhase.memberReveal);
    });
  });

  group('VelvetRopePhase handles', () {
    test('every phase has a MONO-CAP handle', () {
      for (final p in VelvetRopePhase.values) {
        expect(p.handle, equals(p.handle.toUpperCase()));
        expect(p.handle, isNotEmpty);
      }
    });
  });

  group('computeRopeLift', () {
    test('0 below lift onset, 1.0 above lift end', () {
      expect(computeRopeLift(0.0), 0.0);
      expect(computeRopeLift(0.10), 0.0);
      expect(computeRopeLift(0.55), 1.0);
      expect(computeRopeLift(1.0), 1.0);
    });
    test('monotonic across lift range', () {
      expect(computeRopeLift(0.40), greaterThan(computeRopeLift(0.25)));
    });
  });

  group('computeWorldDim', () {
    test('0 below world-dim onset, ~0.78 at end', () {
      expect(computeWorldDim(0.0), 0.0);
      expect(computeWorldDim(0.40), 0.0);
      expect(computeWorldDim(0.75), closeTo(0.78, 0.001));
      expect(computeWorldDim(1.0), closeTo(0.78, 0.001));
    });
  });

  group('VelvetRopeCeremony — host integration', () {
    testWidgets('renders idle when play=false', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: VelvetRopeCeremony(play: false)),
          ),
        ),
      );
      expect(find.byType(VelvetRopeCeremony), findsOneWidget);
    });

    testWidgets('plays to completion and fires onAdmitted', (t) async {
      var called = false;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: VelvetRopeCeremony(
                play: true,
                duration: const Duration(milliseconds: 500),
                onAdmitted: () => called = true,
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
