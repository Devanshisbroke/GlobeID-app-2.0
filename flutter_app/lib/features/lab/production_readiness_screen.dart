import 'package:flutter/material.dart';

import '../../data/production/production_pillar.dart';
import '../../data/production/production_readiness_service.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';

/// Production Readiness Hub — the capstone of Phase 10.
///
/// Aggregates every production-reliability pillar (FX, Flight,
/// Visa, Telemetry, Offline cache, Error log, Crash, Perf) into a
/// single glance-able dashboard with a green/gold/amber/red tier
/// ladder so the reviewer can see at a glance which surfaces are
/// fully production-wired and which are still demo / idle.
class ProductionReadinessScreen extends StatefulWidget {
  const ProductionReadinessScreen({super.key});
  @override
  State<ProductionReadinessScreen> createState() =>
      _ProductionReadinessScreenState();
}

class _ProductionReadinessScreenState extends State<ProductionReadinessScreen> {
  late final ProductionReadinessService _svc;
  late ProductionReadinessReport _report;

  @override
  void initState() {
    super.initState();
    _svc = ProductionReadinessService();
    _report = _svc.snapshot();
  }

  void _toggleSentry() => setState(() {
        _svc.sentryActive = !_svc.sentryActive;
        _report = _svc.snapshot();
      });
  void _toggleFx() => setState(() {
        _svc.fxLive = !_svc.fxLive;
        _report = _svc.snapshot();
      });
  void _toggleFlight() => setState(() {
        _svc.flightLive = !_svc.flightLive;
        _report = _svc.snapshot();
      });
  void _toggleVisa() => setState(() {
        _svc.visaLive = !_svc.visaLive;
        _report = _svc.snapshot();
      });

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Production readiness',
      subtitle: 'Phase 10 capstone · live + idle + demo audit',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          _TierBanner(report: _report),
          const SizedBox(height: Os2.space4),
          _RatioRow(report: _report),
          const SizedBox(height: Os2.space4),
          _SimulationCard(
            fxLive: _svc.fxLive,
            flightLive: _svc.flightLive,
            visaLive: _svc.visaLive,
            sentryActive: _svc.sentryActive,
            onToggleFx: _toggleFx,
            onToggleFlight: _toggleFlight,
            onToggleVisa: _toggleVisa,
            onToggleSentry: _toggleSentry,
          ),
          const SizedBox(height: Os2.space4),
          for (final pillar in _report.pillars) ...[
            _PillarCard(pillar: pillar),
            const SizedBox(height: Os2.space3),
          ],
          const SizedBox(height: Os2.space2),
          _ContractCard(report: _report),
        ],
      ),
    );
  }
}

class _TierBanner extends StatelessWidget {
  const _TierBanner({required this.report});
  final ProductionReadinessReport report;
  @override
  Widget build(BuildContext context) {
    final tier = report.tier;
    final tone = Color(tier.tone);
    return Container(
      padding: const EdgeInsets.all(Os2.space5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tone.withValues(alpha: 0.18),
            Os2.floor1,
          ],
        ),
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: tone.withValues(alpha: 0.62)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: tone,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: tone, blurRadius: 12, spreadRadius: 1),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Os2Text.monoCap(
                tier.handle,
                color: tone,
                size: Os2.textTiny,
              ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Os2Text.display(
            '${(report.live / (report.total == 0 ? 1 : report.total) * 100).toStringAsFixed(0)}%',
            color: Os2.inkBright,
            size: Os2.textXxl,
          ),
          const SizedBox(height: 6),
          Os2Text.body(
            'Live coverage across ${report.total} production pillars. ${report.demo} demo · ${report.idle} idle · ${report.error + report.missing} attention.',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
        ],
      ),
    );
  }
}

