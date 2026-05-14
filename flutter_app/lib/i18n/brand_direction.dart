import 'package:flutter/material.dart';

/// Phase 13b — Brand-locked text direction primitives.
///
/// Even under RTL locales (e.g. Arabic), elements that are part of
/// the GlobeID **brand chrome** — the `GLOBE · ID` watermark, the
/// `N° XXXXXXXX` case number, the mono-cap eyebrows — read Latin
/// LTR. They are the trademark, not the body copy. This file
/// provides primitives that callers wrap around brand chrome so it
/// is locked to LTR regardless of the surrounding `Directionality`.
class BrandDirection {
  BrandDirection._();

  /// True when the nearest `Directionality` ancestor is RTL.
  static bool isRtl(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl;

  /// True when the nearest `Directionality` ancestor is LTR.
  static bool isLtr(BuildContext context) =>
      Directionality.of(context) == TextDirection.ltr;
}

/// Wrap brand chrome (watermark, monogram, case number, mono-cap
/// eyebrows) in this widget. The subtree is forced to LTR so the
/// Latin trademark renders identically across every locale.
class BrandLtr extends StatelessWidget {
  const BrandLtr({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Directionality(textDirection: TextDirection.ltr, child: child);
}

/// Renders [child] mirrored when the ambient direction is RTL.
///
/// Useful for arrow icons, slide-in indicators, and any glyph whose
/// visual handedness encodes "forward" or "next". The mirror is a
/// pure horizontal scale (no width/height impact), so layout is
/// preserved.
class MirrorAware extends StatelessWidget {
  const MirrorAware({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mirror = Directionality.of(context) == TextDirection.rtl;
    if (!mirror) return child;
    return Transform.scale(scaleX: -1, scaleY: 1, child: child);
  }
}

/// Returns an `Alignment` that flips its horizontal anchor under
/// RTL — useful for gradient stops and child positioning.
Alignment brandAligned(BuildContext context, Alignment ltrAlignment) {
  if (Directionality.of(context) == TextDirection.ltr) return ltrAlignment;
  return Alignment(-ltrAlignment.x, ltrAlignment.y);
}

/// Returns an `EdgeInsetsDirectional`'s effective LTR/RTL flip as a
/// concrete `EdgeInsets`. Useful in tests + screenshot routines
/// where `EdgeInsetsDirectional` doesn't apply automatically.
EdgeInsets resolveDirectionalPadding(
  BuildContext context, {
  double start = 0,
  double end = 0,
  double top = 0,
  double bottom = 0,
}) {
  final isRtl = Directionality.of(context) == TextDirection.rtl;
  return EdgeInsets.fromLTRB(
    isRtl ? end : start,
    top,
    isRtl ? start : end,
    bottom,
  );
}
