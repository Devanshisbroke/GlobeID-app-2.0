// GlobeID UI/UX Bible — visual-language foundations.
//
// This file is the canonical Dart binding for the design tokens,
// named motion curves, named transitions, material primitives and
// per-screen lighting hints described in `GLOBEID_UIUX_BIBLE.md`.
//
// Every reusable value in here corresponds to a numbered section in
// the bible — the section reference appears in the doc-comment so
// future implementers can walk back to the source of truth.
//
// Convention: any new flagship surface MUST source its colors from
// [BibleSubstrate]/[BibleTone]/[BibleSignal], its motion from
// [BibleCurves], its page transitions from [BibleTransitions], and
// its visual material from [BibleMaterial]. Anything that doesn't
// route through these tokens is, by the bible, a regression.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// ─── §4.1 Color — Substrate palette ──────────────────────────────────
//
// "Deep backgrounds, the atmosphere the UI floats in." The substrate
// of a screen sets its altitude in the Earth-OS metaphor (§3): the
// deeper / darker the substrate, the higher the altitude.
class BibleSubstrate {
  BibleSubstrate._();

  /// Root background — lock screen, globe, deep sleep / first paint.
  /// Geosynchronous altitude.
  static const Color midnightIndigo = Color(0xFF05060A);

  /// Interior surfaces at altitude — cabin window glass material.
  /// Stratospheric altitude.
  static const Color cabinCharcoal = Color(0xFF0E1117);

  /// Ground-level screens — most "in-the-moment" tabs.
  /// Tower / pedestrian altitude.
  static const Color tarmacSlate = Color(0xFF161A22);

  /// Paper-light surfaces — passport, journal, postcards.
  /// Intimate altitude (~30 cm).
  static const Color vellumBone = Color(0xFFF4EFE6);

  /// Boarding-pass paper / document substrate.
  /// Intimate altitude.
  static const Color snowfieldWhite = Color(0xFFFBFBFD);
}

// ─── §4.1 Color — Tone palette ───────────────────────────────────────
//
// Contextual accents drawn from the *type of moment* the screen
// represents. The bible's rule: any single screen uses ONE tone (and
// at most one signal). Three colors total. Anything more is a
// regression.
class BibleTone {
  BibleTone._();

  // Identity / passport — museum-case, diplomatic, archival.
  static const Color diplomaticGarnet = Color(0xFF7A1D2E);
  static const Color foilGold = Color(0xFFB8902B);
  static const Color stampInk = Color(0xFF0B1B3A);

  // Wallet / payments — treasury, vault, mint.
  static const Color treasuryGreen = Color(0xFF0E7A4F);
  static const Color waxCrimson = Color(0xFFA02B3C);
  static const Color mintGlass = Color(0xFF7FE3C4);

  // Travel / boarding — apron / runway / aurora.
  static const Color jetCyan = Color(0xFF0EA5E9);
  static const Color auroraViolet = Color(0xFF7C3AED);
  static const Color runwayAmber = Color(0xFFF59E0B);

  // Globe / map — equatorial, oceanic, polar.
  static const Color equatorTeal = Color(0xFF10B981);
  static const Color horizonCoral = Color(0xFFFB7185);
  static const Color polarBlue = Color(0xFF3B82F6);

  // Lounge / arrival — soft furnishing, candle, after-hours.
  static const Color champagneSand = Color(0xFFD9C19A);
  static const Color velvetMauve = Color(0xFF8B5A6E);
  static const Color honeyAmber = Color(0xFFE0A85B);
}

// ─── §4.1 Color — Signal palette ─────────────────────────────────────
//
// Purely functional. Used sparingly. Never decorative.
class BibleSignal {
  BibleSignal._();

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);
}

// ─── §5.1 Motion — Named curves (aircraft maneuvers) ─────────────────
//
// Five curves, named like maneuvers. The bible: "No screen uses
// Material's default Curves.linear for anything except progress
// indicators. Linear is dead motion."
class BibleCurves {
  BibleCurves._();

