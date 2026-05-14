import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/i18n/brand_motion_policy.dart';

void main() {
  group('BrandMotionPolicy.isReduced', () {
    testWidgets('returns false under default MediaQuery', (t) async {
      late BuildContext captured;
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Builder(builder: (ctx) {
            captured = ctx;
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(BrandMotionPolicy.isReduced(captured), isFalse);
    });

    testWidgets('returns true when disableAnimations is set', (t) async {
      late BuildContext captured;
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(builder: (ctx) {
            captured = ctx;
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(BrandMotionPolicy.isReduced(captured), isTrue);
    });
  });

  group('BrandMotionPolicy.adaptDuration', () {
    testWidgets('full motion passes through unchanged', (t) async {
      late BuildContext captured;
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Builder(builder: (ctx) {
            captured = ctx;
            return const SizedBox.shrink();
          }),
        ),
      );
      for (final role in BrandMotionRole.values) {
        expect(
          BrandMotionPolicy.adaptDuration(
            captured,
            const Duration(milliseconds: 800),
            role: role,
          ),
          const Duration(milliseconds: 800),
        );
      }
    });

    testWidgets('reduced motion adapts each role', (t) async {
      late BuildContext captured;
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(builder: (ctx) {
            captured = ctx;
            return const SizedBox.shrink();
          }),
        ),
      );

      expect(
        BrandMotionPolicy.adaptDuration(
          captured,
          const Duration(milliseconds: 800),
          role: BrandMotionRole.structural,
        ),
        const Duration(milliseconds: 100),
      );

      expect(
        BrandMotionPolicy.adaptDuration(
          captured,
          const Duration(milliseconds: 800),
          role: BrandMotionRole.ambient,
        ),
        Duration.zero,
      );

      expect(
        BrandMotionPolicy.adaptDuration(
          captured,
          const Duration(milliseconds: 800),
          role: BrandMotionRole.signature,
        ),
        const Duration(milliseconds: 400),
      );
    });
  });

  group('BrandMotionPolicy.adaptCurve', () {
    testWidgets('full motion passes the curve through', (t) async {
      late BuildContext captured;
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Builder(builder: (ctx) {
            captured = ctx;
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(
        BrandMotionPolicy.adaptCurve(captured, Curves.elasticOut),
        Curves.elasticOut,
      );
    });

    testWidgets('reduced motion substitutes easeOutCubic', (t) async {
      late BuildContext captured;
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(builder: (ctx) {
            captured = ctx;
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(
        BrandMotionPolicy.adaptCurve(captured, Curves.elasticOut),
        Curves.easeOutCubic,
      );
    });
  });

  group('ReducedMotionGate', () {
    testWidgets('ambient: replaced with placeholder under reduced motion',
        (t) async {
      await t.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: ReducedMotionGate(
            role: BrandMotionRole.ambient,
            placeholder: Text('AMBIENT-OFF', textDirection: TextDirection.ltr),
            child: Text('BREATHING', textDirection: TextDirection.ltr),
          ),
        ),
      );
      expect(find.text('AMBIENT-OFF'), findsOneWidget);
      expect(find.text('BREATHING'), findsNothing);
    });

    testWidgets('ambient: renders child when motion is enabled', (t) async {
      await t.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(),
          child: ReducedMotionGate(
            role: BrandMotionRole.ambient,
            placeholder: Text('AMBIENT-OFF', textDirection: TextDirection.ltr),
            child: Text('BREATHING', textDirection: TextDirection.ltr),
          ),
        ),
      );
      expect(find.text('BREATHING'), findsOneWidget);
      expect(find.text('AMBIENT-OFF'), findsNothing);
    });

    testWidgets(
        'structural / signature: render child even under reduced motion',
        (t) async {
      for (final role in [BrandMotionRole.structural, BrandMotionRole.signature]) {
        await t.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: ReducedMotionGate(
              role: role,
              placeholder: const Text('OFF', textDirection: TextDirection.ltr),
              child: const Text('ON', textDirection: TextDirection.ltr),
            ),
          ),
        );
        expect(find.text('ON'), findsOneWidget);
        expect(find.text('OFF'), findsNothing);
      }
    });
  });

  group('shouldRenderAmbient', () {
    testWidgets('true under full motion', (t) async {
      late BuildContext captured;
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Builder(builder: (ctx) {
            captured = ctx;
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(BrandMotionPolicy.shouldRenderAmbient(captured), isTrue);
    });

    testWidgets('false under reduced motion', (t) async {
      late BuildContext captured;
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(builder: (ctx) {
            captured = ctx;
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(BrandMotionPolicy.shouldRenderAmbient(captured), isFalse);
    });
  });
}
