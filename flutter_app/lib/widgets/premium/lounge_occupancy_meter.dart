import 'package:flutter/material.dart';

import '../../app/theme/airport_typography.dart';
import '../../app/theme/app_tokens.dart';
import 'contextual_surface.dart';
import 'liquid_wave_surface.dart';

/// LoungeOccupancyMeter — a horizontal liquid-wave bar with a
/// human-readable label, used on lounge surfaces to telegraph
/// "how full is the lounge right now". The wave amplitude scales
/// with occupancy so a busy lounge looks visibly more agitated.
class LoungeOccupancyMeter extends StatelessWidget {
  const LoungeOccupancyMeter({
    super.key,
    required this.occupied,
    required this.capacity,
    this.tone,
    this.label = 'Occupancy',
  });

  final int occupied;
  final int capacity;
  final Color? tone;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = this.tone ?? theme.colorScheme.primary;
    final pct = capacity == 0 ? 0.0 : (occupied / capacity).clamp(0.0, 1.0);
    return ContextualSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label.toUpperCase(),
                  style: AirportFontStack.caption(context)),
              const Spacer(),
              Text('$occupied / $capacity',
                  style: AirportFontStack.board(context, size: 18)
                      .copyWith(color: tone)),
            ],
          ),
          const SizedBox(height: AppTokens.space2),
          LiquidWaveSurface(
            progress: pct,
            tone: tone,
            height: 44,
          ),
          const SizedBox(height: AppTokens.space2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quiet',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              Text('${(pct * 100).round()}% full',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: tone, fontWeight: FontWeight.w800)),
              Text('Packed',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ],
      ),
    );
  }
}
