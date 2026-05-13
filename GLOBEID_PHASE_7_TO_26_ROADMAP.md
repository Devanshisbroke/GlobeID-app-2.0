# GlobeID — Phase 7 → Phase 26 Roadmap

This document is the authoritative plan for the next **20 phases** of GlobeID
elevation. Each phase has **5 sub-phases**, each sub-phase ships as **its own
pull request** branched off `main`. Target: ~100 PRs.

**Brand DNA (non-negotiable across every PR):**

- Gold accents: `#D4AF37`, `#E9C75D`, `Os2.foilGoldHero`
- Mono-cap chrome: 9–11 pt caps, 2.4 letter-spacing, 18 % white
- OLED black substrate: `#050505`, `#050912`
- Hairline frames: `#FFFFFF @ 0.08` border, `Os2.goldHairline` rule
- `GLOBE·ID` watermark drift on every Live surface

**Acceptance for every PR:**

1. `flutter analyze --no-pub` → 0 issues
2. `flutter test --no-pub` → full suite green
3. Branch off `main`, mergeable independently
4. No emoji, no Material flat fills, no defaulted Cupertino chrome
5. No existing tests modified to make the change pass

---

## Phase 7 — Travel Copilot / Intelligence Layer

> Make GlobeID feel like it *thinks* on your behalf. Apple Wallet *holds*; GlobeID *advises*.

- **7a.** `CopilotSuggestionStrip` primitive — one card, one CTA, mono-cap eyebrow `COPILOT · NOW`
- **7b.** Pre-emptive Inbox alerts — passport expiry / visa renewal / advisory escalation surfaces as signature-haptic Inbox items
- **7c.** Trust Score breakdown surface — visa-on-time %, financial reliability, document recency, social vouches; foil sweep on score reveal
- **7d.** Visa renewal proactive flow — sheet primitive triggered by Copilot
- **7e.** FX convert-now recommendations — "EUR/USD spiked 0.7% · convert €500 saves $14"

## Phase 8 — Identity Vault Deepening

> Right now Identity Vault is a list. Make it a manufactured credential vault.

- **8a.** Cryptographic ownership proof footer on every credential (`VERIFIED · NOT REVOKED · BLOCK ##` + NfcPulse)
- **8b.** Selective disclosure UI — toggle visibility per audience ("AIRLINE sees passport+DOB only")
- **8c.** Biometric gate on sensitive fields (Face/Touch ID reveal animation)
- **8d.** Issuance ceremony — 2.4s gold-foil press + signature haptic when a credential is added
- **8e.** Credential history timeline per document

## Phase 9 — Ambient Brand (Watch + Widgets + Live Activities)

> A credential brand has to be omnipresent. Right now GlobeID lives only inside the app.

- **9a.** Home-screen widget primitives — next trip countdown, FX heartbeat, visa expiry warning
- **9b.** Live Activities scaffold — iOS Dynamic Island boarding countdown sim
- **9c.** Wear OS / Watch face complication scaffold
- **9d.** Quick scanner tile — Android Quick Settings entry point
- **9e.** iMessage / share extension entry points

## Phase 10 — Real APIs / Production Reliability

> Replace demo data without losing demo polish.

- **10a.** Flight data adapter (AeroAPI / FlightAware shim behind repository)
- **10b.** FX rates adapter (Frankfurter / OpenExchangeRates, 30s refresh)
- **10c.** Visa rules adapter (PassportIndex JSON)
- **10d.** Telemetry sink — wire `error_telemetry.dart` to Sentry / PostHog stub
- **10e.** Offline-first cache + `STALE · 2h AGO` mono-cap chip

## Phase 11 — Cinematic Reimagining

> Signature moments the user tells a friend about.

- **11a.** Passport opening ceremony — 3s cinematic cold-open
- **11b.** Visa stamp 4-frame sequence — ink load → arc swing → press → bleed
- **11c.** Boarding "PRINTED" reveal — printer slot animation + `Haptics.printerStrike`
- **11d.** Country "DECLASSIFIED" reveal — top-secret folder lifts, stamps strike
- **11e.** Lounge admission — gold velvet rope lifts, OLED dimmer on the world

## Phase 12 — Brand Surface Expansion

> Brand DNA on every surface, not just Live screens.

- **12a.** Watermark drift on every modal/sheet (currently only Live surfaces)
- **12b.** GlobeID seal cold-mount stamp — replaces Flutter splash
- **12c.** Scanner viewfinder gold brackets + mono-cap `SCANNING · DOCUMENT` chip
- **12d.** Receipt chrome unified to brand (gold hairline, mono-cap header, OLED bg)
- **12e.** Notification chrome — banner + lock-screen template

## Phase 13 — Localization + Accessibility (full pass)

