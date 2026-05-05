import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../insights/insights_provider.dart';

/// Passport book v2 — premium stamp grid with subtle tilt on press,
/// hero gradient backdrop, total counter.
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
          final tier = (data['tier'] as String?) ?? 'Citizen';
          if (stamps.isEmpty) {
            return const EmptyState(
              title: 'No stamps yet',
              message:
                  'Complete your first verified trip to earn your first stamp.',
              icon: Icons.workspace_premium_rounded,
            );
          }
          return ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              AnimatedAppearance(
                child: PremiumCard(
                  padding: const EdgeInsets.all(AppTokens.space5),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFF59E0B).withValues(alpha: 0.32),
                      const Color(0xFF7C3AED).withValues(alpha: 0.18),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium_rounded,
                          color: Colors.white, size: 32),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tier,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                )),
                            Text('${stamps.length} stamps collected',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space5),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: AppTokens.space3,
                  crossAxisSpacing: AppTokens.space3,
                  childAspectRatio: 0.92,
                ),
                itemCount: stamps.length,
                itemBuilder: (_, i) {
                  final s = stamps[i] as Map<String, dynamic>;
                  return AnimatedAppearance(
                    delay: Duration(milliseconds: 40 * i),
                    child: _StampTile(
                      data: s,
                      tilt: (i % 5 - 2) * 0.04,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StampTile extends StatefulWidget {
  const _StampTile({required this.data, required this.tilt});
  final Map<String, dynamic> data;
  final double tilt;
  @override
  State<_StampTile> createState() => _StampTileState();
}

class _StampTileState extends State<_StampTile> {
  final bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.96,
      onTap: () {},
      child: AnimatedContainer(
        duration: AppTokens.durationMd,
        curve: AppTokens.easeOutSoft,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0014)
          ..rotateZ(_pressed ? 0 : widget.tilt)
          ..rotateX(_pressed ? 0 : math.pi / 60 * widget.tilt.sign),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusXl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.18),
              theme.colorScheme.primary.withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.32),
            width: 1.5,
          ),
          boxShadow: AppTokens.shadowSm(tint: theme.colorScheme.primary),
        ),
        padding: const EdgeInsets.all(AppTokens.space3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.data['flag']?.toString() ?? '🌍',
                style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 6),
            Text(widget.data['title']?.toString() ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
