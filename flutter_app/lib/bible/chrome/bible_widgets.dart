import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bible_tokens.dart';
import '../bible_typography.dart';
import 'bible_pressable.dart';

// ───────────────────────────────────────────── BibleSectionHeader

class BibleSectionHeader extends StatelessWidget {
  const BibleSectionHeader({
    super.key,
    required this.eyebrow,
    this.title,
    this.trailing,
    this.tone,
  });
  final String eyebrow;
  final String? title;
  final Widget? trailing;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, B.space5, 0, B.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BText.eyebrow(eyebrow, color: tone ?? B.inkOnDarkLow),
                if (title != null) ...[
                  const SizedBox(height: B.space1),
                  BText.title(title!, size: 17),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────── BibleDivider

class BibleDivider extends StatelessWidget {
  const BibleDivider({super.key, this.inset = 0});
  final double inset;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      child: const SizedBox(
        height: 0.5,
        child: ColoredBox(color: B.hairlineLight),
      ),
    );
  }
}

// ───────────────────────────────────────────── BibleAnimatedNumber

/// Animated numerical readout — interpolates between value changes.
class BibleAnimatedNumber extends StatelessWidget {
  const BibleAnimatedNumber({
    super.key,
    required this.value,
    this.duration = B.dSheet,
    this.curve = B.takeoff,
    this.format,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.color = B.inkOnDark,
    this.size = 32,
  });
  final double value;
  final Duration duration;
  final Curve curve;
  final String Function(double v)? format;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: value, end: value),
      duration: duration,
      curve: curve,
      builder: (_, v, __) {
        final str = format != null ? format!(v) : v.toStringAsFixed(0);
        return Text(
          '$prefix$str$suffix',
          style: style ?? BType.solari(color: color, size: size),
        );
      },
    );
  }
}

// ───────────────────────────────────────────── BibleSparkline

class BibleSparkline extends StatelessWidget {
  const BibleSparkline({
    super.key,
    required this.values,
    required this.tone,
    this.height = 56,
    this.strokeWidth = 2,
    this.fill = true,
  });
  final List<double> values;
  final Color tone;
  final double height;
  final double strokeWidth;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _SparkPainter(
          values: values,
          tone: tone,
          strokeWidth: strokeWidth,
          fill: fill,
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.values,
    required this.tone,
    required this.strokeWidth,
    required this.fill,
  });
  final List<double> values;
  final Color tone;
  final double strokeWidth;
  final bool fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final range = (max - min).abs() < 1e-6 ? 1.0 : (max - min);
    final dx = size.width / (values.length - 1).clamp(1, 9999);

    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * dx;
      final norm = (values[i] - min) / range;
      final y = size.height - norm * (size.height - strokeWidth);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    if (fill) {
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              tone.withValues(alpha: 0.30),
              tone.withValues(alpha: 0),
            ],
          ).createShader(Offset.zero & size),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = tone
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      !identical(old.values, values) ||
      old.tone != tone ||
      old.strokeWidth != strokeWidth ||
      old.fill != fill;
}

// ───────────────────────────────────────────── BibleGlyphHalo

class BibleGlyphHalo extends StatelessWidget {
  const BibleGlyphHalo({
    super.key,
    required this.icon,
    this.tone = B.foilGold,
    this.size = 64,
    this.iconSize,
  });
  final IconData icon;
  final Color tone;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            tone.withValues(alpha: 0.30),
            tone.withValues(alpha: 0.08),
            tone.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        border: Border.all(
          color: tone.withValues(alpha: 0.45),
          width: 0.8,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize ?? size * 0.46, color: tone),
    );
  }
}

// ───────────────────────────────────────────── BibleGlowPulse

class BibleGlowPulse extends StatefulWidget {
  const BibleGlowPulse({
    super.key,
    required this.child,
    this.tone = B.jetCyan,
    this.period = B.barcodeBreath,
    this.maxBlur = 18,
  });
  final Widget child;
  final Color tone;
  final Duration period;
  final double maxBlur;

  @override
  State<BibleGlowPulse> createState() => _BibleGlowPulseState();
}

