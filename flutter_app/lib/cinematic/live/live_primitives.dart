import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../nexus/nexus_tokens.dart';

/// Shared cinematic primitives for the family of `*LiveScreen` surfaces
/// (passport, boarding pass, visa, forex, immigration, lounge, etc.).
///
/// Every Live screen renders on top of an OLED-black substrate with:
///
///   • An [AtmosphereBackdrop] — radial substrate glow tinted to the
///     vertical's tone (visa = ruby, forex = jade, immigration =
///     indigo, etc.).
///   • A [StarDustLayer] — drifting micro particles that animate at
///     6-second loops.
///   • A signature object substrate (visa booklet, banknote linen,
///     transit-card PETG, dossier vellum, etc.) painted via specialised
///     painters in `live_substrate.dart`.
///
/// Use [LiveCanvas] as the root scaffold of any Live screen — it wires
/// the atmosphere and stardust automatically and accepts a `child` for
/// the object itself.
class LiveCanvas extends StatefulWidget {
  const LiveCanvas({
    super.key,
    required this.tone,
    required this.child,
    this.bottomBar,
    this.statusBar,
    this.dustDensity = 1.0,
  });

  /// Vertical tone — the radial substrate is tinted with this colour.
  final Color tone;

  /// The object (visa, banknote, transit card, etc.) sits at the
  /// optical centre of the canvas.
  final Widget child;

  /// Optional pinned bottom CTA bar.
  final Widget? bottomBar;

  /// Optional top-pinned status bar (e.g. "EXPIRES IN 23 D · 14 H").
  final Widget? statusBar;

  /// Multiplier for the [StarDustLayer] density (1.0 = default, 0 = off).
  final double dustDensity;

  @override
  State<LiveCanvas> createState() => _LiveCanvasState();
}

