import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/section_header.dart';
import '../insights/insights_provider.dart';

/// Intelligence v2 — premium briefing layout with stat tiles,
/// gradient hero, and animated reveal of context + travel insights.
class IntelligenceScreen extends ConsumerWidget {
  const IntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = ref.watch(contextProvider);
    final travel = ref.watch(travelInsightsProvider);
    final theme = Theme.of(context);
    return PageScaffold(
      title: 'Intelligence',
      subtitle: 'Deterministic travel briefings',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space5),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.34),
                  theme.colorScheme.primary.withValues(alpha: 0.06),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.bolt_rounded,
                        color: Colors.white.withValues(alpha: 0.85)),
                    const SizedBox(width: 6),
                    Text('LIVE BRIEFING',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        )),
                  ]),
                  const SizedBox(height: AppTokens.space3),
                  Text('Deterministic, on-device',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    'No hallucinations. Insights derived from your trips, wallet, and identity.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Now', dense: true),
          ctx.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(
              title: 'Context unavailable',
              message: e.toString(),
              icon: Icons.cloud_off_rounded,
            ),
            data: (m) => AnimatedAppearance(
              delay: const Duration(milliseconds: 80),
              child: _StatGrid(entries: m.entries.take(8).toList()),
            ),
          ),
          const SectionHeader(title: 'Travel insights', dense: true),
          travel.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(
              title: 'Insights unavailable',
              message: e.toString(),
              icon: Icons.cloud_off_rounded,
            ),
            data: (m) => AnimatedAppearance(
              delay: const Duration(milliseconds: 160),
              child: _StatGrid(entries: m.entries.take(8).toList()),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.entries});
  final List<MapEntry<String, dynamic>> entries;
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppTokens.space2,
      crossAxisSpacing: AppTokens.space2,
      childAspectRatio: 1.7,
      children: [
        for (final e in entries) _StatTile(label: e.key, value: e.value),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final dynamic value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(value.toString(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
