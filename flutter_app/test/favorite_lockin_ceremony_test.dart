import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/cinema2/favorite_lockin_ceremony.dart';

void main() {
  group('FavoriteLockInFrames', () {
    test('phaseAt resolves per frame boundary', () {
      expect(
        FavoriteLockInFrames.phaseAt(Duration.zero),
        FavoriteLockInPhase.toss,
      );
      expect(
        FavoriteLockInFrames.phaseAt(const Duration(milliseconds: 200)),
        FavoriteLockInPhase.toss,
      );
      expect(
        FavoriteLockInFrames.phaseAt(const Duration(milliseconds: 600)),
        FavoriteLockInPhase.apex,
      );
      expect(
        FavoriteLockInFrames.phaseAt(const Duration(milliseconds: 1100)),
        FavoriteLockInPhase.land,
      );
      expect(
        FavoriteLockInFrames.phaseAt(const Duration(milliseconds: 1700)),
        FavoriteLockInPhase.lock,
      );
      expect(
        FavoriteLockInFrames.phaseAt(const Duration(milliseconds: 2000)),
        FavoriteLockInPhase.complete,
      );
    });

    test('boundary durations sum to 2.0 s', () {
      expect(FavoriteLockInFrames.completeAt.inMilliseconds, 2000);
    });

    test('phases progress monotonically', () {
      final samples = const <int>[
        0, 100, 300, 600, 900, 1100, 1300, 1700, 2000,
      ];
      FavoriteLockInPhase? last;
      for (final ms in samples) {
        final p = FavoriteLockInFrames.phaseAt(Duration(milliseconds: ms));
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

  group('FavoriteLockInCeremony widget', () {
    testWidgets('mounts with autoPlay false', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: FavoriteLockInCeremony(
                countryCode: 'JP',
                countryName: 'JAPAN',
                autoPlay: false,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(FavoriteLockInCeremony), findsOneWidget);
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
              child: FavoriteLockInCeremony(
                countryCode: 'FR',
                countryName: 'FRANCE',
                onComplete: () => done = true,
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 50));
      await t.pump(const Duration(milliseconds: 2100));
      expect(done, isTrue);
    });
  });

  group('FavoriteLockInCeremonyScreen', () {
    testWidgets('mounts CINEMA · 15D + REPLAY · LOCK CTA', (t) async {
      await t.pumpWidget(
        const MaterialApp(home: FavoriteLockInCeremonyScreen()),
      );
      await t.pump(const Duration(milliseconds: 16));
      expect(find.text('CINEMA · 15D'), findsOneWidget);
      expect(find.text('REPLAY · LOCK'), findsOneWidget);
    });
  });
}
