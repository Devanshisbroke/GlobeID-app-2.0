import 'package:flutter/material.dart';

import '../../data/flight/aeroapi_flight_adapter.dart';
import '../../data/flight/demo_flight_adapter.dart';
import '../../data/flight/flight_models.dart';
import '../../data/flight/flight_service.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

/// `/lab/flight-adapter` — operator surface for the new
/// FlightAdapter stack.
class FlightAdapterScreen extends StatefulWidget {
  const FlightAdapterScreen({super.key});

  @override
  State<FlightAdapterScreen> createState() => _FlightAdapterScreenState();
}

class _FlightAdapterScreenState extends State<FlightAdapterScreen> {
  bool _live = false;
  bool _loading = false;
  String? _error;
  FlightQuote? _quote;
  FlightService? _service;

  static const _handle = FlightHandle('LH', '401');

  @override
  void initState() {
    super.initState();
    _rebuildService();
    _refresh();
  }

  void _rebuildService() {
    _service?.dispose();
    _service = FlightService(
      adapter: _live ? AeroapiFlightAdapter() : DemoFlightAdapter(),
      fallback: _live ? DemoFlightAdapter() : null,
    );
  }

  @override
  void dispose() {
    _service?.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final svc = _service;
    if (svc == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final q = await svc.refresh(_handle);
      if (!mounted) return;
      setState(() {
        _quote = q;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Flight adapter',
      subtitle:
          _live ? 'Live · AeroAPI (FlightAware)' : 'Demo · phase machine',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          _SourceCard(
            live: _live,
            loading: _loading,
            onToggle: (v) {
              if (_live == v) return;
              setState(() {
                _live = v;
                _quote = null;
              });
              _rebuildService();
              _refresh();
            },
            onRefresh: _loading ? null : _refresh,
          ),
          const SizedBox(height: Os2.space4),
          if (_error != null) ...[
            _ErrorCard(message: _error!),
            const SizedBox(height: Os2.space4),
          ],
          _QuoteCard(quote: _quote),
          const SizedBox(height: Os2.space5),
          const _IntegrationCard(),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.live,
    required this.loading,
    required this.onToggle,
    required this.onRefresh,
  });
  final bool live;
  final bool loading;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onRefresh;
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
            'SOURCE · LH 401',
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Row(
            children: [
              _Chip(
                label: 'DEMO',
                active: !live,
                onTap: () => onToggle(false),
              ),
              const SizedBox(width: 8),
              _Chip(
                label: 'LIVE',
                active: live,
                onTap: () => onToggle(true),
              ),
              const Spacer(),
              Pressable(
                onTap: onRefresh,
                semanticLabel: 'Refresh flight',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: Os2.foilGoldHero,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (loading)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.6,
                            color: Os2.canvas,
                          ),
                        )
                      else
                        const Icon(
                          Icons.refresh_rounded,
                          color: Os2.canvas,
                          size: 14,
                        ),
                      const SizedBox(width: 6),
                      Os2Text.monoCap(
                        'REFRESH',
                        color: Os2.canvas,
                        size: Os2.textTiny,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: '$label source',
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

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});
  final FlightQuote? quote;
  @override
  Widget build(BuildContext context) {
    if (quote == null) {
      return Container(
        padding: const EdgeInsets.all(Os2.space4),
        decoration: BoxDecoration(
          color: Os2.floor1,
          borderRadius: BorderRadius.circular(Os2.rCard),
          border: Border.all(color: Os2.hairline),
        ),
        child: Os2Text.body(
          'No snapshot yet. Tap REFRESH.',
          color: Os2.inkMid,
          size: Os2.textSm,
        ),
      );
    }
    final q = quote!;
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        gradient: Os2.foilGoldHero,
        borderRadius: BorderRadius.circular(Os2.rCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            'SNAPSHOT · ${q.source.toUpperCase()}',
            color: Os2.canvas,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Os2Text.title(
                q.handle.display,
                color: Os2.canvas,
                size: Os2.textXl,
              ),
              const Spacer(),
              Os2Text.monoCap(
                q.phase.handle,
                color: Os2.canvas,
                size: Os2.textTiny,
              ),
            ],
          ),
          const SizedBox(height: Os2.space2),
          Os2Text.monoCap(
            '${q.origin} → ${q.destination}'
            '${q.gate != null ? ' · GATE ${q.gate}' : ''}',
            color: Os2.canvas.withValues(alpha: 0.8),
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space3),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'DELAY',
                  value: q.delayMinutes == 0
                      ? 'ON · TIME'
                      : (q.delayMinutes > 0
                          ? '+${q.delayMinutes}m'
                          : '${q.delayMinutes}m'),
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'TERMINAL',
                  value: q.terminal ?? '—',
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'SCHED',
                  value: _hhmm(q.scheduledOut),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Os2Text.monoCap(
          label,
          color: Os2.canvas.withValues(alpha: 0.6),
          size: Os2.textTiny,
        ),
        const SizedBox(height: 2),
        Os2Text.monoCap(
          value,
          color: Os2.canvas,
          size: Os2.textTiny,
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A0F0F),
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: const Color(0xFFFF6A6A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            'FETCH · FAILED',
            color: const Color(0xFFFF8A8A),
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Os2Text.body(message, color: Os2.inkBright, size: Os2.textSm),
        ],
      ),
    );
  }
}

class _IntegrationCard extends StatelessWidget {
  const _IntegrationCard();
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
            'Every flight source in GlobeID implements FlightAdapter — single method `Future<FlightQuote> quote(FlightHandle)`. FlightService wraps an adapter with per-handle single-flight refresh, broadcast watch streams, and a fallback chain (AeroAPI → demo on failure).',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
          const SizedBox(height: Os2.space3),
          Os2Text.body(
            'AeroAPI — aeroapi.flightaware.com/aeroapi/flights/{ident}. v4 contract, x-apikey header, AEROAPI_KEY supplied via --dart-define. Demo — deterministic state machine that walks LH 401 (MUC → JFK) through every FlightPhase across a 14-minute cycle.',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
        ],
      ),
    );
  }
}
