import 'package:flutter/material.dart';

/// GlobeID — UI/UX Bible canonical design tokens.
///
/// This is the **single source of truth** for every color, curve,
/// duration, spacing token, density tier, altitude level, emotional
/// register, and material identifier referenced by widgets under
/// `lib/bible/`.
///
/// The Bible layer is a deliberate evolution of `lib/os2/`. Where OS2
/// chose pitch-black as a non-negotiable canvas, the Bible reintroduces
/// the *substrate palette* — Midnight Indigo, Cabin Charcoal, Tarmac
/// Slate, Vellum Bone, Snowfield White — and treats each register as a
/// physically grounded atmosphere with its own ambient light.
///
/// Read in conjunction with `UI_UX_BIBLE.md` at the repo root.
class B {
  B._();

  // ────────────────────────────────────────────── substrate palette (§4.1)
  /// Root background — lock, globe, deep sleep, idle stillness.
  static const Color midnightIndigo = Color(0xFF05060A);

  /// Interior surfaces at altitude (cabin) — home, services, copilot.
  static const Color cabinCharcoal = Color(0xFF0E1117);

  /// Ground-level surfaces — wallet, treasury, kiosk.
  static const Color tarmacSlate = Color(0xFF161A22);

  /// Paper-light surface for documents (passport, journal, recap).
  static const Color vellumBone = Color(0xFFF4EFE6);

  /// Document substrate — boarding pass, receipts.
  static const Color snowfieldWhite = Color(0xFFFBFBFD);

  // ────────────────────────────────────────────── tone palettes (§4.1)
  // Each register picks one tone (rule: 1 substrate + 1 tone + at most
  // 1 signal). Tones are physically grounded — paper substrates lean
  // into warm tones (foil gold, garnet); cabin substrates lean cool
  // (jet cyan, aurora violet).

  // Identity / passport
  static const Color diplomaticGarnet = Color(0xFF7A1D2E);
  static const Color foilGold = Color(0xFFB8902B);
  static const Color stampInk = Color(0xFF0B1B3A);

  // Wallet / payments
  static const Color treasuryGreen = Color(0xFF0E7A4F);
  static const Color waxCrimson = Color(0xFFA02B3C);
  static const Color mintGlass = Color(0xFF7FE3C4);

  // Travel / boarding
  static const Color jetCyan = Color(0xFF0EA5E9);
  static const Color auroraViolet = Color(0xFF7C3AED);
  static const Color runwayAmber = Color(0xFFF59E0B);

  // Globe / map
  static const Color equatorTeal = Color(0xFF10B981);
  static const Color horizonCoral = Color(0xFFFB7185);
  static const Color polarBlue = Color(0xFF3B82F6);

  // Lounge / arrival
  static const Color champagneSand = Color(0xFFD9C19A);
  static const Color velvetMauve = Color(0xFF8B5A6E);
  static const Color honeyAmber = Color(0xFFE0A85B);

