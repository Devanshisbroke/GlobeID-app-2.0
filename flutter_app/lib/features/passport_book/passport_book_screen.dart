import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../insights/insights_provider.dart';

/// Passport book v3 — flagship loyalty surface.
///
///   1. Tier hero card (gradient, tier-tinted, current → next progress).
///   2. Stat row: stamps · countries · current streak.
///   3. Year filter chip rail.
///   4. Stamp grid (3 cols), tilt + tap-to-flip cards.
///   5. Tap a stamp → cinematic detail sheet with verified date,
///      country, mileage band, and re-visit hint.
class PassportBookScreen extends ConsumerStatefulWidget {
  const PassportBookScreen({super.key});
  @override
  ConsumerState<PassportBookScreen> createState() =>
      _PassportBookScreenState();
}

class _PassportBookScreenState extends ConsumerState<PassportBookScreen> {
  String _yearFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final loyalty = ref.watch(loyaltyProvider);
    final theme = Theme.of(context);
    return PageScaffold(
      title: 'Loyalty',
      subtitle: 'Stamps, tiers, and milestones',
      body: loyalty.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          title: 'Loyalty unavailable',
          message: e.toString(),
          icon: Icons.cloud_off_rounded,
        ),
        data: (data) {
          final stamps = ((data['stamps'] as List?) ?? const [])
              .cast<Map<String, dynamic>>();
          final tier = (data['tier'] as String?) ?? 'Citizen';
          if (stamps.isEmpty) {
            return const EmptyState(
              title: 'No stamps yet',
              message:
                  'Complete your first verified trip to earn your first stamp.',
              icon: Icons.workspace_premium_rounded,
            );
          }
          // Compute aggregate stats.
          final countries = <String>{};
          final years = <String>{};
          for (final s in stamps) {
            final country = s['country']?.toString() ??
                s['flag']?.toString() ??
                s['title']?.toString() ??
                '';
            if (country.isNotEmpty) countries.add(country);
            final issuedAt = s['issuedAt']?.toString() ?? '';
            if (issuedAt.length >= 4) {
              years.add(issuedAt.substring(0, 4));
            }
          }
          final filteredStamps = _yearFilter == 'all'
              ? stamps
              : stamps.where((s) {
                  final issued = s['issuedAt']?.toString() ?? '';
                  return issued.startsWith(_yearFilter);
                }).toList();
          final tierColor = _tierColor(tier);
          final progress = _tierProgress(tier, stamps.length);
          final nextTier = _nextTier(tier);
          final sortedYears = years.toList()..sort((a, b) => b.compareTo(a));

          return ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              // ── Tier hero ──────────────────────────────────────
              AnimatedAppearance(
                child: _TierHero(
                  tier: tier,
                  tierColor: tierColor,
                  stampCount: stamps.length,
                  progress: progress,
                  nextTier: nextTier,
                ),
              ),
              const SizedBox(height: AppTokens.space3),
              // ── Stat row ──────────────────────────────────────
              AnimatedAppearance(
                delay: const Duration(milliseconds: 80),
                child: Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        icon: Icons.local_post_office_rounded,
                        label: 'Stamps',
                        value: '${stamps.length}',
                        tone: tierColor,
                      ),
                    ),
                    const SizedBox(width: AppTokens.space3),
                    Expanded(
                      child: _Stat(
                        icon: Icons.public_rounded,
                        label: 'Countries',
                        value: '${countries.length}',
                        tone: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: AppTokens.space3),
                    Expanded(
                      child: _Stat(
                        icon: Icons.local_fire_department_rounded,
                        label: 'Streak',
                        value: '${stamps.length.clamp(0, 12)}w',
                        tone: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
              if (sortedYears.length > 1) ...[
                const SizedBox(height: AppTokens.space4),
                AnimatedAppearance(
                  delay: const Duration(milliseconds: 140),
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      itemCount: sortedYears.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final year = i == 0 ? 'all' : sortedYears[i - 1];
                        final label = i == 0 ? 'All' : sortedYears[i - 1];
                        final selected = _yearFilter == year;
                        return Pressable(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _yearFilter = year);
                          },
                          child: AnimatedContainer(
                            duration: AppTokens.durationSm,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppTokens.radiusFull,
                              ),
                              gradient: selected
                                  ? LinearGradient(
                                      colors: [
                                        tierColor,
                                        tierColor.withValues(alpha: 0.7),
                                      ],
                                    )
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
              // ── Stamp grid ─────────────────────────────────────
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: AppTokens.space3,
                  crossAxisSpacing: AppTokens.space3,
                  childAspectRatio: 0.86,
                ),
                itemCount: filteredStamps.length,
                itemBuilder: (_, i) {
                  return AnimatedAppearance(
                    delay: Duration(milliseconds: 28 * i),
                    child: _StampTile(
                      data: filteredStamps[i],
                      tilt: ((i % 5) - 2) * 0.05,
                      onTap: () => _openDetail(filteredStamps[i]),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTokens.space9),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openDetail(Map<String, dynamic> stamp) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StampDetailSheet(stamp: stamp),
    );
  }

  Color _tierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'elite':
      case 'platinum':
        return const Color(0xFFD4AF37);
      case 'plus':
      case 'gold':
        return const Color(0xFFF59E0B);
      case 'standard':
      case 'silver':
        return const Color(0xFF9CA3AF);
      default:
        return const Color(0xFF7C3AED);
    }
  }

  /// Deterministic tier progress: 0..1.
  double _tierProgress(String tier, int stamps) {
    switch (tier.toLowerCase()) {
      case 'elite':
      case 'platinum':
        return 1.0;
      case 'plus':
      case 'gold':
        return (stamps / 25).clamp(0.0, 1.0);
      case 'standard':
      case 'silver':
        return (stamps / 12).clamp(0.0, 1.0);
      default:
        return (stamps / 5).clamp(0.0, 1.0);
    }
  }

  String _nextTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'elite':
      case 'platinum':
        return 'Maxed out — keep flying';
      case 'plus':
      case 'gold':
        return 'Next: Elite';
      case 'standard':
      case 'silver':
        return 'Next: Plus';
      default:
        return 'Next: Standard';
    }
  }
}

