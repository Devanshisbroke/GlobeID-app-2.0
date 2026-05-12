import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../os2_tokens.dart';
import 'os2_text.dart';

/// OS 2.0 — Progress arc.
///
/// A circular arc gauge. Optimised for inline use (40–80pt diameter).
/// Renders a hairline track + tone-tinted progress sweep + centre
/// monoCap value. Animates from current → target on update.
class Os2ProgressArc extends StatefulWidget {
  const Os2ProgressArc({
    super.key,
    required this.value, // 0..1
    this.tone = Os2.travelTone,
    this.diameter = 60,
    this.strokeWidth = 4,
    this.center,
    this.label,
    this.dense = false,
  });

  final double value;
  final Color tone;
  final double diameter;
  final double strokeWidth;
  final Widget? center;
  final String? label;
  final bool dense;

  @override
  State<Os2ProgressArc> createState() => _Os2ProgressArcState();
}

class _Os2ProgressArcState extends State<Os2ProgressArc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Os2.mCruise,
  );
  late Animation<double> _anim;
  double _last = 0;

  @override
  void initState() {
    super.initState();
    _anim = Tween<double>(begin: 0, end: widget.value.clamp(0, 1))
        .animate(CurvedAnimation(parent: _c, curve: Os2.cTakeoff));
    _last = widget.value.clamp(0, 1);
    _c.forward();
  }

  @override
  void didUpdateWidget(covariant Os2ProgressArc old) {
    super.didUpdateWidget(old);
    final clamped = widget.value.clamp(0, 1).toDouble();
    if (clamped != _last) {
      _anim = Tween<double>(begin: _last, end: clamped)
          .animate(CurvedAnimation(parent: _c, curve: Os2.cTakeoff));
      _c
        ..reset()
        ..forward();
      _last = clamped;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.diameter,
          height: widget.diameter,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(widget.diameter, widget.diameter),
                    painter: _ArcPainter(
                      value: _anim.value,
                      tone: widget.tone,
                      strokeWidth: widget.strokeWidth,
                    ),
                  ),
                  if (widget.center != null) widget.center!,
                ],
              ),
            ),
          ),
        ),
        if (widget.label != null) ...[
          SizedBox(height: widget.dense ? 2 : 4),
          Os2Text.monoCap(
            widget.label!,
            color: Os2.inkLow,
            size: widget.dense ? 9 : 10,
          ),
        ],
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.value,
    required this.tone,
    required this.strokeWidth,
  });

  final double value;
  final Color tone;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (size.shortestSide - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: r);

    final track = Paint()
      ..color = Os2.hairline
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, r, track);

    if (value <= 0) return;
    final p = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + math.pi * 2 * value,
        colors: [tone.withValues(alpha: 0.30), tone],
      ).createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, p);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.value != value ||
      old.tone != tone ||
      old.strokeWidth != strokeWidth;
}
