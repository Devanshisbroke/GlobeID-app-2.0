import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/cinema2/tier_promotion_ceremony.dart';

void main() {
  group('TierPromotionFrames', () {
    test('phaseAt resolves per frame boundary', () {
      expect(
        TierPromotionFrames.phaseAt(Duration.zero),
        TierPromotionPhase.glow,
      );
      expect(
        TierPromotionFrames.phaseAt(const Duration(milliseconds: 300)),
        TierPromotionPhase.glow,
      );
      expect(
        TierPromotionFrames.phaseAt(const Duration(milliseconds: 800)),
        TierPromotionPhase.lift,
      );
      expect(
        TierPromotionFrames.phaseAt(const Duration(milliseconds: 1400)),
        TierPromotionPhase.rings,
      );
      expect(
        TierPromotionFrames.phaseAt(const Duration(milliseconds: 2100)),
        TierPromotionPhase.reveal,
      );
      expect(
        TierPromotionFrames.phaseAt(const Duration(milliseconds: 2700)),
        TierPromotionPhase.hold,
      );
      expect(
        TierPromotionFrames.phaseAt(const Duration(milliseconds: 3200)),
        TierPromotionPhase.complete,
      );
    });

    test('boundary durations sum to 3.2 s', () {
      expect(TierPromotionFrames.completeAt.inMilliseconds, 3200);
    });

    test('phases progress monotonically', () {
      final samples = const <int>[
        0, 200, 500, 800, 1200, 1500, 1900, 2200, 2500, 2900, 3200,
      ];
      TierPromotionPhase? last;
      for (final ms in samples) {
        final p = TierPromotionFrames.phaseAt(Duration(milliseconds: ms));
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

  group('TierPromotionCeremony widget', () {
    testWidgets('mounts with autoPlay false', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: TierPromotionCeremony(
                fromTier: 'ATELIER',
                toTier: 'PILOT',
                autoPlay: false,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(TierPromotionCeremony), findsOneWidget);
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
              child: TierPromotionCeremony(
                fromTier: 'STANDARD',
                toTier: 'ATELIER',
                onComplete: () => done = true,
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 50));
      await t.pump(const Duration(milliseconds: 3300));
      expect(done, isTrue);
    });
  });

  group('TierPromotionCeremonyScreen', () {
    testWidgets('mounts the CINEMA · 15C eyebrow + REPLAY CTA', (t) async {
      await t.pumpWidget(
        const MaterialApp(home: TierPromotionCeremonyScreen()),
      );
      await t.pump(const Duration(milliseconds: 16));
      expect(find.text('CINEMA · 15C'), findsOneWidget);
      expect(find.text('REPLAY · PROMOTION'), findsOneWidget);
    });
  });
}
