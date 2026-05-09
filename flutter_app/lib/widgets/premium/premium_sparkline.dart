import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

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
    final theme = Theme.of(context);
    final tone = widget.tone ?? theme.colorScheme.primary;
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
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.62),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  const Spacer(),
                  if (widget.delta != null)
                    Text(
                      _fmtDelta(widget.delta!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: widget.delta! >= 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFE11D48),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            SizedBox(
              height: widget.height,
              child: CustomPaint(
                size: Size.infinite,
                painter: _SparklinePainter(
                  values: widget.values,
                  tone: tone,
                  progress: t,
                  isDark: theme.brightness == Brightness.dark,
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
    required this.isDark,
  });
  final List<double> values;
  final Color tone;
  final double progress;
  final bool isDark;

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

    // Fill gradient.
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          tone.withValues(alpha: 0.32),
          tone.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // Line stroke.
    final stroke = Paint()
      ..color = tone
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, stroke);

    // Last-point glow.
    final lastIdx = visibleCount - 1;
    final lx = lastIdx * stepX;
    final lyNorm = (values[lastIdx] - minV) / range;
    final ly = h - lyNorm * (h - 8) - 4;
    final glow = Paint()
      ..color = tone.withValues(alpha: 0.42)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(lx, ly), 5, glow);
    canvas.drawCircle(
      Offset(lx, ly),
      3.2,
      Paint()..color = tone,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.progress != progress ||
      old.values != values ||
      old.tone != tone;
}