class _RatioRow extends StatelessWidget {
  const _RatioRow({required this.report});
  final ProductionReadinessReport report;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _RatioPip(label: 'LIVE', count: report.live, tone: const Color(0xFF6CE0A8))),
        const SizedBox(width: 8),
        Expanded(child: _RatioPip(label: 'DEMO', count: report.demo, tone: const Color(0xFFD4AF37))),
        const SizedBox(width: 8),
        Expanded(child: _RatioPip(label: 'IDLE', count: report.idle, tone: const Color(0xFF8B96A6))),
        const SizedBox(width: 8),
        Expanded(child: _RatioPip(label: 'TODO', count: report.error + report.missing, tone: const Color(0xFFFFB347))),
      ],
    );
  }
}

class _RatioPip extends StatelessWidget {
  const _RatioPip({required this.label, required this.count, required this.tone});
  final String label;
  final int count;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rChip),
        border: Border.all(color: tone.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Os2Text.credential('$count', color: tone, size: 26),
          const SizedBox(height: 2),
          Os2Text.monoCap(label, color: tone, size: Os2.textTiny),
        ],
      ),
    );
  }
}

class _SimulationCard extends StatelessWidget {
  const _SimulationCard({
    required this.fxLive,
    required this.flightLive,
    required this.visaLive,
    required this.sentryActive,
    required this.onToggleFx,
    required this.onToggleFlight,
    required this.onToggleVisa,
    required this.onToggleSentry,
  });
  final bool fxLive;
  final bool flightLive;
  final bool visaLive;
  final bool sentryActive;
  final VoidCallback onToggleFx;
  final VoidCallback onToggleFlight;
  final VoidCallback onToggleVisa;
  final VoidCallback onToggleSentry;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: Os2.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            'SIMULATE · WIRING',
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space3),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ToggleChip(
                label: 'FX · LIVE',
                active: fxLive,
                onTap: onToggleFx,
              ),
              _ToggleChip(
                label: 'FLIGHT · LIVE',
                active: flightLive,
                onTap: onToggleFlight,
              ),
              _ToggleChip(
                label: 'VISA · LIVE',
                active: visaLive,
                onTap: onToggleVisa,
              ),
              _ToggleChip(
                label: 'SENTRY · ACTIVE',
                active: sentryActive,
                onTap: onToggleSentry,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Os2.goldDeep.withValues(alpha: 0.18) : null,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? Os2.goldDeep.withValues(alpha: 0.62)
                : Os2.hairline,
          ),
        ),
        child: Os2Text.monoCap(
          label,
          color: active ? Os2.goldDeep : Os2.inkLow,
          size: Os2.textTiny,
        ),
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({required this.pillar});
  final ProductionPillar pillar;
  @override
  Widget build(BuildContext context) {
    final tone = Color(pillar.status.tone);
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(
          color: pillar.status.isCritical
              ? tone.withValues(alpha: 0.5)
              : Os2.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Os2Text.monoCap(
                  pillar.handle,
                  color: Os2.inkBright,
                  size: Os2.textTiny,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tone.withValues(alpha: 0.4)),
                ),
                child: Os2Text.monoCap(
                  pillar.status.handle,
                  color: tone,
                  size: Os2.textTiny,
                ),
              ),
            ],
          ),
          const SizedBox(height: Os2.space2),
          Os2Text.body(
            pillar.sub,
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
          if (pillar.detail != null) ...[
            const SizedBox(height: 6),
            Os2Text.monoCap(
              pillar.detail!,
              color: Os2.inkLow,
              size: Os2.textTiny,
            ),
          ],
        ],
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({required this.report});
  final ProductionReadinessReport report;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: Os2.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            'CONTRACT',
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Os2Text.body(
            'Production Readiness Hub aggregates every production-reliability pillar into a single glance-able dashboard. Tier ladder: GREEN (≥80% live, zero critical), GOLD (50–80% live), AMBER (<50% live), RED (any error / missing). Pillars marked DEMO ship the same brand-perfect UX with fixture data; flipping the live flag swaps in the production source.',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
          const SizedBox(height: Os2.space2),
          Os2Text.monoCap(
            'REPORT · GENERATED · ${report.generatedAt.toIso8601String().substring(0, 19)}Z',
            color: Os2.inkLow,
            size: Os2.textTiny,
          ),
        ],
      ),
    );
  }
}
