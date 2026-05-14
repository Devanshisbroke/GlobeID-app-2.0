import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/features/visa/visa_renewal_ceremony.dart';

void main() {
  Widget _harness(Widget child) => MaterialApp(
        home: child,
      );

  group('VisaRenewalCeremony', () {
    testWidgets('renders Stage 1 — Detect with hero countdown', (t) async {
      await t.pumpWidget(_harness(
        const VisaRenewalCeremony(
          country: 'Schengen Area',
          flag: '🇪🇺',
          daysToExpiry: 11,
          visaType: 'Schengen short-stay',
        ),
      ));

      // Stage chrome
      expect(find.text('COPILOT · RENEW'), findsOneWidget);
      expect(find.text('STAGE 1 OF 4'), findsOneWidget);
      // Hero countdown
      expect(find.text('11'), findsOneWidget);
      expect(find.text('DAYS UNTIL EXPIRY'), findsOneWidget);
      // Visa info row
      expect(find.text('VISA · SCHENGEN AREA'), findsOneWidget);
      expect(find.text('Schengen short-stay'), findsOneWidget);
      // Footer CTA
      expect(find.text('BEGIN RENEWAL'), findsOneWidget);
    });

    testWidgets('advances Stage 1 → Stage 2 on CTA tap', (t) async {
      await t.pumpWidget(_harness(
        const VisaRenewalCeremony(daysToExpiry: 11),
      ));
      // Tap BEGIN RENEWAL
      await t.tap(find.text('BEGIN RENEWAL'));
      await t.pump(const Duration(milliseconds: 400));
      // Stage 2 chrome should be visible.
      expect(find.text('COPILOT · VERIFY'), findsOneWidget);
      expect(find.text('STAGE 2 OF 4'), findsOneWidget);
      expect(find.text('CONFIRM IDENTITY'), findsOneWidget);
      // Verify tiles render
      expect(find.text('Passport biometric'), findsOneWidget);
      expect(find.text('Live selfie capture'), findsOneWidget);
      expect(find.text('Residency proof'), findsOneWidget);
    });

    testWidgets('Stage 2 → Stage 3 reveals submission summary', (t) async {
      await t.pumpWidget(_harness(
        const VisaRenewalCeremony(daysToExpiry: 11),
      ));
      await t.tap(find.text('BEGIN RENEWAL'));
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.text('CONFIRM IDENTITY'));
      await t.pump(const Duration(milliseconds: 400));

      expect(find.text('COPILOT · SUBMIT'), findsOneWidget);
      expect(find.text('STAGE 3 OF 4'), findsOneWidget);
      expect(find.text('SIGN AND SUBMIT'), findsOneWidget);
      // Summary row labels (mono-cap)
      expect(find.text('COUNTRY'), findsOneWidget);
      expect(find.text('VISA TYPE'), findsOneWidget);
      expect(find.text('BEARER NAME'), findsOneWidget);
      expect(find.text('PASSPORT'), findsOneWidget);
    });

    testWidgets('Stage 3 → Stage 4 reveals reference number + DONE', (t) async {
      await t.pumpWidget(_harness(
        const VisaRenewalCeremony(daysToExpiry: 11),
      ));
      await t.tap(find.text('BEGIN RENEWAL'));
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.text('CONFIRM IDENTITY'));
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.text('SIGN AND SUBMIT'));
      // Wait for signature haptic delay + transition.
      await t.pump(const Duration(milliseconds: 600));

      expect(find.text('COPILOT · ISSUED'), findsOneWidget);
      expect(find.text('STAGE 4 OF 4'), findsOneWidget);
      expect(find.text('DONE'), findsOneWidget);
      expect(find.text('GLOBE·ID · REFERENCE'), findsOneWidget);
      expect(
        find.textContaining('Submitted to the Schengen Area consulate'),
        findsOneWidget,
      );
    });

    testWidgets('every stage exposes a close button', (t) async {
      await t.pumpWidget(_harness(
        const VisaRenewalCeremony(daysToExpiry: 11),
      ));
      expect(find.bySemanticsLabel('Close visa renewal'), findsOneWidget);
    });
  });
}
