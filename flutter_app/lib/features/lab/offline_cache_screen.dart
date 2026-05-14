import 'package:flutter/material.dart';

import '../../data/offline/stale_text.dart';
import '../../data/offline/timestamped_cache.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';
import '../../widgets/stale_chip.dart';

class OfflineCacheScreen extends StatefulWidget {
  const OfflineCacheScreen({super.key});
  @override
  State<OfflineCacheScreen> createState() => _OfflineCacheScreenState();
}

class _OfflineCacheScreenState extends State<OfflineCacheScreen> {
  late final TimestampedCache<String, _Snapshot> _cache;
  Duration _now = Duration.zero;
  bool _online = true;

  @override
  void initState() {
    super.initState();
    _cache = TimestampedCache(now: () => DateTime.now().add(_now));
    // Seed three reference rows so the screen has something to show
    // on cold mount.
    final t = DateTime.now();
    _cache.put('FX · EUR/USD',
        const _Snapshot('1.0842', '+0.02'), at: t);
    _cache.put('FLIGHT · LH 401',
        const _Snapshot('GATE · B27', 'BOARDING'), at: t);
    _cache.put('VISA · IN→AE',
        const _Snapshot('VISA · ON · ARRIVAL', '14d'), at: t);
  }

  @override
  void dispose() {
    _cache.dispose();
    super.dispose();
  }

  Future<void> _refresh(String key) async {
    if (!_online) return;
    setState(() {
      _cache.put(
        key,
        _refreshed(key),
        at: DateTime.now().add(_now),
      );
    });
  }

  _Snapshot _refreshed(String key) => switch (key) {
        'FX · EUR/USD' => const _Snapshot('1.0853', '+0.13'),
        'FLIGHT · LH 401' => const _Snapshot('IN · AIR', 'EN ROUTE'),
        'VISA · IN→AE' => const _Snapshot('VISA · ON · ARRIVAL', '14d'),
        _ => const _Snapshot('—', '—'),
      };

  void _advance(Duration step) {
    setState(() {
      _now += step;
    });
  }

  @override
  Widget build(BuildContext context) {
    final wall = DateTime.now().add(_now);
    return PageScaffold(
      title: 'Offline-first cache',
      subtitle: 'STALE chip ladder across surfaces',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          _StateCard(
            online: _online,
            wall: wall,
            onTimeStep: _advance,
            onToggleNetwork: (v) => setState(() => _online = v),
          ),
          const SizedBox(height: Os2.space4),
          for (final key in _cache.keys) ...[
            _CacheRow(
              keyLabel: key,
              snapshot: _cache.get(key)!,
              fetchedAt: _cache.timestamp(key)!,
              now: wall,
              onRefresh: _online ? () => _refresh(key) : null,
            ),
            const SizedBox(height: Os2.space3),
          ],
          const SizedBox(height: Os2.space2),
          const _IntegrationCard(),
        ],
      ),
    );
  }
}

class _Snapshot {
  const _Snapshot(this.headline, this.sub);
  final String headline;
  final String sub;
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.online,
    required this.wall,
    required this.onTimeStep,
    required this.onToggleNetwork,
  });
  final bool online;
  final DateTime wall;
  final void Function(Duration) onTimeStep;
  final ValueChanged<bool> onToggleNetwork;
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
            'STATE · OFFLINE · SIM',
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Row(
            children: [
              _Chip(
                label: 'NETWORK · ON',
                active: online,
                onTap: () => onToggleNetwork(true),
              ),
              const SizedBox(width: 8),
              _Chip(
                label: 'NETWORK · OFF',
                active: !online,
                onTap: () => onToggleNetwork(false),
              ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Os2Text.monoCap(
            'ADVANCE · WALL · CLOCK',
            color: Os2.inkLow,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final step in const [
                Duration(minutes: 1),
                Duration(minutes: 7),
                Duration(hours: 2),
                Duration(days: 2),
              ])
                _Chip(
                  label: '+ ${_durationHandle(step)}',
                  active: false,
                  onTap: () => onTimeStep(step),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _durationHandle(Duration d) {
    if (d.inDays >= 1) return '${d.inDays}d';
    if (d.inHours >= 1) return '${d.inHours}h';
    return '${d.inMinutes}m';
  }
}

class _CacheRow extends StatelessWidget {
  const _CacheRow({
    required this.keyLabel,
    required this.snapshot,
    required this.fetchedAt,
    required this.now,
    required this.onRefresh,
  });
  final String keyLabel;
  final _Snapshot snapshot;
  final DateTime fetchedAt;
  final DateTime now;
  final VoidCallback? onRefresh;
  @override
  Widget build(BuildContext context) {
    final age = now.difference(fetchedAt);
    final severity = staleSeverity(age);
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(
          color: severity == StaleSeverity.fresh
              ? Os2.hairline
              : Color(severity.tone).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Os2Text.monoCap(keyLabel,
                  color: Os2.inkBright, size: Os2.textTiny),
              const Spacer(),
              StaleChip(
                fetchedAt: fetchedAt,
                threshold: const Duration(minutes: 5),
                now: now,
                renderWhenFresh: true,
              ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Os2Text.display(
            snapshot.headline,
            color: Os2.inkBright,
            size: Os2.textXl,
          ),
          const SizedBox(height: 6),
          Os2Text.monoCap(
            snapshot.sub,
            color: Os2.inkMid,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space3),
          Row(
            children: [
              Pressable(
                onTap: onRefresh,
                semanticLabel: 'Refresh $keyLabel',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: onRefresh != null ? Os2.foilGoldHero : null,
                    color: onRefresh == null ? Os2.floor2 : null,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: onRefresh != null
                          ? Colors.transparent
                          : Os2.hairline,
                    ),
                  ),
                  child: Os2Text.monoCap(
                    onRefresh == null ? 'OFFLINE' : 'REFRESH',
                    color: onRefresh != null ? Os2.canvas : Os2.inkLow,
                    size: Os2.textTiny,
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
      semanticLabel: label,
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
            'TimestampedCache<K, V> is the offline-first floor every Live surface stands on. put() stamps a value with a wall-clock timestamp; isStale(threshold) flips when the age exceeds the threshold; watch(k) is a broadcast stream so multiple observers stay in sync.',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
          const SizedBox(height: Os2.space3),
          Os2Text.body(
            'StaleChip renders the canonical MONO-CAP "STALE · 14m · AGO" pill. Severity ladder: fresh (emerald, hidden by default) → notice (gold, > 5m) → warning (amber, > 1h) → danger (red, > 24h). Every Live surface mounts this chip on its last-known snapshot when the upstream feed fails.',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
        ],
      ),
    );
  }
}
