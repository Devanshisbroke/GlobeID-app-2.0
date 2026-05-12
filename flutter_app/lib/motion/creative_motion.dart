import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../core/ambient_sound.dart';

/// Confetti celebration overlay for milestone achievements.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, required this.trigger, this.child});
  final bool trigger;
  final Widget? child;
  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  List<_P> _ps = [];
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) setState(() => _active = false);
      });
    if (widget.trigger) _fire();
  }

  @override
  void didUpdateWidget(covariant ConfettiOverlay old) {
    super.didUpdateWidget(old);
    if (widget.trigger && !old.trigger) _fire();
  }

  void _fire() {
    HapticFeedback.heavyImpact();
    AmbientSound.instance.play(SoundCue.tierUpgrade);
    final rng = math.Random();
    const colors = [
      Color(0xFF0EA5E9),
      Color(0xFF8B5CF6),
      Color(0xFF22C55E),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
      Color(0xFFEF4444)
    ];
    _ps = List.generate(
        100,
        (_) => _P(
              x: 0.5 + (rng.nextDouble() - 0.5) * 0.3,
              y: 0.3,
              vx: (rng.nextDouble() - 0.5) * 3,
              vy: -(2 + rng.nextDouble() * 4),
              rot: rng.nextDouble() * math.pi * 2,
              rs: (rng.nextDouble() - 0.5) * 8,
              sz: 4 + rng.nextDouble() * 8,
              c: colors[rng.nextInt(colors.length)],
              sh: rng.nextInt(3),
            ));
    setState(() => _active = true);
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        if (widget.child != null) widget.child!,
        if (_active)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => CustomPaint(
                    painter: _CP(ps: _ps, t: _ctrl.value),
                  ),
                ),
              ),
            ),
          ),
      ]);
}

class _P {
  _P(
      {required this.x,
      required this.y,
      required this.vx,
      required this.vy,
      required this.rot,
      required this.rs,
      required this.sz,
      required this.c,
      required this.sh});
  final double x, y, vx, vy, rot, rs, sz;
  final Color c;
  final int sh;
}

class _CP extends CustomPainter {
  _CP({required this.ps, required this.t});
  final List<_P> ps;
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    final op = (1 - t).clamp(0.0, 1.0);
    for (final p in ps) {
      final tt = t * 3.2;
      final x = (p.x + p.vx * tt * 0.08) * size.width;
      final y = (p.y + p.vy * tt * 0.08 + 9.8 * tt * tt * 0.004) * size.height;
      if (y > size.height) continue;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rot + p.rs * tt);
      final paint = Paint()..color = p.c.withValues(alpha: op * 0.85);
      if (p.sh == 0) {
        canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: p.sz, height: p.sz),
            paint);
      } else if (p.sh == 1) {
        canvas.drawCircle(Offset.zero, p.sz / 2, paint);
      } else {
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset.zero, width: p.sz * 0.3, height: p.sz * 1.5),
            paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CP old) => old.t != t;
}

/// Animated number ticker — rolls digits like an airport departure board.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter(
      {super.key,
      required this.value,
      this.style,
      this.prefix = '',
      this.suffix = ''});
  final int value;
  final TextStyle? style;
  final String prefix, suffix;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.toDouble()),
        duration: const Duration(milliseconds: 1200),
        curve: AppTokens.easeOutSoft,
        builder: (_, v, __) => Text('$prefix${v.round()}$suffix',
            style: style ??
                Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
      );
}

/// Breathing glow pulsation around a widget.
class BreathingGlow extends StatefulWidget {
  const BreathingGlow(
      {super.key, required this.child, this.color, this.glowRadius = 20});
  final Widget child;
  final Color? color;
  final double glowRadius;
  @override
  State<BreathingGlow> createState() => _BGState();
}

class _BGState extends State<BreathingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = widget.color ?? Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = Curves.easeInOut.transform(_c.value);
          return Container(
              decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                BoxShadow(
                    color: col.withValues(alpha: 0.10 + 0.15 * t),
                    blurRadius: widget.glowRadius * (0.5 + 0.5 * t),
                    spreadRadius: widget.glowRadius * 0.2 * t),
              ]),
              child: child);
        },
        child: widget.child);
  }
}

/// Scroll-driven theme tinting overlay — hue shifts cool→warm.
class ScrollTint extends StatelessWidget {
  const ScrollTint(
      {super.key,
      required this.scrollOffset,
      required this.maxOffset,
      required this.child});
  final double scrollOffset, maxOffset;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final p = maxOffset > 0 ? (scrollOffset / maxOffset).clamp(0.0, 1.0) : 0.0;
    final hue = 210 - 175 * p;
    final c = HSLColor.fromAHSL(0.08, hue, 0.6, 0.5).toColor();
    return Stack(children: [
      Positioned.fill(
          child: IgnorePointer(
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [c.withValues(alpha: 0.02), c.withValues(alpha: 0.08)],
      ))))),
      child,
    ]);
  }
}
