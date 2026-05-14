import 'package:flutter/material.dart';

/// Atelier — the GlobeID internal design-system reference.
///
/// Every brand primitive (Os2Text variants, BreathingHalo,
/// NfcPulse, HolographicFoil, LiveStatusPill, Pressable, etc.)
/// is enumerated here as a catalog entry so the operator can
/// browse, preview, and read the canonical usage notes in one
/// place. The catalog is intentionally a data-only model so the
/// component cards and detail screens can iterate it without
/// re-declaring the brand language.
class AtelierCatalog {
  AtelierCatalog._();

  /// The full ordered catalog. Domain order is deliberate —
  /// the operator descends from typography to interaction to
  /// state to live primitives, mirroring how a brand surface
  /// composes from the inside out.
  static const List<AtelierComponent> all = <AtelierComponent>[
    // ─── TYPOGRAPHY ───────────────────────────────────────────
    AtelierComponent(
      id: 'os2text-display',
      domain: AtelierDomain.typography,
      name: 'Os2Text.display',
      summary: 'Hero numeral / brand title · 44-56 pt · -2.4 tracking · w900',
      role: 'Used once per screen for the dominant figure (trust score, '
          'balance, queue percent). Pairs with mono-cap eyebrow above.',
      tokenSummary: 'Os2.textXxl → Os2.textH1 · letterSpacing -2.4 · '
          'fontWeight w900 · color: white or foil gold',
    ),
    AtelierComponent(
      id: 'os2text-headline',
      domain: AtelierDomain.typography,
      name: 'Os2Text.headline',
      summary: 'Section headline · 28-32 pt · -1.2 tracking · w800',
      role: 'Card titles, world entry banners, copilot strip headlines.',
      tokenSummary: 'Os2.textXl · letterSpacing -1.2 · fontWeight w800',
    ),
    AtelierComponent(
      id: 'os2text-body',
      domain: AtelierDomain.typography,
      name: 'Os2Text.body',
      summary: 'Body copy · 14-16 pt · +0.2 tracking · w500',
      role: 'Read-grade copy throughout cards, sheets, dossiers.',
      tokenSummary: 'Os2.textBase · letterSpacing +0.2 · fontWeight w500',
    ),
    AtelierComponent(
      id: 'os2text-monocap',
      domain: AtelierDomain.typography,
      name: 'Os2Text.monoCap',
      summary: 'Brand chrome eyebrow · Departure Mono · +1.6 tracking · w800',
      role: 'Every section eyebrow ("PHASE · 14A · TYPOGRAPHY"), case N°, '
          'status pill body. Locale-immutable.',
      tokenSummary: 'fontFamily Departure Mono · letterSpacing +1.6 · '
          'fontWeight w800 · case ALL CAPS',
    ),
    AtelierComponent(
      id: 'os2text-credential',
      domain: AtelierDomain.typography,
      name: 'Os2Text.credential',
      summary: 'Big stat numerals · tabular figures · hairline tracking',
      role: 'Trust score, queue %, FX rate, balance. Tabular so digits '
          'lock to a grid as values change.',
      tokenSummary: 'fontFeatures: tabular figures · letterSpacing -0.4 · '
          'fontWeight w900',
    ),
    AtelierComponent(
      id: 'os2text-watermark',
      domain: AtelierDomain.typography,
      name: 'Os2Text.watermark',
      summary: 'GLOBE · ID monogram chrome · 9 pt · 2.4 tracking · 18% white',
      role: 'Locked Latin LTR. Drifts on every Live surface and AppleSheet '
          'as the brand thread.',
      tokenSummary: 'fontSize 9 · letterSpacing +2.4 · color: white @ 18%',
    ),

    // ─── INTERACTION ──────────────────────────────────────────
    AtelierComponent(
      id: 'pressable',
      domain: AtelierDomain.interaction,
      name: 'Pressable',
      summary: 'Universal tappable affordance with semantic + haptic layer',
      role: 'Wraps every hot tappable in the app. Provides Semantics(button: '
          'true) when semanticLabel is set; auto-fires selection haptic on '
          'press.',
      tokenSummary: 'tap scale 0.96 · 120 ms easeOutCubic · selection haptic',
    ),
    AtelierComponent(
      id: 'magnetic-pressable',
      domain: AtelierDomain.interaction,
      name: 'MagneticPressable',
      summary: 'Premium-tier Pressable with magnetic pull-toward-cursor',
      role: 'Reserved for credential cards, premium tiles, and signet rows '
          'where the tap feels like attraction, not flatness.',
      tokenSummary: 'tap scale 0.94 · magnetic pull 6 px · spring rebound',
    ),

    // ─── STATE ────────────────────────────────────────────────
    AtelierComponent(
      id: 'os2-empty',
      domain: AtelierDomain.state,
      name: 'Os2EmptyState',
      summary: 'Cinematic empty state · mono-cap eyebrow + soft glow + CTA',
      role: 'Replaces every blank list. Eyebrow declares context, secondary '
          'CTA offers a way forward, halo glows in tone.',
      tokenSummary: 'tone-scoped halo · 1.4 s cinematic mount',
    ),
    AtelierComponent(
      id: 'os2-error',
      domain: AtelierDomain.state,
      name: 'Os2ErrorState',
      summary: 'Same chrome as empty, red accent + retry CTA + error code',
      role: 'Used when a Live data source fails. Error code stays mono so it '
          'can be screen-shotted and triaged.',
      tokenSummary: 'red accent #EF6464 · retry haptic · error code monospace',
    ),
    AtelierComponent(
      id: 'os2-loading',
      domain: AtelierDomain.state,
      name: 'Os2LoadingState',
      summary: 'Skeleton substrate with brand-tone shimmer',
      role: 'Replaces every spinner. Shimmer sweeps left → right in the '
          'tone of the host world.',
      tokenSummary: 'shimmer 1.6 s loop · easeInOut · 12 % opacity peak',
    ),
    AtelierComponent(
      id: 'cinematic-state-chrome',
      domain: AtelierDomain.state,
      name: 'CinematicStateChrome',
      summary: 'Substrate that frames empty / error / loading content',
      role: 'Internal scaffolding used by Os2EmptyState / Os2ErrorState / '
          'Os2LoadingState. Provides the OLED background + hairline frame.',
      tokenSummary: 'OLED #050505 · hairline 46 % white · 20 px radius',
    ),

    // ─── LIVE PRIMITIVES ──────────────────────────────────────
    AtelierComponent(
      id: 'breathing-halo',
      domain: AtelierDomain.live,
      name: 'BreathingHalo',
      summary: 'Soft radial halo that breathes 0.8 → 1.0 alpha at 4 s cadence',
      role: 'Renders behind Live credentials to signal aliveness. Cadence '
          'tightens to 2 s on urgent state (expiry, gate change).',
      tokenSummary: 'tone-scoped · 4 s cosine · ambient role (off when '
          'reduced motion)',
    ),
    AtelierComponent(
      id: 'holographic-foil',
      domain: AtelierDomain.live,
      name: 'HolographicFoil',
      summary: 'Tilt-driven gold sweep across credentials',
      role: 'Listens to accelerometer to drift a gold band across the '
          'credential surface. Replaces flat color with iridescent depth.',
      tokenSummary: 'D4AF37 → E9C75D gradient · 22° tilt range · 8 s loop',
    ),
    AtelierComponent(
      id: 'nfc-pulse',
      domain: AtelierDomain.live,
      name: 'NfcPulse',
      summary: 'Concentric ring pulse · 1.4 s loop · NFC armed signal',
      role: 'Fires while a credential is armed for tap. Stops the moment '
          'the tap completes. Doubles as scan-ready indicator on transit.',
      tokenSummary: 'gold ring · 3 staggered radii · ambient role',
    ),
    AtelierComponent(
      id: 'live-status-pill',
      domain: AtelierDomain.live,
      name: 'LiveStatusPill',
      summary: 'Mono-cap chip with state-keyed tone and breathing dot',
      role: 'Universal "alive" status indicator. ARMED (gold) · LIVE (azure) '
          '· STALE (amber) · OFFLINE (mute) · CRITICAL (coral).',
      tokenSummary: '+1.6 mono-cap · 3 px breathing dot · auto-tone',
    ),
    AtelierComponent(
      id: 'live-data-pulse',
      domain: AtelierDomain.live,
      name: 'LiveDataPulse',
      summary: 'Single-tick visualizer · plays when underlying data changes',
      role: 'Plays a 800 ms gold ring outward each time the bound value '
          'mutates. Used on FX rates, queue counts, gate updates.',
      tokenSummary: 'controller-driven · 800 ms easeOutCubic · signature role',
    ),
    AtelierComponent(
      id: 'rolling-digits',
      domain: AtelierDomain.live,
      name: 'RollingDigits',
      summary: 'Per-digit rolling counter for serial numbers / queue ticks',
      role: 'Each digit slides up/down with easeOutCubic when the underlying '
          'value crosses a tens boundary. Brand-correct alternative to '
          'TweenAnimationBuilder for credential-grade numerics.',
      tokenSummary: '400 ms per digit · easeOutCubic · tabular figures',
    ),
    AtelierComponent(
      id: 'globe-id-signature',
      domain: AtelierDomain.live,
      name: 'GlobeIdSignature',
      summary: 'Gold cursive signature stroke · plays on stamp commit',
      role: 'The hand-drawn "engineered by GlobeID" stroke that lays down '
          'on issuance ceremony, stamp commit, and seal commit moments.',
      tokenSummary: '1.2 s ink-loaded sweep · once per ceremony',
    ),
  ];

