import 'package:flutter_test/flutter_test.dart';
import 'package:globeid/domain/service_engine.dart';

void main() {
  group('service engine', () {
    test('ranks visa and insurance for upcoming foreign travel', () {
      final rankings = rankServices(const ServiceInput(
        activeCountryIso2: 'US',
        nextDestinationIso2: 'JP',
        daysToNextTrip: 14,
        overBudgetCategoryCount: 0,
      ));

      expect(rankings.first.tab, ServiceTab.visa);
      expect(
        rankings.take(4).map((r) => r.tab),
        containsAll(<ServiceTab>[
          ServiceTab.visa,
          ServiceTab.insurance,
          ServiceTab.esim,
          ServiceTab.exchange,
        ]),
      );
    });

    test('boosts ride urgency for imminent trips', () {
      final rankings = rankServices(const ServiceInput(
        activeCountryIso2: 'IN',
        nextDestinationIso2: 'AE',
        daysToNextTrip: 1,
        overBudgetCategoryCount: 0,
      ));

      expect(rankings.first.tab, ServiceTab.rides);
      expect(rankings.first.reason, contains('book the ride'));
    });

    test('surfaces local services when already abroad without a near trip', () {
      final rankings = rankServices(const ServiceInput(
        activeCountryIso2: 'SG',
        nextDestinationIso2: null,
        daysToNextTrip: 9999,
        overBudgetCategoryCount: 0,
      ));

      expect(rankings.first.tab, ServiceTab.local);
      expect(rankings[1].tab, ServiceTab.food);
    });

    test('nudges exchange when budget categories are over', () {
      final rankings = rankServices(const ServiceInput(
        activeCountryIso2: 'US',
        nextDestinationIso2: 'US',
        daysToNextTrip: 40,
        overBudgetCategoryCount: 2,
      ));

      final exchange = rankings.firstWhere((r) => r.tab == ServiceTab.exchange);
      final hotels = rankings.firstWhere((r) => r.tab == ServiceTab.hotels);
      expect(exchange.score, greaterThan(hotels.score));
    });

    test('maps airport country and destination currency', () {
      expect(airportCountryIso2('hnd'), 'JP');
      expect(currencyForCountryIso2('jp'), 'JPY');
      expect(airportCountryIso2('unknown'), isNull);
    });
  });
}
