import 'package:flutter/material.dart';

/// Phase-7 design tokens, ported from `tailwind.config.ts` and
/// `lib/design-system.ts` / `lib/motion-tokens.ts` in the React app.
///
/// All tokens are static + const so they can be referenced from anywhere
/// without provider scoping.
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

  // ── Radii ─────────────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radius2xl = 28;
  static const double radiusFull = 999;

  // ── Touch targets ─────────────────────────────────────────────────
  static const double iconButtonSize = 44; // Apple HIG floor.

  // ── Motion ────────────────────────────────────────────────────────
  /// Standard easings, ported from `lib/motion-tokens.ts`.
  static const Curve easeStandard = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve easeOutSoft = Cubic(0.16, 1, 0.3, 1);
  static const Curve easeInSoft = Cubic(0.4, 0, 1, 1);
  static const Curve easeOutQuart = Cubic(0.25, 1, 0.5, 1);

  // Spring presets — used by [SpringSimulation]-driven page transitions.
  static const Duration durationXxs = Duration(milliseconds: 90);
  static const Duration durationXs = Duration(milliseconds: 140);
  static const Duration durationSm = Duration(milliseconds: 220);
  static const Duration durationMd = Duration(milliseconds: 320);
  static const Duration durationLg = Duration(milliseconds: 480);
  static const Duration durationXl = Duration(milliseconds: 700);

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

  static AccentSwatch accentByName(String name) {
    return accents.firstWhere(
      (a) => a.name == name,
      orElse: () => accents.first,
    );
  }
}

@immutable
class AccentSwatch {
  const AccentSwatch(this.name, this.shade600, this.shade400);
  final String name;
  final Color shade600;
  final Color shade400;

  Color get primary => shade600;
  Color get glow => shade400;
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
