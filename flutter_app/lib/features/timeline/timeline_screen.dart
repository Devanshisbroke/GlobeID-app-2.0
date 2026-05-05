import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../user/user_provider.dart';

/// Timeline v2 — vertical event rail with year separators, brand
/// accent dots, premium row cards.
class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final theme = Theme.of(context);
    final past = user.records.where((r) => r.isPast).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (past.isEmpty) {
      return const PageScaffold(
        title: 'Timeline',
        subtitle: '0 past trips',
        body: EmptyState(
          title: 'No past trips',
          message: 'Travel records will appear here as you fly.',
          icon: Icons.history_rounded,
        ),
      );
    }

    String? lastYear;
    final children = <Widget>[];
    for (var i = 0; i < past.length; i++) {
      final r = past[i];
      final year = r.date.split('-').first;
      if (year != lastYear) {
        children.add(Padding(
          padding: EdgeInsets.only(
              top: lastYear == null ? 0 : AppTokens.space5,
              bottom: AppTokens.space2),
          child: Row(
            children: [
              Text(year,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(width: 8),
              Expanded(
                  child: Container(
                height: 1,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              )),
            ],
          ),
        ));
        lastYear = year;
      }
      children.add(AnimatedAppearance(
        delay: Duration(milliseconds: 50 * i),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.6),
                          ],
                        ),
                        boxShadow: AppTokens.shadowSm(
                          tint: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.10),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(r.from,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      )),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    child: Icon(
                                      Icons.flight_rounded,
                                      size: 14,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  Text(r.to,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      )),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('${r.airline} · ${r.date} · ${r.duration}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  )),
                            ],
                          ),
                        ),
                        if (r.flightNumber != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.06),
                              borderRadius:
                                  BorderRadius.circular(AppTokens.radiusFull),
                            ),
                            child: Text(r.flightNumber!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                )),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ));
    }

    return PageScaffold(
      title: 'Timeline',
      subtitle: '${past.length} past trips',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: children,
      ),
    );
  }
}
