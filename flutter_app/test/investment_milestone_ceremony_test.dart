import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/cinema3/investment_milestone_ceremony.dart';

void main() {
  group('InvestmentMilestoneFrames', () {
    test('phaseAt resolves per frame boundary', () {
      expect(
        InvestmentMilestoneFrames.phaseAt(Duration.zero),
        InvestmentMilestonePhase.baseline,
      );
      expect(
        InvestmentMilestoneFrames.phaseAt(const Duration(milliseconds: 300)),
        InvestmentMilestonePhase.baseline,
      );
      expect(
        InvestmentMilestoneFrames.phaseAt(const Duration(milliseconds: 800)),
        InvestmentMilestonePhase.fill,
      );
      expect(
        InvestmentMilestoneFrames.phaseAt(const Duration(milliseconds: 1500)),
        InvestmentMilestonePhase.target,
      );
      expect(
        InvestmentMilestoneFrames.phaseAt(const Duration(milliseconds: 2000)),
        InvestmentMilestonePhase.crown,
      );
      expect(
        InvestmentMilestoneFrames.phaseAt(const Duration(milliseconds: 2700)),
        InvestmentMilestonePhase.settle,
      );
      expect(
        InvestmentMilestoneFrames.phaseAt(const Duration(milliseconds: 3000)),
        InvestmentMilestonePhase.complete,
      );
    });

    test('boundary durations sum to 3.0 s', () {
      expect(InvestmentMilestoneFrames.completeAt.inMilliseconds, 3000);
    });

    test('phases progress monotonically', () {
      final samples = const <int>[
        0, 200, 400, 800, 1300, 1500, 1800, 2200, 2400, 2700, 3000,
      ];
      InvestmentMilestonePhase? last;
      for (final ms in samples) {
        final p =
            InvestmentMilestoneFrames.phaseAt(Duration(milliseconds: ms));
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

  group('InvestmentMilestoneCeremony widget', () {
    testWidgets('mounts with autoPlay false', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: InvestmentMilestoneCeremony(
                label: 'EMERGENCY FUND · 6 MO',
                amount: '€100,000',
                autoPlay: false,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(InvestmentMilestoneCeremony), findsOneWidget);
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
              child: InvestmentMilestoneCeremony(
                label: 'PORTFOLIO · €100K',
                amount: '€100,000',
                onComplete: () => done = true,
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 50));
      await t.pump(const Duration(milliseconds: 3100));
      expect(done, isTrue);
    });
  });

  group('InvestmentMilestoneCeremonyScreen', () {
    testWidgets('mounts CINEMA · 16A + REPLAY · MILESTONE CTA', (t) async {
      await t.pumpWidget(
        const MaterialApp(home: InvestmentMilestoneCeremonyScreen()),
      );
      await t.pump(const Duration(milliseconds: 16));
      expect(find.text('CINEMA · 16A'), findsOneWidget);
      expect(find.text('REPLAY · MILESTONE'), findsOneWidget);
    });
  });
}
