
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_tokens.dart';

/// Visual tier progression ladder for the identity screen.
///
/// Shows: Member → Verified → Premium → Sovereign → Diplomat
/// with the current tier highlighted, glow effect, and progress
/// toward the next tier.
class TierProgression extends StatelessWidget {
  const TierProgression({
    super.key,
    required this.currentScore,
    required this.currentTier,
  });

  final int currentScore;
  final int currentTier; // 0-4

  static const _tiers = <_TierDef>[
    _TierDef('Member', Icons.person_rounded, Color(0xFF64748B), 0),
    _TierDef('Verified', Icons.verified_rounded, Color(0xFF0EA5E9), 25),
    _TierDef('Premium', Icons.workspace_premium_rounded, Color(0xFF8B5CF6), 50),
    _TierDef('Sovereign', Icons.shield_rounded, Color(0xFFD97706), 75),
    _TierDef('Diplomat', Icons.diamond_rounded, Color(0xFFD4AF37), 95),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTokens.space4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radius2xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _tiers[currentTier].color.withValues(alpha: 0.12),
            _tiers[currentTier].color.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(
          color: _tiers[currentTier].color.withValues(alpha: 0.22),
          width: 0.7,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tier Progression',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          Text(
            'Score $currentScore / 100 — ${_nextTierMessage()}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.60),
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          // Tier ladder
          Row(
            children: [
              for (var i = 0; i < _tiers.length; i++) ...[
                Expanded(
                  child: _TierNode(
                    tier: _tiers[i],
                    isCurrent: i == currentTier,
                    isReached: i <= currentTier,
                    index: i,
                  ),
                ),
                if (i < _tiers.length - 1)
                  Expanded(
                    child: _TierConnector(
                      isActive: i < currentTier,
                      color: _tiers[i].color,
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppTokens.durationMd, curve: AppTokens.easeOutSoft)
        .slideY(begin: 0.03, end: 0);
  }

  String _nextTierMessage() {
    if (currentTier >= _tiers.length - 1) return 'Maximum tier reached';
    final next = _tiers[currentTier + 1];
    final needed = next.minScore - currentScore;
    return '$needed pts to ${next.label}';
  }
}

class _TierNode extends StatelessWidget {
  const _TierNode({
    required this.tier,
    required this.isCurrent,
    required this.isReached,
    required this.index,
  });

  final _TierDef tier;
  final bool isCurrent;
  final bool isReached;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isReached ? tier.color : tier.color.withValues(alpha: 0.30);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: AppTokens.durationMd,
          curve: AppTokens.easeOutSoft,
          width: isCurrent ? 40 : 30,
          height: isCurrent ? 40 : 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrent ? color : color.withValues(alpha: 0.15),
            border: Border.all(
              color: color.withValues(alpha: isCurrent ? 0.85 : 0.35),
              width: isCurrent ? 2.0 : 1.0,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            tier.icon,
            size: isCurrent ? 20 : 14,
            color: isCurrent ? Colors.white : color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tier.label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
            color: isCurrent ? color : color.withValues(alpha: 0.65),
            fontSize: isCurrent ? 10 : 9,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _TierConnector extends StatelessWidget {
  const _TierConnector({required this.isActive, required this.color});
  final bool isActive;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        color: isActive ? color : color.withValues(alpha: 0.15),
      ),
    );
  }
}

class _TierDef {
  const _TierDef(this.label, this.icon, this.color, this.minScore);
  final String label;
  final IconData icon;
  final Color color;
  final int minScore;
}
