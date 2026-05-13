import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/motion/motion_tokens.dart';

void main() {
  group('Motion tokens', () {
    test('duration ladder is monotonically increasing for primary timings',
        () {
      final ladder = <Duration>[
        Motion.dInstant,
        Motion.dTap,
        Motion.dQuickReverse,
        Motion.dModal,
        Motion.dSheet,
        Motion.dPage,
        Motion.dCruise,
        Motion.dPortal,
      ];
      for (var i = 1; i < ladder.length; i++) {
        expect(
          ladder[i] > ladder[i - 1],
          isTrue,
          reason: 'expected ${ladder[i]} > ${ladder[i - 1]} at index $i',
        );
      }
    });

    test('breath durations are positive and ordered fast < slow', () {
      expect(Motion.dBreathFast > Duration.zero, isTrue);
      expect(Motion.dBreathSlow > Motion.dBreathFast, isTrue);
    });

    test('curves include only Cubic / built-in', () {
      // Smoke test: every named curve transforms 0/1 cleanly and
      // returns something inside [0..1] roughly bounded — except
      // `cSpring` which overshoots.
      for (final c in [
        Motion.cStandard,
        Motion.cEmphasized,
        Motion.cExit,
        Motion.cSettle,
      ]) {
        expect(c.transform(0.0), closeTo(0.0, 1e-3));
        expect(c.transform(1.0), closeTo(1.0, 1e-3));
        for (final t in [0.25, 0.5, 0.75]) {
          final v = c.transform(t);
          expect(v.isFinite, isTrue);
          expect(v, greaterThanOrEqualTo(-0.05));
          expect(v, lessThanOrEqualTo(1.05));
        }
      }
    });

    test('cSpring overshoots above 1.0 somewhere in (0, 1)', () {
      // The spring curve is intentionally bouncy.
      const spring = Motion.cSpring;
      final samples = List<double>.generate(40, (i) => i / 40);
      final maxV = samples.map(spring.transform).reduce((a, b) => a > b ? a : b);
      expect(maxV, greaterThan(1.0));
    });

    test('cLinear is the literal Curves.linear', () {
      expect(Motion.cLinear, same(Curves.linear));
    });
  });

  group('SpringSpec', () {
    test('description respects damping ratio (critically damped)', () {
      const spec = SpringSpec(response: 0.4, damping: 1.0);
      final d = spec.description;
      // Critically damped: damping == 2 * sqrt(mass * stiffness).
      // With mass=1, that means damping^2 == 4 * stiffness.
      expect(d.damping * d.damping, closeTo(4 * d.stiffness, 1e-3));
    });

    test('description respects damping ratio (underdamped, bouncy)', () {
      const spec = SpringSpec(response: 0.4, damping: 0.5);
      final d = spec.description;
      // Underdamped: damping^2 < 4 * stiffness.
      expect(d.damping * d.damping, lessThan(4 * d.stiffness));
    });

    test('shorter response → higher stiffness', () {
      const fast = SpringSpec(response: 0.2, damping: 0.8);
      const slow = SpringSpec(response: 0.6, damping: 0.8);
      expect(fast.description.stiffness, greaterThan(slow.description.stiffness));
    });
  });
}
