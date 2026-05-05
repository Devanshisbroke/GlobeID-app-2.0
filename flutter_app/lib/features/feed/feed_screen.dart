import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_scaffold.dart';
import '../insights/insights_provider.dart';

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
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppTokens.space2),
            itemBuilder: (_, i) {
              final m = items[i] as Map<String, dynamic>;
              return GlassSurface(
                child: Row(
                  children: [
                    Icon(Icons.history_rounded,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: AppTokens.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['title']?.toString() ?? '',
                              style: theme.textTheme.titleSmall),
                          Text(m['subtitle']?.toString() ?? '',
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
