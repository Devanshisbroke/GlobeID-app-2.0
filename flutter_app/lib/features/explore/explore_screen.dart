import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_scaffold.dart';
import '../insights/insights_provider.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reco = ref.watch(recommendationsProvider);
    final theme = Theme.of(context);
    return PageScaffold(
      title: 'Explore',
      subtitle: 'Curated for your next destination',
      body: reco.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          title: 'Recommendations unavailable',
          message: e.toString(),
          icon: Icons.cloud_off_rounded,
        ),
        data: (data) {
          final items = (data['items'] as List?) ?? const [];
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No recommendations yet',
              message: 'Add a trip and we\'ll surface things to do.',
              icon: Icons.travel_explore_rounded,
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppTokens.space2),
            itemBuilder: (_, i) {
              final item = items[i] as Map<String, dynamic>;
              return GlassSurface(
                child: Row(
                  children: [
                    Icon(Icons.place_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: AppTokens.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title']?.toString() ?? 'Suggestion',
                              style: theme.textTheme.titleSmall),
                          Text(item['subtitle']?.toString() ?? '',
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
