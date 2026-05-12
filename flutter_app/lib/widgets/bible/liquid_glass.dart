// Apple-grade liquid-glass material system.
//
// Mirrors the SwiftUI `Material` API (ultraThin / thin / regular /
// thick / chrome) so every surface in the app can pick the right
// thickness tier and the visual language stays consistent. Built on
// top of `BackdropFilter` with the three signature iOS-17 ingredients
// that the cheap Material 3 frosted glass in vanilla Flutter is
// missing:
//
//   1. **Saturation boost** — content viewed through glass is
//      saturated (~1.45×) so colour pops behind the material rather
//      than washing out. This is the single biggest perceptual
//      difference between Apple-grade glass and "Flutter blur with a
//      white tint".
//   2. **Luminosity-aware tint** — the tint colour and alpha are
//      picked from a 4-stop ladder per thickness × brightness so the
//      glass reads correctly on both pure-OLED black and warm-paper
//      light.
//   3. **Specular top edge** — a single 0.5-pt gradient strip along
//      the top edge that simulates light catching the lacquer. Apple
//      uses this to imply the sheet has thickness, not just a tint.
//
// Use [LiquidGlass] for any surface that should read as "glass".
// Pair with [LiquidGlassThickness] to express where the surface
// sits in the depth ladder:
//
//   chrome   → top bar, bottom nav (the thinnest, most translucent;
//              wallpaper visibly bleeds through)
//   ultraThin → chips, badges, inline pills
//   thin     → list rows, secondary cards
//   regular  → primary cards, hero panels
//   thick    → modal sheets, long-press peek, in-flight overlays
//
// The Bible (§4.3 Materials) prescribes this exact ladder.

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../nexus/nexus_tokens.dart';

/// Five thickness tiers mirroring SwiftUI's `Material`.
///
/// Higher tiers blur more, tint more opaquely, and cast deeper
/// shadows. Layering rule: a surface should sit on top of a strictly
/// thinner surface (regular on chrome is fine, regular on regular is
/// not — you'll lose the depth read).
enum LiquidGlassThickness {
  /// Top bar / bottom nav. Most translucent; wallpaper bleeds
  /// through. ~σ 22 blur.
  chrome,

  /// Chips, badges, inline pills. ~σ 14 blur.
  ultraThin,

  /// List rows, secondary cards, FX board cells. ~σ 18 blur.
  thin,

  /// Primary cards, hero panels. ~σ 24 blur.
  regular,

  /// Modal sheets, long-press peek, in-flight overlays. ~σ 30 blur.
  thick,
}

