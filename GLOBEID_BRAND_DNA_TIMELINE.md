# GlobeID — Brand DNA Timeline

Authoritative phase history of the GlobeID design language. Each phase shipped a
chapter; each chapter codified a brand invariant. The timeline is **append-only**
— existing chapters are the historical record, not a draft.

This document is the markdown counterpart of `BrandDnaTimeline` in
`flutter_app/lib/atelier/models/brand_dna_timeline.dart`. The two are kept in
lock-step so designers, marketing and the in-app Atelier (Phase 14e) all read
the same canonical history.

---

## Phase · 01 — Foundation · Ecosystem stabilization

**Headline.** Every route wired, every dead CTA reconnected.

The first pass made the world coherent. Orphan routes closed, dead CTAs
reconnected, navigation tree audited end-to-end. Set the rule that no surface
ships without being reachable from at least one entry point.

> **Invariant.** No dead routes. Every screen is reachable from app chrome.

---

## Phase · 02 — Nexus · Services + sheet substrate

**Headline.** Services ecosystem speaks the GlobeID language.

Brought the Services world onto the Nexus design language: mono-cap chrome,
foil hairline, OLED canvas. Every sheet got the cinematic substrate.
Notifications shifted from system chrome to brand chrome.

> **Invariant.** Sheets are physical glass: blur backdrop · gold hairline under
> handle · OLED gradient · detent snap.

---

## Phase · 03 — Refinement · Motion + haptics taxonomy

**Headline.** Named motion vocabulary; semantic haptic vocabulary.

Codified every duration + curve into the `Motion` taxonomy. Codified every
tactile gesture into the `Haptics` vocabulary. No more ad-hoc 250 ms or
`lightImpact()` — every motion + tap is a named brand decision.

> **Invariant.** Motion + haptics ship from a named vocabulary, not magic
> numbers. `dPage`, `sCrisp`, `Haptics.signature`.

---

## Phase · 04 — Alive · Live surface elevation

**Headline.** Every Live surface gained a real "alive" cadence.

Visa expiry urgency, Forex directional FX, Country threat mood, Transit NFC tap
states, Customs lock-in shake, Passport iridescent strip, Navigation rim
shimmer. Every surface that claims to be live now reads as alive.

> **Invariant.** Live surfaces breathe. Cadence reflects the underlying state —
> fast = urgent, slow = ambient.

---

## Phase · 05 — AppleSheet · Modal cinema

**Headline.** One sheet substrate to rule them all · gold hairline · detents.

`AppleSheet` primitive landed. Migrated every `showModalBottomSheet` to it:
payment confirm, trip budget, wallet detail, social post, voice command,
command palette, flights / arrival / eSIM / passport. Onboarding became
cinematic with stagger + signature haptics.

> **Invariant.** No bespoke sheet chrome. Every modal goes through `AppleSheet`
> so brand language is consistent.

---

## Phase · 06 — Connective tissue · Typography + states + a11y

**Headline.** Canonical type scale · cinematic states · semantic chrome.

Type scale moved from magic numbers to named anchors (`textTiny` → `textH1`).
`Os2Text.credential` + `watermark` codified the brand pillars. Empty / error /
loading states unified into `CinematicStateChrome`. Semantic labels on every
hot tappable.

> **Invariant.** Typography is named, not numeric. States are cinematic, not
> Material. Tappables announce role + label + hint.

---

## Phase · 07 — Copilot · Intelligence layer

**Headline.** GlobeID advises, not just holds.

Copilot suggestion strip surfaces the highest-value next action. Pre-emptive
inbox alerts replaced buried badges. `TrustScoreBreakdown` explains every score
line. Visa renewal ceremony + FX convert-now turned passive data into proactive
ceremony.

> **Invariant.** Intelligence is a brand pillar. Surfaces propose next actions;
> users do not have to hunt.

---

## Phase · 08 — Identity · Vault deepening

**Headline.** Credentials feel sovereign, not stored.

