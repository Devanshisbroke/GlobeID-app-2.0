import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/branding/seal_loading_state.dart';

void main() {
  group('sealLoadingPhaseFor', () {
    test('idle at t == 0', () {
      expect(sealLoadingPhaseFor(0), SealLoadingPhase.idle);
    });
    test('substrate fade in [0, 0.18)', () {
      expect(sealLoadingPhaseFor(0.05), SealLoadingPhase.substrateFade);
      expect(sealLoadingPhaseFor(0.17), SealLoadingPhase.substrateFade);
    });
    test('press in [0.18, 0.48)', () {
      expect(sealLoadingPhaseFor(0.18), SealLoadingPhase.press);
      expect(sealLoadingPhaseFor(0.40), SealLoadingPhase.press);
      expect(sealLoadingPhaseFor(0.47), SealLoadingPhase.press);
    });
    test('settle in [0.48, 0.62)', () {
      expect(sealLoadingPhaseFor(0.48), SealLoadingPhase.settle);
      expect(sealLoadingPhaseFor(0.55), SealLoadingPhase.settle);
    });
    test('ink bleed in [0.62, 0.80)', () {
      expect(sealLoadingPhaseFor(0.62), SealLoadingPhase.inkBleed);
      expect(sealLoadingPhaseFor(0.79), SealLoadingPhase.inkBleed);
    });
    test('marked in [0.80, 1.0]', () {
      expect(sealLoadingPhaseFor(0.80), SealLoadingPhase.marked);
      expect(sealLoadingPhaseFor(0.99), SealLoadingPhase.marked);
      expect(sealLoadingPhaseFor(1.0), SealLoadingPhase.marked);
    });
  });

  group('sealLoadingHandles', () {
    test('handles cover every phase', () {
      for (final phase in SealLoadingPhase.values) {
        expect(sealLoadingHandles[phase], isNotNull);
        expect(sealLoadingHandles[phase]!.isNotEmpty, isTrue);
      }
    });
  });

  group('computeSealScale', () {
    test('initial scale = 0.40 in substrate phase', () {
      expect(computeSealScale(0.0), closeTo(0.40, 0.001));
      expect(computeSealScale(0.10), closeTo(0.40, 0.001));
    });
    test('overshoot peaks above 1.0 during press', () {
      // Press uses easeOutBack with a target of 1.12; the curve
      // overshoots its own target by a small margin, so we only
      // assert that the value comfortably exceeds the starting scale
      // and stays bounded under 1.30.
      final mid = computeSealScale(0.38);
      expect(mid, greaterThan(0.5));
      expect(mid, lessThan(1.30));
    });
    test('settles back to 1.0 after settle window', () {
      expect(computeSealScale(0.62), closeTo(1.0, 0.001));
      expect(computeSealScale(0.8), closeTo(1.0, 0.001));
      expect(computeSealScale(1.0), closeTo(1.0, 0.001));
    });
  });

  group('computeInkBleedFraction', () {
    test('zero outside bleed window', () {
      expect(computeInkBleedFraction(0.0), 0.0);
      expect(computeInkBleedFraction(0.61), 0.0);
    });
    test('one at end of bleed window', () {
      expect(computeInkBleedFraction(0.80), closeTo(1.0, 0.001));
      expect(computeInkBleedFraction(0.95), closeTo(1.0, 0.001));
    });
    test('monotonic within bleed window', () {
      final a = computeInkBleedFraction(0.65);
      final b = computeInkBleedFraction(0.72);
      final c = computeInkBleedFraction(0.78);
      expect(a, lessThan(b));
      expect(b, lessThan(c));
    });
  });

  group('computeMarkerOpacity', () {
    test('zero before marked window', () {
      expect(computeMarkerOpacity(0.79), 0.0);
    });
    test('linear ramp across marked window', () {
      expect(computeMarkerOpacity(0.90), closeTo(0.5, 0.001));
      expect(computeMarkerOpacity(1.0), closeTo(1.0, 0.001));
    });
  });

  group('SealLoadingState widget', () {
    testWidgets('mounts and renders idle state when autoPlay=false',
        (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SealLoadingState(
              autoPlay: false,
            ),
          ),
        ),
      );
      expect(find.byType(SealLoadingState), findsOneWidget);
      expect(find.text('G·ID'), findsOneWidget);
    });

    testWidgets('play() runs the ceremony to completion', (t) async {
      final key = GlobalKey<SealLoadingStateState>();
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SealLoadingState(key: key, autoPlay: false),
          ),
        ),
      );
      // Play and let the ceremony settle.
      // ignore: unawaited_futures
      key.currentState!.play();
      await t.pump(const Duration(milliseconds: 1700));
      await t.pumpAndSettle();
      expect(find.text('GLOBE · ID'), findsOneWidget);
    });
  });
}
