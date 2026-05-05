import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../insights/insights_provider.dart';

/// Activity feed v2 — premium event rows with brand-tinted icon
/// chips, staggered reveal, no GlassSurface noise.
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(activityInsightsProvider);
    final theme = Theme.of(context);
    return PageScaffold(
      title: 'Activity',
      subtitle: 'Your recent travel activity',
      body: activity.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          title: 'Activity unavailable',
          message: e.toString(),
          icon: Icons.cloud_off_rounded,
        ),
        data: (data) {
          final items = (data['items'] as List?) ?? const [];
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No activity yet',
              message: 'Your scans, trips, and bookings will live here.',
              icon: Icons.bolt_rounded,
            );
          }
          return ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              for (var i = 0; i < items.length; i++)
                AnimatedAppearance(
                  delay: Duration(milliseconds: 40 * i),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.space3),
                    child: _Row(
                      data: items[i] as Map<String, dynamic>,
                      accent: _accentForIndex(i, theme),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Color _accentForIndex(int i, ThemeData theme) {
    const palette = [
      Color(0xFF7C3AED),
      Color(0xFF06B6D4),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
      Color(0xFF6366F1),
    ];
    return palette[i % palette.length];
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.data, required this.accent});
  final Map<String, dynamic> data;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = data['title']?.toString() ?? '';
    final subtitle = data['subtitle']?.toString() ?? '';
    final type = data['type']?.toString() ?? '';
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.32),
                  accent.withValues(alpha: 0.12),
                ],
              ),
            ),
            child: Icon(_iconFor(type), color: accent),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'trip':
        return Icons.flight_takeoff_rounded;
      case 'scan':
        return Icons.qr_code_scanner_rounded;
      case 'booking':
        return Icons.event_available_rounded;
      case 'identity':
        return Icons.fingerprint_rounded;
      case 'pass':
        return Icons.confirmation_number_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.history_rounded;
    }
  }
}