class _LiveCanvasState extends State<LiveCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          AtmosphereBackdrop(tone: widget.tone),
          if (widget.dustDensity > 0)
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _ambient,
                  builder: (_, __) => CustomPaint(
                    isComplex: true,
                    willChange: true,
                    painter: _StarDustPainter(
                      t: _ambient.value,
                      density: widget.dustDensity,
                      tone: widget.tone,
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(N.s4, N.s2, N.s4, N.s2),
                child: Column(
                  children: [
                    if (widget.statusBar != null) widget.statusBar!,
                    Expanded(child: Center(child: widget.child)),
                    if (widget.bottomBar != null) widget.bottomBar!,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft radial substrate glow tinted to the vertical's tone. Sits
/// underneath everything; never animates so it stays cheap.
class AtmosphereBackdrop extends StatelessWidget {
  const AtmosphereBackdrop({super.key, required this.tone});

  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.45),
            radius: 1.25,
            colors: [
              tone.withValues(alpha: 0.22),
              tone.withValues(alpha: 0.06),
              Colors.black,
            ],
            stops: const [0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }
}

class _StarDustPainter extends CustomPainter {
  _StarDustPainter({
    required this.t,
    required this.density,
    required this.tone,
  });
  final double t;
  final double density;
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    final count = (160 * density).toInt();
    for (var i = 0; i < count; i++) {
      final px = rng.nextDouble();
      final py = rng.nextDouble();
      final phase = rng.nextDouble();
      final shimmer =
          0.32 + 0.42 * (0.5 + 0.5 * math.sin(2 * math.pi * (t + phase)));
      final r = 0.4 + rng.nextDouble() * 1.4;
      final p = Paint()
        ..color = (rng.nextBool() ? Colors.white : tone)
            .withValues(alpha: shimmer * 0.22);
      canvas.drawCircle(Offset(px * size.width, py * size.height), r, p);
    }
  }

  @override
  bool shouldRepaint(covariant _StarDustPainter old) =>
      old.t != t || old.density != density || old.tone != tone;
}

/// Foil styling style — used to pick the holo sweep gradient.
///
/// Each style stays inside the calm cinematic palette — gold remains
/// dominant in every preset, the variants only introduce a *subtle*
/// hue shift so the foil reads as authentic security holography
/// rather than a flat single-stop sweep.
enum HolographicFoilStyle {
  /// Classic gold sweep — the default. Backwards-compatible.
  gold,

  /// Gold with subtle ice / amber hue shifts at the edges. Used for
  /// passport-grade credentials where the foil should suggest
  /// optically-variable security ink.
  iridescent,

  /// Cooler aurora variant — gold core with cyan and violet
  /// highlights. Reserved for digital-only credentials (transit
  /// passes, eVisas, NFC seals).
  aurora,
}

/// Resolves a [HolographicFoilStyle] to a gradient color stack.
List<Color> _foilStops(HolographicFoilStyle style) {
  switch (style) {
    case HolographicFoilStyle.gold:
      return const [
        Color(0x00FFFFFF),
        Color(0x33D4AF37),
        Color(0x55E3C083),
        Color(0x33D4AF37),
        Color(0x00FFFFFF),
      ];
    case HolographicFoilStyle.iridescent:
      // Gold-dominant but with a hint of ice at the leading edge and
      // amber at the trailing edge so the sweep reads as security
      // foil that catches light at multiple angles.
      return const [
        Color(0x00FFFFFF),
        Color(0x1A66B7FF), // ice highlight
        Color(0x44D4AF37), // primary gold
        Color(0x60E9C75D), // hot gold core
        Color(0x44D4AF37),
        Color(0x1AE3C083), // warm amber tail
        Color(0x00FFFFFF),
      ];
    case HolographicFoilStyle.aurora:
      // Cooler variant for digital credentials. Gold still leads but
      // cyan + violet bookend the sweep so the foil reads as digital
      // holography rather than printed gold.
      return const [
        Color(0x00FFFFFF),
        Color(0x2266B7FF), // cyan
        Color(0x44D4AF37), // gold
        Color(0x55E9C75D),
        Color(0x44D4AF37),
        Color(0x229B6FE3), // violet
        Color(0x00FFFFFF),
      ];
  }
}

/// A persistent horizontal foil sweep that animates left-to-right over
/// any child. Used for the holographic mark on visa pages, banknotes
/// and credentials.
///
/// Provide either an explicit [colors] gradient (full control) or pick
/// a preset [style]. When both are omitted the default is
/// [HolographicFoilStyle.gold] — identical to the pre-refinement
/// behavior.
class HolographicFoil extends StatefulWidget {
  const HolographicFoil({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 6),
    this.colors,
    this.style = HolographicFoilStyle.gold,
    this.secondarySweep = false,
    this.radial = false,
    this.tilt = Offset.zero,
  });

  final Widget child;
  final Duration duration;

  /// Explicit gradient stops. When non-null overrides [style].
  final List<Color>? colors;

  /// One of [HolographicFoilStyle.gold] / [iridescent] / [aurora].
  /// Ignored when [colors] is provided.
  final HolographicFoilStyle style;

  /// When true, paints a second, slower, counter-direction sweep on
  /// top of the primary one. Doubles the GPU cost of the foil layer
  /// so reserve it for hero credentials (passport bearer page,
  /// premium boarding pass).
  final bool secondarySweep;

  /// When true, the sweep is rendered as a radial gradient whose
  /// focal point orbits the credential center instead of sweeping
  /// linearly. Used for the most cinematic credentials (visa hero
  /// stamp, passport bearer page) where the foil should read as a
  /// concentrated holographic seal rather than a sweep.
  final bool radial;

  /// Device / gesture tilt offset (typically `dx,dy` in `[-1, 1]`).
  /// When non-zero, the sweep direction rotates with the tilt — the
  /// foil reads as "catching the light" because the highlight follows
  /// the user's physical tilt, matching how a real holographic
  /// security ink looks when you tilt a passport.
  ///
  /// For linear sweeps, `tilt.dx` shifts the sweep phase and
  /// `tilt.dy` rotates the sweep axis. For radial sweeps, the tilt
  /// nudges the focal-point orbit offset.
  final Offset tilt;

  @override
  State<HolographicFoil> createState() => _HolographicFoilState();
}

class _HolographicFoilState extends State<HolographicFoil>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stops = widget.colors ?? _foilStops(widget.style);
    // Isolate the per-frame shader pass in its own repaint layer so
    // siblings (text, decoration, icons) don't repaint at the holo
    // sweep cadence.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = _c.value;
          // Tilt influence — small magnitudes so a calm tilt nudges
          // the sweep, an aggressive tilt swings it noticeably. Both
          // axes are clamped because gesture deltas occasionally
          // overshoot the design `[-1, 1]` range.
          final tx = widget.tilt.dx.clamp(-1.0, 1.0);
          final ty = widget.tilt.dy.clamp(-1.0, 1.0);
          Widget sweep;
          if (widget.radial) {
            // Radial holographic sweep — the focal point orbits the
            // credential's center on a small circle so the highlight
            // reads as a concentrated optically-variable seal instead
            // of a linear sweep. Used for hero credentials.
            //
            // Tilt nudges the orbit's offset so when the user tilts
            // the device, the focal highlight follows the tilt.
            final theta = t * 2 * math.pi;
            final fx = math.cos(theta) * 0.35 + tx * 0.20;
            final fy = math.sin(theta) * 0.35 + ty * 0.20;
            sweep = ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                return RadialGradient(
                  center: const Alignment(0, 0),
                  focal: Alignment(fx.clamp(-0.6, 0.6), fy.clamp(-0.6, 0.6)),
                  focalRadius: 0.05,
                  radius: 0.9,
                  colors: stops,
                ).createShader(bounds);
              },
              child: child,
            );
          } else {
            // Linear sweep with tilt — tx shifts the phase forward
            // along the sweep axis (so the highlight appears to move
            // toward where the user has tilted), ty rotates the axis
            // slightly off-horizontal so vertical tilt is also felt.
            final phase = t * 2.8 + tx * 0.45;
            final yawDelta = ty * 0.30;
            sweep = ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment(-1.4 + phase, -0.3 + yawDelta),
                  end: Alignment(-0.4 + phase, 0.3 + yawDelta),
                  colors: stops,
                ).createShader(bounds);
              },
              child: child,
            );
          }
          if (widget.secondarySweep && !widget.radial) {
            // Counter-sweep at a slower, offset phase — gives the
            // foil a second highlight band so credentials read as
            // genuinely holographic instead of a single linear
            // wipe. Both sweeps share the same color stack so the
            // tonal floor stays calm. Counter-sweep also follows
            // the tilt, but mirrored, so the two highlights split
            // around the tilt center.
            final t2 = (t * 0.55 + 0.5) % 1.0;
            final phase2 = t2 * 2.8 - tx * 0.45;
            final yawDelta2 = -ty * 0.30;
            sweep = ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment(1.4 - phase2, 0.4 + yawDelta2),
                  end: Alignment(0.4 - phase2, -0.4 + yawDelta2),
                  colors: stops,
                ).createShader(bounds);
              },
              child: sweep,
            );
          }
          return sweep;
        },
        child: widget.child,
      ),
    );
  }
}

/// OVI (optically variable ink) disc — a small holographic seal that
/// shifts hue as a value (typically `0..1`) advances. The disc has a
/// metallic ring, a central glyph, and a subtle parallax shimmer.
class OviSeal extends StatelessWidget {
  const OviSeal({
    super.key,
    required this.icon,
    required this.tone,
    this.size = 64,
    this.label,
  });

  final IconData icon;
  final Color tone;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                tone.withValues(alpha: 0.95),
                N.tierGoldHi.withValues(alpha: 0.85),
                tone.withValues(alpha: 0.65),
                N.tierGold.withValues(alpha: 0.85),
                tone.withValues(alpha: 0.95),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
          child: Center(
            child: Container(
              width: size * 0.68,
              height: size * 0.68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.55),
              ),
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.96),
                size: size * 0.36,
              ),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 6),
          Text(
            label!,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              fontSize: 9,
            ),
          ),
        ],
      ],
    );
  }
}

