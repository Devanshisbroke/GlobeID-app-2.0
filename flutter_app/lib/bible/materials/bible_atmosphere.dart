import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../bible_tokens.dart';

/// GlobeID — **Atmosphere** material (§4.3, §4.1 _Living gradients_).
///
/// A 4-stop ambient gradient with one slowly animated stop. Period is
/// 30–90 s (default 72 s per Bible §4.1) — too slow to be noticed
/// consciously, fast enough that a returning glance feels different.
///
/// This is the root substrate for every Bible screen. It is *NOT* a
/// card. It is the room the cards float in.
///
/// Used for: globe, lock screen, onboarding, every scaffolded page.
class BibleAtmosphere extends StatefulWidget {
  const BibleAtmosphere({
    super.key,
    required this.child,
    this.emotion = BEmotion.stillness,
    this.tone,
    this.period = B.livingGradient,
    this.quality = BRenderQuality.normal,
    this.bloomIntensity = 1.0,
  });

  /// Subject placed on top of the atmosphere.
  final Widget child;

  /// Emotional register driving substrate + bloom colour.
  final BEmotion emotion;

  /// Optional override for the tone-bloom colour (≤6 % alpha is
  /// recommended). Defaults to the emotion's bloom.
  final Color? tone;

  /// Period of the gradient drift. Bible §4.1 calls for 30–90 s.
  final Duration period;

  /// Render quality. `reduced` snaps the animated stop to a static
  /// midpoint and disables the secondary bloom.
  final BRenderQuality quality;

  /// Multiplier on bloom alpha (0..1).
  final double bloomIntensity;

  @override
  State<BibleAtmosphere> createState() => _BibleAtmosphereState();
}

class _BibleAtmosphereState extends State<BibleAtmosphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.period);
    _maybeStart();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mq = MediaQuery.maybeOf(context);
    final newReduce = mq?.disableAnimations ?? false;
    if (newReduce != _reduceMotion) {
      _reduceMotion = newReduce;
      _maybeStart();
    }
  }

  void _maybeStart() {
    if (widget.quality == BRenderQuality.reduced || _reduceMotion) {
      _ctrl.stop();
      _ctrl.value = 0.5;
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant BibleAtmosphere oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      _ctrl.duration = widget.period;
    }
    if (oldWidget.quality != widget.quality) {
      _maybeStart();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.emotion.substrate;
    final bloom = (widget.tone ?? widget.emotion.bloom).withValues(
      alpha: (widget.tone ?? widget.emotion.bloom).a *
          widget.bloomIntensity.clamp(0.0, 1.4),
    );

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        // A 0..1 phase mapped through cosine for a soft pendulum.
        final phase = _reduceMotion ||
                widget.quality == BRenderQuality.reduced
            ? 0.5
            : (math.sin(_ctrl.value * 2 * math.pi) * 0.5 + 0.5);

        return Stack(
          children: [
            // Stop 1 — substrate base.
            Positioned.fill(
              child: ColoredBox(color: base),
            ),
            // Stop 2 — primary tone bloom (slowly drifts diagonally).
            Positioned.fill(
              child: CustomPaint(
                painter: _BloomPainter(
                  phase: phase,
                  tone: bloom,
                  emotion: widget.emotion,
                ),
              ),
            ),
            // Stop 3 — vignette to anchor the eye at center.
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.05),
                      radius: 1.4,
                      stops: [0.0, 0.65, 1.0],
                      colors: [
                        Color(0x00000000),
                        Color(0x33000000),
                        Color(0xCC000000),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Stop 4 — subject layer.
            widget.child,
          ],
        );
      },
    );
  }
}

class _BloomPainter extends CustomPainter {
  _BloomPainter({
    required this.phase,
    required this.tone,
    required this.emotion,
  });
  final double phase;
  final Color tone;
  final BEmotion emotion;

  @override
  void paint(Canvas canvas, Size size) {
    // Each emotional register parks the bloom at a different anchor.
    // Stillness → mid-upper. Anticipation → upper-right.
    // Activation → lower-right. Recovery → lower-left.
    final anchor = _anchor(emotion);
    // Drift +/- 30 px diagonally.
    final ax = anchor.dx * size.width + (phase * 60 - 30);
    final ay = anchor.dy * size.height + (phase * 60 - 30);

    final radius = size.shortestSide * 0.95;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          tone,
          tone.withValues(alpha: tone.a * 0.45),
          tone.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(ax, ay),
        radius: radius,
      ));

    canvas.drawRect(Offset.zero & size, paint);

    // Secondary, dimmer counter-bloom (mirrored) — adds depth.
    final cx = (1.0 - anchor.dx) * size.width + (phase * -40 + 20);
    final cy = (1.0 - anchor.dy) * size.height + (phase * -40 + 20);
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          tone.withValues(alpha: tone.a * 0.35),
          tone.withValues(alpha: 0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(cx, cy),
        radius: radius * 0.7,
      ));
    canvas.drawRect(Offset.zero & size, paint2);
  }

  Offset _anchor(BEmotion e) {
    switch (e) {
      case BEmotion.stillness:
        return const Offset(0.50, 0.12);
      case BEmotion.anticipation:
        return const Offset(0.85, 0.18);
      case BEmotion.activation:
        return const Offset(0.78, 0.78);
      case BEmotion.recovery:
        return const Offset(0.22, 0.78);
    }
  }

  @override
  bool shouldRepaint(covariant _BloomPainter old) =>
      old.phase != phase || old.tone != tone || old.emotion != emotion;

  @override
  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) => false;
}

/// `BibleAtmosphere` for accessibility tests — disables animation
/// regardless of MediaQuery so test goldens are deterministic.
class BibleAtmosphereStatic extends StatelessWidget {
  const BibleAtmosphereStatic({
    super.key,
    required this.child,
    this.emotion = BEmotion.stillness,
    this.tone,
  });
  final Widget child;
  final BEmotion emotion;
  final Color? tone;
  @override
  Widget build(BuildContext context) {
    return SemanticsConfiguration().isMergingSemanticsOfDescendants
        ? const SizedBox.shrink()
        : MediaQuery(
            data: MediaQuery.maybeOf(context)
                    ?.copyWith(disableAnimations: true) ??
                const MediaQueryData(disableAnimations: true),
            child: BibleAtmosphere(
              emotion: emotion,
              tone: tone,
              quality: BRenderQuality.reduced,
              child: child,
            ),
          );
  }
}
