import 'dart:ui';

import 'package:flutter/material.dart';

import '../os2_tokens.dart';

/// OS 2.0 — Slab.
///
/// The atom of every OS 2.0 surface. A continuous-curve squircle slab
/// rendered against the OLED canvas with:
///   • a true-black floor tier (so depth comes from hierarchy, not hue);
///   • a 0.5px luminous hairline tinted by the world tone;
///   • an inner specular sweep along the top edge;
///   • an optional ambient halo that bleeds the tone radially out of
///     one corner (the slab "remembers" what kind of moment it is);
///   • an optional breathing pulse that subtly modulates the halo
///     intensity over 7s.
///
/// Slabs do NOT use BackdropFilter blur. They are not glass. They are
/// solid OLED slabs — the visual language of the OS 2.0 rebuild.
class Os2Slab extends StatefulWidget {
  const Os2Slab({
    super.key,
    required this.child,
    this.tone = Os2.pulseTone,
    this.tier = Os2SlabTier.floor2,
    this.radius = Os2.rSlab,
    this.padding = const EdgeInsets.all(Os2.space5),
    this.halo = Os2SlabHalo.corner,
    this.breath = true,
    this.onTap,
    this.elevation = Os2SlabElevation.resting,
  });

  final Widget child;

  /// World tone used for the hairline, the halo, and the specular sweep.
  final Color tone;

  /// Which floor tier the slab sits on. Lower-numbered tiers are
  /// darker; the visual hierarchy is established entirely through tier
  /// stacking, never through colour.
  final Os2SlabTier tier;

  /// Continuous-curve squircle radius. Defaults to [Os2.rSlab] (32 pt).
  /// Hero slabs use [Os2.rHero]; chip-like slabs use [Os2.rCard].
  final double radius;

  final EdgeInsets padding;

  /// Where the ambient halo blooms from. [Os2SlabHalo.none] disables
  /// the halo entirely.
  final Os2SlabHalo halo;

  /// Whether the halo subtly breathes (slow 7s sine). Disabling this
  /// is helpful for surfaces that are never the focal slab.
  final bool breath;

  final VoidCallback? onTap;

  /// Whether the slab carries the elevation signature of a focal hero
  /// (extra ambient + lift), a resting tile, or a flat strip.
  final Os2SlabElevation elevation;

  @override
  State<Os2Slab> createState() => _Os2SlabState();
}

enum Os2SlabTier { floor1, floor2, floor3 }

enum Os2SlabHalo { none, corner, edge, full }

enum Os2SlabElevation { flat, resting, raised, cinematic }

class _Os2SlabState extends State<Os2Slab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: Os2.mBreathSlow,
  );

  @override
  void initState() {
    super.initState();
    if (widget.breath) _breath.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant Os2Slab old) {
    super.didUpdateWidget(old);
    if (widget.breath && !_breath.isAnimating) {
      _breath.repeat(reverse: true);
    } else if (!widget.breath && _breath.isAnimating) {
      _breath.stop();
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  Color get _floor {
    switch (widget.tier) {
      case Os2SlabTier.floor1:
        return Os2.floor1;
      case Os2SlabTier.floor2:
        return Os2.floor2;
      case Os2SlabTier.floor3:
        return Os2.floor3;
    }
  }

  List<BoxShadow> get _shadows {
    switch (widget.elevation) {
      case Os2SlabElevation.flat:
        return const [];
      case Os2SlabElevation.resting:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ];
      case Os2SlabElevation.raised:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.62),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: widget.tone.withValues(alpha: 0.10),
            blurRadius: 36,
            spreadRadius: -8,
          ),
        ];
      case Os2SlabElevation.cinematic:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.72),
            blurRadius: 44,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: widget.tone.withValues(alpha: 0.18),
            blurRadius: 56,
            spreadRadius: -8,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Continuous-curve squircle. Flutter's `ContinuousRectangleBorder`
    // doesn't quite match a true superellipse, but at our radii it
    // reads visually right and lets the hairline painter share the
    // exact same outline.
    final shape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(widget.radius),
    );

    // Static parts of the slab — shape, shadows, specular, content,
    // hairline. These should never rebuild on the breath tick.
    final staticChild = DecoratedBox(
      decoration: ShapeDecoration(
        color: _floor,
        shape: shape,
        shadows: _shadows,
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: Stack(
          children: [
            // Halo: animated by the breath controller. Isolated below in
            // its own RepaintBoundary + AnimatedBuilder so the rest of
            // the slab — including the child subtree — never repaints
            // on the breath tick.
            if (widget.halo != Os2SlabHalo.none)
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _breath,
                      builder: (context, _) {
                        final t = widget.breath
                            ? Curves.easeInOut.transform(_breath.value)
                            : 0.0;
                        return CustomPaint(
                          painter: _HaloPainter(
                            tone: widget.tone,
                            halo: widget.halo,
                            breath: t,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SpecularPainter(tone: widget.tone),
                ),
              ),
            ),
            Padding(
              padding: widget.padding,
              child: widget.child,
            ),
            if (widget.onTap != null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: shape,
                    onTap: widget.onTap,
                  ),
                ),
              ),
          ],
        ),
      ),
    ).withHairline(widget.tone, widget.radius);

    return staticChild;
  }
}

