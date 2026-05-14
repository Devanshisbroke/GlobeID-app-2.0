import 'production_pillar.dart';

/// Aggregates production-reliability pillars into a single report
/// the readiness hub can render at a glance.
///
/// Each pillar is independently configurable — pass `live: true`
/// to flip the FX adapter status from DEMO → LIVE without changing
/// the rest of the report. This is a service, not a probe — it
/// reflects the *configured* state, not a runtime health-check
/// ping. Per-pillar runtime probes are layered above this service
/// by the surfaces that own them.
class ProductionReadinessService {
  ProductionReadinessService({
    DateTime Function()? now,
    this.fxLive = false,
    this.flightLive = false,
    this.visaLive = false,
    this.sentryActive = false,
    this.offlineCache = true,
    this.errorTelemetry = true,
    this.crashReporting = false,
    this.perfInstrumentation = false,
  }) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  bool fxLive;
  bool flightLive;
  bool visaLive;
  bool sentryActive;
  bool offlineCache;
  bool errorTelemetry;
  bool crashReporting;
  bool perfInstrumentation;

  ProductionReadinessReport snapshot() {
    final at = _now();
    return ProductionReadinessReport(
      generatedAt: at,
      pillars: [
        ProductionPillar(
          handle: 'FX · LIVE · ADAPTER',
          sub: 'Frankfurter (ECB) live exchange rates',
          status: fxLive ? ProductionStatus.live : ProductionStatus.demo,
          lastChecked: at,
          detail: 'frankfurter.app · 30s refresh · fallback to ECB demo',
        ),
        ProductionPillar(
          handle: 'FLIGHT · LIVE · ADAPTER',
          sub: 'AeroAPI / FlightAware live flight status',
          status: flightLive ? ProductionStatus.live : ProductionStatus.demo,
          lastChecked: at,
          detail: 'aeroapi.flightaware.com · 60s refresh · demo phases',
        ),
        ProductionPillar(
          handle: 'VISA · LIVE · ADAPTER',
          sub: 'PassportIndex matrix · 199 corridors',
          status: visaLive ? ProductionStatus.live : ProductionStatus.demo,
          lastChecked: at,
          detail: 'github.com/ilyankou · 7d cache · demo 2024 snapshot',
        ),
        ProductionPillar(
          handle: 'TELEMETRY · SENTRY',
          sub: 'Sentry-compatible HTTP envelope',
          status: sentryActive
              ? ProductionStatus.live
              : ProductionStatus.idle,
          lastChecked: at,
          detail: 'SENTRY_DSN · v7 store endpoint · 32-event retry queue',
        ),
        ProductionPillar(
          handle: 'OFFLINE · FIRST · CACHE',
          sub: 'TimestampedCache + STALE chip ladder',
          status: offlineCache
              ? ProductionStatus.live
              : ProductionStatus.missing,
          lastChecked: at,
          detail: 'in-memory · per-key watch · STALE @ 5m / 1h / 24h',
        ),
        ProductionPillar(
          handle: 'ERROR · TELEMETRY',
          sub: 'Local debug log + buffer sink',
          status: errorTelemetry
              ? ProductionStatus.live
              : ProductionStatus.missing,
          lastChecked: at,
          detail: 'lib/core/error_telemetry.dart · BufferTelemetrySink',
        ),
        ProductionPillar(
          handle: 'CRASH · REPORTING',
          sub: 'Native crash capture (iOS + Android)',
          status: crashReporting
              ? ProductionStatus.live
              : ProductionStatus.missing,
          lastChecked: at,
          detail: 'pending — Sentry native SDK / Firebase Crashlytics',
        ),
        ProductionPillar(
          handle: 'PERF · INSTRUMENTATION',
          sub: 'Frame timing + transaction spans',
          status: perfInstrumentation
              ? ProductionStatus.live
              : ProductionStatus.missing,
          lastChecked: at,
          detail: 'pending — Sentry Performance / Firebase Perf',
        ),
      ],
    );
  }
}
