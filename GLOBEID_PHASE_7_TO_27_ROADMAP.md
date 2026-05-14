# GlobeID — Phase 7 → Phase 27 Roadmap

This document is the authoritative plan for the next **21 phases** of GlobeID
elevation. Each phase has **6 sub-phases**, each sub-phase ships as **its own
pull request** branched off `main`. Target: **126 PRs**.

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
- 7a. `CopilotSuggestionStrip` primitive — one card, one CTA, mono-cap eyebrow `COPILOT · NOW`
- 7b. Pre-emptive Inbox alerts — passport expiry / visa renewal / advisory escalation
- 7c. Trust Score breakdown surface — visa-on-time %, financial reliability, foil sweep
- 7d. Visa renewal proactive flow — sheet primitive triggered by Copilot
- 7e. FX convert-now recommendations — "EUR/USD spiked 0.7% · convert €500 saves $14"
- 7f. Copilot Hub screen — all active recommendations in one place

## Phase 8 — Identity Vault Deepening
- 8a. Cryptographic ownership proof footer — `VERIFIED · NOT REVOKED · BLOCK ##` + NfcPulse
- 8b. Selective disclosure UI — toggle visibility per audience
- 8c. Biometric gate on sensitive fields — Face/Touch ID reveal
- 8d. Issuance ceremony — 2.4s gold-foil press + signature haptic
- 8e. Credential history timeline per document
- 8f. Revocation surface — "this credential was revoked" with red breathing halo

## Phase 9 — Ambient Brand (Watch + Widgets + Live Activities)
- 9a. Home-screen widget primitives — next trip countdown, FX heartbeat, visa expiry warning
- 9b. Live Activities scaffold — iOS Dynamic Island boarding countdown
- 9c. Wear OS / Watch face complication scaffold
- 9d. Quick scanner tile — Android Quick Settings entry point
- 9e. iMessage / share extension entry points
- 9f. CarPlay / Android Auto travel surface stub

## Phase 10 — Real APIs / Production Reliability
- 10a. Flight data adapter (AeroAPI / FlightAware shim)
- 10b. FX rates adapter (Frankfurter / OpenExchangeRates, 30s refresh)
- 10c. Visa rules adapter (PassportIndex JSON)
- 10d. Telemetry sink — wire `error_telemetry.dart` to Sentry / PostHog stub
- 10e. Offline-first cache + `STALE · 2h AGO` mono-cap chip
- 10f. Background sync orchestrator

## Phase 11 — Cinematic Reimagining
- 11a. Passport opening ceremony — 3s cinematic cold-open
- 11b. Visa stamp 4-frame sequence — ink load → arc swing → press → bleed
- 11c. Boarding "PRINTED" reveal — printer slot animation
- 11d. Country "DECLASSIFIED" reveal — top-secret folder lifts, stamps strike
- 11e. Lounge admission — gold velvet rope lifts, OLED dimmer
- 11f. Customs cleared "ENTRY GRANTED" stamp + signature haptic

## Phase 12 — Brand Surface Expansion
- 12a. Watermark drift on every modal/sheet (currently only Live surfaces)
- 12b. GlobeID seal cold-mount stamp — replaces Flutter splash
- 12c. Scanner viewfinder gold brackets + mono-cap `SCANNING · DOCUMENT` chip
- 12d. Receipt chrome unified to brand (gold hairline, mono-cap header, OLED bg)
- 12e. Notification chrome — banner + lock-screen template
- 12f. Share preview cards — GlobeID branded screenshots when sharing

## Phase 13 — Localization + Accessibility (full pass)
- 13a. i18n scaffold — `.arb` files, en-US base
- 13b. RTL audit + mirror chrome (gold hairline flips for RTL)
- 13c. Dynamic Type / scaling audit at 130 % / 150 % / 200 %
- 13d. Reduced motion full audit
- 13e. WCAG AA contrast pass on gold-on-OLED + mono-cap chrome
- 13f. Screen-reader full pass — every Live surface fully announceable

## Phase 14 — Atelier Design System
- 14a. `/atelier` internal route — component gallery for every Os2 primitive
- 14b. Motion choreography doc + page
- 14c. `tokens.json` export — gold/mono-cap/OLED palette + type-scale
- 14d. Golden tests for chrome primitives (`golden_toolkit`)
- 14e. Brand guidelines doc generation
- 14f. Storybook-style component playground

## Phase 15 — Wallet Deepening
- 15a. Multi-currency wallet + auto-routing by location
- 15b. Travel-specific virtual cards — per-trip, frozen on trip end
- 15c. Receipt OCR + auto-categorization (stub)
- 15d. Crypto rails surface (BTC/ETH for international transfers)
- 15e. Express checkout sheet primitive — Apple/Google Pay-style
- 15f. Currency hedging recommendations surface

