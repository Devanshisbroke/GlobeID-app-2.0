# GlobeID — Codex Handoff (GPT-5.5 Extra High)

> **Audience.** This document is the single, comprehensive handoff for an autonomous coding agent (Codex / GPT-5.5 Extra High) to take over expansion of the GlobeID Flutter app and continue evolving it into a flagship global identity / travel / wallet super-app.
>
> **Companion docs (already in the repo, read in this order if you want full depth):**
> 1. `ARCHITECTURE.md` — 2,174-line exhaustive architecture of the original TS/Capacitor app.
> 2. `FLUTTER_HANDOFF.md` — original 857-line handoff written for the first migration agent.
> 3. `HANDOFF.md` — companion product / engineering handoff (725 lines).
> 4. `BACKLOG.md` — 250-item product backlog from the TS app.
> 5. `flutter_app/REMAINING_GAPS.md` + `flutter_app/ELEVATION_DELTA.md` + `flutter_app/MIGRATION_MAPPING.md`.
>
> **You do not need to re-audit the TS repo to get started.** This file consolidates everything you need.

---

## 0. TL;DR for Codex

- **What GlobeID is:** a deterministic-first, cross-platform travel + identity super-app — passport scanning, encrypted vault, multi-leg trip planner, Apple-Wallet-style boarding passes, 3D globe with flight arcs, voice intents, services hub, multi-currency wallet, intelligence engine.
- **Original TS app:** 53,778 LOC across `src/` (490 .tsx/.ts files), 25 screens, 21 Zustand stores, 75+ pure-function `lib/` modules, ~316 unit tests, Hono backend at `server/` with ~25 REST endpoints, Three.js + R3F 3D globe.
- **Current Flutter app:** 30,203 LOC across 100 .dart files in `flutter_app/lib/` (45 feature folders, 33 routes, 5-tab shell + secondary full-screen routes). `flutter analyze` is clean (0 issues). 6/6 unit tests pass.
- **Latest live "feel alive" pass (PR #54, merged):** living digital passport (`/passport-live`), living boarding pass (`/boarding/:tripId/:legId`), accelerometer-driven wallet stack with fan-out, twinkling-globe + flowing arcs + night-side city lights, premium slide+scale+blur page transitions, `Haptics` vocabulary + `SoundCues` stub at `flutter_app/lib/motion/motion.dart`.
- **Your mission:** continue evolving the app from "feel alive" toward **"the universal operating system for humanity"** — Apple/Google/Notion/Figma/Airbnb/Arc-level polish, full feature parity with the TS app, and ecosystem expansion beyond it.
- **You have full implementation freedom.** No package limit, no LOC limit, no architectural-purity dogma. The user explicitly wants the app to be 150–200 MB+, GPU-heavy, asset-rich, and feel like a complete software ecosystem — not a lightweight demo.

---

## 1. The full vision

GlobeID should ultimately feel like:

> **The universal operating system for humanity** — one app that replaces the dozens of travel / identity / wallet / service apps a global citizen needs.

The user's verbatim direction:

- **Identity.** "The digital passport should feel like a REAL passport in digital form. Passport opening animation, layered passport pages, holographic overlays, anti-counterfeit effects, depth lighting, animated seals/stamps, subtle page transitions, real passport spacing/layout logic, NFC/biometric identity feeling, immersive interaction patterns."
- **Travel.** "When clicking a trip/flight: show a REAL airline-style boarding pass, immersive transition into boarding mode, dynamic QR/barcode rendering, airport-style UI systems, live trip timeline feeling, flight arc synchronization, animated travel states, premium travel motion systems."
- **Wallet.** "Wallet cards should: stack naturally, animate naturally, expand naturally, react physically, feel premium, feel touch-responsive, feel OS-level. NOT static cards. NOT fake placeholders. NOT simple Flutter containers."
- **Polish.** "Apple Human Interface teams. Google Material teams. Airbnb designers. Notion engineers. Figma interaction teams. Arc Browser teams. Linear product teams. Elite motion designers. Elite systems engineers."
- **Scale.** "MAKE THE APP HUGE. MAKE THE APP FEEL HUGE. MAKE THE APP FEEL LIKE A COMPLETE SOFTWARE ECOSYSTEM. The app can be: 150MB–200MB+."

Translate this into engineering: **every screen is a digital twin of a real object**, **every gesture is tactile**, **every transition is cinematic**, **every state has motion**, **every system feels engineered, not assembled.**

---

## 2. The original TypeScript ecosystem (high-level map)

Source under `src/` (do not touch — it's the legacy reference; kept for parity diffing).

### 2.1 Screens (25, in `src/screens/`)

`Home.tsx`, `Wallet.tsx`, `Identity.tsx`, `IdentityVault.tsx`, `LockScreen.tsx`, `Travel.tsx`, `TravelTimeline.tsx`, `TravelIntelligence.tsx`, `TripDetail.tsx`, `TripPlanner.tsx`, `DocumentVault.tsx`, `EntryReceipt.tsx`, `Onboarding.tsx`, `Profile.tsx`, `UserProfile.tsx`, `HybridScanner.tsx`, `KioskSimulator.tsx`, `GlobalMap.tsx`, `Explore.tsx`, `PlanetExplorer.tsx`, `SocialFeed.tsx`, `SocialFeedV2.tsx`, `ServicesHub.tsx`, `SuperServicesHub.tsx`, `AnalyticsDashboard.tsx`, `MultiCurrency.tsx`, plus `screens/services/{Activities,FoodDiscovery,HotelBooking,RideBooking,Transport}.tsx`.

### 2.2 Component domains (in `src/components/`)

- `ai/` — AIAssistantButton, AIAssistantSheet, TravelAssistant, TravelCopilot, TripPlanCard, VoicePrompt
- `analytics/` — CategoryHeatmap
- `animations/` — LottieView, transitions
- `dashboard/` — CarbonFootprintChart, ProfileCard, QuickActions, Suggestions, TravelAlerts, TravelStats, UpcomingTrips
- `explorer/` — CultureHighlights, DestinationCard, DestinationStory, DiscoveryAchievements, DiscoveryFeed, ExplorerHUD, PopularityIndicator
- `identity/` — BorderEntrySimulation, CredentialCard, **DigitalPassport**, DocExpiryChip, EntryStamp, IdentityScoreCard, IdentityScoreSparkline, IdentityTimeline, LiveCameraScanner, **PassportBook**, PassportScanner, QRDisplay, ScoreFactorDrawer, SecurityStatus, SessionStatus, VerificationFlow, WelcomeOverlay
- `intelligence/` — AutomationFlagList, ContextBanner, DestinationCard, IntelligenceHUD, PredictiveNextTripCard, TravelTrends
- `layout/` — AnimatedPage, FAB, OfflineBanner, SyncBadge, plus `v2/` Phase-7 chrome + CommandPalette
- `map/` — **AirTrafficLayer, AirportMarkers, CinematicCamera, DestinationMarkers, ExplorerPaths, FlightArcs, GlobalFlightFlows, GlobalHeatmap, Globe, GlobeScene, IdentityMapLayer, LandmarkMarkers, Map2DView, MapControls, PassengerNetwork, PassengerParticles, RegionalDensity, RouteInsights, RouteNetwork, RoutePlayback, Starfield, TravelParticles, TravelStreams, UserLocation**
- `payments/` — QRPayment, QRScanner
- `services/` — BudgetPanel, EsimPanel, ExchangePanel, FoodPanel, FraudPanel, HotelsPanel, InsurancePanel, IntelligencePanel, LocalServicesPanel, LoyaltyPanel, RidesPanel, SafetyPanel, ScorePanel, ServiceCard, VisaPanel, WeatherPanel
- `simulation/` — ContinentTraffic, SimulationHUD, SpeedControl, TravelTimeline
- `social/` — CreatePost, Notifications, PostCard, StoriesBar
- `system/` — Coachmark, EdgeSwipeBack, EmptyState, ErrorBoundary, LazyMount, NativeBackButton, PullToRefresh, RouteErrorBoundary
- `travel/` — CountryInsights, FlightStatusCard, TripCard, TripLifecycleBadge, TripLifecycleCard
- `trip/` — TripGlobePreview etc.
- `ui/` — full shadcn-style design-system primitives (button, card, sheet, sonner, …) + AnimatedNumber, CinematicLoader, GlassCard, IdentityScore, InitialsAvatar, KeyboardShortcuts, LazyImage, Skeleton, SkeletonLoader, UltraGlass, VirtualList
- `voice/` — VoiceCommandButton
- `wallet/` — CurrencyCard, CurrencyConverter, DocumentCard, **PassDetail**, **PassStack**, SpendingAnalytics, TransactionList

### 2.3 State (21 Zustand stores at `src/store/`)

`alertsStore`, `budgetStore`, `commandPaletteStore`, `contextStore`, `copilotStore`, `fraudStore`, `insightsStore`, `lifecycleStore`, `loyaltyStore`, `recommendationsStore`, `safetyStore`, `scoreStore`, `serviceFavorites`, `socialStore`, `tripNotesStore`, `tripPlannerStore`, `userFeedStore`, `userStore`, `vaultAuditStore`, `walletStore`, `weatherStore`. All persisted under `globeid:*` keys.

### 2.4 Pure logic (75+ modules at `src/lib/`)

`achievements`, `airlineBrand`, `airports`, `analytics`, `apiClient`, `audioCues`, `audioFeedback`, `auditLog`, `biometricAuth`, `boardingPass`, `cameraCapture`, `cameraPresets`, `confetti`, `connectionDetector`, `countdown`, `countries`, `countryThemes`, `currencyEngine`, `demoData`, `demoServices`, `destinationAnalytics`, `distanceEngine`, `documentExpiry`, `documentVault`, `eventBus`, `explorerData`, `groundTransport`, `iconMap`, `ics`, `identityTier`, `imageEdge`, `imageVariance`, `locationEngine`, `loungeAccess`, `motion-tokens`, `mrzParser`, `mrzToDocument`, `nativeBridge`, `notificationChannels`, `ocrPreprocess`, `ocrService`, `onboarding`, `packingList`, `passOrdering`, `predictiveDeparture`, `qrEncoder`, `receiptRenderer`, `relativeDate`, `secureClipboard`, `shareSheet`, `sheetSnap`, `signOut`, `smartSuggestions`, `socialDB`, `starCatalog`, `sunPosition`, `syncEngine`, `themeAccents`, `themePrefs`, `tokenService`, `transitions`, `travelHeatmap`, `travelInsights`, `travelPrediction`, `travelSuggestions`, `travelTimeline`, `tripGenerator`, `tripIntel`, `tripLifecycle`, `utils`, `verificationSession`, `visaEngine`, `visaRequirements`, `voiceIntents`, `weatherForecast`.

### 2.5 Cinematic / motion (in `src/cinematic/` + `src/motion/`)

`AtmosphereLayer`, `DepthParallax`, `IconMotion`, `ParticleField`, `ScrollCinematics`, `UILighting`, `cinematicColors`, `motionEngine`, `motionOrchestrator`, `uiSound`, `motionConfig`.

### 2.6 Hooks (19 in `src/hooks/`)

`useAI`, `useDeviceTilt`, `useMobileDetect`, `useMotion`, `usePermissions`, `usePullToRefresh`, `useReducedEffects`, `useReducedMotionMatch`, `useScrollTint`, `useToast`, `useTravelContext`, `useVaultAutoLock`, `useVerificationSession`, `useVisibleClock`, `useVoiceCommands`, `useVoiceControl`, `useWeatherForecast`, `useMobile`.

### 2.7 Backend (`server/`)

Hono + Drizzle + SQLite. Routes under `server/src/routes/`: `alerts`, `budget`, `context`, `copilot`, `esim`, `exchange`, `food`, `fraud`, `hotels`, `insights`, `insurance`, `lifecycle`, `local`, `loyalty`, `planner`, `recommendations`, `rides`, `safety`, `score`, `trips`, `user`, `visa`, `wallet`, `weather`. Schema at `server/src/db/schema.ts` (~289 LOC). HMAC token signing at `server/src/auth/token.ts`.

---

## 3. Current Flutter migration status

### 3.1 Folder layout (`flutter_app/lib/`)

```
app/                 — router, app_shell, theme/ (tokens, material3, app_tokens.dart)
cinematic/           — globe_renderer.dart (582 LOC, custom Earth painter), great_circle, world_outlines
core/                — network/api_client.dart (dio envelope), storage/persisted_store
data/                — api/{globeid_api, demo_data (1224 LOC fallback), … }, models/{lifecycle, wallet, travel, …}
domain/              — airline_brand, airports, identity_tier, mrz_parser, visa_requirements
features/            — 32 feature folders (see below)
motion/              — motion.dart (NEW: GlobeMotion curves, premiumSlideTransition, Haptics, SoundCues stub)
widgets/             — design system primitives (PageScaffold, PremiumCard, Pressable, AnimatedAppearance, CinematicButton, AppToast, GlassSurface, SectionHeader, EmptyState, Sparkline, AnimatedNumber, …)
```

### 3.2 Feature folders (32)

`analytics`, `boarding_pass`, `copilot`, `explore`, `feed`, `home`, `identity`, `insights`, `intelligence`, `kiosk`, `lifecycle`, `lock`, `map`, `multi_currency`, `onboarding`, `passport_book`, `planner`, `profile`, `receipt`, `scanner`, `score`, `security`, `services`, `settings`, `social`, `timeline`, `travel`, `trip`, `user`, `vault`, `voice`, `wallet`.

### 3.3 Routes (33, in `flutter_app/lib/app/router.dart`)

**Gate:** `/lock`, `/onboarding`.
**Shell (5 tabs):** `/`, `/wallet`, `/travel`, `/services`, `/map`.
**Secondary:** `/profile`, `/kiosk-sim`, `/receipt`, `/timeline`, `/planner`, `/copilot`, `/social`, `/explore`, `/passport-book`, `/passport-live`, `/intelligence`, `/explorer`, `/vault`, `/feed`, `/multi-currency`, `/scan`, `/analytics`, `/pass/:id`, `/trip/:id`, `/boarding/:tripId/:legId`, `/services/{hotels,rides,food,activities,transport}`.

### 3.4 What's already done well

- **Living digital passport** (`features/passport_book/passport_live_screen.dart`, ~1248 LOC) — cover flip animation, embossed crest custom painter, holographic foil shimmer, animated ink stamps, MRZ rendering, security mesh, starfield backdrop.
- **Living boarding pass** (`features/boarding_pass/boarding_pass_live_screen.dart`, ~650 LOC) — brand-tinted card, animated foil strip, route arc with airplane painter, live countdown timer, perforation tear strip, PDF417 barcode painter, flippable back face, brightness boost overlay with giant QR.
- **Living wallet stack** (`features/wallet/wallet_screen.dart` `_PassStack`) — accelerometer tilt on active card, long-press fan-out gesture, Stack/Fan toggle pill.
- **Living globe** (`cinematic/globe_renderer.dart`) — twinkling starfield, night-side city lights (warm 0xFFFFD27D glints), flowing dashed flight arcs (animated dash phase), atmosphere halo, sun terminator, hubs with pulse rings.
- **Premium motion** (`motion/motion.dart`) — `GlobeMotion.spring/.pop/.settle` curves, `premiumSlideTransition` (slide+scale+blur), `Haptics` vocabulary, `SoundCues` stub.
- **Design system** — `PageScaffold`, `PremiumCard`, `Pressable`, `AnimatedAppearance`, `CinematicButton`, `AppToast.show(...)`, `GlassSurface`, `SectionHeader`, `EmptyState`, tier-aware color mapping (Elite/Platinum gold, Plus/Gold amber, Standard/Silver gray, default purple), `.withValues(alpha:)` everywhere (no `withOpacity` calls), spring curves, haptic vocab, layered animations, parallax tilt patterns.
- **DemoData** (`data/api/demo_data.dart`, 1224 LOC) — offline-first deterministic data fallback. **Do not remove.**
- **Build state:** `flutter pub get` clean, `flutter analyze` 0 issues, `flutter test` 6/6 pass.

### 3.5 What's still thin / missing

(See §6 for the prioritized roadmap.)

- Identity not in main tab bar (5-tab vs original 6-tab).
- No theme toggle in app chrome (only via `/profile`).
- `AtmosphereLayer` from TS not yet ported (animated orbs + particles + light ray).
- 3D globe is still a custom-painter approximation, not WebGL/R3F level.
- Several screens (`SocialScreen`, `IntelligenceScreen`, `PassportBookScreen` grid, `ExploreScreen`, `FeedScreen`, service sub-screens) are functionally wired but visually "thinner" than the TS originals.
- Auto-lock controller (`WidgetsBindingObserver`) not wired.
- Deep links (`globeid://`) not wired to `app_links` listener.
- Onboarding `completed` flag not yet persisted to SharedPreferences.
- Boarding-pass HMAC sign/verify roundtrip tests missing.
- Y.js multi-device social sync — not feasible in Flutter without a CRDT package; punt or replace.
- Stripe Issuing virtual card — out of scope.
- iOS Info.plist permission strings still placeholders (verify before TestFlight).

---

## 4. Comprehensive missing-parity inventory

Cross-reference of everything that was in `src/` and is **not yet** at parity in `flutter_app/`.

### 4.1 Screens

| TS screen | Flutter equivalent | Gap |
|---|---|---|
| `Home.tsx` | `home/home_screen.dart` | TS has live atmosphere layer + parallax HUD; Flutter has briefing HUD but lighter atmosphere |
| `Identity.tsx` | `identity/identity_screen.dart` | Identity not in bottom-nav (TS had 6 tabs, Flutter has 5) |
| `IdentityVault.tsx` | `vault/vault_screen.dart` | Missing audit log surface, share-with-TTL, encrypted export |
| `LockScreen.tsx` | `lock/lock_screen.dart` | Auto-lock observer not wired |
| `Travel.tsx` | `travel/travel_screen.dart` | Country insights cards thinner |
| `TravelTimeline.tsx` | `timeline/timeline_screen.dart` | OK |
| `TravelIntelligence.tsx` | `intelligence/intelligence_screen.dart` | TS has curated weekly briefing; Flutter shows raw map |
| `TripDetail.tsx` | `trip/trip_detail_screen.dart` | Now has boarding-pass entry; weather/visa/packing inline cards still thinner |
| `TripPlanner.tsx` | `planner/planner_screen.dart` | Drag-to-reorder, budget breakdown, multi-leg autocomplete missing |
| `DocumentVault.tsx` | `vault/vault_screen.dart` | Missing visa-stamp browser, scan-and-forget |
| `EntryReceipt.tsx` | `receipt/receipt_screen.dart` | OK |
| `Onboarding.tsx` | `onboarding/onboarding_screen.dart` | 5-step cinematic from PR #52 ✅; persistence flag still needs hookup |
| `Profile.tsx` / `UserProfile.tsx` | `profile/profile_screen.dart` | Settings expansion still needed |
| `HybridScanner.tsx` | `scanner/scanner_screen.dart` | Edge overlay + MLKit ✅; auto-categorise missing |
| `KioskSimulator.tsx` | `kiosk/kiosk_screen.dart` | HMAC verify in PR #53 ✅; face-mesh demo still placeholder |
| `GlobalMap.tsx` | `map/map_screen.dart` | 2D `flutter_map` only — no 3D globe inside this screen |
| `Explore.tsx` | `explore/explore_screen.dart` | Pinch-zoom feed missing |
| `PlanetExplorer.tsx` | none | Not yet ported |
| `SocialFeed.tsx` / `SocialFeedV2.tsx` | `social/social_screen.dart` + `feed/feed_screen.dart` | Stories bar, post creation, notifications missing |
| `ServicesHub.tsx` / `SuperServicesHub.tsx` | `services/services_screen.dart` + sub-screens | All 16 service panels need depth (Budget, Esim, Exchange, Food, Fraud, Hotels, Insurance, Intelligence, LocalServices, Loyalty, Rides, Safety, Score, Visa, Weather) |
| `AnalyticsDashboard.tsx` | `analytics/analytics_screen.dart` | OK |
| `MultiCurrency.tsx` | `multi_currency/multi_currency_screen.dart` | OK |

### 4.2 Cross-cutting features still to land

1. **3D globe upgrade** — current is CPU-side custom painter. Options: (a) port to a Skia shader (`Fragment`-based SkSL) for atmospheric scattering + bloom; (b) use Rive 2 with Skia GPU; (c) use `flutter_3d_controller` or `model_viewer_plus` for a real GLB Earth; (d) `flutter_gl` + Three.js bridge. **Recommended: keep current painter as the universal fallback, add an opt-in shader path** (since the user explicitly said "no GPU limitations").
2. **AtmosphereLayer port** — animated orbs (3) + particle field (18) + light ray, with `reduceTransparency` fallback.
3. **Theme toggle in app chrome** — top-right `ThemeToggle` widget that cycles `ThemeMode` and exposes accent picker on long-press.
4. **Identity tab in bottom nav** — restore 6-tab parity (Home / Identity / Wallet / Travel / Map / Services). Tab math: per-slot width = (W − 2*padding − FAB-gap) / 6.
5. **Auto-lock controller** — `WidgetsBindingObserver` plumbed from `AppShell` to lock vault after 30 s background.
6. **Deep links** — `app_links` listener mapping `globeid://trip/<id>` and `globeid://pass/<code>` to go_router paths on cold + warm start.
7. **Live activities / push** — `flutter_local_notifications` already in pubspec; need scheduled "leave for airport" alarm based on `predictive_departure.dart`, and FCM/APNS registration.
8. **Live MRZ overlay** — pipe `mobile_scanner` frames through `google_mlkit_text_recognition` and overlay detected MRZ strip live with confidence score.
9. **Voice intent overlay** — `speech_to_text` stream → regex parser (port `voiceIntents.ts`) → `Haptics.confirm()` + go_router push.
10. **Audio cues** — wire `SoundCues` stub to a real audio package (e.g. `audioplayers` ^6.x or `soloud`); load `.wav` cues into `assets/audio/`.
11. **Trip group wallet** — collapse multi-leg trips into a paginated "trip wallet" (Apple Wallet group cards).
12. **Pass back-side flip per pass** — already in `boarding_pass_live` ✅; replicate on every doc type.
13. **Boarding-pass HMAC tests** — port `boarding_pass.test.ts` cases to `test/boarding_pass_test.dart`.
14. **MRZ TD1/TD3 parser tests** — fixtures already exist in TS at `lib/mrzParser.test.ts`.
15. **Currency engine tests** — rate snap + conversion edge cases.
16. **Connection detector + predictive departure tests.**

### 4.3 Backend integration status

`flutter_app/lib/data/api/globeid_api.dart` wraps `dio` against the Hono endpoints. **All endpoints are wired** but the app falls back to `DemoData` (1224 LOC) when offline — verified working. Endpoint coverage:

- ✅ `/api/user`, `/api/wallet`, `/api/trips`, `/api/lifecycle`, `/api/score`, `/api/insights`, `/api/recommendations`, `/api/loyalty`, `/api/visa`, `/api/weather`, `/api/exchange`, `/api/hotels`, `/api/rides`, `/api/food`, `/api/local`, `/api/safety`, `/api/fraud`, `/api/budget`, `/api/insurance`, `/api/esim`, `/api/planner`, `/api/copilot`, `/api/alerts`, `/api/context`.
- ❌ Real auth (currently demo). Backend ships HMAC token signing (`server/src/auth/token.ts`); Flutter uses static demo token. Need OAuth/SSO + email magic-link.
- ❌ WebSocket / SSE for live flight push (`/api/flightStatus` is poll-only).
- ❌ Server-sent share URLs (`/share/trip/:id`).

---

## 5. Premium UI/UX upgrade plan

Layered checklist — each item is a single PR's worth of work.

### 5.1 Visual depth

- **Adaptive blur layers** — `BackdropFilter(ImageFilter.blur)` on every glass surface, with `MediaQuery.maybeDisableAnimationsOf` fallback to flat fill.
- **Atmospheric shadows** — replace `BoxShadow(blurRadius: 20)` with multi-layer `BoxShadow` stacks (one tight, one wide, one tinted).
- **Per-surface gradient** — `cardDark` 0x111827 → 0x0E1422 vertical gradient on every card.
- **Specular highlights on cards** — add a 12 % white radial highlight at top-left on every elevated card.
- **Ambient grain** — port `cinematic/UILighting.tsx` ambient grain texture as a `CustomPainter` overlay at 4 % alpha.
- **Cinematic dark canvas** — layered radial gradients per scaffold (already partial, finish for every screen).

### 5.2 Motion depth

- **Spring on every press** — wrap every button in `Pressable` (already a primitive); audit for missing usage.
- **Staggered list reveals** — wrap every list with `AnimatedAppearance(delay: i * 60ms)`.
- **Hero on every navigable card** — add unique `Hero(tag: '...')` to PassCard, TripCard, DocumentCard, StampTile, ServiceCard. Audit collisions before pushing.
- **Page transitions** — `premiumSlideTransition` already wired in router ✅. Verify it's used for every secondary route.
- **Tab transitions** — replace shell tab switches with `FadeThroughTransition` (`animations` package).
- **Pull-to-refresh** — every scrollable adopts `RefreshIndicator` (most do; audit for misses).
- **Swipe-back gesture** — Cupertino-style edge swipe on Android (port `EdgeSwipeBack.tsx`).
- **Haptics on every state change** — call `Haptics.tap/open/close/confirm/error/scrub/navigate` instead of raw `HapticFeedback`.

### 5.3 Typography

- **Premium font stack** — current default; consider adding `google_fonts` with `Inter Tight` for body and `Cormorant Garamond` for passport headings.
- **Optical sizing** — variable-font weights at small sizes (display: 700; body: 400 weight 500 fill).
- **Letter-spacing scale** — display: -0.02; body: 0; eyebrow: 0.6 (tracking).

### 5.4 Empty / loading states

- **Skeleton shimmer** — every list has a `Skeleton` widget (port `SkeletonLoader.tsx`).
- **Animated empty states** — every `EmptyState` has a Lottie or custom-painter illustration that loops subtly.
- **Pull-to-refresh shimmer** — replace stock spinner with branded radial bloom.

### 5.5 Microinteractions

- **Form field focus ring** — animated outline expands on focus.
- **Toggle thumbs** — spring physics on `Switch` (replace stock with `CupertinoSwitch` + `GlobeMotion.pop`).
- **Number tickers** — every numeric metric uses `AnimatedNumber` (already a primitive; audit usage).
- **Sparkline reveals** — every `Sparkline` does a left-to-right reveal on first paint.
- **Confetti / success bursts** — port `confetti.ts` to a `CustomPainter` particle field on confirmations.

---

## 6. Prioritized roadmap (phases)

Implementation phases, in order of visual + functional impact. Each phase = ~1–3 PRs.

### Phase 1 — Living document twins (passport done; expand)

- Living **driving licence** screen (`/license-live`) — embossed seal, hologram, magstripe painter, MRZ parser hookup.
- Living **visa stamp** screen (`/visa-live`) — country-tinted ink, security thread, watermark.
- Living **vaccination certificate** (`/health-live`) — WHO yellow card with embossed crest, batch-number QR.
- Each lives under `flutter_app/lib/features/<doc>_live/<doc>_live_screen.dart`, follows the passport pattern.

### Phase 2 — 3D globe upgrade

- Add `assets/shaders/atmosphere.frag` — SkSL shader for atmospheric scattering (Rayleigh approximation).
- Add `assets/shaders/clouds.frag` — animated cloud band with Fractal noise.
- Wire shaders via `Shader.fromAsset` in `globe_renderer.dart`. CPU-painter remains the fallback.
- Add real Earth texture (Blue Marble 8k) at `assets/images/earth_8k.jpg`. Use `flutter_3d_controller` or `model_viewer_plus` as opt-in for a true GLB.

### Phase 3 — Identity tab + chrome polish

- Add Identity tab back into `AppShell` bottom nav (6-tab parity). Re-balance per-slot width math.
- Top-right `ThemeToggle` in app chrome with accent picker bottom-sheet on long-press.
- Atmosphere layer port to `widgets/atmosphere_layer.dart` (3 drifting orbs + 18 particles + light ray + reduce-effects fallback).

### Phase 4 — Live MRZ + live boarding pass push

- Pipe `mobile_scanner` frames through `google_mlkit_text_recognition` for live MRZ overlay with confidence ring.
- Replace boarding-pass polling with SSE on `/api/flightStatus/sse`. Backend gets a new SSE endpoint.
- Live Activity / Live Notification for active flight (Android `flutter_local_notifications` ongoing channel; iOS Live Activity via `live_activities` package).

### Phase 5 — Voice + sound cue wiring

- Port `voiceIntents.ts` regex parser to `lib/domain/voice_intents.dart`.
- Wire `speech_to_text` stream → intent parser → go_router push.
- Wire `audioplayers` ^6.x into `SoundCues.play(...)`. Load `.wav` cues into `assets/audio/{tap,open,close,confirm,error,navigate,success}.wav` (royalty-free; recommend Apple SF Symbols-equivalent set).

### Phase 6 — Service hub depth (16 panels)

For every panel (Budget, Esim, Exchange, Food, Fraud, Hotels, Insurance, Intelligence, LocalServices, Loyalty, Rides, Safety, Score, Visa, Weather, Activities/Transport):

1. Hero card with brand gradient.
2. Live deterministic data row (FX rate, weather temp, visa expiry days).
3. CTA → service-specific full-screen experience.
4. Skeleton shimmer + animated empty state.

### Phase 7 — Social + feed depth

- Stories bar (port `StoriesBar.tsx`).
- Post creation flow (port `CreatePost.tsx`).
- Notifications inbox (port `Notifications.tsx`).
- Pinch-zoom photo viewer (port via `photo_view` package).

### Phase 8 — Wallet ecosystem depth

- Trip-group wallet card (paginated multi-leg).
- Pass auto-pin within 24 h of departure.
- Pass-card brightness ramp on tap (already in pass_detail ✅; verify on all doc types).
- Stripe Issuing virtual card placeholder (out-of-scope live, but UI mock OK).
- Crypto bridge view (read-only Etherscan via free API).

### Phase 9 — Test parity

- Port the high-value tests from `src/`: boarding-pass HMAC roundtrip, MRZ TD1/TD3 parser, currency engine, connection detector, predictive departure, identity tier banding.
- Target 50+ tests in `test/` (currently 6).

### Phase 10 — Backend evolution

- Real auth (Lucia / better-auth + email magic link).
- WebSocket / SSE for flight status.
- Audit log table + endpoints.
- OpenAPI spec generation (`hono-openapi` + `openapi-typescript` for typed client).
- Healthcheck + Prometheus `/metrics`.

---

## 7. Advanced Flutter rendering / motion recommendations

Use these aggressively — the user explicitly wants GPU-heavy, asset-rich, ecosystem-feel.

### 7.1 Shaders

- Add `assets/shaders/` folder. Compile SkSL via Flutter's `Shader.fromAsset`.
- Recommended shaders:
  - `atmosphere.frag` — Rayleigh + Mie scattering on globe edge.
  - `clouds.frag` — Fractal noise cloud band animated by `pulseT`.
  - `holographic.frag` — rainbow sweep for passport / boarding-pass foil.
  - `glass.frag` — true frosted glass for surfaces (cheaper than `BackdropFilter` per-frame).
  - `aurora.frag` — animated aurora sheen for premium tier banners.

### 7.2 Custom painters (already heavy use; expand)

- Embossed crest, security mesh, ink stamps, perforations, PDF417 barcodes — already in.
- Add: animated globe meridians, sun rays, lens flares, cloud silhouettes, water ripple on hub markers.

### 7.3 Rive

- Add `rive` package for vector animation hot-paths (onboarding cinematic, passport hologram, success bursts).
- Build `assets/rive/{onboarding,passport,success,error}.riv` and load via `RiveAnimation.asset`.

### 7.4 Lottie

- Already in pubspec. Use for empty-state animations and onboarding transitions.

### 7.5 3D / GLB

- For a real Earth, add `flutter_3d_controller` + `assets/models/earth.glb` (Blue Marble 8k baked).
- Or `model_viewer_plus` for inline glTF.

### 7.6 Particles

- `flutter_animate` + custom particle painter. Or wrap `nima_flutter` if you want skeletal animation.
- Confetti, snow, stars, sparkles on every confirm.

### 7.7 Page transitions

- `motion/motion.dart` already exposes `premiumSlideTransition`. Add:
  - `premiumSharedAxisTransition` for tab swaps.
  - `premiumContainerTransform` for card → detail (mimics Material `OpenContainer`).
  - `premiumZoomTransition` for full-screen modals.

### 7.8 Haptics

- `Haptics` vocabulary already in. Add `Haptics.heartbeat()` for live trip countdown ticks (every-minute subtle pulse).

---

## 8. Architecture evolution recommendations

### 8.1 State management

- Stay on **Riverpod 2.x** (already in). Resist migrating to bloc/redux — Riverpod's `Notifier` + `FutureProvider` already maps 1:1 to TS Zustand.
- Add **`riverpod_generator`** for codegen if the provider count grows past ~50.
- Add `riverpod_lint` to dev deps for catching common pitfalls.

### 8.2 Routing

- Stay on **`go_router` 14.x**. Add a `RouteObserver` for analytics + back-stack auditing.
- Move `_route` factory to `motion/motion.dart` (so any module can build a `CustomTransitionPage` with the premium transition).

### 8.3 Persistence

- Currently `SharedPreferences` — fine for V1. For doc vault, migrate to `flutter_secure_storage` (already in pubspec). Add a hot-swap layer.
- For larger blobs (PDFs, photos), use `path_provider` + encrypted file (libsodium).

### 8.4 Networking

- `dio` 5.x + `ApiClient` envelope. Add `pretty_dio_logger` for dev. Add `dio_smart_retry` for resilience.
- Add SSE / WebSocket support via `dio` interceptor + `web_socket_channel`.

### 8.5 Modular feature folders

- Each `features/<name>/` should contain `<name>_screen.dart`, `<name>_provider.dart`, `<name>_widgets.dart`, `<name>_models.dart`. Audit current folders for consistency.

### 8.6 Code generation

- `freezed` + `json_serializable` for models (currently hand-rolled). Worth doing once model count > 20.
- `riverpod_generator` once provider count > 50.

### 8.7 Testing

- `flutter_test` + `mocktail` for unit / widget tests.
- `integration_test` for E2E flows (onboarding → scan → save → wallet → trip detail → kiosk verify).
- `golden_toolkit` for visual regression on key screens.
- `patrol` for full-stack E2E with native plugin testing.

### 8.8 Performance

- Always use `RepaintBoundary` around `CustomPaint` widgets that animate independently.
- Use `AutomaticKeepAliveClientMixin` on tab screens to avoid rebuilds on tab swap.
- Use `IndexedStack` for the bottom-nav shell to keep all tabs alive without rebuilding.
- Profile with `flutter run --profile` + DevTools timeline for jank.

### 8.9 Security

- Add `flutter_jailbreak_detection` + refuse to run on rooted devices.
- Add `screenshot_protection` to redact PassDetail / VaultScreen on screen recording.
- Audit log every vault read / write to a local SQLite via `sqflite`.

---

## 9. Backend / frontend integration status

### 9.1 Wired ✅

All 24 Hono endpoints have a corresponding `globeid_api.dart` method, and every Riverpod provider falls back to `DemoData` on network failure. Verified with `flutter test` integration of the API client.

### 9.2 Partially wired ⚠️

- **Authentication.** Backend has HMAC token signing at `server/src/auth/token.ts`; Flutter uses a static demo token in `core/network/api_client.dart`. **Action:** swap for real OAuth (recommend `flutter_appauth` ^7.x) + add a refresh-token interceptor.
- **Live flight status.** Backend exposes `/api/flightStatus` (poll). Flutter polls every 60 s. **Action:** add SSE endpoint backend-side, switch Flutter to `EventSource` listener.

### 9.3 Not wired ❌

- **Push.** Need FCM / APNS registration via `firebase_messaging` ^15.x + backend hook to push on flight-status change.
- **Deep links.** `app_links` is in pubspec but not wired. **Action:** plumb a top-level `appLinkSubscription` in `App` widget that calls `router.push()` on incoming URI.
- **Y.js social sync.** Punted — replace with simple polling.

---

## 10. Remaining bugs / issues / tasks

(Triaged from REMAINING_GAPS.md, ELEVATION_DELTA.md, and BACKLOG.md.)

### 10.1 Bugs

- [ ] Onboarding `completed` flag not persisted (router redirect always lets you in if you re-open app).
- [ ] Auto-lock controller not implemented (vault stays open across background → resume).
- [ ] Some screens (`SocialScreen`) are still empty-state-only.
- [ ] Identity tab missing from bottom nav.
- [ ] iOS Info.plist permission strings still placeholders from `flutter create`.

### 10.2 Tasks

- [ ] Port AtmosphereLayer.
- [ ] Port voice intent regex parser.
- [ ] Port boarding-pass HMAC roundtrip test.
- [ ] Port MRZ TD1/TD3 parser tests.
- [ ] Port currency engine tests.
- [ ] Port connection detector tests.
- [ ] Port predictive departure tests.
- [ ] Add Theme toggle to AppChrome top-right.
- [ ] Add 6th Identity tab.
- [ ] Wire `app_links`.
- [ ] Wire `audioplayers` to SoundCues stub.
- [ ] Wire `firebase_messaging` for push.
- [ ] Wire SSE for live flight status.
- [ ] Add iOS Info.plist permission strings.
- [ ] Add PassportLive equivalent for Driving Licence, Visa, Vaccination.
- [ ] Add real auth flow (OAuth / magic link).
- [ ] Add screenshot protection on PassDetail / VaultScreen.

### 10.3 Polish

- [ ] Audit every screen for `withOpacity` (banned — must use `.withValues(alpha:)`).
- [ ] Audit every screen for `Hero(tag:)` collisions.
- [ ] Audit every list for `AnimatedAppearance` staggered reveal.
- [ ] Audit every button for `Pressable` + spring scale.
- [ ] Audit every state-change for `Haptics.X()` call.
- [ ] Audit every empty state for animated illustration.

---

## 11. "Feel alive" ecosystem expansion ideas

Beyond parity — these are user-vision-aligned moonshot features.

### 11.1 Identity ecosystem

- **NFC passport read** via `nfc_manager` — read MRZ + chip on real e-passport.
- **FaceID-style face mesh** — `google_mlkit_face_detection` + custom 3D mesh painter.
- **Border-entry simulator** — animated kiosk arch + face match + stamp drop.
- **Identity score watcher** — live pulse animation when score changes.
- **Verifiable credentials (W3C VC)** — issue a signed JWT for any document, show QR.

### 11.2 Travel ecosystem

- **Real-time flight 4D playback** — replay any past flight as a 4D arc on the globe.
- **Time-zone watch** — animated dual-time clock on TripDetail.
- **Trip wallet (group)** — collapse multi-leg trip into a paginated card with progress dots.
- **Live boarding-pass refresh** — gate change → push → card animates the new gate in with a flip.
- **Flight arc music** — generative ambient track that morphs with flight phase (taxi / climb / cruise / descent).

### 11.3 Wallet ecosystem

- **Trip-shared expense wallet** — Splitwise-style group expense log.
- **Loyalty aggregator** — link FF programs, show tier progress with animated bars.
- **Crypto bridge** — read-only Etherscan view, with animated balance updates.
- **eSIM marketplace** — Airalo / Saily affiliate API integration with country-tinted SIM cards.

### 11.4 Services ecosystem

- **AI travel co-pilot** — port `TravelCopilot.tsx` + wire to streaming SSE `/api/copilot`.
- **AR boarding pass scan** — `arkit_plugin` / `arcore_flutter_plugin` exploration.
- **Translator overlay** — camera + on-device MLKit translate.
- **SOS / embassy lookup** — geolocator → embassy lookup table → one-tap call.
- **Health / vaccination requirements** — deterministic table per destination.

### 11.5 Globe ecosystem

- **Real Earth texture** — Blue Marble 8k.
- **Animated cloud band** — Fractal-noise SkSL shader.
- **Aurora at poles** — animated aurora sheen at high latitudes.
- **Meteor showers** — random shooting stars across the starfield.
- **Constellation overlay** — port `starCatalog.ts` (Yale BSC) and connect stars into constellations on long-press.
- **City lights brightness by population** — modulate the night-side glints by city size.

### 11.6 Motion ecosystem

- **Page-turn audio** — wire `flip` sound on every page-flip animation (passport, boarding-pass back face).
- **Heartbeat haptic** — subtle pulse on live countdowns.
- **Spring physics on every modal** — replace bottom sheet with custom spring-driven sheet.
- **Hero choreography** — chain Hero animations (tap a TripCard → it morphs into the boarding-pass header → into a full boarding-pass card, all in one gesture).

---

## 12. Key files to read first (reading order for Codex)

When you wake up in this repo, in this exact order:

1. `CODEX_HANDOFF.md` (this file).
2. `flutter_app/lib/app/router.dart` — full route table.
3. `flutter_app/lib/app/app_shell.dart` — bottom nav + chrome.
4. `flutter_app/lib/motion/motion.dart` — motion vocabulary.
5. `flutter_app/lib/cinematic/globe_renderer.dart` — globe painter.
6. `flutter_app/lib/features/passport_book/passport_live_screen.dart` — reference "feel alive" implementation.
7. `flutter_app/lib/features/boarding_pass/boarding_pass_live_screen.dart` — reference "feel alive" implementation.
8. `flutter_app/lib/features/wallet/wallet_screen.dart` — fan-out + tilt reference.
9. `flutter_app/lib/data/api/demo_data.dart` — offline-first fallback (1224 LOC; do not remove).
10. `flutter_app/lib/data/api/globeid_api.dart` — backend client.

Then skim:

- `flutter_app/lib/widgets/` — design system primitives.
- `flutter_app/lib/data/models/` — domain models.
- `flutter_app/lib/domain/` — pure-function modules.
- `server/src/routes/` — backend route surface.
- `server/src/db/schema.ts` — DB schema.

---

## 13. Hard rules / forbidden actions (verbatim from user)

These were laid down across the PR #52, #53, #54 sessions. Do not violate.

- ❌ DO NOT optimize for tiny app size — make it 150–200 MB+.
- ❌ DO NOT create a simplified Flutter clone.
- ❌ DO NOT stop at "compiles" — verify cinematic feel.
- ❌ DO NOT remove `DemoData` (offline-first fallback).
- ❌ DO NOT commit secrets (`.env`, credentials, keys).
- ❌ DO NOT use `withOpacity()` — always use `.withValues(alpha: ...)`.
- ❌ DO NOT introduce new `Hero(tag:)` without checking collisions.
- ❌ DO NOT push directly to `main` or `master`.
- ❌ DO NOT force-push to anyone else's branch (own feature branch + `--force-with-lease` is fine).
- ❌ DO NOT skip git hooks (`--no-verify`, `--no-gpg-sign`).
- ❌ DO NOT amend commits — only add new commits.
- ❌ DO NOT run `git add .` — always specify paths.
- ❌ DO NOT use static cards, placeholder UIs, or simple containers.
- ❌ DO NOT skip animation / motion systems.
- ❌ DO NOT modify tests to make them pass (unless explicitly asked).
- ❌ DO NOT use `Any`, `getattr`, `setattr`, or other lazy attribute access.

---

## 14. Hard standards / required practices

- ✅ `flutter analyze` must return **0 issues** before every commit.
- ✅ `flutter test` must pass before every PR.
- ✅ Every new screen passes `PageScaffold` for chrome.
- ✅ Every elevated card uses `PremiumCard` or `GlassSurface`.
- ✅ Every button uses `Pressable` for spring + haptic.
- ✅ Every list uses `AnimatedAppearance` for staggered reveal.
- ✅ Every state change calls into the `Haptics` vocabulary.
- ✅ Every secondary route uses `premiumSlideTransition` (already wired in router).
- ✅ Every `CustomPaint` is wrapped in `RepaintBoundary` if it animates independently.
- ✅ Every Riverpod provider has a `.hydrate()` method that falls back to `DemoData`.
- ✅ Every screen respects `MediaQuery.maybeDisableAnimationsOf(context)` (reduce-motion).
- ✅ Every PR is created off `main` (never directly to `main`), uses `git_pr(action='fetch_template')` then `git_pr(action='create')`.
- ✅ Every PR waits for `git(action='pr_checks', wait_mode='all')` to pass before reporting.

---

## 15. Build + test commands

```sh
# Setup
cd flutter_app
export PATH="$HOME/flutter/bin:$PATH"   # if not already on PATH
flutter pub get

# Analyze + test
flutter analyze
flutter test

# Run
flutter run                    # debug, host device or emulator
flutter run --profile          # profile mode for perf testing
flutter build apk --debug      # Android APK
flutter build apk --release    # release APK
flutter build appbundle        # Play Store bundle
flutter build ios              # iOS (Mac required)
```

---

## 16. PR conventions

- Branch name: `devin/$(date +%s)-<slug>` (or `codex/$(date +%s)-<slug>` for Codex sessions).
- Commit message format:
  ```
  feat(flutter): <one-line summary in imperative mood>

  <bullet-list of changes>
  ```
- PR title: same one-liner as the commit subject.
- PR body: must use the repo's PR template (fetched via `git_pr(action='fetch_template')`).
- Always include screenshots / recordings for visual changes.
- Always include preview deployment URLs (Vercel / Netlify) if CI provides them.

---

## 17. Recent merged work (context for Codex)

| PR | Title | Status |
|---|---|---|
| #52 | feat(flutter): flagship elevation pass — nav rebalance, briefing HUD, planner wizard, social feed, copilot streaming, activity v3, onboarding 5-step | merged |
| #53 | feat(flutter): elevation pass II — kiosk HMAC, timeline enrichment, explore v3, passport-book v3, polish | merged |
| #54 | feat(flutter): make GlobeID feel ALIVE — living passport, boarding pass, wallet stack, globe, motion | merged |

**You are starting from the state at the head of `main` after PR #54 merged.**

---

## 18. Closing note for Codex

Codex / GPT-5.5 Extra High — you have **maximum implementation freedom**. The user has explicitly asked for ambitious, ecosystem-scale, GPU-heavy, asset-rich, motion-driven, deeply tactile work. Don't shy away from massive PRs (3–10 k LOC), shaders, custom painters, large assets, advanced animations. The constraint is **quality, not size**.

When in doubt, ask:

- Does this **feel alive**?
- Does this **feel tactile**?
- Does this **feel like a digital twin** of the real-world object?
- Would Apple / Notion / Figma / Airbnb / Arc Browser / Linear ship this?

If any answer is no — keep iterating.

The user's vision is a **next-generation flagship global identity + travel + wallet + ecosystem platform**. Build accordingly.

— GlobeID team (handed off via Devin, 2026-05-06)
