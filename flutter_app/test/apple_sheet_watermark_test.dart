import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/sheets/apple_sheet.dart';

void main() {
  group('defaultCaseNumber', () {
    test('is deterministic for the same input', () {
      final a = defaultCaseNumber('Confirm payment', 'WALLET · PAY');
      final b = defaultCaseNumber('Confirm payment', 'WALLET · PAY');
      expect(a, equals(b));
      expect(a, startsWith('N° '));
      expect(a.length, equals(11)); // 'N° ' + 8 hex chars
    });

    test('different inputs yield different case numbers', () {
      final a = defaultCaseNumber('Confirm payment', 'WALLET · PAY');
      final b = defaultCaseNumber('Trip budget', 'TRIP · BUDGET');
      expect(a, isNot(equals(b)));
    });

    test('handles null title + eyebrow gracefully', () {
      final a = defaultCaseNumber(null, null);
      expect(a, startsWith('N° '));
      expect(a.length, equals(11));
    });
  });

  group('AppleSheetWatermark', () {
    testWidgets('renders GLOBE · ID + case number', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppleSheetWatermark(
                tone: Color(0xFFD4AF37),
                caseNumber: 'N° DEADBEEF',
              ),
            ),
          ),
        ),
      );
      expect(find.text('GLOBE · ID'), findsOneWidget);
      expect(find.text('N° DEADBEEF'), findsOneWidget);
    });
  });
}
