import 'package:flutter/material.dart';

import '../os2_tokens.dart';

/// OS 2.0 — typography helpers.
///
/// Every text node in `lib/os2/` should be one of:
///   • [Os2Text.display]   — 44–56 pt, -2.4 tracking, w900
///   • [Os2Text.headline]  — 28–32 pt, -1.2 tracking, w800
///   • [Os2Text.title]     — 18–22 pt, -0.4 tracking, w700
///   • [Os2Text.body]      — 14–16 pt, +0.2 tracking, w500
///   • [Os2Text.caption]   — 11–12 pt, +0.8 tracking uppercase, w700
///   • [Os2Text.monoCap]   — Departure Mono, +1.6 tracking, w800
///
/// These wrap [Text] with the bible's restraint values pre-applied so
/// callsites never have to remember `letterSpacing: -2.4`.
class Os2Text extends StatelessWidget {
  const Os2Text.display(
    this.data, {
    super.key,
    this.color,
    this.size = 48,
    this.weight = FontWeight.w900,
    this.maxLines = 2,
    this.height = 1.04,
    this.align,
  })  : _track = Os2.trackDisplay,
        _font = null,
        _upper = false;

  const Os2Text.headline(
    this.data, {
    super.key,
    this.color,
    this.size = 30,
    this.weight = FontWeight.w800,
    this.maxLines = 2,
    this.height = 1.08,
    this.align,
  })  : _track = Os2.trackHeadline,
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
        _font = null,
        _upper = false;

  const Os2Text.body(
    this.data, {
    super.key,
    this.color,
    this.size = 15,
    this.weight = FontWeight.w500,
    this.maxLines = 4,
    this.height = 1.36,
    this.align,
  })  : _track = Os2.trackBody,
        _font = null,
        _upper = false;

  const Os2Text.caption(
    this.data, {
    super.key,
    this.color,
    this.size = 11,
    this.weight = FontWeight.w700,
    this.maxLines = 2,
    this.height = 1.2,
    this.align,
  })  : _track = Os2.trackCaption,
        _font = null,
        _upper = true;

  const Os2Text.monoCap(
    this.data, {
    super.key,
    this.color,
    this.size = 12,
    this.weight = FontWeight.w800,
    this.maxLines = 1,
    this.height = 1.0,
    this.align,
  })  : _track = Os2.trackMonoCap,
        _font = 'Departure Mono',
        _upper = true;

  final String data;
  final Color? color;
  final double size;
  final FontWeight weight;
  final int maxLines;
  final double height;
  final TextAlign? align;
  final double _track;
  final String? _font;
  final bool _upper;

  @override
  Widget build(BuildContext context) {
    return Text(
      _upper ? data.toUpperCase() : data,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: TextStyle(
        fontFamily: _font,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: _track,
        height: height,
        color: color ?? Os2.inkHigh,
        // Aviation HUD — tabular numerals so digits never jitter as
        // counters / balances / readouts update.
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
