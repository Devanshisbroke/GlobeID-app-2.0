import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/cinema2/milestone_bloom_ceremony.dart';

void main() {
  group('MilestoneBloomFrames', () {
    test('phaseAt resolves the expected phase per frame boundary', () {
      expect(
        MilestoneBloomFrames.phaseAt(Duration.zero),
        MilestoneBloomPhase.ring,
      );
      expect(
        MilestoneBloomFrames.phaseAt(const Duration(milliseconds: 300)),
        MilestoneBloomPhase.ring,
      );
      expect(
        MilestoneBloomFrames.phaseAt(const Duration(milliseconds: 700)),
        MilestoneBloomPhase.petals,
      );
      expect(
        MilestoneBloomFrames.phaseAt(const Duration(milliseconds: 1200)),
        MilestoneBloomPhase.pulse,
      );
      expect(
        MilestoneBloomFrames.phaseAt(const Duration(milliseconds: 2000)),
        MilestoneBloomPhase.settle,
      );
      expect(
        MilestoneBloomFrames.phaseAt(const Duration(milliseconds: 2800)),
        MilestoneBloomPhase.complete,
      );
      expect(
        MilestoneBloomFrames.phaseAt(const Duration(milliseconds: 4000)),
        MilestoneBloomPhase.complete,
      );
    });

    test('boundary durations sum to 2.8 s', () {
      expect(MilestoneBloomFrames.completeAt.inMilliseconds, 2800);
    });

    test('phases progress monotonically', () {
      final samples = const <int>[
        0, 200, 500, 800, 1100, 1400, 1700, 2200, 2700, 2800,
      ];
      MilestoneBloomPhase? last;
      for (final ms in samples) {
        final p = MilestoneBloomFrames.phaseAt(Duration(milliseconds: ms));
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

  group('MilestoneBloomCeremony widget', () {
    testWidgets('mounts and paints with autoPlay false', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: MilestoneBloomCeremony(
                milestoneLabel: 'BARCELONA · ARRIVAL',
                phaseLabel: 'PHASE · 03 / 06',
                autoPlay: false,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(MilestoneBloomCeremony), findsOneWidget);
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
              child: MilestoneBloomCeremony(
                milestoneLabel: 'TOKYO · DEPARTURE',
                phaseLabel: 'PHASE · 02 / 06',
                onComplete: () => done = true,
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 50));
      await t.pump(const Duration(milliseconds: 2900));
      expect(done, isTrue);
    });
  });

  group('MilestoneBloomCeremonyScreen', () {
    testWidgets('mounts the CINEMA · 15B eyebrow and REPLAY CTA',
        (t) async {
      await t.pumpWidget(
        const MaterialApp(home: MilestoneBloomCeremonyScreen()),
      );
      await t.pump(const Duration(milliseconds: 16));
      expect(find.text('CINEMA · 15B'), findsOneWidget);
      expect(find.text('REPLAY · BLOOM'), findsOneWidget);
    });
  });
}
