import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../os2_tokens.dart';
import 'os2_text.dart';

/// OS 2.0 — Dial.
///
/// A 270° radial gauge with a needle. Used for FX confidence, signal
/// strength, lounge occupancy headroom — anywhere a meter would be
/// over-engineered. Range maps to ticks; the needle springs to [value].
class Os2Dial extends StatefulWidget {
  const Os2Dial({
    super.key,
    required this.value, // 0..1
    this.tone = Os2.travelTone,
    this.diameter = 132,
    this.label,
    this.center,
    this.ticks = 9,
    this.trailing,
  });

  final double value;
  final Color tone;
  final double diameter;
  final String? label;
  final String? trailing;
  final Widget? center;
  final int ticks;

  @override
  State<Os2Dial> createState() => _Os2DialState();
}

class _Os2DialState extends State<Os2Dial>
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
  void didUpdateWidget(covariant Os2Dial old) {
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
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _DialPainter(
            value: _current,
            tone: widget.tone,
            ticks: widget.ticks,
          ),
          child: Center(
            child: widget.center ??
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Os2Text.headline(
                      '${(_current * 100).round()}',
                      color: Os2.inkBright,
                      size: widget.diameter * 0.26,
                    ),
                    if (widget.label != null) ...[
                      const SizedBox(height: 2),
                      Os2Text.caption(widget.label!, color: widget.tone),
                    ],
                    if (widget.trailing != null) ...[
                      const SizedBox(height: 2),
                      Os2Text.monoCap(widget.trailing!,
                          color: Os2.inkMid, size: 10),
                    ],
                  ],
                ),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.value,
    required this.tone,
    required this.ticks,
  });

  final double value;
  final Color tone;
  final int ticks;

  static const double _start = math.pi * 0.75; // 135°
  static const double _sweep = math.pi * 1.5; // 270°

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 6;

    // Floor arc.
    final floor = Paint()
      ..color = Os2.hairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = Os2.strokeRegular
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _start,
      _sweep,
      false,
      floor,
    );

    // Progress arc.
    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: _start,
        endAngle: _start + _sweep,
        colors: [
          tone.withValues(alpha: 0.65),
          tone,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _start,
      _sweep * value,
      false,
      progress,
    );

    // Tick marks.
    final tick = Paint()
      ..color = Os2.inkFaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = Os2.strokeFine;
    for (var i = 0; i < ticks; i++) {
      final t = i / (ticks - 1);
      final a = _start + _sweep * t;
      final r0 = radius - 10;
      final r1 = radius - 4;
      final p0 = center + Offset(math.cos(a) * r0, math.sin(a) * r0);
      final p1 = center + Offset(math.cos(a) * r1, math.sin(a) * r1);
      canvas.drawLine(p0, p1, tick);
    }

    // Needle.
    final needleAngle = _start + _sweep * value;
    final needleEnd = center +
        Offset(math.cos(needleAngle) * (radius - 14),
            math.sin(needleAngle) * (radius - 14));
    final needle = Paint()
      ..color = tone
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needle);

    // Hub.
    final hub = Paint()..color = Os2.inkBright;
    canvas.drawCircle(center, 3.4, hub);
    final hubRim = Paint()
      ..color = tone
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 3.4, hubRim);
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.value != value || old.tone != tone || old.ticks != ticks;
}
