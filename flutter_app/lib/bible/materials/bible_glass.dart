import 'dart:ui';

import 'package:flutter/material.dart';

import '../bible_tokens.dart';

/// GlobeID — **Glass** material (§4.3).
///
/// Cabin-window glass surface: backdrop blur σ≈14, white tint ~6 %,
/// internal hairline border at ~12 %.
///
/// Used for: nav bars, sheets, modal dialogs, floating chrome
/// (HUD pills, voice orb, command palette overlay).
///
/// Materials are **physically grounded**: glass blurs what is behind
/// it. The widget therefore needs to live above a non-uniform
/// background to read as "glass" rather than "tinted rectangle". The
/// blur is auto-disabled when `BRenderQuality.reduced` is requested.
class BibleGlass extends StatelessWidget {
  const BibleGlass({
    super.key,
    required this.child,
    this.radius = B.rCard,
    this.padding = const EdgeInsets.all(B.space4),
    this.tint = B.glassTint,
    this.hairline = B.glassHairline,
    this.blurSigma = B.glassBlurSigma,
    this.elevation = 0,
    this.borderWidth = 0.6,
    this.borderTone,
    this.quality = BRenderQuality.normal,
  });

  /// Subject placed on the glass surface.
  final Widget child;

  /// Continuous-curve radius of the glass card.
  final double radius;

  /// Inset between glass edge and `child`.
  final EdgeInsets padding;

  /// Inner colour overlay (≤8 % alpha) — the *frost*. Defaults to
  /// 6 % white per Bible §4.3.
  final Color tint;

  /// Internal hairline border colour. Defaults to 12 % white per Bible.
  final Color hairline;

  /// Gaussian blur sigma. `14` is the Bible default.
  final double blurSigma;

  /// Optional drop shadow elevation (`0..2`).
  final double elevation;

  /// Width of the hairline border.
  final double borderWidth;

  /// Optional tone-tinted overlay (≤6 % alpha) for register tinting.
  final Color? borderTone;

  /// Render quality. `reduced` disables the blur and renders an
  /// opaque substrate-toned surface.
  final BRenderQuality quality;

  @override
  Widget build(BuildContext context) {
    final shape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(
        color: borderTone ?? hairline,
        width: borderWidth,
      ),
    );

    final inner = Padding(
      padding: padding,
      child: child,
    );

    final shadow = elevation == 0
        ? const <BoxShadow>[]
        : <BoxShadow>[
            BoxShadow(
              color: const Color(0x33000000).withValues(
                alpha: 0.22 * elevation.clamp(0.0, 2.0),
              ),
              blurRadius: 18 * elevation.clamp(0.5, 2.0),
              spreadRadius: 0,
              offset: Offset(0, 8 * elevation.clamp(0.5, 2.0)),
            ),
          ];

    if (quality == BRenderQuality.reduced) {
      return DecoratedBox(
        decoration: ShapeDecoration(
          color: B.cabinCharcoal,
          shape: shape,
          shadows: shadow,
        ),
        child: inner,
      );
    }

    // Compose: clip to shape → backdrop blur → tint → hairline border.
    return DecoratedBox(
      decoration: ShapeDecoration(shape: shape, shadows: shadow),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint,
                  tint.withValues(alpha: tint.a * 0.5),
                ],
              ),
            ),
            child: inner,
          ),
        ),
      ),
    );
  }
}
