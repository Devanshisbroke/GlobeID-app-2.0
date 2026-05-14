import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/identity/issuance_ceremony.dart';

void main() {
  group('IssuancePhase timing', () {
    test('phases end in strictly ascending order', () {
      var prev = 0.0;
      for (final phase in IssuancePhase.values) {
        expect(phase.end, greaterThan(prev),
            reason: '${phase.name} should end after the previous phase');
        prev = phase.end;
      }
    });

    test('final phase ends at 1.0', () {
      expect(IssuancePhase.values.last.end, 1.0);
    });
  });

  group('IssuanceCeremony — lifecycle', () {
    testWidgets('mounts and fires onComplete after the ceremony', (t) async {
      var completed = false;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IssuanceCeremony(
              title: 'Republic of Iceland · Passport',
              subtitle: 'Bearer · GlobeID',
              issuer: 'Republic of Iceland',
              blockHeight: 12148337,
              duration: const Duration(milliseconds: 600),
              onComplete: () => completed = true,
            ),
          ),
        ),
      );
      // Pump past the full duration.
      await t.pump(const Duration(milliseconds: 80));
      await t.pump(const Duration(milliseconds: 200));
      await t.pump(const Duration(milliseconds: 400));
      await t.pumpAndSettle();
      expect(completed, isTrue);
    });

    testWidgets('renders the GLOBE·ID watermark after the bleed phase',
        (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssuanceCeremony(
              title: 'GlobeID Atelier · Identity Card',
              subtitle: 'Bearer · GlobeID',
              issuer: 'GlobeID Atelier',
              blockHeight: 12148337,
              duration: Duration(milliseconds: 600),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      // Watermark appears in the settled phase.
      expect(find.text('GLOBE·ID · ISSUANCE'), findsOneWidget);
      // Settled card shows the minted chip + block number.
      expect(find.text('CREDENTIAL · MINTED'), findsOneWidget);
      expect(find.textContaining('BLOCK 12,148,337'), findsOneWidget);
      expect(
        find.text('GlobeID Atelier · Identity Card'),
        findsOneWidget,
      );
    });

    testWidgets('settled card surfaces the issuer line', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssuanceCeremony(
              title: 'Republic of Iceland · Passport',
              subtitle: 'Bearer · Devansh Barai',
              issuer: 'Republic of Iceland · MIA',
              blockHeight: 12345678,
              duration: Duration(milliseconds: 400),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      // monoCap upper-cases the issuer copy.
      expect(
        find.text('ISSUED BY · REPUBLIC OF ICELAND · MIA'),
        findsOneWidget,
      );
      expect(find.text('Bearer · Devansh Barai'), findsOneWidget);
    });

    testWidgets('safe to dispose mid-ceremony', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssuanceCeremony(
              title: 'X',
              subtitle: 'Y',
              issuer: 'Z',
              blockHeight: 1,
              duration: Duration(milliseconds: 800),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 200));
      await t.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      // No assertion: success is no throw / no leak.
    });
  });
}
