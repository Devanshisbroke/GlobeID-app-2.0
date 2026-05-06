import 'package:flutter/material.dart';

/// A compact sparkline chart for inline mini-charts. Uses a smooth
/// cubic curve, an accent fill underneath, and rounded endpoints. The
/// optional [animate] flag will tween the line in over [duration].
class Sparkline extends StatefulWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 36,
    this.strokeWidth = 1.6,
    this.fillAlpha = 0.16,
    this.animate = true,
    this.duration = const Duration(milliseconds: 700),
  });

  final List<num> values;
  final Color color;
  final double height;
  final double strokeWidth;
  final double fillAlpha;
  final bool animate;
  final Duration duration;

  @override
  State<Sparkline> createState() => _SparklineState();
}

class _SparklineState extends State<Sparkline>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _ctrl.forward();
    } else {
      _ctrl.value = 1;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SizedBox(
        height: widget.height,
        child: CustomPaint(
          painter: _SparkPainter(
            values: widget.values,
            color: widget.color,
            progress: _anim.value,
            stroke: widget.strokeWidth,
            fillAlpha: widget.fillAlpha,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.values,
    required this.color,
    required this.progress,
    required this.stroke,
    required this.fillAlpha,
  });

  final List<num> values;
  final Color color;
  final double progress;
  final double stroke;
  final double fillAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final w = size.width;
    final h = size.height;
    // Normalise to a typed `List<double>` so `reduce` always receives a
    // `(double, double) => double` combiner regardless of whether the
    // caller passed `List<int>` or `List<double>`. Without this, dart2js
    // throws `type '(num, num) => num' is not a subtype of type '(int,
    // int) => int'` on web because the iterable's reified type wins.
    final dvals = values.map((v) => v.toDouble()).toList(growable: false);
    final minV = dvals.reduce((a, b) => a < b ? a : b);
    final maxV = dvals.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.0001 ? 1.0 : (maxV - minV);

    final dx = w / (dvals.length - 1);
    final pts = <Offset>[];
    for (var i = 0; i < dvals.length; i++) {
      final v = (dvals[i] - minV) / range;
      pts.add(Offset(i * dx, h - v * (h - 4) - 2));
    }

    // Animate by trimming the path.
    final visibleCount = (pts.length * progress).clamp(2, pts.length).toInt();
    final visible = pts.sublist(0, visibleCount);

    final linePath = _smooth(visible);
    final fillPath = Path.from(linePath)
      ..lineTo(visible.last.dx, h)
      ..lineTo(visible.first.dx, h)
      ..close();

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: fillAlpha),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fill);

    final line = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, line);

    // Endpoint glow.
    final dot = Paint()..color = color;
    canvas.drawCircle(visible.last, stroke * 1.6, dot);
    canvas.drawCircle(
      visible.last,
      stroke * 3,
      Paint()..color = color.withValues(alpha: 0.32),
    );
  }

  Path _smooth(List<Offset> p) {
    final path = Path()..moveTo(p.first.dx, p.first.dy);
    for (var i = 0; i < p.length - 1; i++) {
      final a = p[i];
      final b = p[i + 1];
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      path.quadraticBezierTo(a.dx, a.dy, mid.dx, mid.dy);
    }
    path.lineTo(p.last.dx, p.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.values != values ||
      old.stroke != stroke;
}
