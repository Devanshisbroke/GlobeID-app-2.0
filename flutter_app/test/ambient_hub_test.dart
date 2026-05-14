import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:globeid/features/ambient/ambient_hub_screen.dart';

GoRouter _router() {
  return GoRouter(
    initialLocation: '/ambient',
    routes: [
      GoRoute(
        path: '/ambient',
        builder: (_, __) => const AmbientHubScreen(),
      ),
      // Stub destinations so context.push doesn't 404 during tests.
      GoRoute(
        path: '/ambient/live-activity',
        builder: (_, __) => const Scaffold(body: SizedBox()),
      ),
      GoRoute(
        path: '/ambient/widgets',
        builder: (_, __) => const Scaffold(body: SizedBox()),
      ),
      GoRoute(
        path: '/ambient/watch',
        builder: (_, __) => const Scaffold(body: SizedBox()),
      ),
      GoRoute(
        path: '/ambient/quick-settings',
        builder: (_, __) => const Scaffold(body: SizedBox()),
      ),
      GoRoute(
        path: '/ambient/lock-screen',
        builder: (_, __) => const Scaffold(body: SizedBox()),
      ),
    ],
  );
}

void main() {
  testWidgets('AmbientHub renders the manifesto', (t) async {
    await t.pumpWidget(MaterialApp.router(routerConfig: _router()));
    await t.pumpAndSettle();
    expect(find.text('AMBIENT · MANIFESTO'), findsOneWidget);
    expect(find.text('GlobeID lives where you live.'), findsOneWidget);
  });

  testWidgets('AmbientHub renders all 5 surface tiles', (t) async {
    await t.pumpWidget(MaterialApp.router(routerConfig: _router()));
    await t.pumpAndSettle();
    // First three render in the initial viewport.
    expect(find.text('LIVE ACTIVITY'), findsOneWidget);
    expect(find.text('HOME WIDGETS'), findsOneWidget);
    expect(find.text('WATCH'), findsOneWidget);
    // Scroll to surface the bottom two.
    await t.drag(find.byType(ListView), const Offset(0, -400));
    await t.pumpAndSettle();
    expect(find.text('QUICK SETTINGS'), findsOneWidget);
    expect(find.text('LOCK SCREEN'), findsOneWidget);
  });

  testWidgets('AmbientHub renders the brand thread closer', (t) async {
    await t.pumpWidget(MaterialApp.router(routerConfig: _router()));
    await t.pumpAndSettle();
    await t.drag(find.byType(ListView), const Offset(0, -800));
    await t.pumpAndSettle();
    expect(find.text('BRAND · THREAD'), findsOneWidget);
  });
}
