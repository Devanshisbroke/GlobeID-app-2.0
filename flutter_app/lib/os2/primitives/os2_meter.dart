import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../os2_tokens.dart';
import 'os2_text.dart';

/// OS 2.0 — Meter.
///
/// Circular tier meter. Two concentric arcs:
///   • the floor arc (a 0.6px hairline, 8% white) running the full
///     circumference;
///   • the progress arc (a 2px tone-tinted arc with a luminous shadow)
///     running from -90° to (-90° + value × 360°);
///   • optional inner "tick" markers at each major tier boundary so the
///     viewer can see where the next tier lives.
///
/// Used by the Identity world's score constellation, the Wallet world's
/// goal tracker, and the Pulse world's tier meter.
class Os2Meter extends StatefulWidget {
  const Os2Meter({
    super.key,
    required this.value, // 0..1
    this.tone = Os2.identityTone,
    this.diameter = 168,
    this.strokeWidth = 5,
    this.label,
    this.subLabel,
    this.center,
    this.ticks = const [],
  });

  /// Progress value, in 0..1. Animates to new values over [Os2.mCruise].
  final double value;
  final Color tone;
  final double diameter;
  final double strokeWidth;
  final String? label;
  final String? subLabel;
  final Widget? center;
  final List<double> ticks;

  @override
  State<Os2Meter> createState() => _Os2MeterState();
}

class _Os2MeterState extends State<Os2Meter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Os2.mCruise,
  );
  late double _from;
  late double _to;

  @override
  void initState() {
    super.initState();
    _from = 0;
    _to = widget.value.clamp(0.0, 1.0);
    _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant Os2Meter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _from = _current;
      _to = widget.value.clamp(0.0, 1.0);
      _c.forward(from: 0);
    }
  }

  double get _current {
    final t = Os2.cBank.transform(_c.value);
    return _from + (_to - _from) * t;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.diameter,
      height: widget.diameter,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return CustomPaint(
              painter: _MeterPainter(
                value: _current,
                tone: widget.tone,
                strokeWidth: widget.strokeWidth,
                ticks: widget.ticks,
              ),
              child: Center(
                child: widget.center ??
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.label != null)
                          Os2Text.headline(
                            widget.label!,
                            color: Os2.inkBright,
                            size: widget.diameter * 0.22,
                            weight: FontWeight.w900,
                          ),
                        if (widget.subLabel != null) ...[
                          const SizedBox(height: 2),
                          Os2Text.caption(
                            widget.subLabel!,
                            color: widget.tone,
                          ),
                        ],
                      ],
                    ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  _MeterPainter({
    required this.value,
    required this.tone,
    required this.strokeWidth,
    required this.ticks,
  });

  final double value;
  final Color tone;
  final double strokeWidth;
  final List<double> ticks;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // Floor arc — full circle hairline.
    final floor = Paint()
      ..color = Os2.hairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = Os2.strokeFine;
    canvas.drawCircle(center, radius, floor);

    // Progress arc.
    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [
          tone.withValues(alpha: 0.85),
          tone,
          tone.withValues(alpha: 0.95),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    final sweep = math.pi * 2 * value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      progress,
    );

    // Tier ticks.
    for (final tick in ticks) {
      final tickAngle = -math.pi / 2 + math.pi * 2 * tick.clamp(0.0, 1.0);
      final start = Offset(
        center.dx + (radius - strokeWidth - 2) * math.cos(tickAngle),
        center.dy + (radius - strokeWidth - 2) * math.sin(tickAngle),
      );
      final end = Offset(
        center.dx + (radius + strokeWidth - 2) * math.cos(tickAngle),
        center.dy + (radius + strokeWidth - 2) * math.sin(tickAngle),
      );
      final tickPaint = Paint()
        ..color = Os2.inkLow
        ..strokeWidth = Os2.strokeRegular
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, tickPaint);
    }

    // Leading edge bloom.
    if (value > 0) {
      final leadAngle = -math.pi / 2 + sweep;
      final leadOffset = Offset(
        center.dx + radius * math.cos(leadAngle),
        center.dy + radius * math.sin(leadAngle),
      );
      final bloom = Paint()
        ..color = tone.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(leadOffset, strokeWidth * 0.7, bloom);
    }
  }

  @override
  bool shouldRepaint(covariant _MeterPainter old) =>
      old.value != value ||
      old.tone != tone ||
      old.strokeWidth != strokeWidth ||
      old.ticks != ticks;
}
