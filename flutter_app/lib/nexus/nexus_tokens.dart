import 'package:flutter/material.dart';

/// Nexus — the canonical visual system for GlobeID, distilled from the
/// Travel OS + Global Wallet reference (lovable.app/os, /wallet).
///
/// Principles:
///  - Pure OLED black substrate. No big animated atmosphere gradients.
///  - Hairline borders, not shadows. Restrained.
///  - Aviation typography: tabular display readouts, eyebrow caps with
///    letter-spacing, mono for IDs / tokens.
///  - Champagne / tier gold is the single accent; everything else is
///    inkOnDark grayscale.
class N {
  N._();

  // ─────────────────────────────────────────────── substrate / ink
  /// Pure OLED background.
  static const Color bg = Color(0xFF000000);

  /// Card surface — used for NPanel.
  static const Color surface = Color(0xFF0A0A0C);

  /// Subtle elevated surface — for stacked layers.
  static const Color surfaceRaised = Color(0xFF111114);

  /// Inset surface — when a card sits inside another card.
  static const Color surfaceInset = Color(0xFF070708);

  /// Hairline color — 0.5 px border @ ~12 % opacity.
  static const Color hairline = Color(0x14FFFFFF);

  /// Heavier hairline — used for active state borders.
  static const Color hairlineHi = Color(0x33FFFFFF);

  // ─────────────────────────────────────────────── ink ladder
  static const Color ink = Color(0xFFF4F4F5);
  static const Color inkHi = Color(0xFFFAFAFA);
  static const Color inkMid = Color(0xFFA1A1AA);
  static const Color inkLow = Color(0xFF71717A);
  static const Color inkFaint = Color(0xFF52525B);
  static const Color inkGhost = Color(0xFF3F3F46);

  // ─────────────────────────────────────────────── accents (restrained)
  /// The single brand accent — used for tier marks + primary CTAs only.
  static const Color tierGold = Color(0xFFC9A961);
  static const Color tierGoldHi = Color(0xFFE3C083);
  static const Color tierGoldLow = Color(0xFF8E7641);

  /// Cool steel — for cabin / aviation accents.
  static const Color steel = Color(0xFF7280A8);
  static const Color steelHi = Color(0xFF93A3CC);

  // ─────────────────────────────────────────────── signal palette
  static const Color success = Color(0xFF3FB68B);
  static const Color warning = Color(0xFFE0A85B);
  static const Color critical = Color(0xFFD55656);
  static const Color info = Color(0xFF6B8FB8);

  // ─────────────────────────────────────────────── spacing
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s7 = 32;
  static const double s8 = 40;
  static const double s9 = 48;
  static const double s10 = 56;
  static const double s12 = 72;

  // ─────────────────────────────────────────────── page padding
  static const EdgeInsets pageX = EdgeInsets.symmetric(horizontal: s6);
  static const EdgeInsets pagePad = EdgeInsets.fromLTRB(s6, s4, s6, s9);
  static const EdgeInsets cardPad = EdgeInsets.all(s5);
  static const EdgeInsets cardPadTight = EdgeInsets.all(s4);
  static const EdgeInsets cardPadLoose = EdgeInsets.all(s6);

  // ─────────────────────────────────────────────── radii
  static const double rChip = 9999;
  static const double rPill = 9999;
  static const double rSmall = 10;
  static const double rCard = 18;
  static const double rCardLg = 22;
  static const double rSheet = 28;

  // ─────────────────────────────────────────────── motion durations
  static const Duration dInstant = Duration(milliseconds: 80);
  static const Duration dTap = Duration(milliseconds: 160);
  static const Duration dQuick = Duration(milliseconds: 220);
  static const Duration dSheet = Duration(milliseconds: 320);
  static const Duration dPage = Duration(milliseconds: 420);
  static const Duration dBanner = Duration(milliseconds: 320);
  static const Duration dPulse = Duration(milliseconds: 1800);

  // ─────────────────────────────────────────────── curves
  /// Default — tight ease-out.
  static const Curve ease = Cubic(0.16, 1.0, 0.3, 1.0);
  static const Curve easeIn = Cubic(0.4, 0.0, 1.0, 1.0);
  static const Curve easeOut = Cubic(0.0, 0.0, 0.2, 1.0);
  static const Curve subtle = Cubic(0.25, 0.46, 0.45, 0.94);

  // ─────────────────────────────────────────────── icon sizes
  static const double iconXs = 12;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;

  // ─────────────────────────────────────────────── stroke widths
  static const double strokeHair = 0.5;
  static const double strokeThin = 1.0;
  static const double strokeMed = 1.5;
  static const double strokeBold = 2.0;
}
