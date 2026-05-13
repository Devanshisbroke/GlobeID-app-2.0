import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:globeid/features/copilot/copilot_hub_models.dart';
import 'package:globeid/features/copilot/copilot_hub_provider.dart';
import 'package:globeid/features/copilot/copilot_hub_screen.dart';

void main() {
  group('copilotHubSuggestionsProvider', () {
    test('returns at least one suggestion of every kind', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final list = container.read(copilotHubSuggestionsProvider);
      final kinds = list.map((s) => s.kind).toSet();
      // The seed should cover travel + wallet + identity at minimum.
      expect(kinds.contains(CopilotHubKind.travel), isTrue);
      expect(kinds.contains(CopilotHubKind.wallet), isTrue);
      expect(kinds.contains(CopilotHubKind.identity), isTrue);
    });

    test('is sorted critical → urgent → notable → passive', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final list = container.read(copilotHubSuggestionsProvider);
      int rank(CopilotHubUrgency u) {
        switch (u) {
          case CopilotHubUrgency.critical:
            return 0;
          case CopilotHubUrgency.urgent:
            return 1;
          case CopilotHubUrgency.notable:
            return 2;
          case CopilotHubUrgency.passive:
            return 3;
        }
      }

      for (var i = 1; i < list.length; i++) {
        expect(
          rank(list[i - 1].urgency) <= rank(list[i].urgency),
          isTrue,
          reason:
              'index $i breaks the urgency monotonicity '
              '(${list[i - 1].urgency} → ${list[i].urgency})',
        );
      }
    });

    test('urgentCountProvider counts urgent + critical only', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final all = container.read(copilotHubSuggestionsProvider);
      final expected = all
          .where((s) =>
              s.urgency == CopilotHubUrgency.urgent ||
              s.urgency == CopilotHubUrgency.critical)
          .length;
      final got = container.read(copilotHubUrgentCountProvider);
      expect(got, expected);
      expect(got, greaterThan(0));
    });

    test('result is unmodifiable', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final list = container.read(copilotHubSuggestionsProvider);
      expect(() => list.removeLast(), throwsUnsupportedError);
    });
  });

  group('CopilotHubScreen — rendering', () {
    Widget harness({GoRouter? router}) {
      final r = router ??
          GoRouter(
            initialLocation: '/copilot/hub',
            routes: [
              GoRoute(
                path: '/copilot/hub',
                builder: (_, __) => const CopilotHubScreen(),
              ),
              GoRoute(path: '/copilot', builder: (_, __) => const Scaffold()),
              for (final p in const [
                '/passport',
                '/visa',
                '/wallet/exchange',
                '/identity',
                '/country',
                '/airport',
              ])
                GoRoute(path: p, builder: (_, __) => Scaffold(
                  body: Center(child: Text('route:$p')),
                )),
            ],
          );
      return ProviderScope(
        child: MaterialApp.router(routerConfig: r),
      );
    }

    testWidgets('renders chrome + every suggestion title', (t) async {
      await t.pumpWidget(harness());
      await t.pump(const Duration(milliseconds: 100));

      expect(find.text('GLOBE·ID · COPILOT'), findsOneWidget);
      expect(find.text('Your travel intelligence'), findsOneWidget);
      expect(find.text('Passport expires in 11 days'), findsOneWidget);
      expect(
        find.text('Schengen visa renewal window opens today'),
        findsOneWidget,
      );
      expect(find.text('Convert \$500 to EUR today'), findsOneWidget);
    });

    testWidgets('chrome surfaces urgent-count chip', (t) async {
      await t.pumpWidget(harness());
      await t.pump(const Duration(milliseconds: 100));
      // The seed has at least 3 urgent + critical items.
      expect(
        find.textContaining('NEED ATTENTION'),
        findsOneWidget,
      );
    });

    testWidgets('tapping CTA pushes the deeplink', (t) async {
      final r = GoRouter(
        initialLocation: '/copilot/hub',
        routes: [
          GoRoute(
            path: '/copilot/hub',
            builder: (_, __) => const CopilotHubScreen(),
          ),
          GoRoute(
            path: '/passport',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('PASSPORT ROUTE'))),
          ),
          GoRoute(path: '/copilot', builder: (_, __) => const Scaffold()),
          for (final p in const [
            '/visa',
            '/wallet/exchange',
            '/identity',
            '/country',
            '/airport',
          ])
            GoRoute(path: p, builder: (_, __) => const Scaffold()),
        ],
      );
      await t.pumpWidget(harness(router: r));
      await t.pump(const Duration(milliseconds: 100));

      // Tap on the critical passport row by its title.
      await t.ensureVisible(find.text('Passport expires in 11 days'));
      await t.tap(find.text('Passport expires in 11 days'));
      await t.pumpAndSettle(const Duration(milliseconds: 600));

      expect(find.text('PASSPORT ROUTE'), findsOneWidget);
    });
  });
}