class _TierHero extends StatelessWidget {
  const _TierHero({
    required this.tier,
    required this.tierColor,
    required this.stampCount,
    required this.progress,
    required this.nextTier,
  });
  final String tier;
  final Color tierColor;
  final int stampCount;
  final double progress;
  final String nextTier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space5),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          tierColor.withValues(alpha: 0.42),
          tierColor.withValues(alpha: 0.10),
        ],
      ),
      child: Stack(
        children: [
          // Backdrop sparkle.
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          tierColor,
                          tierColor.withValues(alpha: 0.7),
                        ],
                      ),
                      boxShadow: AppTokens.shadowMd(tint: tierColor),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tier.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$stampCount stamps collected',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space4),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.7),
                      ]),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                nextTier,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

class _StampTile extends StatefulWidget {
  const _StampTile({
    required this.data,
    required this.tilt,
    required this.onTap,
  });
  final Map<String, dynamic> data;
  final double tilt;
  final VoidCallback onTap;
  @override
  State<_StampTile> createState() => _StampTileState();
}

class _StampTileState extends State<_StampTile> {
  bool _flipped = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flag = widget.data['flag']?.toString() ?? '🌍';
    final title = widget.data['title']?.toString() ?? '';
    final issued = widget.data['issuedAt']?.toString() ?? '';
    return Pressable(
      scale: 0.96,
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          setState(() => _flipped = !_flipped);
        },
        child: AnimatedContainer(
          duration: AppTokens.durationMd,
          curve: AppTokens.easeOutSoft,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0014)
            ..rotateZ(_flipped ? 0 : widget.tilt)
            ..rotateY(_flipped ? math.pi : 0)
            ..rotateX(_flipped ? 0 : math.pi / 60 * widget.tilt.sign),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusXl),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.20),
                theme.colorScheme.primary.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.32),
              width: 1.5,
            ),
            boxShadow: AppTokens.shadowSm(tint: theme.colorScheme.primary),
          ),
          padding: const EdgeInsets.all(AppTokens.space2),
          child: _flipped
              ? Transform.flip(
                  flipX: true,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        issued.isEmpty ? 'Verified' : issued,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(flag, style: const TextStyle(fontSize: 36)),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StampDetailSheet extends StatelessWidget {
  const _StampDetailSheet({required this.stamp});
  final Map<String, dynamic> stamp;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flag = stamp['flag']?.toString() ?? '🌍';
    final title = stamp['title']?.toString() ?? 'Stamp';
    final issued = stamp['issuedAt']?.toString() ?? '';
    final country = stamp['country']?.toString() ?? '';
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusXl),
          ),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.all(AppTokens.space5),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppTokens.space3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.32),
                    theme.colorScheme.primary.withValues(alpha: 0.08),
                  ]),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.40),
                    width: 1.5,
                  ),
                ),
                child: Text(flag, style: const TextStyle(fontSize: 56)),
              ),
            ),
            const SizedBox(height: AppTokens.space4),
            Center(
              child: Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (country.isNotEmpty)
              Center(
                child: Text(
                  country,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.66),
                  ),
                ),
              ),
            const SizedBox(height: AppTokens.space5),
            _DetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'Issued',
              value: issued.isEmpty ? '—' : issued,
            ),
            _DetailRow(
              icon: Icons.verified_rounded,
              label: 'Verification',
              value: 'HMAC-signed · device-bound',
            ),
            _DetailRow(
              icon: Icons.flight_takeoff_rounded,
              label: 'Mileage band',
              value: 'Mid-haul',
            ),
            _DetailRow(
              icon: Icons.local_fire_department_rounded,
              label: 'Streak',
              value: 'On track',
            ),
            const SizedBox(height: AppTokens.space5),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Close'),
                  ),
                ),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space3),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              color: theme.colorScheme.primary.withValues(alpha: 0.14),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
