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

/// A persistent horizontal foil sweep that animates left-to-right over
/// any child. Used for the holographic mark on visa pages, banknotes
/// and credentials.
class HolographicFoil extends StatefulWidget {
  const HolographicFoil({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 6),
    this.colors = const [
      Color(0x00FFFFFF),
      Color(0x33D4AF37),
      Color(0x55E3C083),
      Color(0x33D4AF37),
      Color(0x00FFFFFF),
    ],
  });

  final Widget child;
  final Duration duration;
  final List<Color> colors;

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
    // Isolate the per-frame shader pass in its own repaint layer so
    // siblings (text, decoration, icons) don't repaint at the holo
    // sweep cadence.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = _c.value;
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment(-1.4 + t * 2.8, -0.3),
                end: Alignment(-0.4 + t * 2.8, 0.3),
                colors: widget.colors,
              ).createShader(bounds);
            },
            child: child,
          );
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
