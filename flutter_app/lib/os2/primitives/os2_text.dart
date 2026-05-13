import 'package:flutter/material.dart';

import '../os2_tokens.dart';

/// OS 2.0 — typography helpers.
///
/// Every text node in `lib/os2/` should be one of:
///   • [Os2Text.display]    — 44–56 pt, -2.4 tracking, w900
///   • [Os2Text.headline]   — 28–32 pt, -1.2 tracking, w800
///   • [Os2Text.title]      — 18–22 pt, -0.4 tracking, w700
///   • [Os2Text.body]       — 14–16 pt, +0.2 tracking, w500
///   • [Os2Text.caption]    — 11–12 pt, +0.8 tracking uppercase, w700
///   • [Os2Text.monoCap]    — Departure Mono, +1.6 tracking, w800
///   • [Os2Text.credential] — Stat numerals (trust score, queue %,
///     balance). 36 pt, -1.0 tracking, w900, tabular figures, height
///     1.0. The cinematic hero number on every Live surface.
///   • [Os2Text.watermark]  — GLOBE·ID monogram chrome. 9 pt, 2.4
///     tracking, w700, white@18%. The chrome thread that runs through
///     every credential, sheet, and onboarding canvas.
///
/// These wrap [Text] with the bible's restraint values pre-applied so
/// callsites never have to remember `letterSpacing: -2.4`. The
/// optional [gradient] parameter on [display], [headline], and
/// [credential] paints the glyph in the canonical [Os2.foilGoldHero]
/// champagne ramp via a [ShaderMask] — the "engineered by GlobeID"
/// signature reserved for hero moments.
class Os2Text extends StatelessWidget {
  const Os2Text.display(
    this.data, {
    super.key,
    this.color,
    this.size = Os2.textH1,
    this.weight = FontWeight.w900,
    this.maxLines = 2,
    this.height = 1.04,
    this.align,
    this.gradient,
  })  : _track = Os2.trackDisplay,
        _canon = Os2.canonDisplay,
        _font = null,
        _upper = false;

  const Os2Text.headline(
    this.data, {
    super.key,
    this.color,
    this.size = Os2.textH2,
    this.weight = FontWeight.w800,
    this.maxLines = 2,
    this.height = 1.08,
    this.align,
    this.gradient,
  })  : _track = Os2.trackHeadline,
        _canon = Os2.canonHeadline,
        _font = null,
        _upper = false;

  const Os2Text.title(
    this.data, {
    super.key,
    this.color,
    this.size = 20,
    this.weight = FontWeight.w700,
    this.maxLines = 2,
    this.height = 1.15,
    this.align,
  })  : _track = Os2.trackTitle,
        _canon = Os2.canonTitle,
        _font = null,
        _upper = false,
        gradient = null;

  const Os2Text.body(
    this.data, {
    super.key,
    this.color,
    this.size = Os2.textBase,
    this.weight = FontWeight.w500,
    this.maxLines = 4,
    this.height = 1.36,
    this.align,
  })  : _track = Os2.trackBody,
        _canon = Os2.canonBody,
        _font = null,
        _upper = false,
        gradient = null;

  const Os2Text.caption(
    this.data, {
    super.key,
    this.color,
    this.size = Os2.textXs,
    this.weight = FontWeight.w700,
    this.maxLines = 2,
    this.height = 1.2,
    this.align,
  })  : _track = Os2.trackCaption,
        _canon = Os2.canonCaption,
        _font = null,
        _upper = true,
        gradient = null;

  const Os2Text.monoCap(
    this.data, {
    super.key,
    this.color,
    this.size = Os2.textSm,
    this.weight = FontWeight.w800,
    this.maxLines = 1,
    this.height = 1.0,
    this.align,
  })  : _track = Os2.trackMonoCap,
        _canon = Os2.canonMonoCap,
        _font = 'Departure Mono',
        _upper = true,
        gradient = null;

  /// Hero stat numerals — the big readouts on every Live surface
  /// (trust score, queue %, wallet balance, transit dwell counter).
  /// Tighter than [display], locked-pitch tabular figures, OLED-bright
  /// by default. Opts into [gradient] for the most cinematic moments
  /// (hero balance card, trust hub centerpiece).
  const Os2Text.credential(
    this.data, {
    super.key,
    this.color,
    this.size = 36,
    this.weight = FontWeight.w900,
    this.maxLines = 1,
    this.height = 1.0,
    this.align,
    this.gradient,
  })  : _track = -1.0,
        _canon = 36,
        _font = null,
        _upper = false;

  /// The GLOBE·ID monogram chrome. Same 9 pt / 18%-white /
  /// 2.4-letter-spacing thread that runs through every Live
  /// credential, AppleSheet, and onboarding canvas. Defaults to the
  /// canonical glyph but can be overridden to append a serial or
  /// timestamp suffix.
  const Os2Text.watermark(
    this.data, {
    super.key,
    this.color,
    this.size = Os2.textTiny,
    this.weight = FontWeight.w700,
    this.maxLines = 1,
    this.height = 1.0,
    this.align,
  })  : _track = 2.4,
        _canon = Os2.textTiny,
        _font = null,
        _upper = true,
        gradient = null;

  final String data;
  final Color? color;
  final double size;
  final FontWeight weight;
  final int maxLines;
  final double height;
  final TextAlign? align;
  final Gradient? gradient;
  final double _track;
  final double _canon;
  final String? _font;
  final bool _upper;

  @override
  Widget build(BuildContext context) {
    // Watermark renders white@18% by default; every other variant
    // reaches for [Os2.inkHigh].
    final defaultColor = _isWatermark
        ? Colors.white.withValues(alpha: 0.18)
        : Os2.inkHigh;
    final text = Text(
      _upper ? data.toUpperCase() : data,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: TextStyle(
        fontFamily: _font,
        fontSize: size,
        fontWeight: weight,
        // Letter-spacing relaxes proportionally below the variant's
        // canonical anchor — a title squeezed to 14 pt should not
        // carry the same -0.4 tracking tuned for the 20 pt anchor.
        letterSpacing: Os2.trackingFor(_track, size, _canon),
        height: height,
        // When a gradient is set, the foreground color is the mask
        // colour (white) — actual hue comes from the ShaderMask.
        color: gradient == null ? (color ?? defaultColor) : Colors.white,
        // Aviation HUD — tabular numerals so digits never jitter as
        // counters / balances / readouts update.
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    if (gradient == null) return text;
    return ShaderMask(
      shaderCallback: (rect) => gradient!.createShader(rect),
      blendMode: BlendMode.srcIn,
      child: text,
    );
  }

  /// True iff this instance was built by the watermark constructor.
  /// Used to fall back to white@18% instead of [Os2.inkHigh] when no
  /// explicit colour is supplied.
  bool get _isWatermark =>
      _track == 2.4 && _canon == Os2.textTiny && _upper && _font == null;
}
