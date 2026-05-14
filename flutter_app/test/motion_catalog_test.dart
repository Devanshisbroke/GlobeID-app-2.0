import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/atelier/models/motion_catalog.dart';
import 'package:globeid/motion/motion_tokens.dart';

void main() {
  group('MotionCatalog · durations', () {
    test('enumerates the 10 canonical durations', () {
      expect(MotionCatalog.durations, hasLength(10));
    });

    test('every duration entry references a real Motion constant', () {
      // Build a map of every public-named Duration constant on Motion.
      final reference = <Duration, String>{
        Motion.dInstant: 'dInstant',
        Motion.dTap: 'dTap',
        Motion.dQuickReverse: 'dQuickReverse',
        Motion.dModal: 'dModal',
        Motion.dSheet: 'dSheet',
        Motion.dPage: 'dPage',
        Motion.dCruise: 'dCruise',
        Motion.dPortal: 'dPortal',
        Motion.dBreathFast: 'dBreathFast',
        Motion.dBreathSlow: 'dBreathSlow',
      };
      for (final entry in MotionCatalog.durations) {
        expect(
          reference.containsKey(entry.duration),
          isTrue,
          reason: '${entry.name} duration does not match any Motion constant',
        );
      }
    });

    test('readable formats ms under 1 s and seconds above', () {
      final fast = MotionCatalog.durationById('d-tap')!;
      expect(fast.readable, '160 ms');
      final slow = MotionCatalog.durationById('d-breath-slow')!;
      expect(slow.readable, contains('s'));
    });

    test('durations are monotonically non-decreasing in order', () {
      final ms = MotionCatalog.durations
          .map((e) => e.duration.inMilliseconds)
          .toList();
      for (var i = 1; i < ms.length; i++) {
        expect(
          ms[i] >= ms[i - 1],
          isTrue,
          reason: 'durations should be sorted ascending — '
              'index $i (${ms[i]}) < index ${i - 1} (${ms[i - 1]})',
        );
      }
    });
  });

  group('MotionCatalog · curves', () {
    test('enumerates the 6 canonical curves', () {
      expect(MotionCatalog.curves, hasLength(6));
    });

    test('every curve has non-empty name, role, and formula', () {
      for (final entry in MotionCatalog.curves) {
        expect(entry.name, isNotEmpty);
        expect(entry.role, isNotEmpty);
        expect(entry.formula, isNotEmpty);
      }
    });

    test('every curve resolves at t=0 → 0 and t=1 → 1', () {
      for (final entry in MotionCatalog.curves) {
        expect(entry.curve.transform(0.0), closeTo(0.0, 1e-6));
        expect(entry.curve.transform(1.0), closeTo(1.0, 1e-6));
      }
    });

    test('cSpring overshoots above 1.0 at some midpoint', () {
      final spring = MotionCatalog.curveById('c-spring')!.curve;
      // The whole point of cSpring is to overshoot. Sample 100 points.
      bool sawOvershoot = false;
      for (var t = 0.0; t <= 1.0; t += 0.01) {
        if (spring.transform(t) > 1.0) sawOvershoot = true;
      }
      expect(sawOvershoot, isTrue);
    });

    test('cLinear is exactly Curves.linear', () {
      expect(MotionCatalog.curveById('c-linear')!.curve, Curves.linear);
    });

    test('curveById returns null on miss', () {
      expect(MotionCatalog.curveById('does-not-exist'), isNull);
    });
  });
}