Cryptographic attestation footer on every credential (`VERIFIED · NOT REVOKED
· BLOCK ##`). Selective disclosure sheet (per-audience reveal). Biometric
reveal gate. Issuance ceremony. Audit trail viewer. Identity vault dashboard
hub.

> **Invariant.** Credentials carry chain-of-custody chrome. Reveal is a
> ceremony — biometric → blur lift → signature haptic.

---

## Phase · 09 — Ambient · Brand beyond the app

**Headline.** Live Activities · widgets · watch · QS · lock screen.

Brought GlobeID chrome to every ambient surface: Dynamic Island live activity
preview, home-screen widgets (trip / FX / visa), watch face complications,
Quick Settings tile, lock screen + Always-On preview, Ambient Hub capstone.

> **Invariant.** Brand is omnipresent. Mono-cap + gold + OLED show up
> everywhere the OS lets us paint.

---

## Phase · 10 — Production · Real adapters + offline-first

**Headline.** Demo data sits behind real adapters · STALE chrome.

`FxAdapter` (Frankfurter / ECB), `FlightAdapter` (AeroAPI / FlightAware),
`VisaAdapter` (PassportIndex), `TelemetrySink` (Sentry envelope),
`TimestampedCache` + `StaleChip`. Production Readiness Hub capstone.

> **Invariant.** Network failure has brand chrome. STALE chips ladder
> (fresh · 1 h · 2 h · 12 h · 24 h) read live, not broken.

---

## Phase · 11 — Cinematics · Signature moments

**Headline.** Passport opening · stamp · printed · declassified · velvet.

Passport Opening Ceremony (3 s · substrate fade + foil sweep + watermark +
bearer-page focus). Visa Stamp 4-frame strike. Boarding `PRINTED` reveal
(roller printer cinematic). Country `DECLASSIFIED` 3-stamp strike. Lounge
velvet rope catenary. Cinematics Hub capstone.

> **Invariant.** Every "first time" earns a ceremony. No first-mount lands
> without a signature moment.

---

## Phase · 12 — Brand surfaces · Watermark · seal · signet · camera

**Headline.** `GLOBE · ID` across every modal · cold mount · camera chrome.

`GLOBE · ID` watermark on every `AppleSheet`. GlobeID cold-mount seal loading
state. Identity signet ladder (`STANDARD · ATELIER · PILOT`). GlobeID camera
chrome (5 scan modes). Receipt / share-sheet templates. Brand surface gallery
capstone.

> **Invariant.** Every surface — modal, splash, camera, receipt — carries the
> `GLOBE · ID` monogram so screenshots advertise the brand.

---

## Phase · 13 — Locale + Accessibility · Globalization

**Headline.** 5 locales · RTL · dynamic type · reduced motion · WCAG AA.

`GlobeIdLocale` enum (en-US base + ar-SA + zh-CN + es-ES + ja-JP).
`BrandDirection` (RTL audit, chrome locked LTR). `BrandTextScale` (Dynamic Type
with chromeCap 1.35×, credentialCap 1.20×). `BrandMotionPolicy` (structural /
ambient / signature roles). `BrandContrast` (WCAG linearized RGB).
`LocaleA11yHub` capstone.

> **Invariant.** `GLOBE · ID` watermark is locale-immutable LTR. Mono-cap
> chrome capped at 1.35×. Reduced motion respects role taxonomy.

---

## Phase · 14 — Atelier · Design system

**Headline.** Catalog · motion lab · token export · regression · DNA timeline.

`AtelierCatalog` (19 primitives · 4 domains). `MotionCatalog` (10 durations · 6
curves · live preview). `BrandTokens` (67 tokens · `tokens.json` · schema v1).
`VisualRegressionCatalog` (8 specimens · canonical sizing). `BrandDnaTimeline`
(this entry).

> **Invariant.** The brand is documented, exportable, regression-checked, and
> historically traceable. It cannot be drift-reset silently.

---

_Append-only. New phases extend the tail._
