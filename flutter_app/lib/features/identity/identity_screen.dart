import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../domain/identity_tier.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/section_header.dart';
import '../score/score_provider.dart';
import '../user/user_provider.dart';

class IdentityScreen extends ConsumerWidget {
  const IdentityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final score = ref.watch(scoreProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppTokens.space5,
        MediaQuery.of(context).padding.top + AppTokens.space5,
        AppTokens.space5,
        AppTokens.space9 + 16,
      ),
      children: [
        Text('Identity', style: theme.textTheme.headlineLarge),
        const SizedBox(height: AppTokens.space5),
        score.when(
          data: (s) => _IdentityHero(
            score: s.score,
            tier: IdentityTier.forScore(s.score),
            history: s.history,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _IdentityHero(
            score: user.profile.identityScore,
            tier: IdentityTier.forScore(user.profile.identityScore),
            history: const [],
          ),
        ),
        const SectionHeader(title: 'Documents'),
        if (user.documents.isEmpty)
          const EmptyState(
            title: 'No documents yet',
            message: 'Add your passport or visa to bump up your tier.',
            icon: Icons.badge_outlined,
          )
        else
          for (final d in user.documents)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.space2),
              child: _DocRow(
                title: d.label,
                subtitle: '${d.country} · expires ${d.expiryDate}',
                trailing: d.status,
              ),
            ),
        const SectionHeader(title: 'Verification factors'),
        score.when(
          data: (s) => Column(
            children: [
              for (final f in s.factors)
                _FactorRow(label: f.label, value: f.value),
            ],
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppTokens.space5),
        FilledButton.icon(
          onPressed: () => context.push('/vault'),
          icon: const Icon(Icons.shield_moon_rounded),
          label: const Text('Open vault'),
        ),
      ],
    );
  }
}

class _IdentityHero extends StatelessWidget {
  const _IdentityHero({
    required this.score,
    required this.tier,
    required this.history,
  });
  final int score;
  final IdentityTier tier;
  final List<int> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassSurface(
      padding: const EdgeInsets.all(AppTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PillChip(
                label: tier.label,
                icon: Icons.workspace_premium_rounded,
              ),
              const Spacer(),
              Text(score.toString(),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  )),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          if (history.length > 2)
            SizedBox(
              height: 80,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.3),
                            theme.colorScheme.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                      spots: [
                        for (var i = 0; i < history.length; i++)
                          FlSpot(i.toDouble(), history[i].toDouble()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow(
      {required this.title, required this.subtitle, required this.trailing});
  final String title;
  final String subtitle;
  final String trailing;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassSurface(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4, vertical: AppTokens.space3),
      child: Row(
        children: [
          Icon(Icons.badge_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          PillChip(label: trailing),
        ],
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          SizedBox(
            width: 120,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              child: LinearProgressIndicator(
                value: value.clamp(0, 1).toDouble(),
                minHeight: 6,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space2),
          Text('${(value * 100).toInt()}%',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}
