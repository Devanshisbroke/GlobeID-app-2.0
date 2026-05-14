import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/cinema2/concierge_handoff_ceremony.dart';

void main() {
  group('ConciergeHandoffFrames', () {
    test('phaseAt resolves per frame boundary', () {
      expect(
        ConciergeHandoffFrames.phaseAt(Duration.zero),
        ConciergeHandoffPhase.userNode,
      );
      expect(
        ConciergeHandoffFrames.phaseAt(const Duration(milliseconds: 300)),
        ConciergeHandoffPhase.userNode,
      );
      expect(
        ConciergeHandoffFrames.phaseAt(const Duration(milliseconds: 600)),
        ConciergeHandoffPhase.travel,
      );
      expect(
        ConciergeHandoffFrames.phaseAt(const Duration(milliseconds: 1100)),
        ConciergeHandoffPhase.receive,
      );
      expect(
        ConciergeHandoffFrames.phaseAt(const Duration(milliseconds: 1700)),
        ConciergeHandoffPhase.seal,
      );
      expect(
        ConciergeHandoffFrames.phaseAt(const Duration(milliseconds: 2300)),
        ConciergeHandoffPhase.settle,
      );
      expect(
        ConciergeHandoffFrames.phaseAt(const Duration(milliseconds: 2600)),
        ConciergeHandoffPhase.complete,
      );
    });

    test('boundary durations sum to 2.6 s', () {
      expect(ConciergeHandoffFrames.completeAt.inMilliseconds, 2600);
    });

    test('phases progress monotonically', () {
      final samples = const <int>[
        0, 200, 500, 900, 1100, 1400, 1700, 2100, 2400, 2600,
      ];
      ConciergeHandoffPhase? last;
      for (final ms in samples) {
        final p = ConciergeHandoffFrames.phaseAt(Duration(milliseconds: ms));
        if (last != null) {
          expect(
            p.index >= last.index,
            isTrue,
            reason: 'regressed at ${ms}ms: $last -> $p',
          );
        }
        last = p;
      }
    });
  });

  group('ConciergeHandoffCeremony widget', () {
    testWidgets('mounts with autoPlay false', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: ConciergeHandoffCeremony(
                serviceLabel: 'PRIVATE DRIVER · 09:40',
                autoPlay: false,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(ConciergeHandoffCeremony), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('fires onComplete after the cinematic finishes', (t) async {
      var done = false;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: ConciergeHandoffCeremony(
                serviceLabel: 'CHEF · 19:30',
                onComplete: () => done = true,
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 50));
      await t.pump(const Duration(milliseconds: 2700));
      expect(done, isTrue);
    });
  });

  group('ConciergeHandoffCeremonyScreen', () {
    testWidgets('mounts CINEMA · 15E + REPLAY · HANDOFF CTA', (t) async {
      await t.pumpWidget(
        const MaterialApp(home: ConciergeHandoffCeremonyScreen()),
      );
      await t.pump(const Duration(milliseconds: 16));
      expect(find.text('CINEMA · 15E'), findsOneWidget);
      expect(find.text('REPLAY · HANDOFF'), findsOneWidget);
    });
  });
}