  // ────────────────────────────────────────────── signal palette (§4.1)
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);

  // ────────────────────────────────────────────── ink (text on substrate)
  // Built so that *every* tone above passes WCAG AA on the substrate
  // it is paired with by the Bible.
  static const Color inkOnDark = Color(0xFFFFFFFF);
  static const Color inkOnDarkHigh = Color(0xE6FFFFFF);
  static const Color inkOnDarkMid = Color(0xB3FFFFFF);
  static const Color inkOnDarkLow = Color(0x80FFFFFF);
  static const Color inkOnDarkFaint = Color(0x4DFFFFFF);

  static const Color inkOnLight = Color(0xFF0B0E14);
  static const Color inkOnLightHigh = Color(0xE60B0E14);
  static const Color inkOnLightMid = Color(0xB30B0E14);
  static const Color inkOnLightLow = Color(0x800B0E14);

  // Hairlines for borders (per material).
  static const Color hairlineLight = Color(0x14FFFFFF); // 8% on dark
  static const Color hairlineLightSoft = Color(0x0AFFFFFF); // 4% on dark
  static const Color hairlineDark = Color(0x140B0E14); // 8% on light
  static const Color hairlineDarkSoft = Color(0x0A0B0E14); // 4% on light

  // ────────────────────────────────────────────── spacing (§4.6, modular 4-px)
  static const double space0 = 0;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 24;
  static const double space6 = 32;
  static const double space7 = 40;
  static const double space8 = 56;
  static const double space9 = 80;

  // ────────────────────────────────────────────── radii
  static const double rPill = 999;
  static const double rTile = 14;
  static const double rCard = 22;
  static const double rSlab = 28;
  static const double rHero = 36;
  static const double rFloor = 56;

  // ────────────────────────────────────────────── motion curves (§5.1)
  /// `takeoff` — ease-out-back-soft. Default entrance.
  static const Curve takeoff = Cubic(0.16, 1.0, 0.30, 1.0);

  /// `cruise` — neutral, used for layout shifts.
  static const Curve cruise = Curves.easeInOutCubic;

  /// `bank` — over-bouncy, for chip taps and selection.
  static const Curve bank = Cubic(0.34, 1.56, 0.64, 1.0);

  /// `descent` — exits, dismissals.
  static const Curve descent = Curves.easeInCubic;

  /// `taxi` — settles, used for state collapse.
  static const Curve taxi = Cubic(0.45, 0.0, 0.55, 1.0);

  // ────────────────────────────────────────────── motion durations
  static const Duration dQuick = Duration(milliseconds: 180);
  static const Duration dIn = Duration(milliseconds: 280);
  static const Duration dOut = Duration(milliseconds: 220);
  static const Duration dSheet = Duration(milliseconds: 360);
  static const Duration dPortal = Duration(milliseconds: 620);
  static const Duration dPour = Duration(milliseconds: 1100);

  // Choreography (§5.2)
  static const Duration cHero = Duration.zero;
  static const Duration cSection = Duration(milliseconds: 120);
  static const Duration cFirstCard = Duration(milliseconds: 160);
  static const Duration cCardStep = Duration(milliseconds: 60);
  static const Duration cChrome = Duration(milliseconds: 320);

  // Ambient (§5.4)
  /// Substrate gradient bloom drift period.
  static const Duration ambientBloom = Duration(seconds: 60);

  /// Lock screen orbital sweep period.
  static const Duration lockOrbit = Duration(seconds: 8);

  /// Boarding pass barcode breathing period.
  static const Duration barcodeBreath = Duration(milliseconds: 4000);

  /// Wallet currency cylinder breath.
  static const Duration cylinderBreath = Duration(milliseconds: 5200);

  /// Generic surface breath (matches OS2's slow tempo).
  static const Duration substrateBreath = Duration(milliseconds: 7400);

  // ────────────────────────────────────────────── live-gradient stops
  /// 4-stop ambient gradient durations for the substrate (§4.1).
  static const Duration livingGradient = Duration(seconds: 72);

  // ────────────────────────────────────────────── parallax depth slots (§8.1)
  /// Background gradient parallax weight.
  static const double slot0 = 0.05;

  /// Substrate / paper parallax weight.
  static const double slot1 = 0.15;

  /// Content (text, photo, numbers) parallax weight.
  static const double slot2 = 0.30;

  /// Foil sheen / specular highlight parallax weight.
  static const double slot3 = 0.65;

  /// Chip / hologram element parallax weight.
  static const double slot4 = 0.85;

  // ────────────────────────────────────────────── glass material (§4.3)
  static const double glassBlurSigma = 14;
  static const Color glassTint = Color(0x0FFFFFFF); // ~6% white
  static const Color glassHairline = Color(0x1FFFFFFF); // ~12% white
}

// ──────────────────────────────────────────────── emotional spine (§2)

/// The four emotional states GlobeID is engineered to make a user
/// feel. Every screen is tagged with one (and only one) state. The
/// state drives substrate color bias, motion tempo, and haptic
/// register defaults.
enum BEmotion {
  /// Idle, lock screen, between trips. Deep midnight, sparse, slow drift.
  stillness,

  /// Pre-trip, packing, visa pending. Warm dusk, gentle glow, countdowns.
  anticipation,

  /// Boarding, kiosk, scan, payment. High contrast, kinetic, percussive.
  activation,