  /// Default entrance — ease-out-back-soft.
  static const Curve takeoff = Cubic(0.16, 1.0, 0.30, 1.0);

  /// Neutral, used for layout shifts.
  static const Curve cruise = Curves.easeInOutCubic;

  /// Over-bouncy, for chip taps and selection.
  static const Curve bank = Cubic(0.34, 1.56, 0.64, 1.0);

  /// Exits, dismissals.
  static const Curve descent = Curves.easeInCubic;

  /// State collapse — settles into place.
  static const Curve taxi = Cubic(0.45, 0.0, 0.55, 1.0);
}

// ─── §5.2 Motion — Choreography stagger ──────────────────────────────
//
// The bible's default cascade. Use [BibleChoreography.delayFor] to
// place a stack of widgets on the same stagger graph.
class BibleChoreography {
  BibleChoreography._();

  /// Hero → 0 ms.
  static const Duration hero = Duration.zero;

  /// Section header → +120 ms.
  static const Duration sectionHeader = Duration(milliseconds: 120);

  /// First card → +160 ms.
  static const Duration firstCard = Duration(milliseconds: 160);

  /// Subsequent cards → +60 ms each.
  static const Duration cardStep = Duration(milliseconds: 60);

  /// Floating chrome (FAB, chip rail) → +320 ms.
  static const Duration floatingChrome = Duration(milliseconds: 320);

  /// Helper: returns the staggered delay for the [index]-th card on
  /// the bible's default cascade.
  static Duration delayFor(int index) {
    if (index <= 0) return firstCard;
    return firstCard + cardStep * index;
  }
}

// ─── §5.3 Motion — Eight named page transitions ──────────────────────
//
// Routes opt in to one of these *explicitly* — never inherit a
// default. The bible: "Material's default fade is dead motion."
class BibleTransitions {
  BibleTransitions._();

