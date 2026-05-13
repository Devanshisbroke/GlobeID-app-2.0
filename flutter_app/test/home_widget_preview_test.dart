import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/ambient/home_widget_preview.dart';

void main() {
  group('TripCountdownWidget', () {
    testWidgets('renders days + destination + date label', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WidgetTileFrame(
              child: TripCountdownWidget(
                destination: 'Tokyo',
                countryFlag: '🇯🇵',
                daysAway: 12,
                dateLabel: 'Nov 24',
              ),
            ),
          ),
        ),
      );
      expect(find.text('12'), findsOneWidget);
      expect(find.text('DAYS · UNTIL DEPARTURE'), findsOneWidget);
      expect(find.text('Tokyo'), findsOneWidget);
      expect(find.text('NOV 24'), findsOneWidget);
    });

    testWidgets('singular DAY when daysAway == 1', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WidgetTileFrame(
              child: TripCountdownWidget(
                destination: 'Tokyo',
                countryFlag: '🇯🇵',
                daysAway: 1,
                dateLabel: 'Nov 24',
              ),
            ),
          ),
        ),
      );
      expect(find.text('DAY · UNTIL DEPARTURE'), findsOneWidget);
    });
  });

  group('FxHeartbeatWidget', () {
    testWidgets('renders pair, rate, and delta sign', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetTileFrame(
              child: FxHeartbeatWidget(
                pair: 'EUR/USD',
                rate: 1.0934,
                deltaPct: 0.72,
                spark: sparklineSamples(),
              ),
            ),
          ),
        ),
      );
      expect(find.text('EUR/USD'), findsOneWidget);
      expect(find.text('1.0934'), findsOneWidget);
      expect(find.text('+0.72%'), findsOneWidget);
    });

    testWidgets('negative delta still renders the sign', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetTileFrame(
              child: FxHeartbeatWidget(
                pair: 'EUR/USD',
                rate: 1.0934,
                deltaPct: -1.25,
                spark: sparklineSamples(),
              ),
            ),
          ),
        ),
      );
      expect(find.text('-1.25%'), findsOneWidget);
    });
  });

  group('VisaExpiryWidget', () {
    testWidgets('renders critical handle when <= 14d', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WidgetTileFrame(
              size: WidgetSize.medium,
              child: VisaExpiryWidget(
                country: 'United States',
                countryFlag: '🇺🇸',
                expiryLabel: '14 Dec 2025',
                daysToExpiry: 7,
              ),
            ),
          ),
        ),
      );
      expect(find.text('CRITICAL · 7D'), findsOneWidget);
      expect(find.text('7d remaining'), findsOneWidget);
    });

    testWidgets('renders expired handle when daysToExpiry < 0', (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WidgetTileFrame(
              size: WidgetSize.medium,
              child: VisaExpiryWidget(
                country: 'United States',
                countryFlag: '🇺🇸',
                expiryLabel: '14 Dec 2024',
                daysToExpiry: -3,
              ),
            ),
          ),
        ),
      );
      expect(find.text('EXPIRED 3D AGO'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);
    });
  });
}
