import 'package:flutter/material.dart';

/// OS 2.0 — design tokens for the new product layer.
///
/// This is the canonical source of every spatial / chromatic /
/// typographic constant used by widgets in `lib/os2/`. Nothing in this
/// directory reaches into `lib/app/theme/app_tokens.dart` — the old
/// theme layer is preserved for the legacy `lib/features/` tree, but
/// the OS 2.0 layer carries its own (deliberately stricter) tokens.
class Os2 {
  Os2._();

  // ───────────────────────────────────────────────────────── canvas
  // OLED-first. Canvas is true black; depth comes from the floor tier,
  // never from coloured backgrounds.
  static const Color canvas = Color(0xFF000000);
  static const Color floor1 = Color(0xFF050608); // surface tier
  static const Color floor2 = Color(0xFF0A0C12); // slab tier
  static const Color floor3 = Color(0xFF11141C); // raised tier
  static const Color hairline = Color(0x14FFFFFF); // 8% white
  static const Color hairlineSoft = Color(0x0AFFFFFF); // 4% white

  // ───────────────────────────────────────────────────────── ink
  static const Color ink = Color(0xFFFFFFFF);
  static const Color inkBright = Color(0xFFFFFFFF); // 100%
  static const Color inkHigh = Color(0xE6FFFFFF); // 90%
  static const Color inkMid = Color(0xB3FFFFFF); // 70%
  static const Color inkLow = Color(0x7AFFFFFF); // 48%
  static const Color inkFaint = Color(0x4DFFFFFF); // 30%

  // ───────────────────────────────────────────── world tones (signals)
  // Each world owns ONE tone. Used sparingly: halo, accent text,
  // active dock pill, breathing rim — never as a full background.
  // Tuned restrained — champagne / muted aviation tones, no neon.
  static const Color pulseTone = Color(0xFFC9A961); // champagne gold
  static const Color identityTone = Color(0xFFB8902B); // foil-gold (deeper)
  static const Color walletTone = Color(0xFF3FB68B); // muted treasury
  static const Color travelTone = Color(0xFF7280A8); // cool steel (not cyan)
  static const Color discoverTone = Color(0xFF4FA88B); // muted equator
  static const Color servicesTone = Color(0xFFC9A961); // champagne (unified)

  // ───────────────────────────────────────────────────── signal palette
  // Restrained signal tones — aviation HUD, not iOS notification badges.
  static const Color signalLive = Color(0xFF6B8FB8); // info steel
  static const Color signalAttention = Color(0xFFE0A85B); // amber
  static const Color signalCritical = Color(0xFFD55656); // critical
  static const Color signalSettled = Color(0xFF3FB68B); // success

  // ───────────────────────────────────────────────────── spatial ladder
  // 4-base scale. Every dimension in os2/ snaps to this grid.
  static const double space0 = 0;
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

  // ───────────────────────────────────────────────────── radii
  // Continuous-curve squircle radii — `Os2Card` and `Os2Panel` use a
  // larger radius than legacy widgets to read as a single sculpted
  // slab, not a stamped rectangle.
  static const double rChip = 100; // pill
  static const double rTile = 14;
  static const double rCard = 24;
  static const double rSlab = 32;
  static const double rHero = 40;
  static const double rFloor = 56;

  // ───────────────────────────────────────────────────── motion
  // Apple-style critically-damped spring tempos. All motion in OS 2.0
  // routes through one of these — no ad-hoc Curves.easeOut anywhere.
  static const Duration mIn = Duration(milliseconds: 280);
  static const Duration mOut = Duration(milliseconds: 220);
  static const Duration mFlick = Duration(milliseconds: 180);
  static const Duration mCruise = Duration(milliseconds: 420);
  static const Duration mPortal = Duration(milliseconds: 620);
  static const Duration mBreathSlow = Duration(milliseconds: 7400);
  static const Duration mBreathFast = Duration(milliseconds: 2200);

  static const Curve cTakeoff = Cubic(0.16, 1.0, 0.32, 1.0); // ease-out-back-ish
  static const Curve cCruise = Cubic(0.42, 0.0, 0.10, 1.0); // standard
  static const Curve cBank = Cubic(0.65, 0.0, 0.35, 1.0); // emphasis
  static const Curve cDescent = Cubic(0.55, 0.0, 1.0, 0.45); // ease-in
  static const Curve cTaxi = Cubic(0.33, 1.0, 0.68, 1.0); // ease-out-quad

  // ───────────────────────────────────────────────────── typography
  // Restraint tracking. The bible's tracking ladder. All Os2Text
  // helpers default to these, no per-callsite letterSpacing.
  static const double trackDisplay = -2.4;
  static const double trackHeadline = -1.2;
  static const double trackTitle = -0.4;
  static const double trackBody = 0.2;
  static const double trackCaption = 0.8;
  static const double trackMonoCap = 1.6;

