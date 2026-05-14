import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:globeid/features/branding/brand_surface_gallery_screen.dart';

void main() {
  group('BrandSurfaceGalleryScreen', () {
    Widget framed() {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const BrandSurfaceGalleryScreen(),
          ),
          GoRoute(
            path: '/wallet',
            builder: (_, __) => const Scaffold(body: Text('WALLET')),
          ),
          GoRoute(
            path: '/lab/seal-coldmount',
            builder: (_, __) => const Scaffold(body: Text('SEAL')),
          ),
          GoRoute(
            path: '/lab/identity-signet',
            builder: (_, __) => const Scaffold(body: Text('SIGNET')),
          ),
          GoRoute(
            path: '/lab/camera-chrome',
            builder: (_, __) => const Scaffold(body: Text('CAMERA')),
          ),
          GoRoute(
            path: '/lab/receipts',
            builder: (_, __) => const Scaffold(body: Text('RECEIPTS')),
          ),
        ],
      );
      return MaterialApp.router(routerConfig: router);
    }

    testWidgets('renders the hero', (t) async {
      await t.pumpWidget(framed());
      await t.pumpAndSettle();
      expect(find.text('Manufactured'), findsOneWidget);
      expect(find.text('credential'), findsOneWidget);
      expect(find.text('ATELIER · GLOBE · ID'), findsOneWidget);
    });

    testWidgets('renders all 5 surface tiles', (t) async {
      await t.binding.setSurfaceSize(const Size(420, 4000));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(framed());
      await t.pumpAndSettle();
      expect(find.text('GLOBE · ID watermark'), findsOneWidget);
      expect(find.text('GlobeID seal'), findsOneWidget);
      expect(find.text('Signet variants'), findsOneWidget);
      expect(find.text('5 scan modes'), findsOneWidget);
      expect(find.text('Receipts'), findsOneWidget);
    });

    testWidgets('renders the chronicle ladder', (t) async {
      await t.binding.setSurfaceSize(const Size(420, 4000));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(framed());
      await t.pumpAndSettle();
      expect(find.text('PHASE · 12 · CHRONICLE'), findsOneWidget);
      // 12a / 12b / 12c / 12d / 12e / 12f phase labels.
      expect(find.textContaining('12A'), findsWidgets);
      expect(find.textContaining('12B'), findsWidgets);
      expect(find.textContaining('12C'), findsWidgets);
      expect(find.textContaining('12D'), findsWidgets);
      expect(find.textContaining('12E'), findsWidgets);
      expect(find.textContaining('12F'), findsWidgets);
    });

    testWidgets('renders the brand capstone signature', (t) async {
      await t.binding.setSurfaceSize(const Size(420, 4000));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(framed());
      await t.pumpAndSettle();
      expect(
        find.text('BRAND · MANUFACTURED · BY · GLOBE · ID'),
        findsOneWidget,
      );
    });
  });
}