extension _Os2SlabHairline on Widget {
  Widget withHairline(Color tone, double radius) {
    return CustomPaint(
      foregroundPainter: _HairlinePainter(
        tone: tone,
        radius: radius,
      ),
      child: this,
    );
  }
}

class _HairlinePainter extends CustomPainter {
  _HairlinePainter({required this.tone, required this.radius});
  final Color tone;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final path = shape.getOuterPath(rect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = Os2.strokeFine
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          tone.withValues(alpha: 0.36),
          Os2.hairline,
          Os2.hairlineSoft,
        ],
      ).createShader(rect);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HairlinePainter old) =>
      old.tone != tone || old.radius != radius;
}

class _HaloPainter extends CustomPainter {
  _HaloPainter({
    required this.tone,
    required this.halo,
    required this.breath,
  });
  final Color tone;
  final Os2SlabHalo halo;
  final double breath;

  @override
  void paint(Canvas canvas, Size size) {
    final intensity = (0.16 + 0.07 * breath).clamp(0.0, 0.30);
    switch (halo) {
      case Os2SlabHalo.none:
        return;
      case Os2SlabHalo.corner:
        final paint = Paint()
          ..shader = RadialGradient(
            center: Alignment.topLeft,
            radius: 1.4,
            colors: [
              tone.withValues(alpha: intensity),
              Colors.transparent,
            ],
            stops: const [0.0, 1.0],
          ).createShader(Offset.zero & size);
        canvas.drawRect(Offset.zero & size, paint);
        return;
      case Os2SlabHalo.edge:
        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              tone.withValues(alpha: intensity * 0.85),
              Colors.transparent,
            ],
          ).createShader(Offset.zero & size);
        canvas.drawRect(Offset.zero & size, paint);
        return;
      case Os2SlabHalo.full:
        final paint = Paint()
          ..shader = RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              tone.withValues(alpha: intensity * 0.6),
              Colors.transparent,
            ],
          ).createShader(Offset.zero & size);
        canvas.drawRect(Offset.zero & size, paint);
        return;
    }
  }

  @override
  bool shouldRepaint(covariant _HaloPainter old) =>
      old.tone != tone || old.halo != halo || old.breath != breath;
}

class _SpecularPainter extends CustomPainter {
  _SpecularPainter({required this.tone});
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    // Inner specular along the top 1px. Makes the slab read as a
    // physical sculpted surface even on OLED black.
    final rect = Rect.fromLTWH(0, 0, size.width, 1.0);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          tone.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.05),
          tone.withValues(alpha: 0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.18, 0.5, 0.78, 1.0],
      ).createShader(rect);
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpecularPainter old) => old.tone != tone;
}

// Unused import shadow — keep dart:ui referenced for ImageFilter in future
// variants of the slab. Stripped by the dead-code shaker.
// ignore: unused_element
ImageFilter _noop() => ImageFilter.blur(sigmaX: 0, sigmaY: 0);