  /// Returns all components grouped by domain, preserving the
  /// authoring order within each domain.
  static Map<AtelierDomain, List<AtelierComponent>> grouped() {
    final map = <AtelierDomain, List<AtelierComponent>>{};
    for (final c in all) {
      map.putIfAbsent(c.domain, () => <AtelierComponent>[]).add(c);
    }
    return map;
  }

  /// Resolves a component by its stable id (used by routes).
  static AtelierComponent? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// A single primitive in the Atelier catalog.
class AtelierComponent {
  const AtelierComponent({
    required this.id,
    required this.domain,
    required this.name,
    required this.summary,
    required this.role,
    required this.tokenSummary,
  });

  /// Stable identifier used in routes (`/atelier/<id>`).
  final String id;

  /// Domain bucket this component belongs to.
  final AtelierDomain domain;

  /// Public Dart name (e.g. `Os2Text.display`).
  final String name;

  /// One-line summary surfaced on the gallery card.
  final String summary;

  /// Longer canonical role description on the detail screen.
  final String role;

  /// Token / spec summary surfaced on the detail screen.
  final String tokenSummary;
}

/// Domain bucket for the catalog ordering.
enum AtelierDomain {
  typography,
  interaction,
  state,
  live,
}

extension AtelierDomainMeta on AtelierDomain {
  String get label {
    switch (this) {
      case AtelierDomain.typography:
        return 'TYPOGRAPHY';
      case AtelierDomain.interaction:
        return 'INTERACTION';
      case AtelierDomain.state:
        return 'STATE';
      case AtelierDomain.live:
        return 'LIVE · PRIMITIVES';
    }
  }

  Color get tone {
    switch (this) {
      case AtelierDomain.typography:
        return const Color(0xFFD4AF37); // foil gold
      case AtelierDomain.interaction:
        return const Color(0xFFE9C75D); // foil light
      case AtelierDomain.state:
        return const Color(0xFF6B8FB8); // azure
      case AtelierDomain.live:
        return const Color(0xFFC9A961); // foil muted
    }
  }

  String get subtitle {
    switch (this) {
      case AtelierDomain.typography:
        return 'Type scale · tracking · weight ladder';
      case AtelierDomain.interaction:
        return 'Pressables · haptics · semantics';
      case AtelierDomain.state:
        return 'Empty · error · loading chrome';
      case AtelierDomain.live:
        return 'Foil · breathing halo · NFC pulse · rolling';
    }
  }
}
