import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/fx/demo_fx_adapter.dart';
import '../../data/fx/frankfurter_fx_adapter.dart';
import '../../data/fx/fx_models.dart';
import '../../data/fx/fx_service.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

/// `/lab/fx-adapter` — operator surface that exercises the new
/// FX adapter stack end-to-end.
///
/// Lets you toggle between the demo and live Frankfurter adapter,
/// fires a refresh, and renders the resulting snapshot with the
/// STALE chip when the fetch is older than the threshold.
class FxAdapterScreen extends StatefulWidget {
  const FxAdapterScreen({super.key});

  @override
  State<FxAdapterScreen> createState() => _FxAdapterScreenState();
}

class _FxAdapterScreenState extends State<FxAdapterScreen> {
  bool _live = false;
  bool _loading = false;
  String? _error;
  FxSnapshot? _snapshot;
  FxService? _service;
  StreamSubscription<FxSnapshot>? _sub;

  static const _pairs = [
    FxPair('USD', 'EUR'),
    FxPair('USD', 'GBP'),
    FxPair('USD', 'JPY'),
    FxPair('USD', 'INR'),
    FxPair('USD', 'AED'),
  ];

  @override
  void initState() {
    super.initState();
    _rebuildService();
    _refresh();
  }

  void _rebuildService() {
    _sub?.cancel();
    _service?.dispose();
    final svc = FxService(
      adapter: _live ? FrankfurterFxAdapter() : DemoFxAdapter(),
      fallback: _live ? DemoFxAdapter() : null,
      refreshInterval: const Duration(seconds: 30),
    );
    _service = svc;
    _sub = svc.stream.listen((snap) {
      if (!mounted) return;
      setState(() => _snapshot = snap);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
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
      final tracked =
          svc.last == null ? await svc.track(_pairs) : await svc.refresh();
      if (!mounted) return;
      setState(() {
        _snapshot = tracked;
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
      title: 'FX adapter',
      subtitle: _live ? 'Live · Frankfurter (ECB)' : 'Demo · drift seed',
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
            onToggle: (v) {
              if (_live == v) return;
              setState(() {
                _live = v;
                _snapshot = null;
              });
              _rebuildService();
              _refresh();
            },
            onRefresh: _loading ? null : _refresh,
            loading: _loading,
          ),
          const SizedBox(height: Os2.space4),
          if (_error != null) ...[
            _ErrorCard(message: _error!),
            const SizedBox(height: Os2.space4),
          ],
          _SnapshotCard(snapshot: _snapshot),
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
    required this.onToggle,
    required this.onRefresh,
    required this.loading,
  });
  final bool live;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onRefresh;
  final bool loading;

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
            'SOURCE',
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Row(
            children: [
              _SourceChip(
                label: 'DEMO',
                active: !live,
                onTap: () => onToggle(false),
              ),
              const SizedBox(width: 8),
              _SourceChip(
                label: 'LIVE',
                active: live,
                onTap: () => onToggle(true),
              ),
              const Spacer(),
              Pressable(
                onTap: onRefresh,
                semanticLabel: 'Refresh rates',
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

class _SourceChip extends StatelessWidget {
  const _SourceChip({
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

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({required this.snapshot});
  final FxSnapshot? snapshot;
  @override
  Widget build(BuildContext context) {
    if (snapshot == null) {
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
    final snap = snapshot!;
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
          Row(
            children: [
              Os2Text.monoCap(
                'SNAPSHOT · ${snap.source.toUpperCase()}',
                color: Os2.goldDeep,
                size: Os2.textTiny,
              ),
              const Spacer(),
              if (snap.isStale())
                _StaleChip(at: snap.fetchedAt)
              else
                Os2Text.monoCap(
                  _ago(snap.fetchedAt),
                  color: Os2.inkLow,
                  size: Os2.textTiny,
                ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          for (final q in snap.quotes.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Os2Text.monoCap(
                    q.pair.handle,
                    color: Os2.inkBright,
                    size: Os2.textTiny,
                  ),
                  const Spacer(),
                  Os2Text.monoCap(
                    q.rate.toStringAsFixed(q.rate < 10 ? 4 : 2),
                    color: Os2.inkBright,
                    size: Os2.textTiny,
                  ),
                  const SizedBox(width: 8),
                  Os2Text.monoCap(
                    '${q.delta >= 0 ? '+' : ''}${(q.delta * 100).toStringAsFixed(2)}%',
                    color: q.delta >= 0
                        ? const Color(0xFF6CCB7E)
                        : const Color(0xFFE07070),
                    size: Os2.textTiny,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'NOW';
    if (d.inMinutes < 60) return '${d.inMinutes}M AGO';
    return '${d.inHours}H AGO';
  }
}

class _StaleChip extends StatelessWidget {
  const _StaleChip({required this.at});
  final DateTime at;
  @override
  Widget build(BuildContext context) {
    final d = DateTime.now().difference(at);
    final tag = d.inMinutes >= 60
        ? '${d.inHours}H AGO'
        : '${d.inMinutes}M AGO';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF3A1F0A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFB870)),
      ),
      child: Os2Text.monoCap(
        'STALE · $tag',
        color: const Color(0xFFFFB870),
        size: Os2.textTiny,
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
            'Every FX source in GlobeID implements FxAdapter — single method `Future<FxQuote> quote(FxPair)` plus an optional `snapshot(List<FxPair>)`. FxService wraps an adapter with last-known-good cache, single-flight refresh, and a fallback chain (live → demo on failure).',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
          const SizedBox(height: Os2.space3),
          Os2Text.body(
            'Frankfurter — api.frankfurter.app/latest. ECB-backed reference rates, free, no key. Demo — deterministic drift seeded by minute + pair handle so the demo state is reproducible (±0.6% per cycle, mean-reverting to base, clamped to ±2%).',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
        ],
      ),
    );
  }
}
