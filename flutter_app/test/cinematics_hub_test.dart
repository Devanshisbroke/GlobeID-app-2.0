import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:globeid/features/cinematics/cinematics_hub_screen.dart';

void main() {
  group('CinematicsHubScreen', () {
    testWidgets('mounts with cover + five ceremony tiles', (t) async {
      final router = GoRouter(
        initialLocation: '/cinematics',
        routes: [
          GoRoute(
            path: '/cinematics',
            builder: (_, __) => const CinematicsHubScreen(),
          ),
          GoRoute(
            path: '/lab/passport-ceremony',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('passport'))),
          ),
          GoRoute(
            path: '/lab/visa-stamp',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('visa'))),
          ),
          GoRoute(
            path: '/lab/boarding-printed',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('boarding'))),
          ),
          GoRoute(
            path: '/lab/declassified',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('declassified'))),
          ),
          GoRoute(
            path: '/lab/velvet-rope',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('velvet'))),
          ),
        ],
      );
      await t.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await t.pumpAndSettle();

      // Cover stats present (visible above the fold).
      expect(find.text('5'), findsOneWidget);
      expect(find.text('13.1s'), findsOneWidget);

      // Five ceremony eyebrows present (off-stage tiles count too).
      expect(find.text('CEREMONY · ONE', skipOffstage: false), findsOneWidget);
      expect(find.text('CEREMONY · TWO', skipOffstage: false), findsOneWidget);
      expect(
          find.text('CEREMONY · THREE', skipOffstage: false), findsOneWidget);
      expect(
          find.text('CEREMONY · FOUR', skipOffstage: false), findsOneWidget);
      expect(find.text('CEREMONY · FIVE', skipOffstage: false), findsOneWidget);
    });

    testWidgets('cover title renders the brand contract', (t) async {
      final router = GoRouter(
        initialLocation: '/cinematics',
        routes: [
          GoRoute(
            path: '/cinematics',
            builder: (_, __) => const CinematicsHubScreen(),
          ),
        ],
      );
      await t.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await t.pumpAndSettle();
      expect(find.text('Every motion · engineered'), findsOneWidget);
      expect(find.text('GLOBE · ID · CINEMATICS'), findsOneWidget);
    });
  });
}
