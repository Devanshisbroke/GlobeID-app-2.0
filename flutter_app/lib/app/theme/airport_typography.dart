import 'package:flutter/material.dart';

/// Airport / Solari-board / runway-class typography presets.
///
/// Used by departure boards, gate countdowns, IATA tags, kiosk
/// surfaces and any place that wants a hard, mechanical, hyper-
/// readable display style. Maps onto the bundled Inter/Manrope
/// stack with tabular-figures + tight tracking.
class AirportFontStack {
  AirportFontStack._();

  /// Big departure board characters. Used by Solari flap component.
  static TextStyle board(BuildContext context, {double size = 36}) {
    final base = Theme.of(context).textTheme.headlineLarge;
    return (base ?? const TextStyle()).copyWith(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.6,
      fontFeatures: const [FontFeature.tabularFigures()],
      height: 1.0,
      color: Colors.white,
    );
  }

  /// Three-letter IATA airport codes. Used in journey strips,
  /// boarding pass legs, and departure tickers.
  static TextStyle iata(BuildContext context, {double size = 28}) {
    final base = Theme.of(context).textTheme.titleLarge;
    return (base ?? const TextStyle()).copyWith(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: 4.0,
      height: 1.05,
    );
  }

  /// Runway-style flight number. Tight, mono-leading, all caps.
  static TextStyle flightNumber(BuildContext context, {double size = 18}) {
    final base = Theme.of(context).textTheme.titleMedium;
    return (base ?? const TextStyle()).copyWith(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: 2.4,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Gate / terminal codes — small but still mechanical.
  static TextStyle gate(BuildContext context, {double size = 14}) {
    final base = Theme.of(context).textTheme.labelLarge;
    return (base ?? const TextStyle()).copyWith(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.8,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Countdown clock / split-flap timer.
  static TextStyle clock(BuildContext context, {double size = 32}) {
    final base = Theme.of(context).textTheme.headlineMedium;
    return (base ?? const TextStyle()).copyWith(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.4,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Caption used under board entries — "ON TIME", "BOARDING".
  static TextStyle caption(BuildContext context, {double size = 11}) {
    final base = Theme.of(context).textTheme.labelSmall;
    return (base ?? const TextStyle()).copyWith(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: 2.2,
    );
  }
}
