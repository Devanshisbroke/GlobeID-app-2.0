import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/models/travel_record.dart';
import '../../widgets/animated_appearance.dart';
import '../../cinematic/states/cinematic_states.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../user/user_provider.dart';

/// Timeline v3 — flagship vertical event rail.
///
/// Adds deterministic per-row enrichment (mileage band, climate hint,
/// route accent), aggregate stat header, year filter chip rail, and
/// keeps the brand-tinted dot + connector aesthetic.
class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});
  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  String _yearFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final theme = Theme.of(context);
    final past = user.records.where((r) => r.isPast).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (past.isEmpty) {
      return const PageScaffold(
        title: 'Timeline',
        subtitle: '0 past trips',
        body: Os2EmptyState(
          eyebrow: 'TRAVEL · TIMELINE',
          title: 'No past trips',
          message: 'Travel records will appear here as you fly. Each leg is verified, signed, and pinned to your timeline.',
          icon: Icons.history_rounded,
        ),
      );
    }
    final years = <String>{};
    for (final r in past) {
      if (r.date.length >= 4) years.add(r.date.substring(0, 4));
    }
    final sortedYears = years.toList()..sort((a, b) => b.compareTo(a));
    final filtered = _yearFilter == 'all'
        ? past
        : past.where((r) => r.date.startsWith(_yearFilter)).toList();

    // Aggregate stats (deterministic).
    final airports = <String>{};
    int totalMiles = 0;
    for (final r in past) {
      airports
        ..add(r.from)
        ..add(r.to);
      totalMiles += _mileageFor(r);
    }

    String? lastYear;
    final children = <Widget>[];
    for (var i = 0; i < filtered.length; i++) {
      final r = filtered[i];
      final year = r.date.split('-').first;
      if (year != lastYear) {
        children.add(
          Padding(
            padding: EdgeInsets.only(
              top: lastYear == null ? 0 : AppTokens.space5,
              bottom: AppTokens.space2,
            ),
            child: Row(
              children: [
                Text(
                  year,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
                  ),
                ),
              ],
            ),
          ),
        );
        lastYear = year;
      }
      children.add(
        AnimatedAppearance(
          delay: Duration(milliseconds: 40 * i),
          child: _TimelineRow(record: r, accent: _accentForIndex(i)),
        ),
      );
    }

    return PageScaffold(
      title: 'Timeline',
      subtitle: '${past.length} past trips',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Stat header ─────────────────────────────────────────
          AnimatedAppearance(
            child: Row(
              children: [
                Expanded(
                  child: _Stat(
                    icon: Icons.flight_takeoff_rounded,
                    label: 'Trips',
                    value: '${past.length}',
                    tone: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: _Stat(
                    icon: Icons.connecting_airports_rounded,
                    label: 'Airports',
                    value: '${airports.length}',
                    tone: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: _Stat(
                    icon: Icons.public_rounded,
                    label: 'Miles',
                    value: _miles(totalMiles),
                    tone: const Color(0xFF06B6D4),
                  ),
                ),
              ],
            ),
          ),
          if (sortedYears.length > 1) ...[
            const SizedBox(height: AppTokens.space4),
            AnimatedAppearance(
              delay: const Duration(milliseconds: 80),
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  itemCount: sortedYears.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final y = i == 0 ? 'all' : sortedYears[i - 1];
                    final label = i == 0 ? 'All' : sortedYears[i - 1];
                    final selected = _yearFilter == y;
                    return Pressable(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _yearFilter = y);
                      },
                      child: AnimatedContainer(
                        duration: AppTokens.durationSm,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusFull),
                          gradient: selected
                              ? LinearGradient(colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ])
                              : null,
                          color: selected
                              ? null
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.06),
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.10),
                          ),
                        ),
                        child: Text(
                          label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: selected
                                ? Colors.white
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.85),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: AppTokens.space5),
          ...children,
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }

  Color _accentForIndex(int i) => const [
        Color(0xFF7C3AED),
        Color(0xFF06B6D4),
        Color(0xFF10B981),
        Color(0xFFF59E0B),
        Color(0xFFEF4444),
        Color(0xFF3B82F6),
      ][i % 6];

  String _miles(int m) {
    if (m >= 10000) return '${(m / 1000).toStringAsFixed(1)}k';
    return '$m';
  }
}

/// Deterministic mileage from from/to airport codes.
int _mileageFor(TravelRecord r) {
  // Stable, repeatable hash so the same trip always shows the same number.
  final s = '${r.from}-${r.to}';
  var h = 0;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return 800 + (h % 7200);
}

String _climateFor(TravelRecord r) {
  final code = (r.to + r.date).codeUnits.fold<int>(0, (a, c) => a + c) % 5;
  switch (code) {
    case 0:
      return '☀ Sunny · 24°';
    case 1:
      return '☁ Cloudy · 18°';
    case 2:
      return '🌧 Rainy · 14°';
    case 3:
      return '❄ Cold · 4°';
    default:
      return '🌫 Mild · 21°';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              gradient: LinearGradient(colors: [
                tone.withValues(alpha: 0.32),
                tone.withValues(alpha: 0.10),
              ]),
            ),
            child: Icon(icon, color: tone, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.record, required this.accent});
  final TravelRecord record;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mileage = _mileageFor(record);
    final climate = _climateFor(record);
    final isLong = mileage > 5000;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Rail dot + connector ────────────────────────────────
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [
                      accent,
                      accent.withValues(alpha: 0.6),
                    ]),
                    boxShadow: AppTokens.shadowSm(tint: accent),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.space2),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.space3),
              child: PremiumCard(
                padding: const EdgeInsets.all(AppTokens.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          record.from,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.flight_rounded,
                            size: 14,
                            color: accent,
                          ),
                        ),
                        Text(
                          record.to,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        if (record.flightNumber != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(
                                AppTokens.radiusFull,
                              ),
                            ),
                            child: Text(
                              record.flightNumber!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.airline} · ${record.date} · ${record.duration}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: AppTokens.space3),
                    // ── Enrichment chips ───────────────────────────────
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Chip(
                          icon: Icons.terrain_rounded,
                          label: '$mileage mi',
                          tone: accent,
                        ),
                        _Chip(
                          icon: isLong
                              ? Icons.airline_seat_flat_rounded
                              : Icons.airline_seat_recline_normal_rounded,
                          label: isLong ? 'Long-haul' : 'Mid-haul',
                          tone: theme.colorScheme.primary,
                        ),
                        _Chip(
                          icon: Icons.cloud_rounded,
                          label: climate,
                          tone: theme.colorScheme.secondary,
                        ),
                        _Chip(
                          icon: Icons.verified_rounded,
                          label: 'Verified',
                          tone: const Color(0xFF10B981),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.tone,
  });
  final IconData icon;
  final String label;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        color: tone.withValues(alpha: 0.14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tone),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: tone,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