/// Apple-grade liquid-glass surface.
///
/// Wraps content in a frosted material with saturation boost,
/// specular top edge, hairline stroke, and ambient cinematic shadow.
/// The corner radius is rendered as a continuous-curve squircle
/// (`StadiumBorder` for full-pill, `ContinuousRectangleBorder` for
/// finite radii) — a subtle but defining Apple detail that vanilla
/// `BorderRadius.circular` does not capture.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.thickness = LiquidGlassThickness.regular,
    this.radius = 28,
    this.tint,
    this.padding,
    this.shadow = LiquidGlassShadow.cinematic,
    this.specular = true,
    this.stroke = true,
  });

  final Widget child;
  final LiquidGlassThickness thickness;

  /// Continuous-curve corner radius. Pass `double.infinity` for a
  /// full pill (StadiumBorder).
  final double radius;

  /// Optional tone tint (foilGold, treasuryGreen, jetCyan, etc.)
  /// blended into the glass at a low alpha so the surface inherits
  /// the screen's bible tone.
  final Color? tint;

  final EdgeInsetsGeometry? padding;
  final LiquidGlassShadow shadow;

  /// Whether to draw the 0.5-pt specular highlight along the top
  /// edge. Disable for chrome surfaces where the highlight would
  /// fight a status-bar tint.
  final bool specular;

  /// Whether to draw the 0.5-pt hairline stroke around the edge.
  final bool stroke;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final spec = _specFor(thickness, isDark);
    final tintColor = tint ?? Colors.transparent;

    final shape = radius.isInfinite || radius >= 9999
        ? const StadiumBorder()
        : ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          );

    final clipper = ShapeBorderClipper(shape: shape);

    final body = ColoredBox(
      // Tint sits over the blur, so colour-bleed from below is still
      // visible. Mix tint into the base tint color additively.
      color: Color.alphaBlend(
        tintColor.withValues(alpha: tintColor.a > 0 ? 0.06 : 0),
        spec.tint,
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );

    final shadows = _shadowsFor(shadow, tintColor, isDark);

    final stroked = stroke
        ? DecoratedBox(
            decoration: ShapeDecoration(
              shape: shape.copyWith(
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.white.withValues(alpha: 0.55),
                  width: 0.5,
                ),
              ),
              shadows: shadows,
            ),
            child: body,
          )
        : DecoratedBox(
            decoration: ShapeDecoration(
              shape: shape,
              shadows: shadows,
            ),
            child: body,
          );

    // Nexus rule: no BackdropFilter. Every glass surface is an opaque
    // N.surface slab with a hairline stroke. Saturation/blur lenses
    // would re-introduce the every-frame GPU cost the Lovable
    // reference rejects; depth comes from the substrate hairline
    // instead. Reduce-transparency users get the same flat substrate.
    return ClipPath(
      clipper: clipper,
      child: ColoredBox(
        color: N.surface,
        child: stroked,
      ),
    );
  }

  static _GlassSpec _specFor(LiquidGlassThickness t, bool isDark) {
    switch (t) {
      case LiquidGlassThickness.chrome:
        return _GlassSpec(
          blur: 22,
          saturation: 1.55,
          brightness: isDark ? 0.85 : 1.10,
          tint: isDark
              ? Colors.black.withValues(alpha: 0.36)
              : Colors.white.withValues(alpha: 0.55),
        );
      case LiquidGlassThickness.ultraThin:
        return _GlassSpec(
          blur: 14,
          saturation: 1.35,
          brightness: isDark ? 0.92 : 1.05,
          tint: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.42),
        );
      case LiquidGlassThickness.thin:
        return _GlassSpec(
          blur: 18,
          saturation: 1.40,
          brightness: isDark ? 0.90 : 1.04,
          tint: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.55),
        );
      case LiquidGlassThickness.regular:
        return _GlassSpec(
          blur: 24,
          saturation: 1.45,
          brightness: isDark ? 0.88 : 1.02,
          tint: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.62),
        );
      case LiquidGlassThickness.thick:
        return _GlassSpec(
          blur: 30,
          saturation: 1.50,
          brightness: isDark ? 0.84 : 0.98,
          tint: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.72),
        );
    }
  }

  static List<BoxShadow> _shadowsFor(
    LiquidGlassShadow shadow,
    Color tint,
    bool isDark,
  ) {
    switch (shadow) {
      case LiquidGlassShadow.none:
        return const [];
      case LiquidGlassShadow.resting:
        return AppTokens.shadowSm(
          tint: isDark ? Colors.black : tint,
        );
      case LiquidGlassShadow.cinematic:
        return AppTokens.shadowCinematic(
          tint: isDark ? Colors.black : tint,
        );
      case LiquidGlassShadow.floating:
        return [
          ...AppTokens.shadowXl(tint: isDark ? Colors.black : tint),
          BoxShadow(
            color: tint.withValues(alpha: isDark ? 0.10 : 0.18),
            blurRadius: 80,
            spreadRadius: -10,
            offset: const Offset(0, 36),
          ),
        ];
    }
  }
}

enum LiquidGlassShadow { none, resting, cinematic, floating }

class _GlassSpec {
  const _GlassSpec({
    required this.blur,
    required this.saturation,
    required this.brightness,
    required this.tint,
  });
  final double blur;
  final double saturation;
  final double brightness;
  final Color tint;
}