/// MRZ-style monospace strip used at the foot of passports, visas and
/// boarding passes. Renders fixed-width chevron-separated codes.
class MrzStrip extends StatelessWidget {
  const MrzStrip({super.key, required this.lines, this.tone = Colors.white});
  final List<String> lines;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: N.s4, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                line,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  letterSpacing: 1.4,
                  color: tone.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A small typographic field block used inside passports, visas,
/// boarding passes — "FIELD" eyebrow + value.
class FieldBlock extends StatelessWidget {
  const FieldBlock({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
    this.tone,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.valueSize = 16,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Color? tone;
  final CrossAxisAlignment crossAxisAlignment;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    final eyebrowColor = (tone ?? Colors.white).withValues(alpha: 0.72);
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          style: TextStyle(
            color: eyebrowColor,
            fontWeight: FontWeight.w800,
            fontSize: 8,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w800,
            fontSize: valueSize,
            letterSpacing: 0.3,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// A 1-line status pill — `STATE · VALUE` — used in countdowns and
/// live-state bars on Live screens.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.icon,
    required this.label,
    required this.tone,
    this.dense = false,
  });

  final IconData icon;
  final String label;
  final Color tone;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 12,
        vertical: dense ? 5 : 7,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(N.rPill),
        color: tone.withValues(alpha: 0.14),
        border: Border.all(
          color: tone.withValues(alpha: 0.40),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: tone, size: dense ? 11 : 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: dense ? 10 : 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom CTA used at the foot of a Live screen. Tappable, gradient
/// gold fill (the only place gold accents survive at full saturation).
class LiveCta extends StatelessWidget {
  const LiveCta({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.secondary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        decoration: BoxDecoration(
          gradient: secondary
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFE9C75D)],
                ),
          color: secondary ? Colors.white.withValues(alpha: 0.06) : null,
          borderRadius: BorderRadius.circular(N.rPill),
          border: Border.all(
            color: secondary
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.transparent,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: secondary ? Colors.white : Colors.black87,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: secondary ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live ticking countdown that re-renders every second. Returns the
/// rendered string via [builder] so the caller can style it however
/// they like (mono ticker, large hero, etc.).
class LiveCountdown extends StatefulWidget {
  const LiveCountdown({
    super.key,
    required this.target,
    required this.builder,
  });

  final DateTime target;
  final Widget Function(BuildContext, Duration remaining) builder;

  @override
  State<LiveCountdown> createState() => _LiveCountdownState();
}

class _LiveCountdownState extends State<LiveCountdown> {
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.target.difference(DateTime.now());
    _tick();
  }

  void _tick() async {
    while (mounted) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        _remaining = widget.target.difference(DateTime.now());
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _remaining);
}

/// Animated breathing ring that pulses radius gently — used as
/// "alive" ambient lighting behind a primary signal (eGate ready,
/// boarding active, scanning idle).
class BreathingRing extends StatefulWidget {
  const BreathingRing({
    super.key,
    required this.tone,
    this.size = 220,
    this.strokeWidth = 1.5,
    this.duration = const Duration(milliseconds: 2400),
  });

  final Color tone;
  final double size;
  final double strokeWidth;
  final Duration duration;

  @override
  State<BreathingRing> createState() => _BreathingRingState();
}

class _BreathingRingState extends State<BreathingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Breathing ring repaints every frame on the AnimationController
    // tick. Isolate it so the surrounding hero / chrome stays static
    // and we only flush this small dirty rect.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = (math.sin(_c.value * math.pi * 2) + 1) / 2;
          final extra = 14.0 * t;
          return CustomPaint(
            size: Size(widget.size + extra, widget.size + extra),
            painter: _RingPainter(
              tone: widget.tone,
              strokeWidth: widget.strokeWidth,
              alpha: 0.20 + 0.40 * t,
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.tone,
    required this.strokeWidth,
    required this.alpha,
  });
  final Color tone;
  final double strokeWidth;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = tone.withValues(alpha: alpha)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      math.min(size.width, size.height) / 2 - strokeWidth,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.alpha != alpha || old.tone != tone || old.strokeWidth != strokeWidth;
}

/// A horizontally scrolling ticker that loops [items] endlessly.
/// Used for spot-rate strips, customs advisories and country alerts.
class LiveTicker extends StatefulWidget {
  const LiveTicker({
    super.key,
    required this.items,
    this.speed = 40.0,
    this.height = 28,
    this.tone = Colors.white,
  });

  final List<String> items;
  final double speed; // px / second
  final double height;
  final Color tone;

  @override
  State<LiveTicker> createState() => _LiveTickerState();
}

class _LiveTickerState extends State<LiveTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.items.join('   ·   ');
    // Isolate the marquee's translation in its own repaint layer so
    // surrounding chrome doesn't repaint at the scroll cadence.
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedBuilder(
                animation: _c,
                builder: (_, __) {
                  final offset = -(_c.value * constraints.maxWidth * 1.5);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: offset,
                        top: 0,
                        child: Row(
                          children: [
                            Text(
                              '$text   ·   $text   ·   $text',
                              style: TextStyle(
                                color: widget.tone.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 1.4,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Tilt-aware parallax wrapper. Reads gyro through a passed-in
/// `tiltOffset` and translates the child along x/y. Lets the caller
/// own the sensor stream so we don't double-subscribe across screens.
class TiltParallax extends StatelessWidget {
  const TiltParallax({
    super.key,
    required this.child,
    required this.tilt,
    this.depth = 8,
  });

  final Widget child;
  final Offset tilt;
  final double depth;

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(tilt.dx * 0.08)
        ..rotateX(-tilt.dy * 0.08)
        ..translateByDouble(tilt.dx * depth, tilt.dy * depth, 0.0, 1.0),
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// One layer in a [LayeredParallax] stack. Each layer translates at
/// its own `depth` so the entire scene reads as a 3D stack rather
/// than a single flat plane.
class ParallaxLayer {
  const ParallaxLayer({required this.child, this.depth = 8});

  /// The widget painted at this depth. The list order = paint order
  /// (first child = back, last child = front).
  final Widget child;

  /// Translation magnitude in logical px per unit of tilt. Suggested
  /// values: 2-4 for background substrates, 6-10 for primary
  /// content, 12-18 for hero seals / glyphs. Deeper layers move
  /// more, which reads as "closer to the viewer".
  final double depth;
}

/// Multi-depth parallax stack — translates each layer at its own
/// depth so the scene reads as a 3D stack instead of a single flat
/// plane.
///
/// The whole stack rotates together (subtle perspective tilt) but
/// each layer slides at its own magnitude — so foil, text and seal
/// drift at different speeds when the user tilts the device. Drop-in
/// next to [TiltParallax]; that single-layer wrapper stays for
/// callers that don't need depth stacking.
class LayeredParallax extends StatelessWidget {
  const LayeredParallax({
    super.key,
    required this.tilt,
    required this.layers,
    this.perspective = 0.001,
    this.rotateScale = 0.06,
  });

  /// Tilt offset (typically derived from gyroscope x/y deltas).
  final Offset tilt;

  /// Layers, back-to-front (first child painted first).
  final List<ParallaxLayer> layers;

  /// Perspective entry for the shared Matrix4. Lower = flatter
  /// scene. Default 0.001 (matches [TiltParallax]).
  final double perspective;

  /// Rotation magnitude applied to the whole stack. Default 0.06 —
  /// slightly subtler than [TiltParallax]'s 0.08 because the layer
  /// drift already does most of the depth work.
  final double rotateScale;

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, perspective)
        ..rotateY(tilt.dx * rotateScale)
        ..rotateX(-tilt.dy * rotateScale),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final layer in layers)
            Transform.translate(
              offset: Offset(
                tilt.dx * layer.depth,
                tilt.dy * layer.depth,
              ),
              child: layer.child,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// GLOBEID SIGNATURE MARK
// ─────────────────────────────────────────────────────────────────────

/// Discreet GlobeID signature mark — a hairline gold rule + 9 px
/// mono-cap watermark — pressed into every Live credential so the
/// object reads as "manufactured by GlobeID" rather than a generic
/// digital card.
///
/// Drop this into the corner of any Live substrate (passport, visa,
/// banknote, transit card, lounge pass, dossier). Stays subtle so
/// it never competes with the credential's primary content — the
/// gold accent is alpha 0.55, the text alpha 0.62.
class GlobeIdSignature extends StatelessWidget {
  const GlobeIdSignature({
    super.key,
    this.label = 'GLOBE\u00B7ID',
    this.serial,
    this.alignment = Alignment.bottomRight,
    this.scale = 1.0,
    this.tone,
  });

  /// Watermark label. Defaults to the canonical `GLOBE·ID` glyph.
  final String label;

  /// Optional micro-serial appended after the label — e.g.
  /// `GBL-7Q3·24M`. Mono, tabular figures.
  final String? serial;

  /// Where the mark sits relative to its parent (corner).
  final Alignment alignment;

  /// Size multiplier. 1.0 ≈ 9 px text; bump for hero credentials.
  final double scale;

  /// Override the accent rule tone. Defaults to GlobeID gold.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final accent = (tone ?? const Color(0xFFD4AF37)).withValues(alpha: 0.55);
    final textColor = Colors.white.withValues(alpha: 0.62);
    final fontSize = 9.0 * scale;
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hairline gold rule.
            Container(
              width: 14 * scale,
              height: 1,
              color: accent,
            ),
            const SizedBox(width: 6),
            Text(
              serial == null ? label : '$label  $serial',
              style: TextStyle(
                color: textColor,
                fontFeatures: const [FontFeature.tabularFigures()],
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// LIVE SURFACE STATE
// ─────────────────────────────────────────────────────────────────────

/// State that any "live" surface (Live Passport, Live Boarding, Live
/// Visa, Live Forex, Live Transit, Live Lounge, Live Country Intel)
/// may be in at a given moment.
///
/// The states form a small ladder. They are *expressive*, not
/// behavioral — a surface may move between them visually (e.g. via a
/// [LiveStateBeacon]) without changing what it functionally does.
enum LiveSurfaceState {
  /// Default. The surface is hydrated and showing live data but the
  /// user has not interacted with it yet.
  idle,

  /// User intent has been detected (long-press began, scroll-to-arm
  /// crossed a threshold, NFC field detected). Visual cue: soft
  /// tonal pulse, ring brighten.
  armed,

  /// The committing transition is in flight — the surface has
  /// accepted the gesture and is rendering its consequential state
  /// (boarding gate live, immigration eGate primed, forex pinned).
  active,

  /// The commit has just landed. Reserved for the brief reveal
  /// frames after [active]. Used to drive signature haptics + a
  /// single hero pulse.
  committed,

  /// Steady-state after [committed]. The surface stays alive but
  /// the cinematic reveal has settled.
  settled,
}

/// Semantic descriptor of a [LiveSurfaceState]. Lets call sites read
/// e.g. `state.label` for the mono-cap chip text without sprinkling
/// switches across the codebase.
extension LiveSurfaceStateX on LiveSurfaceState {
  /// Mono-cap label suitable for a hairline chip ("IDLE" / "ARMED"
  /// / "LIVE" / "COMMITTED" / "SETTLED").
  String get label {
    switch (this) {
      case LiveSurfaceState.idle:
        return 'IDLE';
      case LiveSurfaceState.armed:
        return 'ARMED';
      case LiveSurfaceState.active:
        return 'LIVE';
      case LiveSurfaceState.committed:
        return 'COMMITTED';
      case LiveSurfaceState.settled:
        return 'SETTLED';
    }
  }

  /// Alpha multiplier for the state's accent glow. Lets a beacon
  /// derive its current intensity without a switch in the caller.
  double get glowAlpha {
    switch (this) {
      case LiveSurfaceState.idle:
        return 0.18;
      case LiveSurfaceState.armed:
        return 0.42;
      case LiveSurfaceState.active:
        return 0.62;
      case LiveSurfaceState.committed:
        return 0.78;
      case LiveSurfaceState.settled:
        return 0.32;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// NFC PULSE — the chip-is-live signal
// ─────────────────────────────────────────────────────────────────────

/// A faint radial pulse that radiates outward from an NFC / chip /
/// contactless icon at a heart-rate cadence — communicating "this
/// credential is awake, tap me" without the noise of a constantly
/// animated background.
///
/// Used on Transit Passes, Lounge member cards, and the OVI seal on
/// hero credentials. The pulse renders BEHIND the icon (so it doesn't
/// obscure anything) and the icon is passed in as the [child].
class NfcPulse extends StatefulWidget {
  const NfcPulse({
    super.key,
    required this.child,
    this.tone,
    this.size = 56,
    this.period = const Duration(milliseconds: 1400),
    this.rings = 2,
    this.maxAlpha = 0.55,
  });

  /// The chip / NFC / wave icon to render at the centre.
  final Widget child;

  /// Pulse ring colour. Defaults to GlobeID hot gold.
  final Color? tone;

  /// Total widget footprint (square). The pulse rings extend to this
  /// outer radius at peak.
  final double size;

  /// One full pulse cycle. Default ~1.4 s — slightly faster than a
  /// resting heart-beat, in the cadence band that reads as "alert".
  final Duration period;

  /// How many overlapping rings echo outward. 1 = a single pulse,
  /// 2 = a stacked pair offset by half a phase (richer cadence),
  /// 3+ gets noisy.
  final int rings;

  /// Peak ring alpha at the brightest frame.
  final double maxAlpha;

  @override
  State<NfcPulse> createState() => _NfcPulseState();
}

class _NfcPulseState extends State<NfcPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tone = widget.tone ?? const Color(0xFFE9C75D);
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) {
            return CustomPaint(
              painter: _NfcPulsePainter(
                t: _c.value,
                tone: tone,
                rings: widget.rings,
                maxAlpha: widget.maxAlpha,
              ),
              child: child,
            );
          },
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

class _NfcPulsePainter extends CustomPainter {
  _NfcPulsePainter({
    required this.t,
    required this.tone,
    required this.rings,
    required this.maxAlpha,
  });

  final double t;
  final Color tone;
  final int rings;
  final double maxAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide / 2;
    for (var i = 0; i < rings; i++) {
      // Each ring is offset by 1/rings of a phase so the pulses
      // stack in a continuous echo instead of all pulsing in unison.
      final phase = (t + i / rings) % 1.0;
      final radius = maxR * (0.35 + 0.65 * phase);
      // Alpha eases in then out — peaks at phase 0.35.
      final fade = (1 - phase) * (phase < 0.15 ? phase / 0.15 : 1);
      final alpha = (maxAlpha * fade).clamp(0.0, 1.0);
      if (alpha <= 0.01) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + 0.6 * (1 - phase)
        ..color = tone.withValues(alpha: alpha);
      canvas.drawCircle(centre, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NfcPulsePainter old) =>
      old.t != t ||
      old.tone != tone ||
      old.rings != rings ||
      old.maxAlpha != maxAlpha;
}

// ─────────────────────────────────────────────────────────────────────
// LIVE STATUS PILL — cinematic state ladder badge
// ─────────────────────────────────────────────────────────────────────

/// A hairline mono-cap pill that shows the current [LiveSurfaceState]
/// — IDLE / ARMED / LIVE / COMMITTED / SETTLED. The pill border and
/// dot pulse at the state's [LiveSurfaceState.glowAlpha], so the eye
/// reads the cinematic ladder without any explicit indicator.
///
/// Drop this into the top-right of any Live surface as a "what's
/// happening" badge. Subtle by design.
class LiveStatusPill extends StatefulWidget {
  const LiveStatusPill({
    super.key,
    required this.state,
    this.tone,
    this.compact = true,
  });

  final LiveSurfaceState state;

  /// Accent tone for the dot + ring. Defaults to GlobeID gold.
  final Color? tone;

  /// When true (default) the pill is tight enough for a credential
  /// corner; when false it adopts a slightly more generous footprint
  /// for a dossier header.
  final bool compact;

  @override
  State<LiveStatusPill> createState() => _LiveStatusPillState();
}

class _LiveStatusPillState extends State<LiveStatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tone = widget.tone ?? const Color(0xFFE9C75D);
    final base = widget.state.glowAlpha;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          // Pulse breathes ±18% around the base glow — gentle, never
          // fully extinguished. ARMED / LIVE / COMMITTED all read
          // brighter than IDLE / SETTLED at their dimmest frame.
          final amp = 0.18 * base;
          final pulse = (base + math.sin(_c.value * math.pi) * amp)
              .clamp(0.06, 0.95);
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 8 : 10,
              vertical: widget.compact ? 4 : 5,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.42),
              border: Border.all(
                color: tone.withValues(alpha: pulse * 0.85),
                width: 0.6,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tone.withValues(alpha: pulse),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.state.label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w900,
                    fontSize: widget.compact ? 8.5 : 9.5,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// LIVE LIFT — credentials float off the OLED substrate
// ─────────────────────────────────────────────────────────────────────

/// Single-frame attention pulse triggered when a Live data field
/// changes — gate-change on a boarding pass, rate-spike on a forex
/// banknote, advisory escalation on a country dossier, queue depth
/// shift on immigration. Emits one full pulse on demand, then
/// settles.
///
/// Wrap any widget that displays mutating live data; call
/// `LiveDataPulseController.pulse()` from outside (e.g. when a
/// provider value changes) to fire one cinematic moment.
class LiveDataPulseController extends ChangeNotifier {
  int _gen = 0;
  int get generation => _gen;

  /// Fire one pulse — the wrapped widget will flash on next frame.
  void pulse() {
    _gen++;
    notifyListeners();
  }
}

/// Wraps a child in a one-shot tonal glow pulse — triggered by a
/// [LiveDataPulseController]. The pulse halos the child's bounds
/// for 600 ms with a tonal accent, then fades.
class LiveDataPulse extends StatefulWidget {
  const LiveDataPulse({
    super.key,
    required this.controller,
    required this.child,
    this.tone,
    this.duration = const Duration(milliseconds: 600),
  });

  final LiveDataPulseController controller;
  final Widget child;
  final Color? tone;
  final Duration duration;

  @override
  State<LiveDataPulse> createState() => _LiveDataPulseState();
}

class _LiveDataPulseState extends State<LiveDataPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  int _lastGen = 0;

  @override
  void initState() {
    super.initState();
    _lastGen = widget.controller.generation;
    widget.controller.addListener(_onPulse);
  }

  @override
  void didUpdateWidget(LiveDataPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onPulse);
      widget.controller.addListener(_onPulse);
    }
  }

  void _onPulse() {
    if (widget.controller.generation == _lastGen) return;
    _lastGen = widget.controller.generation;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPulse);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tone = widget.tone ?? const Color(0xFFE9C75D);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        // Pulse profile: ease-out shimmer. Alpha rises quickly to
        // peak at t=0.25 then fades by t=1.
        final t = _c.value;
        final alpha =
            t == 0 ? 0.0 : (t < 0.25 ? t / 0.25 : (1 - t) / 0.75);
        return DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: alpha > 0.01
                ? [
                    BoxShadow(
                      color: tone.withValues(alpha: alpha * 0.65),
                      blurRadius: 18 + 26 * t,
                      spreadRadius: -2 + 4 * t,
                    ),
                  ]
                : const [],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// ORBITAL PERKS — tiny dots orbit a seal to show active perks
// ─────────────────────────────────────────────────────────────────────

/// A configurable number of small dots that orbit around the child
/// at a fixed [radius]. Each dot can carry its own tone, so this is
/// used on the Lounge OVI seal to show which perks (shower, food,
/// fast-track, wifi) are active. Slow ~6 s period — ambient, not
/// attention-grabbing.
class OrbitalPerks extends StatefulWidget {
  const OrbitalPerks({
    super.key,
    required this.child,
    required this.tones,
    this.radius = 32,
    this.dotSize = 4,
    this.period = const Duration(seconds: 6),
  });

  final Widget child;

  /// One tone per orbiting dot — tone list length defines count.
  final List<Color> tones;
  final double radius;
  final double dotSize;
  final Duration period;

  @override
  State<OrbitalPerks> createState() => _OrbitalPerksState();
}

class _OrbitalPerksState extends State<OrbitalPerks>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.tones.length;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          return CustomPaint(
            painter: _OrbitalPerksPainter(
              t: _c.value,
              tones: widget.tones,
              radius: widget.radius,
              dotSize: widget.dotSize,
              count: n,
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _OrbitalPerksPainter extends CustomPainter {
  _OrbitalPerksPainter({
    required this.t,
    required this.tones,
    required this.radius,
    required this.dotSize,
    required this.count,
  });
  final double t;
  final List<Color> tones;
  final double radius;
  final double dotSize;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    if (count == 0) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    for (var i = 0; i < count; i++) {
      // Phase offset so dots fan out evenly around the orbit.
      final phase = (t + i / count) % 1.0;
      final theta = phase * 2 * math.pi;
      final x = cx + radius * math.cos(theta);
      final y = cy + radius * math.sin(theta);
      final paint = Paint()
        ..color = tones[i].withValues(alpha: 0.78)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), dotSize, paint);
      // Soft trailing glow.
      canvas.drawCircle(
        Offset(x, y),
        dotSize * 2,
        Paint()..color = tones[i].withValues(alpha: 0.14),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitalPerksPainter old) =>
      old.t != t ||
      old.tones.length != tones.length ||
      old.radius != radius ||
      old.dotSize != dotSize;
}

// ─────────────────────────────────────────────────────────────────────
// PASSPORT BOOKMARK RIBBON — red silk ribbon flutters off the page edge
// ─────────────────────────────────────────────────────────────────────

/// A small silk-ribbon bookmark that hangs off the right edge of an
/// open passport / dossier. Flutters very gently (4s period, 6°
/// rotation amplitude) so it reads as a real object hanging from a
/// real book. Place inside a Stack at the top-right corner of the
/// open page.
class PassportRibbonBookmark extends StatefulWidget {
  const PassportRibbonBookmark({
    super.key,
    this.tone = const Color(0xFFB72424),
    this.length = 80,
    this.width = 10,
    this.period = const Duration(seconds: 4),
  });

  final Color tone;
  final double length;
  final double width;
  final Duration period;

  @override
  State<PassportRibbonBookmark> createState() =>
      _PassportRibbonBookmarkState();
}

class _PassportRibbonBookmarkState extends State<PassportRibbonBookmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final eased =
              math.sin(_c.value * math.pi); // 0 → 1 → 0
          final tilt = (eased - 0.5) * (math.pi / 30); // ±6°
          return Transform.rotate(
            angle: tilt,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: widget.width,
              height: widget.length,
              child: CustomPaint(
                painter: _RibbonPainter(
                  tone: widget.tone,
                  width: widget.width,
                  length: widget.length,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  _RibbonPainter({
    required this.tone,
    required this.width,
    required this.length,
  });
  final Color tone;
  final double width;
  final double length;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, width, length);
    // Silk gradient — slightly darker in the center for a shadow
    // fold.
    final gradient = LinearGradient(
      colors: [
        tone.withValues(alpha: 0.92),
        tone,
        tone.withValues(alpha: 0.72),
        tone,
      ],
      stops: const [0.0, 0.35, 0.65, 1.0],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // Forked V-cut at the bottom for a real ribbon end.
    final path = Path()
      ..moveTo(0, length)
      ..lineTo(width / 2, length - width)
      ..lineTo(width, length)
      ..lineTo(width, length - 0.5)
      ..lineTo(0, length - 0.5)
      ..close();
    canvas.drawPath(
        path, Paint()..color = Colors.black.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter old) =>
      old.tone != tone || old.width != width || old.length != length;
}

// ─────────────────────────────────────────────────────────────────────
// GLOBEID WATERMARK DRIFT — subliminal manufactured-by signature
// ─────────────────────────────────────────────────────────────────────

/// A very faint, slowly-drifting GLOBE·ID watermark layer for the
/// background of any Live substrate. Acts as the subliminal
/// "manufactured by GlobeID" signature — your eye never catches it
/// at rest, but the brain registers the slow drift as a sign of
/// life. Period defaults to 40 seconds (one full crossing) so the
/// motion is well below conscious threshold.
///
/// Stack this *behind* substrate content (depth ~ 1).
class GlobeIdWatermarkDrift extends StatefulWidget {
  const GlobeIdWatermarkDrift({
    super.key,
    this.text = 'GLOBE\u00b7ID',
    this.tone,
    this.alpha = 0.05,
    this.fontSize = 60,
    this.period = const Duration(seconds: 40),
  });

  final String text;
  final Color? tone;
  final double alpha;
  final double fontSize;
  final Duration period;

  @override
  State<GlobeIdWatermarkDrift> createState() => _GlobeIdWatermarkDriftState();
}

class _GlobeIdWatermarkDriftState extends State<GlobeIdWatermarkDrift>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tone = (widget.tone ?? const Color(0xFFE9C75D))
        .withValues(alpha: widget.alpha);
    return IgnorePointer(
      ignoring: true,
      child: ClipRect(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              return CustomPaint(
                painter: _GlobeIdWatermarkPainter(
                  t: _c.value,
                  tone: tone,
                  text: widget.text,
                  fontSize: widget.fontSize,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GlobeIdWatermarkPainter extends CustomPainter {
  _GlobeIdWatermarkPainter({
    required this.t,
    required this.tone,
    required this.text,
    required this.fontSize,
  });
  final double t;
  final Color tone;
  final String text;
  final double fontSize;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: tone,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: fontSize * 0.12,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Drift diagonally — slow translation, no rotation. Wrap with
    // two copies so the seam never lands inside the visible bounds.
    final dx = -tp.width + (size.width + tp.width * 2) * t;
    final dy = size.height * 0.5 - tp.height / 2;

    canvas.save();
    canvas.translate(dx, dy);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlobeIdWatermarkPainter old) =>
      old.t != t ||
      old.tone != tone ||
      old.text != text ||
      old.fontSize != fontSize;
}

// ─────────────────────────────────────────────────────────────────────
// BREATHING HALO — state-driven ambient pulse around any child
// ─────────────────────────────────────────────────────────────────────

/// A soft tonal halo that breathes around its child at a cadence
/// determined by [state] (slow at IDLE, fast at ACTIVE, single-pulse
/// at COMMITTED, settled back to slow at SETTLED). Lives off-screen
/// of the credential proper — drop it behind a Live surface to
/// signal aliveness without altering the substrate.
class BreathingHalo extends StatefulWidget {
  const BreathingHalo({
    super.key,
    required this.child,
    required this.tone,
    this.state = LiveSurfaceState.active,
    this.maxAlpha = 0.30,
    this.expand = 12,
  });

  final Widget child;
  final Color tone;
  final LiveSurfaceState state;

  /// Peak alpha at the top of the breathing cycle.
  final double maxAlpha;

  /// Pixel radius the halo expands to past the child bounds.
  final double expand;

  @override
  State<BreathingHalo> createState() => _BreathingHaloState();
}

class _BreathingHaloState extends State<BreathingHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.state.breathingPeriod,
  )..repeat(reverse: true);

  @override
  void didUpdateWidget(covariant BreathingHalo old) {
    super.didUpdateWidget(old);
    if (old.state.breathingPeriod != widget.state.breathingPeriod) {
      // Smooth-rate change so the cadence shift never snaps.
      _c.duration = widget.state.breathingPeriod;
      _c
        ..reset()
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        // Eased breath — slow inhale, slow exhale.
        final t = Curves.easeInOutSine.transform(_c.value);
        final alpha = widget.maxAlpha * t;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -widget.expand,
              top: -widget.expand,
              right: -widget.expand,
              bottom: -widget.expand,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: widget.tone.withValues(alpha: alpha),
                        blurRadius: 28 + widget.expand,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// LIVE ENTRANCE — substrate → content → foil cinematic mount
// ─────────────────────────────────────────────────────────────────────

/// Staggered fade-in for Live credentials. Substrate appears first
/// (0 → 220 ms), content fades in second (180 → 460 ms), foil
/// sweep glows in third (420 → 760 ms). This makes a Live credential
/// feel like it's being printed / materialized when the screen
/// mounts, instead of just snapping into place.
///
/// Provide the three layers (`substrate`, `content`, `foil`) in
/// back-to-front order — the wrapper composes them in a [Stack].
class LiveEntrance extends StatefulWidget {
  const LiveEntrance({
    super.key,
    required this.substrate,
    required this.content,
    this.foil,
    this.duration = const Duration(milliseconds: 760),
    this.autoStart = true,
  });

  /// Bottom layer — the credential substrate (leather, linen, PETG,
  /// vellum). Appears first.
  final Widget substrate;

  /// Middle layer — content (text, seals, photo). Appears second.
  final Widget content;

  /// Top layer — foil sweep / shimmer. Appears third. Optional.
  final Widget? foil;

  final Duration duration;
  final bool autoStart;

  @override
  State<LiveEntrance> createState() => _LiveEntranceState();
}

class _LiveEntranceState extends State<LiveEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _band(double t, double start, double end) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    final p = (t - start) / (end - start);
    return Curves.easeOutCubic.transform(p.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(opacity: _band(t, 0.00, 0.30), child: widget.substrate),
            Opacity(opacity: _band(t, 0.25, 0.60), child: widget.content),
            if (widget.foil != null)
              Opacity(opacity: _band(t, 0.55, 1.00), child: widget.foil!),
          ],
        );
      },
    );
  }
}

/// One-shot "credential is materializing" wrapper for an existing
/// Live screen body. Wraps any single child and animates substrate →
/// content → foil cinematic stages purely as alpha + tiny rise:
///
///   0.00 → 0.45  substrate band  (alpha 0 → 1, no rise)
///   0.20 → 0.70  content band    (alpha 0 → 1, rise from 8 px)
///   0.50 → 1.00  foil band       (alpha 0 → 1, no rise)
///
/// Use when the screen already composes substrate + content + foil
/// inline (most Live screens do) and you only want the cinematic
/// reveal feel without restructuring the layout into three slots.
class LiveMaterialize extends StatefulWidget {
  const LiveMaterialize({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 820),
    this.autoStart = true,
    this.rise = 8.0,
  });

  final Widget child;
  final Duration duration;
  final bool autoStart;

  /// Vertical translation in pixels at t=0 — the credential settles
  /// downward into its final position as it materializes.
  final double rise;

  @override
  State<LiveMaterialize> createState() => _LiveMaterializeState();
}

class _LiveMaterializeState extends State<LiveMaterialize>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.rise),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// LIVE SURFACE STATE — breathing cadence semantics
// ─────────────────────────────────────────────────────────────────────

/// Maps a [LiveSurfaceState] to a recommended breathing period for
/// any substrate / pulse / halo tied to that surface. Used to keep
/// the cinematic ladder consistent across every Live screen — slow
/// at IDLE, fast at ACTIVE, single-pulse on COMMITTED, settled back
/// to slow on SETTLED.
extension LiveSurfaceStateCadence on LiveSurfaceState {
  /// Recommended breathing period for any pulse/halo tied to the
  /// state. Slower at rest, faster as urgency rises.
  Duration get breathingPeriod {
    switch (this) {
      case LiveSurfaceState.idle:
        return const Duration(milliseconds: 4000);
      case LiveSurfaceState.armed:
        return const Duration(milliseconds: 2200);
      case LiveSurfaceState.active:
        return const Duration(milliseconds: 1400);
      case LiveSurfaceState.committed:
        return const Duration(milliseconds: 800);
      case LiveSurfaceState.settled:
        return const Duration(milliseconds: 4200);
    }
  }

  /// Recommended NFC ring count for the state. ACTIVE/COMMITTED
  /// surfaces show a denser ring stack.
  int get suggestedNfcRings {
    switch (this) {
      case LiveSurfaceState.idle:
      case LiveSurfaceState.settled:
        return 1;
      case LiveSurfaceState.armed:
        return 2;
      case LiveSurfaceState.active:
      case LiveSurfaceState.committed:
        return 3;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// ROLLING DIGITS — counts up to a target on activation
// ─────────────────────────────────────────────────────────────────────

/// A column of digits that animates from 0 to a target integer over
/// [duration]. Tabular figures, monospace cadence, ease-out curve so
/// the last digits "settle". Used for the forex banknote serial
/// roll, the lounge member tier badge, the wallet balance reveal.
class RollingDigits extends StatefulWidget {
  const RollingDigits({
    super.key,
    required this.target,
    this.digits = 6,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.prefix = '',
    this.suffix = '',
  });

  /// Target value to land on.
  final int target;

  /// Force a minimum number of digits (zero-padded). E.g. digits=6
  /// for a banknote serial (A000042 → A002847).
  final int digits;

  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final String suffix;

  @override
  State<RollingDigits> createState() => _RollingDigitsState();
}

class _RollingDigitsState extends State<RollingDigits>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();
  late int _from = 0;

  @override
  void didUpdateWidget(RollingDigits oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _from = oldWidget.target;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        // Ease-out: digits race up then settle.
        final t = Curves.easeOutCubic.transform(_c.value);
        final current = (_from + (widget.target - _from) * t).round();
        final text =
            '${widget.prefix}${current.toString().padLeft(widget.digits, '0')}${widget.suffix}';
        return Text(
          text,
          style: (widget.style ??
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.6,
                  ))
              .copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}

/// Wraps a Live credential in a soft drop shadow + tonal ambient
/// occlusion so the object reads as floating off the OLED surface
/// instead of sitting flat against it. Used on every Live hero
/// credential (passport, boarding, visa, banknote, transit, lounge).
class LiveLift extends StatelessWidget {
  const LiveLift({
    super.key,
    required this.child,
    this.tone,
    this.depth = 14,
    this.spread = 0.0,
  });

  final Widget child;

  /// Ambient tone bled under the credential. Subtle; reinforces the
  /// vertical's accent without being visible directly.
  final Color? tone;

  /// Vertical offset of the soft cast shadow (px). Default 14.
  final double depth;

  /// Extra spread on the shadow blur. 0 is conservative; bump for
  /// taller cards.
  final double spread;

  @override
  Widget build(BuildContext context) {
    final accent = (tone ?? const Color(0xFFD4AF37));
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            // Deep core shadow — the "weight" of the credential.
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.62),
              offset: Offset(0, depth),
              blurRadius: 32 + spread,
              spreadRadius: 0,
            ),
            // Tonal ambient — a faint coloured halo of the vertical
            // sneaks through the shadow so the OLED substrate
            // "remembers" the credential is there.
            BoxShadow(
              color: accent.withValues(alpha: 0.18),
              offset: Offset(0, depth * 0.5),
              blurRadius: 48 + spread,
              spreadRadius: 0,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