  /// 1. `riseTransition` — slide up 12 %, fade in, scale from 0.94.
  static Widget rise(
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    final t = CurvedAnimation(parent: animation, curve: BibleCurves.takeoff);
    final out = CurvedAnimation(parent: secondary, curve: BibleCurves.descent);
    return FadeTransition(
      opacity: t,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.12), end: Offset.zero)
            .animate(t),
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(t),
          child: FadeTransition(
            opacity: ReverseAnimation(out.drive(Tween(begin: 0, end: 0.4))),
            child: child,
          ),
        ),
      ),
    );
  }

  /// 2. `scaleFromAnchor(anchor)` — scale from a tapped point.
  static Widget scaleFromAnchor(
    Animation<double> animation,
    Alignment anchor,
    Widget child,
  ) {
    final t = CurvedAnimation(parent: animation, curve: BibleCurves.takeoff);
    return FadeTransition(
      opacity: t,
      child: ScaleTransition(
        scale: Tween(begin: 0.86, end: 1.0).animate(t),
        alignment: anchor,
        child: child,
      ),
    );
  }

  /// 3. `morphTransition` — cross-fade with concurrent scale-down of
  /// the exiting page.
  static Widget morph(
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    final t = CurvedAnimation(parent: animation, curve: BibleCurves.cruise);
    final out = CurvedAnimation(parent: secondary, curve: BibleCurves.descent);
    return FadeTransition(
      opacity: t,
      child: ScaleTransition(
        scale: Tween(begin: 0.98, end: 1.0).animate(t),
        child: FadeTransition(
          opacity:
              ReverseAnimation(out.drive(Tween(begin: 0.0, end: 0.6))),
          child: ScaleTransition(
            scale: ReverseAnimation(out.drive(Tween(begin: 0.0, end: 0.04))),
            child: child,
          ),
        ),
      ),
    );
  }

  /// 4. `dropTransition` — slide down with bounce.
  static Widget drop(
    Animation<double> animation,
    Widget child,
  ) {
    final t = CurvedAnimation(parent: animation, curve: BibleCurves.bank);
    return SlideTransition(
      position: Tween(begin: const Offset(0, -0.18), end: Offset.zero)
          .animate(t),
      child: FadeTransition(opacity: t, child: child),
    );
  }

  /// 5. `blurFadeTransition` — incoming fades in while background
  /// blurs from σ=8→0.
  static Widget blurFade(
    Animation<double> animation,
    Widget child,
  ) {
    final t = CurvedAnimation(parent: animation, curve: BibleCurves.cruise);
    return AnimatedBuilder(
      animation: t,
      builder: (_, c) {
        final sigma = 8 * (1 - t.value);
        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Opacity(opacity: t.value, child: c),
        );
      },
      child: child,
    );
  }

  /// 6. `slideLateralTransition` — iOS push-from-right with parallax
  /// depth on exit.
  static Widget slideLateral(
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    final t = CurvedAnimation(parent: animation, curve: BibleCurves.cruise);
    final out = CurvedAnimation(parent: secondary, curve: BibleCurves.cruise);
    return SlideTransition(
      position:
          Tween(begin: const Offset(1.0, 0), end: Offset.zero).animate(t),
      child: SlideTransition(
        position: Tween(begin: Offset.zero, end: const Offset(-0.30, 0))
            .animate(out),
        child: child,
      ),
    );
  }

  /// 7. `reducedMotionTransition` — accessibility opt-out.
  static Widget reducedMotion(
    Animation<double> animation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }

  /// 8. `atmosphericDescent` — descending the altitude stack
  /// (Globe → Travel → Trip → Boarding). Vertical slide + scale +
  /// 200 ms blur lens that resolves on land.
  static Widget atmosphericDescent(
    Animation<double> animation,
    Widget child,
  ) {
    final t = CurvedAnimation(parent: animation, curve: BibleCurves.takeoff);
    return AnimatedBuilder(
      animation: t,
      builder: (_, c) {
        final sigma = 6 * (1 - t.value);
        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.18), end: Offset.zero)
                .animate(t),
            child: ScaleTransition(
              scale: Tween(begin: 1.06, end: 1.0).animate(t),
              child: Opacity(opacity: t.value, child: c),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

// ─── §4.4 Lighting — single virtual light source per screen ──────────
//
// Each flagship screen declares its [BibleLighting] so that foil
// sheens, drop shadows, and metal highlights all align to the same
// fictional sun.
@immutable
class BibleLighting {
  /// Angle of the virtual light source, in degrees, measured CCW
  /// from the +X axis. 90° = above, 0° = right, 180° = left.
  final double angleDeg;

  /// Intensity multiplier (0..1). 1.0 = direct overhead noon.
  final double intensity;

  /// The dominant warmth bias of the light source — determines
  /// whether highlights look gold or steel.
  final Color warmth;

  const BibleLighting({
    required this.angleDeg,
    required this.intensity,
    required this.warmth,
  });

  /// Identity / passport: museum case lighting, 45°, soft, gold.
  static const identity = BibleLighting(
    angleDeg: 135,
    intensity: 0.72,
    warmth: BibleTone.foilGold,
  );

  /// Wallet: treasury vault, 90°, neutral.
  static const wallet = BibleLighting(
    angleDeg: 90,
    intensity: 0.85,
    warmth: BibleTone.mintGlass,
  );

  /// Boarding pass: airport apron afternoon, 30°, warm.
  static const boarding = BibleLighting(
    angleDeg: 30,
    intensity: 0.92,
    warmth: BibleTone.runwayAmber,
  );

  /// Globe: directional sun (real-world solar position).
  static const globe = BibleLighting(
    angleDeg: 60,
    intensity: 1.0,
    warmth: BibleTone.polarBlue,
  );

  /// Lounge: table lamp, 200°, very warm.
  static const lounge = BibleLighting(
    angleDeg: 200,
    intensity: 0.55,
    warmth: BibleTone.honeyAmber,
  );

  /// Convert the angle to a unit offset on the (-1..1, -1..1) plane.
  Offset get unitOffset {
    final radians = angleDeg * math.pi / 180.0;
    return Offset(math.cos(radians), -math.sin(radians));
  }
}

// ─── §4.3 Materials — five physically-grounded surfaces ──────────────
//
// Glass / Foil / Paper / Metal / Atmosphere. Each is a widget that
// composes the right blur, gradient, noise and shadow stack for that
// material. The bible: "Materials never mix."
enum BibleMaterial { glass, foil, paper, metal, atmosphere }

class BibleSurface extends StatelessWidget {
  final BibleMaterial material;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final BibleLighting lighting;

  const BibleSurface({
    super.key,
    required this.material,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.lighting = BibleLighting.identity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final r = BorderRadius.circular(radius);

    switch (material) {
      case BibleMaterial.glass:
        return ClipRRect(
          borderRadius: r,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.40),
                borderRadius: r,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 0.6,
                ),
              ),
              child: child,
            ),
          ),
        );

      case BibleMaterial.foil:
        // Foil: gradient sheen biased by the lighting angle.
        final l = lighting.unitOffset;
        return Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: r,
            gradient: LinearGradient(
              begin: Alignment(l.dx * -0.8, l.dy * -0.8),
              end: Alignment(l.dx * 0.8, l.dy * 0.8),
              colors: [
                BibleTone.foilGold.withValues(alpha: 0.65),
                BibleTone.foilGold,
                Colors.white.withValues(alpha: 0.92),
                BibleTone.foilGold,
                BibleTone.foilGold.withValues(alpha: 0.55),
              ],
              stops: const [0.0, 0.32, 0.5, 0.68, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: BibleTone.foilGold.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: Offset(l.dx * 6, l.dy * 6 + 12),
              ),
            ],
          ),
          child: child,
        );

      case BibleMaterial.paper:
        // Paper: vellum substrate + grain noise + minimal shadow.
        return DecoratedBox(
          decoration: BoxDecoration(
            color: BibleSubstrate.snowfieldWhite,
            borderRadius: r,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: r,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                Padding(padding: padding, child: child),
                IgnorePointer(
                  child: CustomPaint(
                    painter: _PaperGrainPainter(),
                    size: Size.infinite,
                  ),
                ),
              ],
            ),
          ),
        );

      case BibleMaterial.metal:
        // Brushed-aluminum gradient with anisotropic highlight.
        final l = lighting.unitOffset;
        return Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: r,
            gradient: LinearGradient(
              begin: Alignment(l.dx * -1, l.dy * -1),
              end: Alignment(l.dx, l.dy),
              colors: const [
                Color(0xFF8A92A1),
                Color(0xFFD7DEE7),
                Color(0xFF8A92A1),
                Color(0xFF5A6473),
              ],
              stops: const [0.0, 0.42, 0.66, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 18,
                offset: Offset(l.dx * 4, l.dy * 4 + 8),
              ),
            ],
          ),
          child: child,
        );

      case BibleMaterial.atmosphere:
        // Layered radial gradients with parallax depth.
        return Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: r,
            gradient: RadialGradient(
              center: Alignment(lighting.unitOffset.dx * 0.4,
                  lighting.unitOffset.dy * 0.4),
              radius: 1.2,
              colors: [
                lighting.warmth.withValues(alpha: 0.18),
                BibleSubstrate.midnightIndigo,
              ],
            ),
          ),
          child: child,
        );
    }
  }
}

class _PaperGrainPainter extends CustomPainter {
  static final math.Random _rng = math.Random(0xC0FFEE);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.018);
    // Cheap deterministic stipple — looks like vellum grain at a
    // viewing distance, no perceptible cost on the GPU.
    for (var i = 0; i < 240; i++) {
      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperGrainPainter oldDelegate) => false;
}