class _BibleGlowPulseState extends State<BibleGlowPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.period)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final phase = math.sin(_ctrl.value * 2 * math.pi) * 0.5 + 0.5;
        return DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.tone.withValues(alpha: 0.18 + 0.22 * phase),
                blurRadius: widget.maxBlur * (0.6 + 0.4 * phase),
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ───────────────────────────────────────────── BibleInfoRail

class BibleInfoEntry {
  const BibleInfoEntry({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color tone;
  final VoidCallback? onTap;
}

class BibleInfoRail extends StatelessWidget {
  const BibleInfoRail({super.key, required this.entries});
  final List<BibleInfoEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          Expanded(child: _Entry(entry: entries[i])),
          if (i != entries.length - 1)
            Container(
              width: 0.5,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: B.space2),
              color: B.hairlineLight,
            ),
        ],
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.entry});
  final BibleInfoEntry entry;
  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(entry.icon, size: 14, color: entry.tone),
            const SizedBox(width: B.space1),
            BText.eyebrow(entry.label, color: entry.tone),
          ],
        ),
        const SizedBox(height: B.space1),
        BText.mono(entry.value, size: 14),
      ],
    );
    if (entry.onTap == null) return body;
    return BiblePressable(onTap: entry.onTap, child: body);
  }
}

// ───────────────────────────────────────────── BiblePip

enum BiblePipState { pending, active, settled }

class BiblePip extends StatelessWidget {
  const BiblePip({
    super.key,
    required this.state,
    required this.tone,
    this.size = 8,
  });
  final BiblePipState state;
  final Color tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = state == BiblePipState.pending
        ? B.inkOnDarkFaint
        : (state == BiblePipState.active ? tone : tone.withValues(alpha: 0.7));
    return Container(
      width: state == BiblePipState.active ? size * 2.2 : size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size),
        boxShadow: state == BiblePipState.active
            ? [BoxShadow(color: tone.withValues(alpha: 0.5), blurRadius: 8)]
            : null,
      ),
    );
  }
}

class BiblePipStack extends StatelessWidget {
  const BiblePipStack({
    super.key,
    required this.pips,
    required this.tone,
    this.gap = B.space1,
  });
  final List<BiblePipState> pips;
  final Color tone;
  final double gap;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < pips.length; i++) ...[
          BiblePip(state: pips[i], tone: tone),
          if (i != pips.length - 1) SizedBox(width: gap),
        ],
      ],
    );
  }
}

// ───────────────────────────────────────────── BibleStatusPill

class BibleStatusPill extends StatelessWidget {
  const BibleStatusPill({
    super.key,
    required this.label,
    this.value,
    this.icon,
    this.tone = B.jetCyan,
    this.dense = false,
    this.breathing = false,
  });
  final String label;
  final String? value;
  final IconData? icon;
  final Color tone;
  final bool dense;
  final bool breathing;

  @override
  Widget build(BuildContext context) {
    final dot = _Dot(tone: tone, breathing: breathing);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? B.space2 : B.space3,
        vertical: dense ? B.space1 : B.space2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(B.rPill),
        color: tone.withValues(alpha: 0.10),
        border: Border.all(
          color: tone.withValues(alpha: 0.30),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: tone),
            const SizedBox(width: B.space1),
          ] else
            Padding(
              padding: const EdgeInsets.only(right: B.space2),
              child: dot,
            ),
          BText.monoCap(label, color: tone, size: dense ? 10 : 11),
          if (value != null) ...[
            const SizedBox(width: B.space2),
            Container(
              width: 0.5,
              height: 10,
              color: tone.withValues(alpha: 0.3),
            ),
            const SizedBox(width: B.space2),
            BText.mono(
              value!,
              color: B.inkOnDarkHigh,
              size: dense ? 11 : 12,
              weight: FontWeight.w600,
            ),
          ],
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.tone, required this.breathing});
  final Color tone;
  final bool breathing;
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: B.barcodeBreath,
    );
    if (widget.breathing) _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final phase = math.sin(_ctrl.value * 2 * math.pi) * 0.5 + 0.5;
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.tone,
            boxShadow: [
              BoxShadow(
                color: widget.tone.withValues(
                  alpha: 0.4 + 0.4 * phase,
                ),
                blurRadius: widget.breathing ? 6 + 6 * phase : 6,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────────────────────────── BiblePremiumHud

class BiblePremiumHud extends StatelessWidget {
  const BiblePremiumHud({
    super.key,
    required this.label,
    required this.value,
    this.tone = B.jetCyan,
    this.icon,
    this.breathing = true,
    this.onTap,
  });
  final String label;
  final String value;
  final Color tone;
  final IconData? icon;
  final bool breathing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = BibleStatusPill(
      label: label,
      value: value,
      icon: icon,
      tone: tone,
      breathing: breathing,
    );
    return onTap == null
        ? pill
        : BiblePressable(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap!();
            },
            child: pill,
          );
  }
}

