import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../app/theme/airport_typography.dart';
import '../../app/theme/app_tokens.dart';

/// VisaReadinessRing — a sealed crest with a circular readiness arc
/// that fills clockwise as travel-doc completion progresses. Used in
/// visa / identity surfaces to telegraph "how ready are you to fly".
class VisaReadinessRing extends StatefulWidget {
  const VisaReadinessRing({
    super.key,
    required this.percent,
    required this.label,
    this.tone,
    this.size = 168,
  });

  final double percent;
  final String label;
  final Color? tone;
  final double size;

  @override
  State<VisaReadinessRing> createState() => _VisaReadinessRingState();
}

class _VisaReadinessRingState extends State<VisaReadinessRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();
  late final Animation<double> _anim = CurvedAnimation(
    parent: _ctrl,
    curve: AppTokens.easeOutSoft,
  );

  @override
  void didUpdateWidget(covariant VisaReadinessRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percent != widget.percent) {
      _ctrl
        ..reset()
        ..forward();
    }
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
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => CustomPaint(
          painter: _RingPainter(
            percent: widget.percent * _anim.value,
            tone: tone,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(widget.percent * _anim.value * 100).round()}%',
                  style: AirportFontStack.board(context, size: 26)
                      .copyWith(color: tone),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.label.toUpperCase(),
                  style: AirportFontStack.caption(context).copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.percent, required this.tone});
  final double percent;
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 14;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = tone.withValues(alpha: 0.12);
    canvas.drawCircle(c, r, track);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10
      ..shader = SweepGradient(
        colors: [tone, tone.withValues(alpha: 0.6), tone],
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      math.pi * 2 * percent.clamp(0.0, 1.0),
      false,
      arc,
    );
    // Inner halo when complete.
    if (percent >= 0.999) {
      final halo = Paint()
        ..color = tone.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawCircle(c, r * 0.86, halo);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.percent != percent || old.tone != tone;
}
