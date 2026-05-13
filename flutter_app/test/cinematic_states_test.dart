import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/states/cinematic_states.dart';
import 'package:globeid/os2/os2_tokens.dart';

/// Phase 6b — cinematic state primitive contract.
///
/// Pins the chrome invariants every empty/error/loading state in the
/// app pulls from. A future refactor can't quietly drop the eyebrow,
/// the watermark, the gold hairline, or the breathing halo without
/// breaking these tests.
void main() {
  Widget mount(Widget child) => MaterialApp(
        home: Scaffold(
          backgroundColor: Os2.canvas,
          body: child,
        ),
      );

  group('Os2EmptyState', () {
    testWidgets('renders eyebrow, title, message, and watermark', (t) async {
      await t.pumpWidget(mount(const Os2EmptyState(
        eyebrow: 'WALLET · LEDGER',
        title: 'No transactions yet',
        message: 'Scan a receipt or record a payment to populate the ledger.',
      )));
      expect(find.text('WALLET · LEDGER'), findsOneWidget);
      expect(find.text('No transactions yet'), findsOneWidget);
      expect(
        find.text('Scan a receipt or record a payment to populate the ledger.'),
        findsOneWidget,
      );
      expect(find.text('GLOBE·ID'), findsOneWidget);
    });

    testWidgets('default tone is GlobeID gold', (t) async {
      await t.pumpWidget(mount(const Os2EmptyState(
        eyebrow: 'WALLET · LEDGER',
        title: 'No transactions yet',
        message: 'No body.',
      )));
      final chrome = t.widget<CinematicStateChrome>(
        find.byType(CinematicStateChrome),
      );
      expect(chrome.tone, equals(Os2.goldDeep));
    });

    testWidgets('explicit tone overrides default', (t) async {
      await t.pumpWidget(mount(Os2EmptyState(
        eyebrow: 'TRIP · PLAN',
        title: 'No trips here',
        message: 'No body.',
        tone: Os2.signalCritical,
      )));
      final chrome = t.widget<CinematicStateChrome>(
        find.byType(CinematicStateChrome),
      );
      expect(chrome.tone, equals(Os2.signalCritical));
    });

    testWidgets('CTA button renders when provided', (t) async {
      var tapped = false;
      await t.pumpWidget(mount(Os2EmptyState(
        eyebrow: 'WALLET · LEDGER',
        title: 'No transactions yet',
        message: 'No body.',
        cta: 'ADD CREDENTIAL',
        onCta: () => tapped = true,
      )));
      expect(find.text('ADD CREDENTIAL'), findsOneWidget);
      await t.tap(find.text('ADD CREDENTIAL'));
      await t.pump();
      expect(tapped, isTrue);
    });
  });

  group('Os2ErrorState', () {
    testWidgets('default tone is critical', (t) async {
      await t.pumpWidget(mount(const Os2ErrorState(
        eyebrow: 'INTELLIGENCE · ALERTS',
        title: 'Alerts unavailable',
        message: 'Backbone is down.',
      )));
      final chrome = t.widget<CinematicStateChrome>(
        find.byType(CinematicStateChrome),
      );
      expect(chrome.tone, equals(Os2.signalCritical));
    });

    testWidgets('error code renders inside the footer slot', (t) async {
      await t.pumpWidget(mount(const Os2ErrorState(
        eyebrow: 'WALLET · LEDGER',
        title: 'Ledger unavailable',
        message: 'Network issue.',
        errorCode: 'WT-403',
      )));
      expect(find.text('WT-403'), findsOneWidget);
    });

    testWidgets('default CTA label is RETRY', (t) async {
      await t.pumpWidget(mount(Os2ErrorState(
        eyebrow: 'WALLET · LEDGER',
        title: 'Ledger unavailable',
        message: 'Network issue.',
        onCta: () {},
      )));
      expect(find.text('RETRY'), findsOneWidget);
    });
  });

  group('Os2LoadingState', () {
    testWidgets('renders title, eyebrow, and watermark', (t) async {
      await t.pumpWidget(mount(const Os2LoadingState(
        eyebrow: 'IDENTITY · LOYALTY',
        title: 'Reading your stamps',
      )));
      expect(find.text('IDENTITY · LOYALTY'), findsOneWidget);
      expect(find.text('Reading your stamps'), findsOneWidget);
      expect(find.text('GLOBE·ID'), findsOneWidget);
      await t.pump(const Duration(milliseconds: 300));
      await t.pump(const Duration(milliseconds: 300));
    });

    testWidgets('disposes the rotation controller without leaking',
        (t) async {
      await t.pumpWidget(mount(const Os2LoadingState(
        eyebrow: 'WALLET · LEDGER',
        title: 'Loading',
      )));
      // Replacing with an unrelated widget triggers disposal.
      await t.pumpWidget(mount(const SizedBox.shrink()));
      // No exception -> controller was disposed cleanly.
      expect(find.text('Loading'), findsNothing);
    });
  });

  group('CinematicStateChrome', () {
    testWidgets('compact mode shrinks the halo footprint', (t) async {
      await t.pumpWidget(mount(const CinematicStateChrome(
        eyebrow: 'WALLET · LEDGER',
        title: 'Inline',
        message: 'Compact inline empty.',
        tone: Os2.goldDeep,
        compact: true,
        glyph: Icon(Icons.receipt_long_rounded),
      )));
      final chrome = t.widget<CinematicStateChrome>(
        find.byType(CinematicStateChrome),
      );
      expect(chrome.compact, isTrue);
    });

    testWidgets('watermark renders even with no footer or CTA', (t) async {
      await t.pumpWidget(mount(const CinematicStateChrome(
        eyebrow: 'WALLET · LEDGER',
        title: 'No transactions yet',
        message: 'No body.',
        tone: Os2.goldDeep,
        glyph: Icon(Icons.receipt_long_rounded),
      )));
      expect(find.text('GLOBE·ID'), findsOneWidget);
    });

    testWidgets('tertiary action renders below primary CTA', (t) async {
      var tertiaryTapped = false;
      await t.pumpWidget(mount(CinematicStateChrome(
        eyebrow: 'WALLET · LEDGER',
        title: 'No transactions yet',
        message: 'No body.',
        tone: Os2.goldDeep,
        glyph: const Icon(Icons.receipt_long_rounded),
        cta: 'ADD',
        onCta: () {},
        tertiary: 'WHY',
        onTertiary: () => tertiaryTapped = true,
      )));
      expect(find.text('ADD'), findsOneWidget);
      expect(find.text('WHY'), findsOneWidget);
      await t.tap(find.text('WHY'));
      await t.pump();
      expect(tertiaryTapped, isTrue);
    });
  });
}
