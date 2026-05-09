import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../motion/haptic_choreography.dart';
import '../../widgets/premium/premium.dart';

/// One predictive concierge intent surfaced to the user.
class ConciergeCommand {
  const ConciergeCommand({
    required this.id,
    required this.label,
    required this.icon,
    this.tone,
    this.onActivate,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color? tone;
  final VoidCallback? onActivate;
}

/// Premium concierge command surface — a magnetic radial deck of
/// pre-loaded actions ("Translate menu", "Find my gate", "Start
/// boarding pass", "Call ride") that responds to long-press and
/// reveals secondary intents.
///
/// Renders as a horizontal magnetic chip rail by default; long-press
/// on the leading "+" chip explodes the deck open into a half-circle
/// of radial chips so the user can pick visually.
class ConciergeCommandSurface extends StatefulWidget {
  const ConciergeCommandSurface({
    super.key,
    required this.commands,
    this.title = 'Ask Globe',
    this.subtitle,
  });

  final List<ConciergeCommand> commands;
  final String title;
  final String? subtitle;

  @override
  State<ConciergeCommandSurface> createState() =>
      _ConciergeCommandSurfaceState();
}

class _ConciergeCommandSurfaceState extends State<ConciergeCommandSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _explode = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 540),
  );
  bool _open = false;

  @override
  void dispose() {
    _explode.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticPatterns.pressureBegin.play();
    if (_open) {
      _explode.reverse();
    } else {
      _explode.forward();
    }
    setState(() => _open = !_open);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ContextualSurface(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space5,
        AppTokens.space4,
        AppTokens.space5,
        AppTokens.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        )),
                    if (widget.subtitle != null)
                      Text(widget.subtitle!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            letterSpacing: 0.4,
                          )),
                  ],
                ),
              ),
              MagneticPressable(
                onTap: _toggle,
                onLongPress: _toggle,
                child: AnimatedRotation(
                  duration: AppTokens.durationSm,
                  turns: _open ? 0.125 : 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    ),
                    child: Icon(
                      _open ? Icons.close_rounded : Icons.add_rounded,
                      color: theme.colorScheme.onSurface,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          AnimatedBuilder(
            animation: _explode,
            builder: (_, __) {
              final t = Curves.easeOutCubic.transform(_explode.value);
              return SizedBox(
                height: 50 + 110 * t,
                child: Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    if (t < 0.99)
                      Opacity(
                        opacity: 1 - t,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              for (final cmd in widget.commands)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      right: AppTokens.space2),
                                  child: _ChipCommand(cmd: cmd),
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (t > 0.001)
                      Opacity(
                        opacity: t,
                        child: SizedBox(
                          height: 160,
                          child: _RadialDeck(
                            commands: widget.commands,
                            progress: t,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChipCommand extends StatelessWidget {
  const _ChipCommand({required this.cmd});
  final ConciergeCommand cmd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = cmd.tone ?? theme.colorScheme.primary;
    return MagneticPressable(
      onTap: () {
        HapticPatterns.tap.play();
        cmd.onActivate?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space3 + 2,
          vertical: AppTokens.space2 + 2,
        ),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          border: Border.all(
            color: tone.withValues(alpha: 0.32),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(cmd.icon, size: 16, color: tone),
            const SizedBox(width: AppTokens.space2),
            Text(cmd.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: theme.colorScheme.onSurface,
                )),
          ],
        ),
      ),
    );
  }
}

class _RadialDeck extends StatelessWidget {
  const _RadialDeck({required this.commands, required this.progress});
  final List<ConciergeCommand> commands;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        final centre = Offset(w / 2, c.maxHeight - 20);
        final radius = (w / 2 - 60).clamp(80.0, 180.0);
        return Stack(
          children: [
            for (var i = 0; i < commands.length; i++)
              _radialChild(centre, radius, i, commands.length, commands[i]),
          ],
        );
      },
    );
  }

  Widget _radialChild(
      Offset centre, double radius, int i, int total, ConciergeCommand cmd) {
    const spread = 0.7;
    final theta = (i / (total - 1).clamp(1, total) - 0.5) * spread;
    final angle = -math.pi / 2 + theta * math.pi;
    final dx = radius * progress * math.cos(angle);
    final dy = radius * progress * math.sin(angle);
    return Positioned(
      left: centre.dx + dx - 40,
      top: centre.dy + dy - 40,
      child: SizedBox(
        width: 80,
        child: _ChipCommand(cmd: cmd),
      ),
    );
  }
}