// ───────────────────────────────────────────── BibleChip

class BibleChip extends StatelessWidget {
  const BibleChip({
    super.key,
    required this.label,
    this.icon,
    this.tone = B.inkOnDarkMid,
    this.dense = false,
  });
  final String label;
  final IconData? icon;
  final Color tone;
  final bool dense;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? B.space2 : B.space3,
        vertical: dense ? B.space1 : B.space2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(B.rPill),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: B.hairlineLight, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: tone),
            const SizedBox(width: B.space1),
          ],
          BText.monoCap(label, color: tone),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────── BibleProgressArc

class BibleProgressArc extends StatelessWidget {
  const BibleProgressArc({
    super.key,
    required this.value,
    required this.tone,
    this.diameter = 88,
    this.strokeWidth = 5,
    this.center,
    this.label,
  });
  final double value; // 0..1
  final Color tone;
  final double diameter;
  final double strokeWidth;
  final Widget? center;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: CustomPaint(
        painter: _ArcPainter(
          value: value.clamp(0.0, 1.0),
          tone: tone,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: center ??
              (label == null
                  ? BText.mono(
                      '${(value * 100).toStringAsFixed(0)}%',
                      size: diameter * 0.18,
                      color: B.inkOnDarkHigh,
                      weight: FontWeight.w700,
                    )
                  : BText.monoCap(label!, color: tone)),
        ),
      ),
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
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - strokeWidth,
    );
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi * 1.25, math.pi * 1.5, false, track);

    final progress = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi * 1.25,
        endAngle: math.pi * 0.25,
        colors: [tone.withValues(alpha: 0.4), tone],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi * 1.25,
      math.pi * 1.5 * value,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.value != value || old.tone != tone;
}

// ───────────────────────────────────────────── BibleTimeline

class BibleTimelineNode {
  const BibleTimelineNode({
    required this.title,
    this.caption,
    this.trailing,
    this.state = BiblePipState.pending,
    this.onTap,
  });
  final String title;
  final String? caption;
  final String? trailing;
  final BiblePipState state;
  final VoidCallback? onTap;
}

class BibleTimeline extends StatelessWidget {
  const BibleTimeline({
    super.key,
    required this.nodes,
    required this.tone,
  });
  final List<BibleTimelineNode> nodes;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < nodes.length; i++)
          _TLRow(
            node: nodes[i],
            tone: tone,
            isFirst: i == 0,
            isLast: i == nodes.length - 1,
          ),
      ],
    );
  }
}

class _TLRow extends StatelessWidget {
  const _TLRow({
    required this.node,
    required this.tone,
    required this.isFirst,
    required this.isLast,
  });
  final BibleTimelineNode node;
  final Color tone;
  final bool isFirst;
  final bool isLast;
  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: B.space2),
      child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!isFirst)
                  Container(
                    height: 6,
                    width: 1,
                    color: B.hairlineLight,
                  ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: node.state == BiblePipState.pending
                        ? Colors.transparent
                        : tone,
                    border: Border.all(
                      color: node.state == BiblePipState.pending
                          ? B.inkOnDarkFaint
                          : tone,
                      width: 1.4,
                    ),
                    boxShadow: node.state == BiblePipState.active
                        ? [
                            BoxShadow(
                              color: tone.withValues(alpha: 0.7),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: B.hairlineLight,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: B.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: BText.title(node.title, size: 15),
                    ),
                    if (node.trailing != null) BText.monoCap(node.trailing!),
                  ],
                ),
                if (node.caption != null) ...[
                  const SizedBox(height: B.space1),
                  BText.caption(node.caption!, color: B.inkOnDarkMid),
                ],
              ],
            ),
          ),
        ],
      ),
      ),
    );
    if (node.onTap == null) return row;
    return BiblePressable(onTap: node.onTap, child: row);
  }
}
