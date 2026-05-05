import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_scaffold.dart';
import '../insights/insights_provider.dart';

class PassportBookScreen extends ConsumerWidget {
  const PassportBookScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          final stamps = (data['stamps'] as List?) ?? const [];
          if (stamps.isEmpty) {
            return const EmptyState(
              title: 'No stamps yet',
              message:
                  'Complete your first verified trip to earn your first stamp.',
              icon: Icons.workspace_premium_rounded,
            );
          }
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppTokens.space3,
              crossAxisSpacing: AppTokens.space3,
              childAspectRatio: 0.95,
            ),
            itemCount: stamps.length,
            itemBuilder: (_, i) {
              final s = stamps[i] as Map<String, dynamic>;
              return GlassSurface(
                padding: const EdgeInsets.all(AppTokens.space3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(s['flag']?.toString() ?? '🌍',
                        style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: AppTokens.space2),
                    Text(s['title']?.toString() ?? '',
                        style: theme.textTheme.titleSmall,
                        textAlign: TextAlign.center),
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
