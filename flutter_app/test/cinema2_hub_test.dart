import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:globeid/cinematic/cinema2/cinema2_hub_screen.dart';

void main() {
  Widget harness(Widget child) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => child),
        for (final r in const <String>[
          '/ceremony/ledger-seal',
          '/ceremony/milestone-bloom',
          '/ceremony/tier-promotion',
          '/ceremony/favorite-lockin',
          '/ceremony/concierge-handoff',
        ])
          GoRoute(
            path: r,
            builder: (_, __) =>
                Scaffold(body: Center(child: Text('stub $r'))),
          ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  // Render at a tall logical size so every sliver is laid out at once.
  void useTallViewport(WidgetTester t) {
    t.view.physicalSize = const Size(800, 4800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  group('Cinema2HubScreen', () {
    testWidgets('mounts the CINEMA II · 15F eyebrow', (t) async {
      useTallViewport(t);
      await t.pumpWidget(harness(const Cinema2HubScreen()));
      await t.pump(const Duration(milliseconds: 16));
      expect(find.text('CINEMA II · 15F'), findsWidgets);
      expect(find.text('CEREMONIES'), findsOneWidget);
    });

    testWidgets('lists all 5 ceremony phase codes', (t) async {
      useTallViewport(t);
      await t.pumpWidget(harness(const Cinema2HubScreen()));
      await t.pump(const Duration(milliseconds: 16));
      for (final code in const <String>[
        'PHASE · 15A',
        'PHASE · 15B',
        'PHASE · 15C',
        'PHASE · 15D',
        'PHASE · 15E',
      ]) {
        expect(find.text(code), findsOneWidget, reason: 'missing $code');
      }
    });

    testWidgets('surfaces invariants charter + operator guidance',
        (t) async {
      useTallViewport(t);
      await t.pumpWidget(harness(const Cinema2HubScreen()));
      await t.pump(const Duration(milliseconds: 16));
      expect(find.text('CHARTER · INVARIANTS'), findsOneWidget);
      expect(find.text('OPERATOR · GUIDANCE'), findsOneWidget);
      for (final label in const <String>[
        'TIMING BUDGET',
        'HAPTIC VOCABULARY',
        'PHASE STATE MACHINE',
        'SINGLE PAINT PASS',
        'REPLAY DETERMINISM',
      ]) {
        expect(find.text(label), findsOneWidget, reason: 'missing $label');
      }
    });

    testWidgets('ceremony titles render', (t) async {
      useTallViewport(t);
      await t.pumpWidget(harness(const Cinema2HubScreen()));
      await t.pump(const Duration(milliseconds: 16));
      for (final title in const <String>[
        'Wallet · ledger seal',
        'Trip · milestone bloom',
        'Identity · tier promotion',
        'Discover · favorite lock-in',
        'Services · concierge handoff',
      ]) {
        expect(find.text(title), findsOneWidget, reason: 'missing $title');
      }
    });
  });
}
