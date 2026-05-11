import 'package:flutter/material.dart';

import '../os2_tokens.dart';
import 'os2_text.dart';

/// OS 2.0 — Sparkline.
///
/// A one-line trend chart drawn against the OLED canvas:
///   • a smooth catmull-rom-ish curve through the supplied [values];
///   • a soft gradient fill below the curve fading to canvas;
///   • a luminous dot pinned to the last point that breathes;
///   • progressive reveal on first mount over [Os2.mCruise].
///
/// Deterministic — no randomness. Repaints only when [values] or [tone]
/// change identity.
class Os2Sparkline extends StatefulWidget {
  const Os2Sparkline({
    super.key,
    required this.values,
    this.tone = Os2.walletTone,
    this.height = 64,
    this.label,
    this.delta,
    this.dense = false,
  });

  /// Series. Must contain at least 2 points; otherwise renders a flat rule.
  final List<double> values;
  final Color tone;
  final double height;
  final String? label;

  /// Optional delta marker shown to the right of the label
  /// (e.g. "+2.4%"). Sign drives the tone (settled / critical).
  final double? delta;
  final bool dense;

  @override
  State<Os2Sparkline> createState() => _Os2SparklineState();
}

class _Os2SparklineState extends State<Os2Sparkline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: Os2.mCruise,
  )..forward();

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasHeader = widget.label != null || widget.delta != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasHeader)
          Padding(
            padding: const EdgeInsets.only(bottom: Os2.space2),
            child: Row(
              children: [
                if (widget.label != null)
                  Expanded(
                    child: Os2Text.caption(
                      widget.label!,
                      color: Os2.inkMid,
                    ),
                  )
                else
                  const Spacer(),
                if (widget.delta != null)
                  Os2Text.monoCap(
                    '${widget.delta! >= 0 ? '+' : ''}'
                    '${widget.delta!.toStringAsFixed(1)}%',
                    color: widget.delta! >= 0
                        ? Os2.signalSettled
                        : Os2.signalCritical,
                    size: 11,
                  ),
              ],
            ),
          ),
        SizedBox(
          height: widget.height,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _reveal,
              builder: (_, __) => CustomPaint(
                painter: _SparkPainter(
                  values: widget.values,
                  tone: widget.tone,
                  progress: Os2.cCruise.transform(_reveal.value),
                  dense: widget.dense,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.values,
    required this.tone,
    required this.progress,
    required this.dense,
  });

  final List<double> values;
  final Color tone;
  final double progress;
  final bool dense;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      // Flat rule.
      final p = Paint()
        ..color = Os2.hairline
        ..strokeWidth = Os2.strokeFine;
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        p,
      );
      return;
    }

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs() < 1e-6 ? 1.0 : (max - min);
    final visibleCount =
        (values.length * progress).clamp(2, values.length).toInt();

    Offset pointFor(int i) {
      final x = size.width * (i / (values.length - 1));
      final y =
          size.height - ((values[i] - min) / range) * size.height * 0.92 - 4;
      return Offset(x, y);
    }

    // Hairline floor.
    final floor = Paint()
      ..color = Os2.hairlineSoft
      ..strokeWidth = Os2.strokeFine;
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      floor,
    );

    // Build path.
    final path = Path()..moveTo(pointFor(0).dx, pointFor(0).dy);
    for (var i = 1; i < visibleCount; i++) {
      final prev = pointFor(i - 1);
      final cur = pointFor(i);
      final mid = Offset((prev.dx + cur.dx) / 2, (prev.dy + cur.dy) / 2);
      path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
      if (i == visibleCount - 1) path.lineTo(cur.dx, cur.dy);
    }

    // Fill below.
    final fill = Path.from(path)
      ..lineTo(pointFor(visibleCount - 1).dx, size.height)
      ..lineTo(pointFor(0).dx, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          tone.withValues(alpha: dense ? 0.22 : 0.18),
          tone.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fill, fillPaint);

    // Stroke.
    final stroke = Paint()
      ..color = tone.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = dense ? 1.4 : 1.8
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, stroke);

    // Last point glow.
    if (visibleCount == values.length) {
      final last = pointFor(values.length - 1);
      final glow = Paint()
        ..color = tone.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(last, 5, glow);
      final dot = Paint()..color = tone;
      canvas.drawCircle(last, dense ? 2.2 : 2.8, dot);
      final ring = Paint()
        ..color = Os2.inkBright
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(last, dense ? 2.2 : 2.8, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.values != values || old.tone != tone || old.progress != progress;
}
