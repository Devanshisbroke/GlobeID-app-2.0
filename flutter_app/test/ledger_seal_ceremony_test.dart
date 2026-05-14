import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/cinema2/ledger_seal_ceremony.dart';

void main() {
  group('LedgerSealFrames', () {
    test('phaseAt resolves the expected phase per frame boundary', () {
      expect(
        LedgerSealFrames.phaseAt(Duration.zero),
        LedgerSealPhase.ribbon,
      );
      expect(
        LedgerSealFrames.phaseAt(const Duration(milliseconds: 200)),
        LedgerSealPhase.ribbon,
      );
      expect(
        LedgerSealFrames.phaseAt(const Duration(milliseconds: 600)),
        LedgerSealPhase.wax,
      );
      expect(
        LedgerSealFrames.phaseAt(const Duration(milliseconds: 1200)),
        LedgerSealPhase.press,
      );
      expect(
        LedgerSealFrames.phaseAt(const Duration(milliseconds: 1800)),
        LedgerSealPhase.settle,
      );
      expect(
        LedgerSealFrames.phaseAt(const Duration(milliseconds: 2400)),
        LedgerSealPhase.complete,
      );
      expect(
        LedgerSealFrames.phaseAt(const Duration(milliseconds: 4000)),
        LedgerSealPhase.complete,
      );
    });

    test('boundary durations sum to 2.4 s', () {
      expect(LedgerSealFrames.completeAt.inMilliseconds, 2400);
    });

    test('phases progress monotonically', () {
      final samples = const <int>[0, 200, 500, 900, 1200, 1700, 2200, 2400];
      LedgerSealPhase? last;
      for (final ms in samples) {
        final p = LedgerSealFrames.phaseAt(Duration(milliseconds: ms));
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

  group('LedgerSealCeremony widget', () {
    testWidgets('mounts and paints with autoPlay false', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 480,
              child: LedgerSealCeremony(
                entryLabel: 'GROCERIES · CARREFOUR',
                amount: '€ 42.60',
                currency: 'EUR',
                autoPlay: false,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(LedgerSealCeremony), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('fires onComplete after the cinematic finishes', (t) async {
      var done = false;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 480,
              child: LedgerSealCeremony(
                entryLabel: 'COFFEE · BLUE BOTTLE',
                amount: '€ 4.20',
                onComplete: () => done = true,
              ),
            ),
          ),
        ),
      );
      // Pump beyond the 2.4 s ceremony.
      await t.pump(const Duration(milliseconds: 50));
      await t.pump(const Duration(milliseconds: 2500));
      expect(done, isTrue);
    });
  });

  group('LedgerSealCeremonyScreen', () {
    testWidgets('mounts the CINEMA · 15A eyebrow and REPLAY CTA',
        (t) async {
      await t.pumpWidget(
        const MaterialApp(home: LedgerSealCeremonyScreen()),
      );
      await t.pump(const Duration(milliseconds: 16));
      expect(find.text('CINEMA · 15A'), findsOneWidget);
      expect(find.text('REPLAY · CEREMONY'), findsOneWidget);
    });
  });
}
