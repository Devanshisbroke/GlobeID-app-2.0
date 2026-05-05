import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_scaffold.dart';
import '../user/user_provider.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final theme = Theme.of(context);
    final past = user.records.where((r) => r.isPast).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return PageScaffold(
      title: 'Timeline',
      subtitle: '${past.length} past trips',
      body: past.isEmpty
          ? const EmptyState(
              title: 'No past trips',
              message: 'Travel records will appear here as you fly.',
              icon: Icons.history_rounded,
            )
          : ListView.separated(
              itemCount: past.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTokens.space2),
              itemBuilder: (_, i) {
                final r = past[i];
                return GlassSurface(
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 56,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: AppTokens.space4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${r.from} → ${r.to}',
                                style: theme.textTheme.titleMedium),
                            Text('${r.airline} · ${r.date} · ${r.duration}',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      if (r.flightNumber != null)
                        Text(r.flightNumber!,
                            style: theme.textTheme.titleSmall?.copyWith(
                              letterSpacing: 1.2,
                            )),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
