import 'package:flutter/material.dart';

/// JourneyStrip — a compact horizontal lifecycle visualization.
///
/// Each step is one node connected by a hairline with a fill that
/// progresses based on [activeIndex]. Active step pulses with the
/// accent ring. Used by Travel OS, Boarding Live, Home, etc.
class JourneyStrip extends StatelessWidget {
  const JourneyStrip({
    super.key,
    required this.steps,
    required this.activeIndex,
    this.height = 64,
  });

  final List<JourneyStep> steps;
  final int activeIndex;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              _Node(
                step: steps[i],
                state: i < activeIndex
                    ? _NodeState.done
                    : (i == activeIndex
                        ? _NodeState.active
                        : _NodeState.pending),
                accent: accent,
              ),
              if (i != steps.length - 1)
                Container(
                  width: 28,
                  height: 1.6,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i < activeIndex
                        ? accent.withValues(alpha: 0.6)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class JourneyStep {
  const JourneyStep({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

enum _NodeState { done, active, pending }

class _Node extends StatelessWidget {
  const _Node({
    required this.step,
    required this.state,
    required this.accent,
  });

  final JourneyStep step;
  final _NodeState state;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (state) {
      _NodeState.done => accent,
      _NodeState.active => accent,
      _NodeState.pending => theme.colorScheme.onSurface.withValues(alpha: 0.32),
    };
    final fill = switch (state) {
      _NodeState.done => accent.withValues(alpha: 0.20),
      _NodeState.active => accent.withValues(alpha: 0.28),
      _NodeState.pending => Colors.transparent,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (state == _NodeState.active)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.16),
                ),
              ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: Border.all(color: color, width: 1.4),
              ),
              alignment: Alignment.center,
              child: Icon(step.icon, size: 14, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          step.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight:
                state == _NodeState.pending ? FontWeight.w500 : FontWeight.w800,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
