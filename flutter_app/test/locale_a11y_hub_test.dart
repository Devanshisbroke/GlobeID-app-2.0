import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:globeid/features/i18n/locale_a11y_hub_screen.dart';

GoRouter _testRouter() {
  return GoRouter(
    initialLocation: '/hub',
    routes: [
      GoRoute(
        path: '/hub',
        builder: (_, __) => const LocaleA11yHubScreen(),
      ),
      GoRoute(
        path: '/lab/locale-gallery',
        builder: (_, __) => const _StubScreen('LocaleGallery'),
      ),
      GoRoute(
        path: '/lab/rtl-audit',
        builder: (_, __) => const _StubScreen('RtlAudit'),
      ),
      GoRoute(
        path: '/lab/dynamic-type',
        builder: (_, __) => const _StubScreen('DynamicType'),
      ),
      GoRoute(
        path: '/lab/reduced-motion',
        builder: (_, __) => const _StubScreen('ReducedMotion'),
      ),
      GoRoute(
        path: '/lab/wcag',
        builder: (_, __) => const _StubScreen('Wcag'),
      ),
    ],
  );
}

class _StubScreen extends StatelessWidget {
  const _StubScreen(this.label);
  final String label;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(label)));
}

Future<void> _scrollToFindAndAssert(
  WidgetTester t,
  Finder needle,
) async {
  // The hub is a ListView, so off-screen modules must be scrolled
  // into view before assertions can find them.
  final list = find.byType(Scrollable).first;
  await t.scrollUntilVisible(needle, 80, scrollable: list);
}

void main() {
  group('LocaleA11yHubScreen', () {
    testWidgets('renders the phase eyebrow and capstone title', (t) async {
      await t.pumpWidget(
        MaterialApp.router(routerConfig: _testRouter()),
      );
      await t.pumpAndSettle();

      expect(find.textContaining('PHASE · 13F'), findsAtLeast(1));
      expect(find.textContaining('Locale + Accessibility'), findsOneWidget);
    });

    testWidgets('scrolls through and renders all 5 phase modules', (t) async {
      await t.pumpWidget(
        MaterialApp.router(routerConfig: _testRouter()),
      );
      await t.pumpAndSettle();

      // Phase 13A is at the top — already visible.
      expect(find.textContaining('PHASE · 13A'), findsOneWidget);

      // Scroll into view for B-E and assert each one in turn.
      for (final phase in ['13B', '13C', '13D', '13E']) {
        await _scrollToFindAndAssert(
          t,
          find.textContaining('PHASE · $phase'),
        );
        expect(find.textContaining('PHASE · $phase'), findsOneWidget);
      }
    });

    testWidgets('live state card shows foil contrast ratio', (t) async {
      await t.pumpWidget(
        MaterialApp.router(routerConfig: _testRouter()),
      );
      await t.pumpAndSettle();

      // 9.5:1 is the foil-on-OLED ratio computed by BrandContrast at runtime.
      expect(find.textContaining(':1'), findsAtLeast(1));
      expect(find.textContaining('GLOBE · ID · LIVE'), findsOneWidget);
    });

    testWidgets('renders the invariants card with key lines', (t) async {
      await t.pumpWidget(
        MaterialApp.router(routerConfig: _testRouter()),
      );
      await t.pumpAndSettle();

      // Scroll to bottom — the invariants card is the last child.
      await _scrollToFindAndAssert(
        t,
        find.textContaining('CAPSTONE · INVARIANTS'),
      );
      expect(find.textContaining('CAPSTONE · INVARIANTS'), findsOneWidget);
      expect(
        find.textContaining('watermark stays Latin LTR'),
        findsOneWidget,
      );
    });
  });
}
