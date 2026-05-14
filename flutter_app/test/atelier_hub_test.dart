import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:globeid/atelier/screens/atelier_hub_screen.dart';

void main() {
  group('AtelierHubScreen', () {
    Widget harness(Widget child) {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => child,
          ),
          for (final r in const <String>[
            '/atelier',
            '/atelier/lab/motion',
            '/atelier/lab/tokens',
            '/atelier/lab/regression',
            '/atelier/lab/dna-timeline',
          ])
            GoRoute(
              path: r,
              builder: (_, __) => Scaffold(
                body: Center(child: Text('stub $r')),
              ),
            ),
        ],
      );
      return MaterialApp.router(routerConfig: router);
    }

    Future<void> scrollUntil(WidgetTester t, String text) async {
      final finder = find.text(text);
      // If already in the widget tree, nothing to do — the lazy
      // viewport already built it.
      if (finder.evaluate().isNotEmpty) return;
      await t.scrollUntilVisible(
        finder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
    }

    testWidgets('mounts with the ATELIER · 14F eyebrow', (t) async {
      await t.pumpWidget(harness(const AtelierHubScreen()));
      await t.pump(const Duration(milliseconds: 16));
      expect(find.text('ATELIER · 14F'), findsOneWidget);
    });

    testWidgets('renders all 5 module phase chips', (t) async {
      await t.pumpWidget(harness(const AtelierHubScreen()));
      await t.pump(const Duration(milliseconds: 16));
      for (final chip in const ['14A', '14B', '14C', '14D', '14E']) {
        await scrollUntil(t, chip);
        expect(find.text(chip), findsOneWidget);
      }
    });

    testWidgets('renders module titles', (t) async {
      await t.pumpWidget(harness(const AtelierHubScreen()));
      await t.pump(const Duration(milliseconds: 16));
      for (final title in const [
        'Component gallery',
        'Motion choreography',
        'Brand tokens · export',
        'Visual regression',
        'Brand DNA timeline',
      ]) {
        await scrollUntil(t, title);
        expect(find.text(title), findsOneWidget);
      }
    });

    testWidgets('surfaces the INVARIANTS · CHARTER section header',
        (t) async {
      await t.pumpWidget(harness(const AtelierHubScreen()));
      await t.pump(const Duration(milliseconds: 16));
      await scrollUntil(t, 'INVARIANTS · CHARTER');
      expect(find.text('INVARIANTS · CHARTER'), findsOneWidget);
    });

    testWidgets('surfaces the OPERATOR · GUIDANCE section header',
        (t) async {
      await t.pumpWidget(harness(const AtelierHubScreen()));
      await t.pump(const Duration(milliseconds: 16));
      await scrollUntil(t, 'OPERATOR · GUIDANCE');
      expect(find.text('OPERATOR · GUIDANCE'), findsOneWidget);
    });

    testWidgets('renders the four guidance heads', (t) async {
      await t.pumpWidget(harness(const AtelierHubScreen()));
      await t.pump(const Duration(milliseconds: 16));
      await scrollUntil(t, 'NEW · SURFACE?');
      expect(find.text('NEW · SURFACE?'), findsOneWidget);
      await scrollUntil(t, 'NEW · MOTION?');
      expect(find.text('NEW · MOTION?'), findsOneWidget);
      await scrollUntil(t, 'NEW · TOKEN?');
      expect(find.text('NEW · TOKEN?'), findsOneWidget);
      await scrollUntil(t, 'NEW · BRAND DECISION?');
      expect(find.text('NEW · BRAND DECISION?'), findsOneWidget);
    });
  });
}
