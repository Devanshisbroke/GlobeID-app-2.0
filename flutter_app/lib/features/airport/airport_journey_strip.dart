import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../motion/haptic_choreography.dart';
import '../../widgets/premium/premium.dart';

/// One stage in the airport orchestrator timeline.
class AirportStage {
  const AirportStage({
    required this.id,
    required this.title,
    required this.icon,
    this.subtitle,
  });
  final String id;
  final String title;
  final IconData icon;
  final String? subtitle;
}

/// Premium airport journey strip — Solari-board flap badges per stage,
/// progress indicator, and a hairline track.
///
/// Used by the airport orchestrator to visualize Check-in → Security →
/// Lounge → Boarding → Onboard → Arrival progression with haptic ping
/// when the active stage advances.
class AirportJourneyStrip extends StatefulWidget {
  const AirportJourneyStrip({
    super.key,
    required this.stages,
    required this.activeIndex,
    this.tone,
  });

  final List<AirportStage> stages;
  final int activeIndex;
  final Color? tone;

  @override
  State<AirportJourneyStrip> createState() => _AirportJourneyStripState();
}

class _AirportJourneyStripState extends State<AirportJourneyStrip> {
  int? _last;

  @override
  void didUpdateWidget(AirportJourneyStrip old) {
    super.didUpdateWidget(old);
    if (_last != widget.activeIndex && widget.activeIndex != old.activeIndex) {
      _last = widget.activeIndex;
      HapticPatterns.gatePing.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = widget.tone ?? theme.colorScheme.primary;
    return ContextualSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space4,
        vertical: AppTokens.space4,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (var i = 0; i < widget.stages.length; i++) ...[
              _StageBadge(
                stage: widget.stages[i],
                index: i,
                active: i == widget.activeIndex,
                completed: i < widget.activeIndex,
                tone: tone,
              ),
              if (i < widget.stages.length - 1)
                Container(
                  width: 32,
                  height: 2,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space2,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        if (i < widget.activeIndex) tone else Colors.white12,
                        if (i + 1 <= widget.activeIndex)
                          tone
                        else
                          Colors.white12,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({
    required this.stage,
    required this.index,
    required this.active,
    required this.completed,
    required this.tone,
  });
  final AirportStage stage;
  final int index;
  final bool active;
  final bool completed;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dim = !active && !completed;
    final color = completed
        ? tone
        : active
            ? tone
            : Colors.white24;
    final boxColor = active
        ? tone
        : completed
            ? tone.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.04);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(AppTokens.radiusXl),
            border: Border.all(
              color: color,
              width: active ? 1.4 : 0.8,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: tone.withValues(alpha: 0.45),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Icon(stage.icon,
              color: active
                  ? Colors.white
                  : completed
                      ? tone
                      : Colors.white54),
        ),
        const SizedBox(height: AppTokens.space2),
        SizedBox(
          width: 92,
          child: Column(
            children: [
              Text(
                stage.title.toUpperCase(),
                textAlign: TextAlign.center,
                style: AirportFontStack.gate(context, size: 10).copyWith(
                  color: dim
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                      : theme.colorScheme.onSurface,
                ),
              ),
              if (stage.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  stage.subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: dim ? 0.32 : 0.6),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