  /// Arrival, lounge, journal, recap. Sunlit, ambient, floaty.
  recovery,
}

extension BEmotionX on BEmotion {
  /// Default substrate for this emotional state.
  Color get substrate {
    switch (this) {
      case BEmotion.stillness:
        return B.midnightIndigo;
      case BEmotion.anticipation:
        return B.cabinCharcoal;
      case BEmotion.activation:
        return B.tarmacSlate;
      case BEmotion.recovery:
        return B.cabinCharcoal;
    }
  }

  /// Default ambient bloom color overlay for the substrate (≤6% alpha).
  Color get bloom {
    switch (this) {
      case BEmotion.stillness:
        return B.polarBlue.withValues(alpha: 0.04);
      case BEmotion.anticipation:
        return B.runwayAmber.withValues(alpha: 0.05);
      case BEmotion.activation:
        return B.jetCyan.withValues(alpha: 0.06);
      case BEmotion.recovery:
        return B.honeyAmber.withValues(alpha: 0.05);
    }
  }
}

// ──────────────────────────────────────────────── altitude metaphor (§3)

/// Five altitudes above the planet. Every screen sits at one.
/// Transitions implicitly move the camera up or down this stack —
/// vertical axis, blur-on-distance, and curve tempo all derived.
enum BAltitude {
  geosynchronous, // Globe, Cassini orbit.
  stratospheric, // Travel, trip detail.
  tower, // Airport, boarding, kiosk.
  pedestrian, // Lounge, services, restaurants.
  intimate, // Identity, passport, wallet, vault.
}

extension BAltitudeX on BAltitude {
  /// Numeric altitude (0..4) used to compute transition blur + direction.
  int get rank {
    switch (this) {
      case BAltitude.geosynchronous:
        return 0;
      case BAltitude.stratospheric:
        return 1;
      case BAltitude.tower:
        return 2;
      case BAltitude.pedestrian:
        return 3;
      case BAltitude.intimate:
        return 4;
    }
  }
}

// ──────────────────────────────────────────────── density tier (§4.6)

/// Three density tiers controlled by emotional register, not data volume.
enum BDensity {
  cabin, // compact — FX board, transactions
  concourse, // default
  atrium, // generous — hero / onboarding / lounge
}

extension BDensityX on BDensity {
  EdgeInsets get pagePadding {
    switch (this) {
      case BDensity.cabin:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 12);
      case BDensity.concourse:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
      case BDensity.atrium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 24);
    }
  }

  double get gap {
    switch (this) {
      case BDensity.cabin:
        return B.space2;
      case BDensity.concourse:
        return B.space3;
      case BDensity.atrium:
        return B.space5;
    }
  }
}

// ──────────────────────────────────────────────── material registry (§4.3)

/// One of the five canonical materials. Materials never mix on a
/// single surface — `BibleGlass`, `BibleFoil`, `BiblePaper`,
/// `BibleMetal`, `BibleAtmosphere`.
enum BMaterial { glass, foil, paper, metal, atmosphere }

// ──────────────────────────────────────────────── render quality (§15)

/// User-selectable render tier — drops blur/particle/shader features.
enum BRenderQuality { reduced, normal, max }

// ──────────────────────────────────────────────── lighting model (§4.4)

/// Single virtual light source per screen, expressed in degrees
/// (0° = right, 90° = up, 180° = left, 270° = down).
class BLight {
  const BLight({required this.angleDeg, required this.intensity});
  final double angleDeg;
  final double intensity; // 0..1

  /// Convert to a unit direction vector (`(dx, dy)` with origin
  /// upper-left).
  Offset get direction {
    final radians = angleDeg * 3.141592653589793 / 180.0;
    // Flutter screen y is inverted (positive = down).
    return Offset(0, 0) +
        Offset(
          intensity * (radians == 0 ? 1.0 : 1.0) *
              (angleDeg == 0
                  ? 1.0
                  : (angleDeg == 90
                      ? 0.0
                      : (angleDeg == 180 ? -1.0 : 0.0))),
          intensity * (angleDeg == 90 ? -1.0 : (angleDeg == 270 ? 1.0 : 0.0)),
        );
  }
}