## Phase 16 — Travel Network / Social
- 16a. Verified Travelers Network surface
- 16b. Concierge chat scaffold — human + AI hybrid
- 16c. Trip-sharing with companions — split costs, shared itinerary
- 16d. Local guides marketplace stub
- 16e. Reviews + verified-traveler badges
- 16f. Travel feed primitive — stories from the network

## Phase 17 — Premium Services Polish
- 17a. Curated experiences (Michelin / Mr & Mrs Smith stub)
- 17b. Visa concierge fulfillment flow
- 17c. Lounge access purchasing in-app
- 17d. Priority security partnerships UI
- 17e. Booking confirmation cinematic
- 17f. Member-tier benefits surface

## Phase 18 — Voice / AI Copilot
- 18a. VoiceCommandOverlay deepening — transcript + waveform
- 18b. Siri Shortcut entry points (iOS stub)
- 18c. Suggestion engine — "What's my best play right now?"
- 18d. Long-press hero credential = AI explain
- 18e. Voice-driven scanner trigger
- 18f. Conversational booking flow

## Phase 19 — Onboarding Reimagined
- 19a. 60-second identity claim flow scaffold
- 19b. Selfie + document + liveness ceremony
- 19c. Manufacturer's seal issuance moment
- 19d. First-credential gold engraving animation
- 19e. Post-claim onboarding tour
- 19f. Welcome ceremony — "Welcome to GlobeID, Bearer #####"

## Phase 20 — Cinematic Substrates
- 20a. `LayeredParallax` universal substrate primitive
- 20b. `AmbientParticles` for premium credentials
- 20c. `SpotlightHalo` on active hero
- 20d. Depth-blur layering on stacked surfaces
- 20e. Volumetric glow for OLED-tier surfaces
- 20f. Substrate paper grain texture

## Phase 21 — Performance / 120Hz
- 21a. RepaintBoundary audit pass 2
- 21b. 120Hz opt-in for animations on supported devices
- 21c. Battery / thermal profiling pass
- 21d. Image cache audit
- 21e. Frame jank baseline + regression tests
- 21f. Build size audit + tree-shake pass

## Phase 22 — Data Layer
- 22a. Riverpod provider audit — remove unused, name conventions
- 22b. State persistence audit (SharedPreferences / Hive)
- 22c. Background sync primitives
- 22d. WebSocket scaffold for live data
- 22e. Data migration framework
- 22f. Repository pattern audit

## Phase 23 — Security / Trust
- 23a. `flutter_secure_storage` for sensitive credential fields
- 23b. Tamper detection scaffold
- 23c. Jailbreak / root detection (stub)
- 23d. Certificate pinning
- 23e. Audit log surface deepened
- 23f. Permission audit

## Phase 24 — Future-State Reimagining
- 24a. AR-ready credential card (Vision Pro stub)
- 24b. Spatial computing scaffold
- 24c. Holographic foil 3D depth pass
- 24d. Multi-device handoff
- 24e. NFC tap-out real-world scaffold
- 24f. Wearable companion handoff

## Phase 25 — Deployment / Operations
- 25a. App Store / Play Store asset generation
- 25b. Privacy manifest (iOS)
- 25c. Release notes generator
- 25d. Crashlytics / telemetry final wiring
- 25e. CI/CD pipeline doc
- 25f. Versioning + release tagging strategy

## Phase 26 — Final Audit Foundation
- 26a. Final A11y audit pass
- 26b. Final brand DNA audit pass
- 26c. Final performance audit pass
- 26d. Final security audit pass
- 26e. Final integration audit + smoke
- 26f. Final regression test pass

## Phase 27 — Brand Cinematics II
- 27a. Passport ribbon physics deepening
- 27b. Visa ink physics — bleed timing, capillary spread
- 27c. Currency note paper texture pass
- 27d. Lounge marble counter material
- 27e. Hotel concierge bell signature haptic
- 27f. Boarding gate departure board flap-anim

## Phase 28 — Production Hardening
- 28a. Crash recovery surface
- 28b. Retry queue for mutations
- 28c. Conflict resolution UI
- 28d. Offline-degrade graceful fallback
- 28e. Network condition awareness chip
- 28f. Self-test surface (diagnostics screen)

## Phase 29 — Launch Readiness
- 29a. App Store screenshot generation
- 29b. App Clip / Instant App stubs
- 29c. Deep link manifests + universal links
- 29d. Smart banners + share intents
- 29e. Splash screen variants per region
- 29f. Pre-launch checklist surface

## Phase 30 — Web Companion
- 30a. PWA scaffold (manifest + service worker)
- 30b. Marketing landing page primitives
- 30c. Public credential viewer (read-only)
- 30d. Web-based scanner (camera API)
- 30e. SEO meta + OpenGraph card generation
- 30f. Web onboarding parity surface

## Phase 31 — Continuous Improvement / Growth
- 31a. Feature flag framework
- 31b. A/B experiment scaffold
- 31c. Kill switches per feature
- 31d. Beta rollout surface
- 31e. Telemetry-driven growth insights surface
- 31f. Referral / invite cinematic
