import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../nexus/nexus_tokens.dart';

/// Premium sparkline — a one-line trend chart with a polished
/// gradient fill, last-point glow, and an optional tweened reveal.
///
/// Values are rendered against the running min/max so the line always
/// fills the canvas. Caller controls the [tone] and the [height].
/// Deterministic; no animation drives state — values come from the
/// caller. The reveal is internal-only and respects
/// `disableAnimations`.
class PremiumSparkline extends StatefulWidget {
  const PremiumSparkline({
    super.key,
    required this.values,
    this.tone,
    this.height = 56,
    this.label,
    this.delta,
    this.dense = false,
  });

  final List<double> values;
  final Color? tone;
  final double height;
  final String? label;
  final double? delta;
  final bool dense;

  @override
  State<PremiumSparkline> createState() => _PremiumSparklineState();
}

class _PremiumSparklineState extends State<PremiumSparkline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ctrl.forward();
    });
  }

  @override
  void didUpdateWidget(covariant PremiumSparkline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.values.length != oldWidget.values.length ||
        !_listEquals(widget.values, oldWidget.values)) {
      _ctrl.forward(from: 0);
    }
  }

  bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tone = widget.tone ?? N.tierGold;
    final reduce = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = reduce ? 1.0 : AppTokens.easeOutQuart.transform(_ctrl.value);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null || widget.delta != null) ...[
              Row(
                children: [
                  if (widget.label != null)
                    Text(
                      widget.label!.toUpperCase(),
                      style: const TextStyle(
                        color: N.inkLow,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        fontSize: 10,
                      ),
                    ),
                  const Spacer(),
                  if (widget.delta != null)
                    Text(
                      _fmtDelta(widget.delta!),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: widget.delta! >= 0 ? N.success : N.critical,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            SizedBox(
              height: widget.height,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _SparklinePainter(
                    values: widget.values,
                    tone: tone,
                    progress: t,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _fmtDelta(double d) {
    final sign = d >= 0 ? '+' : '';
    return '$sign${d.toStringAsFixed(2)}%';
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.tone,
    required this.progress,
  });
  final List<double> values;
  final Color tone;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final w = size.width;
    final h = size.height;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : maxV - minV;

    final visibleCount =
        (values.length * progress).clamp(1, values.length).toInt();
    final stepX = w / (values.length - 1);

    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < visibleCount; i++) {
      final x = i * stepX;
      final norm = (values[i] - minV) / range;
      final y = h - norm * (h - 8) - 4;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, h);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo((visibleCount - 1) * stepX, h);
    fillPath.close();

    // Restrained tonal wash (no glow / no saturation spike).
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          tone.withValues(alpha: 0.18),
          tone.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // Line stroke (hairline thickness for restrained Lovable feel).
    final stroke = Paint()
      ..color = tone
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, stroke);

    // Solid last-point marker — no blur halo.
    final lastIdx = visibleCount - 1;
    final lx = lastIdx * stepX;
    final lyNorm = (values[lastIdx] - minV) / range;
    final ly = h - lyNorm * (h - 8) - 4;
    canvas.drawCircle(
      Offset(lx, ly),
      2.5,
      Paint()..color = tone,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.progress != progress || old.values != values || old.tone != tone;
}
