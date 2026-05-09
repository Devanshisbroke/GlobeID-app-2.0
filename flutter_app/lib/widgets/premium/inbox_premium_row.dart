import 'package:flutter/material.dart';

import '../../app/theme/airport_typography.dart';
import '../../app/theme/app_tokens.dart';
import 'magnetic_pressable.dart';
import 'sensor_pendulum.dart';

/// InboxPremiumRow — a tactile, pressable notification row with
/// gyroscope micro-tilt, magnetic touch affordance, and a coloured
/// severity rail on the leading edge. Drop-in replacement for a
/// regular ListTile inside an inbox-style list.
class InboxPremiumRow extends StatelessWidget {
  const InboxPremiumRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    this.timestamp,
    this.unread = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tone;
  final String? timestamp;
  final bool unread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SensorPendulum(
      translation: 1.4,
      rotation: 0.005,
      child: MagneticPressable(
        onTap: onTap,
        scale: 0.98,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppTokens.space5,
            vertical: AppTokens.space1 + 1,
          ),
          padding: const EdgeInsets.all(AppTokens.space3),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTokens.radiusXl),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
            boxShadow: unread
                ? [
                    BoxShadow(
                      color: tone.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: unread
                      ? tone
                      : tone.withValues(alpha: 0.32),
                  borderRadius:
                      BorderRadius.circular(AppTokens.radiusFull),
                ),
              ),
              const SizedBox(width: AppTokens.space3),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.14),
                  borderRadius:
                      BorderRadius.circular(AppTokens.radiusFull),
                ),
                child: Icon(icon, color: tone, size: 20),
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight:
                            unread ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (timestamp != null) ...[
                const SizedBox(width: AppTokens.space2),
                Text(
                  timestamp!.toUpperCase(),
                  style: AirportFontStack.caption(context).copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.55),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
