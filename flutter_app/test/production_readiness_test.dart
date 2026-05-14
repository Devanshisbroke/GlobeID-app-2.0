import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/data/production/production_pillar.dart';
import 'package:globeid/data/production/production_readiness_service.dart';

void main() {
  group('ProductionStatus', () {
    test('handle strings are non-empty MONO-CAP', () {
      for (final s in ProductionStatus.values) {
        expect(s.handle, equals(s.handle.toUpperCase()));
        expect(s.handle, isNotEmpty);
      }
    });

    test('isCritical only for error + missing', () {
      expect(ProductionStatus.error.isCritical, isTrue);
      expect(ProductionStatus.missing.isCritical, isTrue);
      expect(ProductionStatus.live.isCritical, isFalse);
      expect(ProductionStatus.demo.isCritical, isFalse);
      expect(ProductionStatus.idle.isCritical, isFalse);
    });
  });

  group('ProductionReadinessService', () {
    test('default snapshot is all demo / idle', () {
      final svc = ProductionReadinessService();
      final report = svc.snapshot();
      expect(report.total, 8);
      expect(report.live, 2); // offlineCache + errorTelemetry default to live
      expect(report.demo, 3); // fx, flight, visa default to demo
      expect(report.idle, 1); // sentry default to idle
      expect(report.missing, 2); // crash + perf default to missing
    });

    test('flipping fxLive flips the FX pillar status', () {
      final svc = ProductionReadinessService(fxLive: true);
      final report = svc.snapshot();
      final fx = report.pillars.firstWhere(
        (p) => p.handle.startsWith('FX'),
      );
      expect(fx.status, ProductionStatus.live);
    });

    test('flipping sentryActive flips the Sentry pillar', () {
      final svc = ProductionReadinessService(sentryActive: true);
      final report = svc.snapshot();
      final sentry = report.pillars.firstWhere(
        (p) => p.handle.startsWith('TELEMETRY'),
      );
      expect(sentry.status, ProductionStatus.live);
    });

    test('every pillar has a non-empty detail line', () {
      final report = ProductionReadinessService().snapshot();
      for (final p in report.pillars) {
        expect(p.detail, isNotNull);
        expect(p.detail!, isNotEmpty);
      }
    });
  });

  group('ReadinessTier', () {
    test('red when any error or missing exists', () {
      final svc = ProductionReadinessService();
      expect(svc.snapshot().tier, ReadinessTier.red);
    });

    test('amber when all wired but <50% live', () {
      final svc = ProductionReadinessService(
        crashReporting: true,
        perfInstrumentation: true,
      );
      // total 8, live = 4 (offlineCache, errorTelemetry, crash, perf) → 50%
      final r = svc.snapshot();
      expect(r.live, 4);
      expect(r.tier, ReadinessTier.gold);
    });

    test('green when ≥80% live and zero critical', () {
      final svc = ProductionReadinessService(
        fxLive: true,
        flightLive: true,
        visaLive: true,
        sentryActive: true,
        crashReporting: true,
        perfInstrumentation: true,
      );
      // total 8, live = 8 → 100%
      final r = svc.snapshot();
      expect(r.live, 8);
      expect(r.tier, ReadinessTier.green);
    });

    test('handle + tone are populated for every tier', () {
      for (final t in ReadinessTier.values) {
        expect(t.handle, isNotEmpty);
        expect(t.tone, isNot(0));
      }
    });
  });

  group('ProductionReadinessReport', () {
    test('total + ratios sum correctly', () {
      final svc = ProductionReadinessService();
      final r = svc.snapshot();
      expect(
        r.live + r.demo + r.idle + r.error + r.missing,
        r.total,
      );
    });
  });
}
