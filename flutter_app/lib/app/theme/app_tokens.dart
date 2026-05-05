import 'package:flutter/material.dart';

/// Design tokens — flagship-grade UI system.
///
/// Reference: Apple HIG, Google M3, Stripe Atlas, Linear's spacing.
/// Every value here is the single source of truth for spacing,
/// radii, motion, gradients, and elevation across the app.
class AppTokens {
  AppTokens._();

  // ── Spacing (4-pt grid) ────────────────────────────────────────────
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space7 = 32;
  static const double space8 = 40;
  static const double space9 = 56;
  static const double space10 = 72;
  static const double space11 = 96;

  // ── Radii ─────────────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radius2xl = 28;
  static const double radius3xl = 36;
  static const double radiusFull = 999;

  // ── Touch targets ─────────────────────────────────────────────────
  static const double iconButtonSize = 44; // Apple HIG floor.

  // ── Motion ────────────────────────────────────────────────────────
  static const Curve easeStandard = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve easeOutSoft = Cubic(0.16, 1, 0.3, 1);
  static const Curve easeInSoft = Cubic(0.4, 0, 1, 1);
  static const Curve easeOutQuart = Cubic(0.25, 1, 0.5, 1);
  static const Curve easeOutExpo = Cubic(0.16, 1, 0.3, 1);
  static const Curve easeOutBack = Cubic(0.34, 1.56, 0.64, 1);

  static const Duration durationXxs = Duration(milliseconds: 90);
  static const Duration durationXs = Duration(milliseconds: 140);
  static const Duration durationSm = Duration(milliseconds: 220);
  static const Duration durationMd = Duration(milliseconds: 320);
  static const Duration durationLg = Duration(milliseconds: 480);
  static const Duration durationXl = Duration(milliseconds: 700);
  static const Duration duration2xl = Duration(milliseconds: 1000);

  // ── Brand accents (8 swatches + custom HSL) ───────────────────────
  static const List<AccentSwatch> accents = [
    AccentSwatch('azure', Color(0xFF0EA5E9), Color(0xFF38BDF8)),
    AccentSwatch('cobalt', Color(0xFF1D4ED8), Color(0xFF3B82F6)),
    AccentSwatch('emerald', Color(0xFF059669), Color(0xFF10B981)),
    AccentSwatch('amber', Color(0xFFD97706), Color(0xFFF59E0B)),
    AccentSwatch('rose', Color(0xFFE11D48), Color(0xFFF43F5E)),
    AccentSwatch('coral', Color(0xFFEA580C), Color(0xFFFB923C)),
    AccentSwatch('plum', Color(0xFF7E22CE), Color(0xFFA855F7)),
    AccentSwatch('violet', Color(0xFF6D28D9), Color(0xFF8B5CF6)),
  ];

  static AccentSwatch accentByName(String name) =>
      accents.firstWhere((a) => a.name == name, orElse: () => accents.first);

  // ── Canvas (deep dark) ────────────────────────────────────────────
  /// Layered dark canvas — background → surface → elevated card.
  static const Color canvasDark = Color(0xFF05060A);
  static const Color surfaceDark = Color(0xFF0B0F1A);
  static const Color cardDark = Color(0xFF111827);
  static const Color borderDark = Color(0x1AFFFFFF);

  static const Color canvasLight = Color(0xFFF6F7FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0x14000000);

  // ── Elevation ladder ─────────────────────────────────────────────
  static List<BoxShadow> shadowSm({Color? tint}) => [
        BoxShadow(
          color: (tint ?? Colors.black).withValues(alpha: 0.10),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> shadowMd({Color? tint}) => [
        BoxShadow(
          color: (tint ?? Colors.black).withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> shadowLg({Color? tint}) => [
        BoxShadow(
          color: (tint ?? Colors.black).withValues(alpha: 0.32),
          blurRadius: 48,
          offset: const Offset(0, 28),
        ),
      ];
}

@immutable
class AccentSwatch {
  const AccentSwatch(this.name, this.shade600, this.shade400);
  final String name;
  final Color shade600;
  final Color shade400;

  Color get primary => shade600;
  Color get glow => shade400;

  /// Headliner gradient — used by hero cards, call-to-action chrome,
  /// and any surface that wants to broadcast brand identity.
  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [shade400, shade600],
      );

  /// Subtle wash — used behind icon tiles, glass surfaces, and
  /// micro-interaction accents.
  LinearGradient get washGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          shade400.withValues(alpha: 0.18),
          shade600.withValues(alpha: 0.08),
        ],
      );
}

/// Density modes — affect padding/typography multipliers.
enum AppDensity { compact, comfortable, spacious }

extension AppDensityX on AppDensity {
  double get scale {
    switch (this) {
      case AppDensity.compact:
        return 0.92;
      case AppDensity.comfortable:
        return 1.0;
      case AppDensity.spacious:
        return 1.08;
    }
  }
}