> Phase 6c shipped the foundation; phase 13 finishes it.

- **13a.** i18n scaffold — `.arb` files, en-US base
- **13b.** RTL audit + mirror chrome (gold hairline flips for RTL)
- **13c.** Dynamic Type / scaling audit at 130 % / 150 % / 200 %
- **13d.** Reduced motion full audit — every halo / foil / parallax respects `MediaQuery.disableAnimations`
- **13e.** WCAG AA contrast pass on gold-on-OLED + mono-cap chrome

## Phase 14 — Atelier Design System

> Right now the brand DNA lives in 200+ widget files. Codify it.

- **14a.** `/atelier` internal route — component gallery for every Os2 primitive
- **14b.** Motion choreography doc + page
- **14c.** `tokens.json` export — gold/mono-cap/OLED palette + type-scale
- **14d.** Golden tests for chrome primitives (`golden_toolkit`)
- **14e.** Brand guidelines doc generation (auto from tokens)

## Phase 15 — Wallet Deepening

- **15a.** Multi-currency wallet + auto-routing by location
- **15b.** Travel-specific virtual cards — per-trip, frozen on trip end
- **15c.** Receipt OCR + auto-categorization (stub adapter)
- **15d.** Crypto rails surface (BTC/ETH for international transfers)
- **15e.** Express checkout sheet primitive — Apple/Google Pay-style

## Phase 16 — Travel Network / Social

- **16a.** Verified Travelers Network surface — people who've been where you're going
- **16b.** Concierge chat scaffold — human + AI hybrid
- **16c.** Trip-sharing with companions — split costs, shared itinerary
- **16d.** Local guides marketplace stub
- **16e.** Reviews + verified-traveler badges

## Phase 17 — Premium Services Polish

- **17a.** Curated experiences (Michelin / Mr & Mrs Smith stub)
- **17b.** Visa concierge fulfillment flow
- **17c.** Lounge access purchasing in-app
- **17d.** Priority security partnerships UI
- **17e.** Booking confirmation cinematic — gold seal stamp + signature haptic

## Phase 18 — Voice / AI Copilot

- **18a.** VoiceCommandOverlay deepening — transcript + waveform visualization
- **18b.** Siri Shortcut entry points (iOS stub)
- **18c.** Suggestion engine — "What's my best play right now?"
- **18d.** Long-press hero credential = AI explain
- **18e.** Voice-driven scanner trigger

## Phase 19 — Onboarding Reimagined

- **19a.** 60-second identity claim flow scaffold
- **19b.** Selfie + document + liveness ceremony
- **19c.** Manufacturer's seal issuance moment
- **19d.** First-credential gold engraving animation
- **19e.** Post-claim onboarding tour

## Phase 20 — Cinematic Substrates (depth/parallax/glow)

- **20a.** `LayeredParallax` universal substrate primitive
- **20b.** `AmbientParticles` for premium credentials
- **20c.** `SpotlightHalo` on active hero
- **20d.** Depth-blur layering on stacked surfaces
- **20e.** Volumetric glow for OLED-tier surfaces

## Phase 21 — Performance / 120Hz

- **21a.** RepaintBoundary audit pass 2
- **21b.** 120Hz opt-in for animations on supported devices
- **21c.** Battery / thermal profiling pass
- **21d.** Image cache audit
- **21e.** Frame jank baseline + regression tests

## Phase 22 — Data Layer

- **22a.** Riverpod provider audit — remove unused, name conventions
- **22b.** State persistence audit (SharedPreferences / Hive)
- **22c.** Background sync primitives
- **22d.** WebSocket scaffold for live data
- **22e.** Data migration framework

## Phase 23 — Security / Trust

- **23a.** `flutter_secure_storage` for sensitive credential fields
- **23b.** Tamper detection scaffold
- **23c.** Jailbreak / root detection (stub)
- **23d.** Certificate pinning
- **23e.** Audit log surface deepened

## Phase 24 — Future-State Reimagining

- **24a.** AR-ready credential card (Vision Pro stub)
- **24b.** Spatial computing scaffold
- **24c.** Holographic foil 3D depth pass
- **24d.** Multi-device handoff
- **24e.** NFC tap-out real-world scaffold

## Phase 25 — Deployment / Operations

- **25a.** App Store / Play Store asset generation
- **25b.** Privacy manifest (iOS)
- **25c.** Release notes generator
- **25d.** Crashlytics / telemetry final wiring
- **25e.** CI/CD pipeline doc

## Phase 26 — Final Audit & Polish

- **26a.** Final A11y audit pass
- **26b.** Final brand DNA audit pass
- **26c.** Final performance audit pass
- **26d.** Final security audit pass
- **26e.** Final integration audit + smoke
