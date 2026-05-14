import 'package:flutter/material.dart';

/// Atelier — brand DNA timeline.
///
/// Authoritative phase history. Each entry captures one shipped
/// chapter of the GlobeID design language: what landed, what brand
/// invariant it codified, and what design moment it added.
///
/// The timeline is intentionally append-only. Existing entries are
/// never rewritten — they are the historical record. New phases
/// extend the tail.
class BrandDnaTimeline {
  BrandDnaTimeline._();

  static const List<DnaChapter> chapters = <DnaChapter>[
    DnaChapter(
      id: 'phase-01',
      phaseLabel: 'PHASE · 01',
      title: 'Foundation · Ecosystem stabilization',
      headline: 'Every route wired, every dead CTA reconnected',
      summary:
          'The first pass made the world coherent. Orphan routes '
          'closed, dead CTAs reconnected, navigation tree audited '
          'end-to-end. Set the rule that no surface ships without '
          'being reachable from at least one entry point.',
      brandInvariant:
          'No dead routes. Every screen is reachable from app chrome.',
      tone: Color(0xFFD4AF37),
    ),
    DnaChapter(
      id: 'phase-02',
      phaseLabel: 'PHASE · 02',
      title: 'Nexus · Services + sheet substrate',
      headline: 'Services ecosystem speaks the GlobeID language',
      summary:
          'Brought the Services world onto the Nexus design '
          'language: mono-cap chrome, foil hairline, OLED canvas. '
          'Every sheet got the cinematic substrate. Notifications '
          'shifted from system chrome to brand chrome.',
      brandInvariant:
          'Sheets are physical glass: blur backdrop · gold hairline '
          'under handle · OLED gradient · detent snap.',
      tone: Color(0xFFD4AF37),
    ),
    DnaChapter(
      id: 'phase-03',
      phaseLabel: 'PHASE · 03',
      title: 'Refinement · Motion + haptics taxonomy',
      headline: 'Named motion vocabulary; semantic haptic vocabulary',
      summary:
          'Codified every duration + curve into the Motion '
          'taxonomy. Codified every tactile gesture into the '
          'Haptics vocabulary. No more ad-hoc 250 ms or '
          'lightImpact() — every motion + tap is a named '
          'brand decision.',
      brandInvariant:
          'Motion + haptics ship from a named vocabulary, not '
          'magic numbers. dPage, sCrisp, Haptics.signature.',
      tone: Color(0xFFC9A961),
    ),
    DnaChapter(
      id: 'phase-04',
      phaseLabel: 'PHASE · 04',
      title: 'Alive · Live surface elevation',
      headline: 'Every Live surface gained a real "alive" cadence',
      summary:
          'Visa expiry urgency, Forex directional FX, Country '
          'threat mood, Transit NFC tap states, Customs lock-in '
          'shake, Passport iridescent strip, Navigation rim '
          'shimmer. Every surface that claims to be live now '
          'reads as alive.',
      brandInvariant:
          'Live surfaces breathe. Cadence reflects the underlying '
          'state — fast = urgent, slow = ambient.',
      tone: Color(0xFFE9C75D),
    ),
    DnaChapter(
      id: 'phase-05',
      phaseLabel: 'PHASE · 05',
      title: 'AppleSheet · Modal cinema',
      headline:
          'One sheet substrate to rule them all · gold hairline · detents',
      summary:
          'AppleSheet primitive landed. Migrated every showModal '
          'bottomSheet to it: payment confirm, trip budget, wallet '
          'detail, social post, voice command, command palette, '
          'flights / arrival / eSIM / passport. Onboarding became '
          'cinematic with stagger + signature haptics.',
      brandInvariant:
          'No bespoke sheet chrome. Every modal goes through '
          'AppleSheet so brand language is consistent.',
      tone: Color(0xFFD4AF37),
    ),
    DnaChapter(
      id: 'phase-06',
      phaseLabel: 'PHASE · 06',
      title: 'Connective tissue · Typography + states + a11y',
      headline: 'Canonical type scale · cinematic states · semantic chrome',
      summary:
          'Type scale moved from magic numbers to named anchors '
          '(textTiny → textH1). Os2Text.credential + watermark '
          'codified the brand pillars. Empty / error / loading '
          'states unified into CinematicStateChrome. Semantic '
          'labels on every hot tappable.',
      brandInvariant:
          'Typography is named, not numeric. States are cinematic, '
          'not Material. Tappables announce role + label + hint.',
      tone: Color(0xFFE9C75D),
    ),
    DnaChapter(
      id: 'phase-07',
      phaseLabel: 'PHASE · 07',
      title: 'Copilot · Intelligence layer',
      headline: 'GlobeID advises, not just holds',
      summary:
          'Copilot suggestion strip surfaces the highest-value '
          'next action. Pre-emptive inbox alerts replaced buried '
          'badges. TrustScoreBreakdown explains every score line. '
          'Visa renewal ceremony + FX convert-now turned passive '
          'data into proactive ceremony.',
      brandInvariant:
          'Intelligence is a brand pillar. Surfaces propose next '
          'actions; users do not have to hunt.',
      tone: Color(0xFFD4AF37),
    ),
    DnaChapter(
      id: 'phase-08',
      phaseLabel: 'PHASE · 08',
      title: 'Identity · Vault deepening',
      headline: 'Credentials feel sovereign, not stored',
      summary:
          'Cryptographic attestation footer on every credential '
          '(VERIFIED · NOT REVOKED · BLOCK ##). Selective '
          'disclosure sheet (per-audience reveal). Biometric '
          'reveal gate. Issuance ceremony. Audit trail viewer. '
          'Identity vault dashboard hub.',
      brandInvariant:
          'Credentials carry chain-of-custody chrome. Reveal is '
          'a ceremony — biometric → blur lift → signature haptic.',
      tone: Color(0xFFD4AF37),
    ),
    DnaChapter(
      id: 'phase-09',
      phaseLabel: 'PHASE · 09',
      title: 'Ambient · Brand beyond the app',
      headline: 'Live Activities · widgets · watch · QS · lock screen',
      summary:
          'Brought GlobeID chrome to every ambient surface: Dynamic '
          'Island live activity preview, home-screen widgets (trip / '
          'FX / visa), watch face complications, Quick Settings tile, '
          'lock screen + Always-On preview, Ambient Hub capstone.',
      brandInvariant:
          'Brand is omnipresent. Mono-cap + gold + OLED show up '
          'everywhere the OS lets us paint.',
      tone: Color(0xFFE9C75D),
    ),
    DnaChapter(
      id: 'phase-10',
      phaseLabel: 'PHASE · 10',
      title: 'Production · Real adapters + offline-first',
      headline: 'Demo data sits behind real adapters · STALE chrome',
      summary:
          'FxAdapter (Frankfurter / ECB), FlightAdapter '
          '(AeroAPI / FlightAware), VisaAdapter (PassportIndex), '
          'TelemetrySink (Sentry envelope), TimestampedCache + '
          'StaleChip. Production Readiness Hub capstone.',
      brandInvariant:
          'Network failure has brand chrome. STALE chips ladder '
          '(fresh · 1h · 2h · 12h · 24h) read live, not broken.',
      tone: Color(0xFFC9A961),
    ),
    DnaChapter(
      id: 'phase-11',
      phaseLabel: 'PHASE · 11',
      title: 'Cinematics · Signature moments',
      headline: 'Passport opening · stamp · printed · declassified · velvet',
      summary:
          'Passport Opening Ceremony (3 s · substrate fade + foil '
          'sweep + watermark + bearer-page focus). Visa Stamp '
          '4-frame strike. Boarding PRINTED reveal (roller printer '
          'cinematic). Country DECLASSIFIED 3-stamp strike. Lounge '
          'velvet rope catenary. Cinematics Hub capstone.',
      brandInvariant:
          'Every "first time" earns a ceremony. No first-mount '
          'lands without a signature moment.',
      tone: Color(0xFFD4AF37),
    ),
    DnaChapter(
      id: 'phase-12',
      phaseLabel: 'PHASE · 12',
      title: 'Brand surfaces · Watermark · seal · signet · camera',
      headline: 'GLOBE·ID across every modal · cold mount · camera chrome',
      summary:
          'GLOBE · ID watermark on every AppleSheet. GlobeID '
          'cold-mount seal loading state. Identity signet ladder '
          '(STANDARD · ATELIER · PILOT). GlobeID camera chrome '
          '(5 scan modes). Receipt / share-sheet templates. Brand '
          'surface gallery capstone.',
      brandInvariant:
          'Every surface — modal, splash, camera, receipt — '
          'carries the GLOBE · ID monogram so screenshots '
          'advertise the brand.',
      tone: Color(0xFFE9C75D),
    ),
    DnaChapter(
      id: 'phase-13',
      phaseLabel: 'PHASE · 13',
      title: 'Locale + Accessibility · Globalization',
      headline:
          '5 locales · RTL · dynamic type · reduced motion · WCAG AA',
      summary:
          'GlobeIdLocale enum (en-US base + ar-SA + zh-CN + es-ES '
          '+ ja-JP). BrandDirection (RTL audit, chrome locked LTR). '
          'BrandTextScale (Dynamic Type with chromeCap 1.35×, '
          'credentialCap 1.20×). BrandMotionPolicy (structural / '
          'ambient / signature roles). BrandContrast (WCAG '
          'linearized RGB). LocaleA11yHub capstone.',
      brandInvariant:
          'GLOBE · ID watermark is locale-immutable LTR. '
          'Mono-cap chrome capped at 1.35×. Reduced motion '
          'respects role taxonomy.',
      tone: Color(0xFF6B8FB8),
    ),
    DnaChapter(
      id: 'phase-14',
      phaseLabel: 'PHASE · 14',
      title: 'Atelier · Design system',
      headline:
          'Catalog · motion lab · token export · regression · DNA timeline',
      summary:
          'AtelierCatalog (19 primitives · 4 domains). '
          'MotionCatalog (10 durations · 6 curves · live preview). '
          'BrandTokens (67 tokens · tokens.json · schema v1). '
          'VisualRegressionCatalog (8 specimens · canonical '
          'sizing). BrandDnaTimeline (this entry).',
      brandInvariant:
          'The brand is documented, exportable, regression-checked, '
          'and historically traceable. It cannot be drift-reset '
          'silently.',
      tone: Color(0xFFE9C75D),
    ),
  ];

  /// Returns the chapter by id (null if not found).
  static DnaChapter? byId(String id) {
    for (final c in chapters) {
      if (c.id == id) return c;
    }
    return null;
  }
}

class DnaChapter {
  const DnaChapter({
    required this.id,
    required this.phaseLabel,
    required this.title,
    required this.headline,
    required this.summary,
    required this.brandInvariant,
    required this.tone,
  });

  final String id;
  final String phaseLabel;
  final String title;
  final String headline;
  final String summary;
  final String brandInvariant;
  final Color tone;
}
