import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/branding/globe_receipt.dart';

void main() {
  group('ReceiptSpec', () {
    test('every kind resolves to a spec', () {
      for (final kind in ReceiptKind.values) {
        final spec = ReceiptSpec.of(kind);
        expect(spec.eyebrow.isNotEmpty, isTrue);
        expect(spec.footer.isNotEmpty, isTrue);
      }
    });

    test('eyebrows + footers are mono-cap with separator dots', () {
      for (final kind in ReceiptKind.values) {
        final spec = ReceiptSpec.of(kind);
        expect(spec.eyebrow, equals(spec.eyebrow.toUpperCase()));
        expect(spec.footer, equals(spec.footer.toUpperCase()));
        expect(spec.footer.contains('GLOBE · ID'), isTrue);
      }
    });

    test('immigration + visa share blue/green system tones', () {
      expect(ReceiptSpec.immigration.tone, const Color(0xFF6B8FB8));
      expect(ReceiptSpec.visa.tone, const Color(0xFF3FB68B));
    });

    test('payment uses canonical foil gold', () {
      expect(ReceiptSpec.payment.tone, const Color(0xFFD4AF37));
    });

    test('every kind tone is distinct', () {
      final tones = ReceiptKind.values.map((k) => ReceiptSpec.of(k).tone).toSet();
      expect(tones.length, ReceiptKind.values.length);
    });
  });

  group('ReceiptRow', () {
    test('value-only construction defaults to non-bold + no tone override', () {
      const row = ReceiptRow(label: 'A', value: 'B');
      expect(row.bold, isFalse);
      expect(row.toneOverride, isNull);
    });

    test('bold + toneOverride can be set', () {
      const row = ReceiptRow(
        label: 'TOTAL',
        value: '€10',
        bold: true,
        toneOverride: Color(0xFFE9C75D),
      );
      expect(row.bold, isTrue);
      expect(row.toneOverride, const Color(0xFFE9C75D));
    });
  });

  group('GlobeReceipt widget', () {
    Widget framed(GlobeReceipt receipt) => MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF050505),
            body: Center(child: receipt),
          ),
        );

    testWidgets('mounts payment receipt with title + amount + footer',
        (t) async {
      await t.pumpWidget(framed(const GlobeReceipt(
        kind: ReceiptKind.payment,
        title: 'Confirmed',
        subtitle: 'Café · Berlin',
        amount: '€ 42.18',
        amountSub: 'EUR · LIVE · RATE',
        rows: [
          ReceiptRow(label: 'METHOD', value: 'Visa · 4282'),
        ],
        caseNumber: 'N° PAY-A8C',
      )));
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('€ 42.18'), findsOneWidget);
      expect(find.text('GLOBE · ID'), findsOneWidget);
      expect(find.text('WALLET · PAYMENT'), findsOneWidget);
      expect(find.text('N° PAY-A8C'), findsOneWidget);
    });

    testWidgets('switches eyebrow + footer per kind', (t) async {
      await t.pumpWidget(framed(const GlobeReceipt(
        kind: ReceiptKind.immigration,
        title: 'Cleared',
        subtitle: 'BER · GATE 14',
        amount: '00:03:48',
        amountSub: 'QUEUE',
        rows: [],
        caseNumber: 'N° IMM',
      )));
      expect(find.text('IMMIGRATION · CLEARED'), findsOneWidget);
      expect(find.text('BORDER · CLEARED · GLOBE · ID'), findsOneWidget);
    });

    testWidgets('renders an empty rows list without crashing', (t) async {
      await t.pumpWidget(framed(const GlobeReceipt(
        kind: ReceiptKind.visa,
        title: 'Visa granted',
        subtitle: 'Japan',
        amount: '90 d',
        amountSub: 'MAX',
        rows: [],
        caseNumber: 'N° VISA',
      )));
      expect(find.text('Visa granted'), findsOneWidget);
    });

    testWidgets('renders a custom signature label', (t) async {
      await t.pumpWidget(framed(const GlobeReceipt(
        kind: ReceiptKind.credential,
        title: 'Issued',
        subtitle: 'IATA',
        amount: '7 y',
        amountSub: 'TENURE',
        rows: [],
        caseNumber: 'N° CRED',
        signatureLabel: 'SIGNED · IATA',
      )));
      expect(find.text('SIGNED · IATA'), findsOneWidget);
    });

    testWidgets('uses fallback timestamp when none given', (t) async {
      await t.pumpWidget(framed(const GlobeReceipt(
        kind: ReceiptKind.trip,
        title: 'Trip archived',
        subtitle: 'BER → LIS',
        amount: '€ 1 248',
        amountSub: 'SETTLED',
        rows: [],
        caseNumber: 'N° TRIP',
      )));
      expect(find.text('LIVE · MOMENT'), findsOneWidget);
    });
  });
}