  // ───────────────────────────────────────────────────── type scale
  //
  // Canonical sizes used across every world. Whenever a callsite
  // overrides `Os2Text.<variant>(size: …)` it should pick from these
  // tokens rather than hard-coding a magic number. Keeping the set
  // small (10 steps) is what makes typography read uniform across
  // unrelated surfaces.
  //
  //   • tiny / micro / xs   — mono-cap chips, status pills, watermarks
  //   • sm / md             — compact callouts, dense labels
  //   • base                — body default
  //   • lg / xl             — small headers / title default
  //   • xxl                 — emphatic title
  //   • h2 / h1             — headline / display
  static const double textTiny = 9;
  static const double textMicro = 10;
  static const double textXs = 11;
  static const double textSm = 12;
  static const double textMd = 13;
  static const double textRg = 14;
  static const double textBase = 15;
  static const double textLg = 16;
  static const double textXl = 18;
  static const double textXxl = 22;
  static const double textH2 = 30;
  static const double textH1 = 48;

  /// Canonical default size for each `Os2Text` variant. Used by
  /// [trackingFor] to relax letter-spacing proportionally when a
  /// callsite shrinks a variant below its canonical anchor.
  static const double canonDisplay = textH1;
  static const double canonHeadline = textH2;
  static const double canonTitle = 20;
  static const double canonBody = textBase;
  static const double canonCaption = textXs;
  static const double canonMonoCap = textSm;

  /// Returns the letter-spacing to apply at [size] for a variant whose
  /// canonical tracking is [track] at [canonical] size.
  ///
  /// At sizes ≥ [canonical] the canonical tracking is used unchanged
  /// (tighter tracking reads correctly at the design size). At sizes
  /// below [canonical] we scale tracking linearly toward 0 so a
  /// `title` rendered at 14 pt doesn't carry the same -0.4 squeeze
  /// that's tuned for the 20 pt anchor.
  static double trackingFor(double track, double size, double canonical) {
    if (size >= canonical) return track;
    return track * (size / canonical);
  }

  // ─────────────────────────────────────────────── brand DNA palette
  //
  // The two-stop gold the entire app pulls from for hero text, foil
  // sweeps, hairlines, and the GLOBE·ID monogram. Kept on the tokens
  // class so every surface that ramps gold reaches for the same
  // canonical colour pair instead of inventing its own.
  static const Color goldDeep = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE9C75D);

  /// Canonical hero gradient — the soft champagne ramp that the
  /// display / headline / credential variants opt into when they want
  /// to read "engineered by GlobeID" instead of flat white.
  static const LinearGradient foilGoldHero = LinearGradient(
    colors: [goldDeep, goldLight, goldDeep],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gold rule painted under the GLOBE·ID watermark — same alpha the
  /// AppleSheet substrate uses so the watermark and the sheet chrome
  /// share one thread.
  static const Color goldHairline = Color(0x6BD4AF37); // 42% alpha

  // ───────────────────────────────────────────────────── touch
  static const double touchMin = 56;
  static const double touchTight = 44;

  // ───────────────────────────────────────────────────── hairline
  static const double strokeFine = 0.5;
  static const double strokeRegular = 0.8;
  static const double strokeBold = 1.2;
}

/// World identifier — every screen in `lib/os2/worlds/` belongs to one.
/// Routing, palette, lighting, and the dock active state all derive
/// from this enum.
enum Os2World {
  pulse,
  identity,
  wallet,
  travel,
  discover,
  services,
}

extension Os2WorldX on Os2World {
  Color get tone {
    switch (this) {
      case Os2World.pulse:
        return Os2.pulseTone;
      case Os2World.identity:
        return Os2.identityTone;
      case Os2World.wallet:
        return Os2.walletTone;
      case Os2World.travel:
        return Os2.travelTone;
      case Os2World.discover:
        return Os2.discoverTone;
      case Os2World.services:
        return Os2.servicesTone;
    }
  }

  String get label {
    switch (this) {
      case Os2World.pulse:
        return 'Pulse';
      case Os2World.identity:
        return 'Identity';
      case Os2World.wallet:
        return 'Wallet';
      case Os2World.travel:
        return 'Travel';
      case Os2World.discover:
        return 'Discover';
      case Os2World.services:
        return 'Services';
    }
  }

  IconData get icon {
    switch (this) {
      case Os2World.pulse:
        return Icons.graphic_eq_rounded;
      case Os2World.identity:
        return Icons.workspace_premium_rounded;
      case Os2World.wallet:
        return Icons.account_balance_rounded;
      case Os2World.travel:
        return Icons.flight_takeoff_rounded;
      case Os2World.discover:
        return Icons.travel_explore_rounded;
      case Os2World.services:
        return Icons.room_service_rounded;
    }
  }

  String get route {
    switch (this) {
      case Os2World.pulse:
        return '/';
      case Os2World.identity:
        return '/identity';
      case Os2World.wallet:
        return '/wallet';
      case Os2World.travel:
        return '/travel';
      case Os2World.discover:
        return '/discover';
      case Os2World.services:
        return '/services';
    }
  }
}
