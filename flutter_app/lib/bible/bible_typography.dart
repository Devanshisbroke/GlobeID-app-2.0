import 'package:flutter/material.dart';

import 'bible_tokens.dart';

/// GlobeID UI/UX Bible — typography system (§4.2).
///
/// The Bible specifies three typefaces:
///   * **Atlas Grotesk** (display, headlines, hero numerals) — geometric.
///   * **Söhne** (body, labels, dense data) — neutral, high legibility.
///   * **Departure Mono** (flight numbers, MRZ, gate codes, FX) —
///     monospaced with a split-flap variant.
///
/// We do not ship licensed type with the prototype. Until the licensed
/// faces are bundled, we render via system fallbacks but apply the
/// Bible's letter-spacing, weight, and tracking rules so the visual
/// register is preserved. Once licensed assets land, swap `_display`,
/// `_body`, `_mono` to the bundled family names.
class BType {
  BType._();

  // Font family slugs. Swap these to the licensed family when the
  // assets land (without touching call sites).
  static const String _display =
      '.SF Pro Display'; // iOS — falls back to Roboto on Android
  static const String _body = '.SF Pro Text';
  static const String _mono = 'monospace';

  // ────────────────────────────────────── hero numerals (Atlas display)

  /// Hero numeral — used for Solari balance, countdown, runway numbers.
  static TextStyle heroNumeral({
    Color color = B.inkOnDark,
    double size = 56,
  }) =>
      TextStyle(
        fontFamily: _display,
        fontSize: size,
        fontWeight: FontWeight.w300,
        height: 1.0,
        letterSpacing: -1.6,
        color: color,
      );

  /// Display H1 — onboarding hero, welcome card, recap card.
  static TextStyle display({
    Color color = B.inkOnDark,
    double size = 32,
  }) =>
      TextStyle(
        fontFamily: _display,
        fontSize: size,
        fontWeight: FontWeight.w500,
        height: 1.06,
        letterSpacing: -0.7,
        color: color,
      );

  /// Title — section headers, hero card titles.
  static TextStyle title({
    Color color = B.inkOnDark,
    double size = 20,
  }) =>
      TextStyle(
        fontFamily: _display,
        fontSize: size,
        fontWeight: FontWeight.w500,
        height: 1.15,
        letterSpacing: -0.3,
        color: color,
      );

  /// Section header.
  static TextStyle section({
    Color color = B.inkOnDarkMid,
    double size = 13,
  }) =>
      TextStyle(
        fontFamily: _body,
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: 1.15,
        letterSpacing: 1.4,
        color: color,
      );

  // ────────────────────────────────────── body & labels (Söhne)

  /// Body — primary copy.
  static TextStyle body({
    Color color = B.inkOnDarkHigh,
    double size = 15,
  }) =>
      TextStyle(
        fontFamily: _body,
        fontSize: size,
        fontWeight: FontWeight.w400,
        height: 1.35,
        letterSpacing: -0.1,
        color: color,
      );

  /// Caption — small explanatory copy.
  static TextStyle caption({
    Color color = B.inkOnDarkMid,
    double size = 12.5,
  }) =>
      TextStyle(
        fontFamily: _body,
        fontSize: size,
        fontWeight: FontWeight.w400,
        height: 1.36,
        letterSpacing: 0,
        color: color,
      );

  /// Eyebrow — uppercase tone-tinted label above section.
  static TextStyle eyebrow({
    Color color = B.inkOnDarkLow,
    double size = 10.5,
  }) =>
      TextStyle(
        fontFamily: _body,
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.0,
        letterSpacing: 1.8,
        color: color,
      );

  // ────────────────────────────────────── Departure Mono

  /// Mono caption — flight numbers, gate codes, FX rates.
  static TextStyle mono({
    Color color = B.inkOnDark,
    double size = 13,
    FontWeight weight = FontWeight.w500,
  }) =>
      TextStyle(
        fontFamily: _mono,
        fontFamilyFallback: const [
          'JetBrainsMono',
          'FiraMono',
          'IBMPlexMono',
          'monospace',
        ],
        fontSize: size,
        fontWeight: weight,
        height: 1.05,
        letterSpacing: 0.6,
        color: color,
      );

  /// Mono cap — uppercase, used for ribbon labels and gate codes.
  static TextStyle monoCap({
    Color color = B.inkOnDarkMid,
    double size = 11,
  }) =>
      TextStyle(
        fontFamily: _mono,
        fontFamilyFallback: const [
          'JetBrainsMono',
          'FiraMono',
          'IBMPlexMono',
          'monospace',
        ],
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.0,
        letterSpacing: 1.4,
        color: color,
      );

  /// Solari numeral — large flap-board number.
  static TextStyle solari({
    Color color = B.inkOnDark,
    double size = 36,
  }) =>
      TextStyle(
        fontFamily: _mono,
        fontFamilyFallback: const [
          'JetBrainsMono',
          'FiraMono',
          'IBMPlexMono',
          'monospace',
        ],
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.0,
        letterSpacing: 1.0,
        color: color,
      );
}

/// Convenience widgets so call-sites read like:
///   `BText.title('Identity')`.
class BText {
  BText._();

  static Widget heroNumeral(
    String text, {
    Color color = B.inkOnDark,
    double size = 56,
    TextAlign? align,
  }) =>
      Text(
        text,
        textAlign: align,
        style: BType.heroNumeral(color: color, size: size),
      );

  static Widget display(
    String text, {
    Color color = B.inkOnDark,
    double size = 32,
    int? maxLines,
    TextAlign? align,
  }) =>
      Text(
        text,
        maxLines: maxLines,
        overflow:
            maxLines == null ? null : TextOverflow.ellipsis,
        textAlign: align,
        style: BType.display(color: color, size: size),
      );

  static Widget title(
    String text, {
    Color color = B.inkOnDark,
    double size = 20,
    int? maxLines,
    TextAlign? align,
  }) =>
      Text(
        text,
        maxLines: maxLines,
        overflow:
            maxLines == null ? null : TextOverflow.ellipsis,
        textAlign: align,
        style: BType.title(color: color, size: size),
      );

  static Widget section(
    String text, {
    Color color = B.inkOnDarkMid,
  }) =>
      Text(
        text.toUpperCase(),
        style: BType.section(color: color),
      );

  static Widget body(
    String text, {
    Color color = B.inkOnDarkHigh,
    int? maxLines,
    TextAlign? align,
  }) =>
      Text(
        text,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        textAlign: align,
        style: BType.body(color: color),
      );

  static Widget caption(
    String text, {
    Color color = B.inkOnDarkMid,
    int? maxLines,
    TextAlign? align,
  }) =>
      Text(
        text,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        textAlign: align,
        style: BType.caption(color: color),
      );

  static Widget eyebrow(
    String text, {
    Color color = B.inkOnDarkLow,
  }) =>
      Text(
        text.toUpperCase(),
        style: BType.eyebrow(color: color),
      );

  static Widget mono(
    String text, {
    Color color = B.inkOnDark,
    double size = 13,
    FontWeight weight = FontWeight.w500,
  }) =>
      Text(
        text,
        style: BType.mono(color: color, size: size, weight: weight),
      );

  static Widget monoCap(
    String text, {
    Color color = B.inkOnDarkMid,
    double size = 11,
  }) =>
      Text(
        text.toUpperCase(),
        style: BType.monoCap(color: color, size: size),
      );

  static Widget solari(
    String text, {
    Color color = B.inkOnDark,
    double size = 36,
  }) =>
      Text(
        text,
        style: BType.solari(color: color, size: size),
      );
}
