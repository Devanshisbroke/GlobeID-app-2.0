import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/i18n/brand_direction.dart';

void main() {
  group('BrandDirection helpers', () {
    testWidgets('isRtl returns true under RTL Directionality', (t) async {
      late BuildContext captured;
      await t.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(builder: (ctx) {
            captured = ctx;
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(BrandDirection.isRtl(captured), isTrue);
      expect(BrandDirection.isLtr(captured), isFalse);
    });

    testWidgets('isLtr returns true under LTR Directionality', (t) async {
      late BuildContext captured;
      await t.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(builder: (ctx) {
            captured = ctx;
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(BrandDirection.isLtr(captured), isTrue);
      expect(BrandDirection.isRtl(captured), isFalse);
    });
  });

  group('BrandLtr', () {
    testWidgets('forces LTR inside an RTL subtree', (t) async {
      late BuildContext captured;
      await t.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: BrandLtr(
            child: Builder(builder: (ctx) {
              captured = ctx;
              return const SizedBox.shrink();
            }),
          ),
        ),
      );
      expect(Directionality.of(captured), TextDirection.ltr);
    });

    testWidgets('is a no-op under LTR Directionality', (t) async {
      late BuildContext captured;
      await t.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BrandLtr(
            child: Builder(builder: (ctx) {
              captured = ctx;
              return const SizedBox.shrink();
            }),
          ),
        ),
      );
      expect(Directionality.of(captured), TextDirection.ltr);
    });
  });

  group('MirrorAware', () {
    testWidgets('mirrors child under RTL', (t) async {
      await t.pumpWidget(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: MirrorAware(
            child: SizedBox.shrink(key: ValueKey('payload')),
          ),
        ),
      );
      final transformFinder = find.byType(Transform);
      expect(transformFinder, findsAtLeast(1));
      final mirrored = t
          .widgetList<Transform>(transformFinder)
          .where((tx) =>
              tx.transform.entry(0, 0) == -1 && tx.transform.entry(1, 1) == 1)
          .toList();
      expect(mirrored.length, 1);
    });

    testWidgets('does not mirror under LTR', (t) async {
      await t.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MirrorAware(
            child: SizedBox.shrink(key: ValueKey('payload')),
          ),
        ),
      );
      // No Transform wrapper with scaleX = -1.
      final mirrored = t
          .widgetList<Transform>(find.byType(Transform))
          .where((tx) =>
              tx.transform.entry(0, 0) == -1 && tx.transform.entry(1, 1) == 1)
          .toList();
      expect(mirrored, isEmpty);
      expect(find.byKey(const ValueKey('payload')), findsOneWidget);
    });
  });

  group('brandAligned', () {
    testWidgets('returns the same Alignment under LTR', (t) async {
      late BuildContext captured;
      await t.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(builder: (ctx) {
            captured = ctx;
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(
        brandAligned(captured, const Alignment(-0.8, 0.2)),
        const Alignment(-0.8, 0.2),
      );
    });

    testWidgets('flips horizontal anchor under RTL', (t) async {
      late BuildContext captured;
      await t.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(builder: (ctx) {
            captured = ctx;
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(
        brandAligned(captured, const Alignment(-0.8, 0.2)),
        const Alignment(0.8, 0.2),
      );
    });
  });

  group('resolveDirectionalPadding', () {
    testWidgets('leaves start/end in place under LTR', (t) async {
      late BuildContext captured;
      await t.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(builder: (ctx) {
            captured = ctx;
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(
        resolveDirectionalPadding(captured, start: 12, end: 4, top: 2, bottom: 3),
        const EdgeInsets.fromLTRB(12, 2, 4, 3),
      );
    });

    testWidgets('swaps start/end under RTL', (t) async {
      late BuildContext captured;
      await t.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(builder: (ctx) {
            captured = ctx;
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(
        resolveDirectionalPadding(captured, start: 12, end: 4, top: 2, bottom: 3),
        const EdgeInsets.fromLTRB(4, 2, 12, 3),
      );
    });
  });
}
