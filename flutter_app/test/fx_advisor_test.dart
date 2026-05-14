import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/copilot/fx_advisor.dart';
import 'package:globeid/cinematic/copilot/fx_convert_now_rail.dart';
import 'package:globeid/data/models/wallet_models.dart';

WalletBalance _bal(String code, String sym, double amount, double rate,
        String flag) =>
    WalletBalance(
      currency: code,
      symbol: sym,
      amount: amount,
      flag: flag,
      rate: rate,
    );

void main() {
  group('FxAdvisor — recommendation engine', () {
    test('empty balances → empty recommendations', () {
      final recs = const FxAdvisor().recommend(
        balances: const [],
        defaultCurrency: 'USD',
      );
      expect(recs, isEmpty);
    });

    test('skips the default currency as a destination', () {
      final balances = [
        _bal('USD', '\$', 5000, 1.0, '🇺🇸'),
        _bal('EUR', '€', 1200, 0.92, '🇪🇺'),
        _bal('JPY', '¥', 80000, 152.4, '🇯🇵'),
      ];
      final recs = const FxAdvisor().recommend(
        balances: balances,
        defaultCurrency: 'USD',
      );
      // No recommendation should "convert USD → USD".
      for (final r in recs) {
        expect(r.fromCurrency, 'USD');
        expect(r.toCurrency, isNot('USD'));
      }
    });

    test('result is deterministic for the same input', () {
      final balances = [
        _bal('USD', '\$', 5000, 1.0, '🇺🇸'),
        _bal('EUR', '€', 1200, 0.92, '🇪🇺'),
        _bal('JPY', '¥', 80000, 152.4, '🇯🇵'),
        _bal('GBP', '£', 800, 0.78, '🇬🇧'),
      ];
      final advisor = const FxAdvisor();
      final a = advisor.recommend(
        balances: balances,
        defaultCurrency: 'USD',
      );
      final b = advisor.recommend(
        balances: balances,
        defaultCurrency: 'USD',
      );
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].toCurrency, b[i].toCurrency);
        expect(a[i].deltaPercent, b[i].deltaPercent);
        expect(a[i].estimatedReceive, b[i].estimatedReceive);
      }
    });

    test('respects maxResults cap', () {
      final balances = [
        _bal('USD', '\$', 5000, 1.0, '🇺🇸'),
        for (var i = 0; i < 12; i++)
          _bal('X${i.toString().padLeft(2, '0')}', '+', 1000,
              1.0 + i * 0.05, '🌐'),
      ];
      final advisor = const FxAdvisor(maxResults: 3);
      final recs = advisor.recommend(
        balances: balances,
        defaultCurrency: 'USD',
      );
      expect(recs.length, lessThanOrEqualTo(3));
    });

    test('strength tiers map to the configured bps thresholds', () {
      final balances = [
        _bal('USD', '\$', 5000, 1.0, '🇺🇸'),
        _bal('EUR', '€', 1200, 0.92, '🇪🇺'),
        _bal('JPY', '¥', 80000, 152.4, '🇯🇵'),
        _bal('GBP', '£', 800, 0.78, '🇬🇧'),
      ];
      final recs = const FxAdvisor().recommend(
        balances: balances,
        defaultCurrency: 'USD',
      );
      for (final r in recs) {
        final abs = r.deltaPercent.abs() * 100; // back to bps
        if (abs >= 110) {
          expect(r.strength, FxStrength.high);
        } else if (abs >= 50) {
          expect(r.strength, FxStrength.notable);
        } else {
          expect(r.strength, FxStrength.passive);
        }
      }
    });
  });

  group('FxConvertNowRail — surface', () {
    testWidgets('empty list collapses to a SizedBox.shrink', (t) async {
      await t.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: FxConvertNowRail(recommendations: []),
        ),
      ));
      expect(find.text('COPILOT · FX TODAY'), findsNothing);
    });

    testWidgets('renders eyebrow + moves count when non-empty',
        (t) async {
      final r = const FxRecommendation(
        fromCurrency: 'USD',
        toCurrency: 'EUR',
        fromFlag: '🇺🇸',
        toFlag: '🇪🇺',
        suggestedAmount: 500,
        estimatedReceive: 460,
        rationale: 'RATE +0.74% TODAY',
        deltaPercent: 0.74,
        estimatedSavings: 3.4,
        strength: FxStrength.notable,
      );
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FxConvertNowRail(recommendations: [r, r]),
        ),
      ));
      expect(find.text('COPILOT · FX TODAY'), findsOneWidget);
      expect(find.text('2 MOVES'), findsOneWidget);
      // The pair line renders inside the card.
      expect(find.text('USD'), findsWidgets);
      expect(find.text('EUR'), findsWidgets);
    });
  });
}
