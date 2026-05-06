# GlobeID — Engineering Handoff

> Comprehensive briefing for any future Devin / Claude / human session
> picking up the GlobeID repository. Read this top-to-bottom before
> writing a single line of code.

Last updated: **2026-05-05** — Session `404f3c94…56a22` (Devin), branch
`devin/1778057685-flutter-elevate-2`.

---

## 1. What is GlobeID?

GlobeID is a **flagship-grade travel + identity super-app**. Think Apple
Wallet × Google Wallet × Notion × Airbnb × Linear, built for frequent
international travellers. It bundles, in one app:

- **Identity** — encrypted vault of passports, visas, boarding passes,
  insurance docs, with auto-lock, audit log, OCR + MRZ parsing,
  factor-based identity score (0–999), tier badge (Standard → Elite),
  passport book with stamps, kiosk simulator for digital pass demos.
- **Wallet** — multi-currency balances + transactions, brand-themed
  boarding passes with QR/HMAC, parallax tilt, pass flip, Apple-Wallet
  stack metaphor, currency converter, exchange-rate intelligence.
- **Travel** — full trip lifecycle (upcoming / in-progress / past),
  per-leg detail with weather + airport intelligence + connection
  detector, immersive boarding pass detail, planner, packing-list,
  visa-requirement engine, predictive departure timer.
- **Map / Globe** — 3D earth with Rayleigh + Fresnel atmosphere, real
  sun terminator (day/night line), Catmull-Rom flight arcs, animated
  airports, destinations, landmarks.
- **Services hub** — hotels, food, rides, transport, activities, eSIM,
  insurance, visa, lounge access, all in one unified panel system.
- **Intelligence / Copilot** — AI travel assistant, smart suggestions,
  anomaly alerts, fraud detection, safety bulletins, weather + currency
  pulse, predictive next-trip card.
- **Social** — public travel feed, follow other travellers, share
  trips, achievements.
- **Premium chrome** — animated atmosphere layer, glass nav, FAB,
  command palette, theme engine (8 brand accents + auto/light/dark +
  high-contrast + reduce-transparency + 3 density modes).

The app's product philosophy is **"never empty, never web-feeling,
never AI-looking"** — every screen is dense with realistic demo data,
every pixel is intentional, every motion is calm and premium.

---

## 2. Repository layout

```
GlobeID-app-2.0/
├── src/                      # ORIGINAL React/TypeScript/Capacitor app
│   ├── App.tsx               # 25 routes via React Router + lazy chunks
│   ├── screens/              # 25 screens (Home, Wallet, Travel, …)
│   ├── components/
│   │   ├── ui/               # 50+ design-system primitives (Phase-7 v2)
│   │   ├── map/              # 21+ R3F globe / atmosphere / flight arcs
│   │   ├── wallet/           # PassStack, PassDetail, CurrencyCard, …
│   │   ├── layout/v2/        # AppChrome, BottomNav, CommandPalette,
│   │   │                     #   PageTransition, Splash
│   │   ├── identity/         # PassportBook, QRDisplay, EntryStamp, …
│   │   ├── services/         # Hotels, Rides, Insurance, Visa panels, …
│   │   ├── intelligence/     # IntelligenceHUD, PredictiveNextTripCard
│   │   ├── animations/       # LottieView
│   │   ├── ai/               # TravelAssistant, AIAssistantButton
│   │   └── system/           # Coachmark, ErrorBoundary, NativeBackButton
│   ├── cinematic/            # 9 motion / atmosphere / sound modules
│   ├── lib/                  # 50+ utilities (themePrefs, transitions,
│   │                         #   mrzParser, boardingPass HMAC,
│   │                         #   currencyEngine, packingList,
│   │                         #   visaRequirements, voiceIntents, …)
│   ├── store/                # 22 Zustand stores
│   ├── hooks/                # 20+ custom hooks
│   ├── services/             # Capacitor bridges, notification orchestration
│   └── styles/               # Tailwind + CSS variable design-tokens
├── android/                  # Native Android shell for the React app
├── ios/                      # Native iOS shell for the React app
├── flutter_app/              # FLUTTER MIGRATION (target output)
│   ├── lib/                  # 80 .dart files, ~16,200 LOC total
│   │   ├── main.dart
│   │   ├── app/              # router, app_shell, theme tokens
│   │   ├── core/             # network (Dio + DemoData fallback),
│   │   │                     #   storage (SharedPreferences)
│   │   ├── data/
│   │   │   ├── api/          # api_client.dart, demo_data.dart (1224+ lines),
│   │   │   │                 #   globeid_api.dart
│   │   │   ├── models/       # User, Wallet, Lifecycle, TravelDoc, …
│   │   │   └── repositories/
│   │   ├── domain/           # Pure-Dart utilities (airline_brand,
│   │   │                     #   airports, mrz_parser, currency_engine,
│   │   │                     #   visa_requirements, sun_position, …)
│   │   ├── features/         # 31 feature folders, one per screen
│   │   └── widgets/          # premium_card, glass_surface, sparkline,
│   │                         #   atmosphere_layer (NEW), pressable,
│   │                         #   page_scaffold, scan_overlay, toast, …
│   ├── pubspec.yaml          # Flutter dependency manifest
│   ├── android/              # Flutter Android shell
│   ├── ios/                  # Flutter iOS shell
│   ├── web/                  # Flutter web shell
│   ├── ARCHITECTURE.md       # Phase-7 architecture doc
│   ├── FLUTTER_HANDOFF.md    # Original migration handoff
│   ├── BACKLOG.md            # 250+ tracked enhancement items
│   ├── ELEVATION_DELTA.md    # Latest TS-vs-Flutter audit (this PR)
│   └── REMAINING_GAPS.md     # Known gaps tracker
├── HANDOFF.md                # ← THIS DOCUMENT
└── README.md                 # Public repo readme
```

The repository contains **two parallel implementations**:
1. The **original** TypeScript/React/Capacitor app under `src/`
   (still functional, used as the architectural source of truth).
2. The **target** Flutter port under `flutter_app/` (the active
   development target, intended to replace the original on mobile).

When in doubt about a feature, **read the TypeScript source first** —
it is the canonical product spec. Markdown documentation may lag.

---

## 3. Vision & Product Philosophy

The app must feel like:

- **Apple-level polish** — every spacing token, type scale, and motion
  curve is intentional. Nothing is "good enough".
- **Google-Wallet clarity** — boarding passes, QR codes, multi-currency
  balances are clean, scannable, and instantly useful.
- **Notion-level structure** — dense information without clutter.
- **Figma-level design system** — every primitive (Card, Button, Pill,
  Surface, Text) is reusable and theme-aware.
- **Linear-level smoothness** — 90/120 Hz feel everywhere; no janky
  transitions.

### Non-negotiable rules
- **NO** generic UI patterns, web-style layouts, or rectangular
  buttons-in-buttons.
- **NO** placeholder broken widgets or dead buttons.
- **NO** empty states without animated illustration + concrete CTA.
- **NO** API calls that hang the UI — every call has a fallback.
- **NEVER** remove core systems (DemoData, layout-safety, sensor
  resilience, OCR pipeline).

### Always-present systems
- DemoData fallback (offline-first; every endpoint returns realistic
  seed data on network failure).
- Layout-safety (clamp every `LayoutBuilder` width/height to ≥ 0).
- Sensor resilience (`.handleError((_) {})` on every accelerometer
  stream so emulators without sensors don't spam errors).
- Edge-to-edge layouts respecting safe areas + dynamic island.
- Reduced-motion fallback for every animated component.

---

## 4. Architecture

### Original (TypeScript)
- **Routing**: `react-router-dom@7` with lazy-chunked routes.
- **State**: 22 Zustand stores + persisted slices in localStorage.
- **Persistence**: Dexie.js (IndexedDB) for vault + audit log.
- **Networking**: TanStack Query + custom `apiClient` wrapper.
- **3D**: Three.js via React-Three-Fiber + drei, custom GLSL shaders
  for atmosphere, terminator, and outer glow.
- **Motion**: framer-motion / motion@12 with shared `layoutId`
  transitions; spring-tuned timeline orchestrator at
  `src/cinematic/motionEngine.ts` + `motionOrchestrator.ts`.
- **Audio**: Tone.js cue registry at `src/cinematic/uiSound.ts`.
- **Native**: Capacitor 6 with Camera, Filesystem, Geolocation, Local
  Notifications, Haptics, Preferences, Share, Status Bar, Screen
  Brightness (optional).
- **OCR**: Tesseract.js + custom MRZ parser (`src/lib/mrzParser.ts`).
- **QR**: `qrcode` for generation, `@zxing/browser` for scanning.

### Flutter target
- **Routing**: `go_router@14` with `ShellRoute` for the 6 core tabs +
  `CustomTransitionPage` slide+fade for secondary routes.
- **State**: `flutter_riverpod@2` (Notifier + AsyncNotifier).
- **Persistence**: `shared_preferences` + `flutter_secure_storage`.
- **Networking**: `dio` with **DemoData fallback interceptor**
  (every endpoint maps to a richly-populated stub if the request fails).
- **3D**: **2D fallback via `flutter_map` + `latlong2`** — the original
  Three.js globe is acknowledged as *out-of-scope* for the migration;
  the flagship handoff explicitly accepts a hybrid 2D-globe approach.
  Future upgrade path: Flutter GPU + custom shader, or `flutter_gl`.
- **Motion**: `flutter_animate` for declarative reveals + custom
  `AnimatedAppearance` widget; spring-curve presets in
  `lib/app/theme/app_tokens.dart`; shared `Hero` widgets for cross-screen
  morphs.
- **Native**: `local_auth`, `vibration`, `app_links`, `path_provider`,
  `share_plus`, `connectivity_plus`, `geolocator`, `flutter_local_notifications`.
- **OCR / scanner**: `mobile_scanner@6` + `google_mlkit_text_recognition`.
- **QR**: `qr_flutter` for generation, `mobile_scanner` for reading.
- **Camera**: `camera@0.11` + `image_picker` for fallback.

### Layered structure (Flutter)
```
core/         → infra (network, storage, secrets, logging)
domain/       → pure Dart business logic (no Flutter imports)
data/         → API client, demo data, models, repositories
features/     → screen + provider per feature
widgets/      → cross-cutting reusable widgets
app/          → router, theme, shell
```

---

## 5. Migration progress (TypeScript → Flutter)

### Routes (parity at the route-level)
All 25 routes from `src/App.tsx` are mapped in `lib/app/router.dart`:
`/`, `/identity`, `/wallet`, `/travel`, `/services`, `/map`, `/profile`,
`/kiosk-sim`, `/receipt`, `/timeline`, `/planner`, `/copilot`, `/social`,
`/explore`, `/passport-book`, `/intelligence`, `/explorer`, `/vault`,
`/feed`, `/multi-currency`, `/scan`, `/analytics`, `/trip/:tripId`,
`/pass/:passId`, `/lock`, `/onboarding`.

### Screens completed (working, demo-data populated)
- Home (greeting + identity score + sparkline + quick actions + trip glance)
- Wallet (PassStack with peeked-dot indicator, PassCard with tilt + flip + QR, balances, transactions)
- Travel (segmented stages + trip cards)
- Trip detail (immersive header, leg timeline)
- Services hub + sub-screens (Hotels, Rides, Food, Transport, Activities)
- Identity (factor radial, stamps grid)
- Vault (encrypted document list, audit log)
- Passport book (animated stamps)
- Multi-currency (FX with sparklines)
- Receipt (scan-to-classify)
- Analytics (interactive fl_chart pie + line)
- Onboarding (3-page carousel)
- Lock (biometric + auto-lock)
- Map (2D `flutter_map` fallback for the 3D globe)
- Scanner (mobile_scanner + MLKit live overlay)
- Profile (theme picker + density + accents)
- Social, Feed, Timeline, Planner, Copilot, Explore, Intelligence,
  Kiosk simulator, Pass detail.

### Subsystems ported
- **DemoData fallback** at `lib/data/api/demo_data.dart` (1224+ lines,
  40+ endpoints) — every API call has a realistic stub.
- **Theme engine** with 8 accents + system/light/dark + density + reduce
  transparency + high-contrast (`lib/features/settings/theme_prefs_provider.dart`).
- **Premium tokens** (`lib/app/theme/app_tokens.dart`) — spacing ladder,
  radii, motion presets, accent swatches, shadow ladder.
- **Glass extension** for frosted-surface tokens at every screen.
- **Cinematic atmosphere layer** (this PR) — drifting orbs + particles +
  ambient ray (`lib/widgets/atmosphere_layer.dart`).
- **Top-right theme chrome** (this PR) — single tap cycles theme, long-
  press opens accent quick-picker bottom sheet.
- **Command palette** at FAB long-press.
- **Frosted bottom nav** with morphing pill indicator + scan FAB.
- **Toast system** via `toastification@2`.
- **Domain modules** — airline_brand, airports, mrz_parser, currency_engine,
  visa_requirements, packing_list, voice_intents, sun_position, audit_log,
  boarding_pass, connection_detector, identity_tier, predictive_departure.

### Subsystems NOT ported (explicit gaps)
- **3D globe** — accepted as out-of-scope in the migration handoff.
  Flutter currently renders a 2D map via `flutter_map`. Upgrading to a
  true 3D globe would require Flutter GPU + custom shader work and is
  large enough to warrant its own multi-week phase.
- **Cinematic audio cues** (Tone.js) — Flutter has no port yet. Native
  `audioplayers` could fill this with a small sound-bank.
- **Brightness ramp** in PassDetail — Capacitor's `screen-brightness`
  plugin is web-only-pluggable. Flutter would need
  `screen_brightness@2` package.
- **Voice intents** end-to-end loop — domain layer is ported but the UI
  glue (microphone bubble + dictation overlay) is not yet wired into
  the chrome.
- **Camera-based MRZ scanning live overlay** — Flutter scanner can
  capture; live MRZ parsing while streaming is partially wired but
  needs polish to feel like Apple's document scanner.

---

## 6. Runtime/build issues fixed (chronological)

| PR | Problem | Fix |
|---|---|---|
| #38 | Initial migration: nothing compiled | Bootstrap full Flutter scaffold. |
| #39 | Bottom nav too web-like, no premium chrome | Glass nav + morphing pill + FAB pulse-glow. |
| #40 | Travel/copilot/timeline/planner missing visual depth | Phase-3 polish across feature set. |
| #41 | Sparkline chart, command palette missing | Phase-4 — premium sparkline + Cmd-K palette. |
| #42 | No toast system, no page transitions, no skeletons | Phase-5 — toast / page transitions / aurora empty states / shimmer skeletons. |
| #43 | Backend unreachable → app hangs / crashes | Offline `DemoData` fallback baked into `ApiClient` interceptor. |
| #44 | **Red-screen Android crash** (`InheritedWidget` "dependent is not a descendant") | Two root causes: (a) `Sparkline.reduce()` TypeError on dart2js (`(num,num)→num` vs `(int,int)→int`), fixed by normalising values to `List<double>` once before reduce; (b) `Hero` tag collision between Home `_TripGlance` and Travel `_TripCard` both using `tag: 'trip-${id}'`. Removed Hero from Home — Travel owns it as the sole source. Plus layout-safety pass (text-overflow guards, IATA blocks Flexible-wrapped, `.handleError` on accelerometer streams). |

### Common pitfalls already encountered

1. **Hero tag collisions** — Multiple route subtrees can briefly coexist
   during a tab switch. **Each `Hero` tag must be unique across the
   visible tree at any moment.** If two screens display a card for the
   same entity (e.g. trip), only one screen owns the Hero.

2. **`reduce()` type inference on dart2js** — `List<num>` reified at
   runtime as `List<int>` requires a combiner of `(int,int)→int`. Always
   normalise to a typed `List<double>` before reducing if values can be
   `int` or `double`.

3. **Missing sensors on emulators** — `accelerometerEventStream()` will
   throw on platforms without an accelerometer (web, desktop, some
   emulators). Always chain `.handleError((_) {})` so the StreamBuilder
   silently falls back to flat instead of crashing.

4. **Negative `BoxConstraints`** — `LayoutBuilder` widths can become
   negative when the parent shrinks (e.g. keyboard appearing). Always
   `clamp(0.0, double.infinity)` before using.

5. **Top-right chrome overlap** — The new floating theme toggle in
   AppShell sits at `top: padding.top + 8, right: 12`. Every shell
   screen (Home/Wallet/Travel/Services/Identity/Map) needs **48px
   right-side padding** on its top row to avoid overlap with the title
   bar. Already applied to the 5 main screens; check any future top
   chrome additions.

6. **`withOpacity` deprecated** — Always use `Color.withValues(alpha:
   …)` on Flutter 3.27+. The codebase has a clean sweep in PR #44; do
   not regress.

---

## 7. Pending / remaining issues

### Known gaps (from `flutter_app/REMAINING_GAPS.md`)
- 3D globe (acknowledged out-of-scope; 2D fallback in place)
- Cinematic audio cues (no `audioplayers` integration yet)
- PassDetail brightness ramp (no `screen_brightness` integration)
- Voice intents UI glue (domain ported, UI not wired)
- Live MRZ overlay during streaming scan

### Quality follow-ups
- Some screens still feel "thin" relative to original TS depth:
  - `IntelligenceScreen` could use the original's `IntelligenceHUD`
    weather + currency + safety strips.
  - `CopilotScreen` chat bubbles need richer typography + suggestion
    chips like the TS `TravelAssistant`.
  - `PlannerScreen` should be a multi-step wizard, not a single form.
  - `KioskScreen` needs the gate-side reveal animation (camera ✕ pass).
- Onboarding cinematic could add Lottie + 60s product-tour video
  fallback.
- Globe screen: add airport markers + arc layer rendered from
  `lifecycle.trips`, even on the 2D fallback, to give it real density.

### Performance follow-ups
- Profile Atmosphere layer on a low-end Android device — if jank, add a
  device-class detection (RAM ≤ 3 GB → reduced-effects fallback).
- Investigate `Image.asset` caching for Lottie + airline logos.
- Memoise `AccelerometerEventStream` per route to avoid double-listeners.

---

## 8. Audited TypeScript systems (canonical reference)

For each subsystem below, the TS source path is the **canonical spec**.
Always read the TS file before re-implementing in Flutter.

### Cinematic motion / audio / atmosphere
- `src/cinematic/motionEngine.ts` (185 lines) — spring-based motion
  choreography coordinator.
- `src/cinematic/motionOrchestrator.ts` (83 lines) — serializes
  route-enter / FAB-collapse / banner-show into a unified timeline.
- `src/cinematic/AtmosphereLayer.tsx` (163 lines) — 3 drifting glow
  orbs + ambient ray + 18 floating particles.
- `src/cinematic/uiSound.ts` (104 lines) — Tone.js audio cue registry.
- `src/cinematic/DepthParallax.tsx`, `IconMotion.tsx`,
  `ParticleField.tsx`, `ScrollCinematics.tsx`, `UILighting.tsx`,
  `cinematicColors.ts` — additional motion primitives.

### Globe / 3D
- `src/components/map/Globe.tsx` — R3F earth (day/night/bump/water/clouds
  shader, real sun terminator, mobile fallback, anisotropy tuning).
- `src/components/map/Atmosphere.tsx` / `AtmosphereLayer.tsx` —
  Fresnel + Rayleigh scattering shader.
- `src/components/map/FlightArcs.tsx` — Catmull-Rom 3D arcs per trip.
- `src/components/map/Starfield.tsx`, `AirportMarkers.tsx`,
  `DestinationMarkers.tsx`, `LandmarkMarkers.tsx` — geographic
  markers.
- `src/components/map/CinematicCamera.ts` — advanced camera control
  with eased orbits.
- `src/lib/sunPosition.ts` — solar declination → world-space sun
  vector. **Already ported** to `lib/domain/sun_position.dart`.

### Wallet
- `src/components/wallet/PassStack.tsx` (315 lines) — Apple-Wallet
  stacked passes with peek + drag-to-cycle + `layoutId` hero.
- `src/components/wallet/PassDetail.tsx` (409 lines) — full-screen pass
  with brightness ramp, tilt parallax, QR + flip, secure-copy with
  30 s auto-clear.
- `src/components/wallet/CurrencyCard.tsx`, `CurrencyConverter.tsx`,
  `DocumentCard.tsx`, `TransactionList.tsx` — wallet primitives.
- `src/lib/airlineBrand.ts` — IATA-to-brand-gradient mapping.
  **Already ported** to `lib/domain/airline_brand.dart`.

### Theme
- `src/lib/themePrefs.ts` (186 lines) — accent / mode / high-contrast /
  reduce-transparency / density / autoTimeOfDay / quietHours.
- `src/lib/themeAccents.ts` — 8 brand swatches.
  **Already ported** to `lib/features/settings/theme_prefs_provider.dart`
  + `lib/app/theme/app_tokens.dart`.

### Layout / chrome
- `src/components/layout/v2/AppChrome.tsx` (75 lines) — root chrome.
- `src/components/layout/v2/BottomNav.tsx` (122 lines) — 6-tab nav with
  shared-layout pill.
- `src/components/layout/v2/CommandPalette.tsx` (232 lines) — Cmd-K.
- `src/components/layout/v2/PageTransition.tsx` (96 lines) — page
  entry/exit animations.
- `src/components/layout/v2/Splash.tsx` (312 lines) — cinematic
  onboarding.
- **Already ported** to `lib/app/app_shell.dart` (with FAB, command
  palette, top-right theme chrome added).

### Stores → Riverpod providers
| TS Zustand store | Flutter Riverpod provider |
|---|---|
| `userStore.ts` | `lib/features/user/user_provider.dart` |
| `walletStore.ts` | `lib/features/wallet/wallet_provider.dart` |
| `lifecycleStore.ts` | `lib/features/lifecycle/lifecycle_provider.dart` |
| `scoreStore.ts` | `lib/features/score/score_provider.dart` |
| `insightsStore.ts` | `lib/features/insights/insights_provider.dart` |
| `commandPaletteStore.ts` | (inline in app_shell) |
| `alertsStore.ts` | (TODO: extract) |
| `copilotStore.ts` | (TODO: extract) |
| Others (loyalty/budget/safety/fraud/contextStore/…) | TODO: extract per feature |

### Hooks → Flutter equivalents
- `useMotion` → motion presets in `app_tokens.dart`
- `useReducedMotion` → `MediaQuery.disableAnimationsOf(context)`
- `useScrollTint` → custom `ScrollNotificationListener` widget (TODO)
- `useVaultAutoLock` → Riverpod `AutoLockController` (in vault feature)
- `useDeviceTilt` → `accelerometerEventStream()` with `.handleError`
- `useVoiceCommands` → speech_to_text wiring (TODO UI glue)

---

## 9. Premium UI/UX systems

### Design tokens (`lib/app/theme/app_tokens.dart`)
- **Spacing**: 4-pt grid `space1` (4) → `space11` (44).
- **Radii**: `radiusSm` (8), `radiusMd` (12), `radiusLg` (18),
  `radius2xl` (28), `radiusFull` (9999).
- **Motion**: durations (xs 100ms, sm 180ms, md 320ms, lg 540ms);
  curves (easeOutSoft, easeOutBack, easeStandard, springSnap).
- **Accents**: 8 swatches (azure, cobalt, emerald, amber, rose, coral,
  plum, violet) — each exposes `primary`, `glow`, `heroGradient`,
  `washGradient`.
- **Canvas**: `canvasDark` (0xFF05060A), `canvasLight` (0xFFF6F7FB).
- **Shadows**: `shadowSm`, `shadowMd`, `shadowLg` factories that take a
  tint colour (lets every elevated surface emit accent-tinted shadow).

### Reusable widgets (`lib/widgets/`)
| Widget | Purpose |
|---|---|
| `atmosphere_layer.dart` (NEW) | Animated drifting orbs + particles + ambient ray. |
| `glass_surface.dart` | Frosted card with backdrop blur + border + tint. |
| `premium_card.dart` | Gradient hero card with tap haptics. |
| `pressable.dart` | Scale-down on press wrapper. |
| `animated_appearance.dart` | Fade + slide-in on first build. |
| `animated_number.dart` | Smooth tween between numeric values. |
| `sparkline.dart` | Inline area-chart for identity-score history. |
| `scan_overlay.dart` | Live edge-detection feel for scanner. |
| `empty_state.dart` | Aurora animated empty state with CTA. |
| `skeletons.dart` | Shimmer skeleton loaders. |
| `toast.dart` | Toastification wrapper. |
| `section_header.dart` | Title + subtitle + action affordance. |
| `page_scaffold.dart` | Common page chrome with safe-area + scroll behaviour. |

---

## 10. Backend / network / demo data

The app supports **two operating modes**, controlled by network reachability:

### Online mode
- Dio sends requests to the configured base URL (defaults to a stub).
- Responses parsed by repositories into typed models.

### Offline / demo mode
- **`ApiClient._request()`** wraps every Dio call in `try/catch`.
- On any network error (timeout, host unreachable, connection reset),
  the request is fulfilled by **`DemoData.lookup(path)`** which returns
  a `{ok: true, data: …}` envelope with rich seed content.
- This means **the app is always usable on a fresh device with no
  backend** — every screen populates with realistic data.

The DemoData payloads live in `lib/data/api/demo_data.dart` (1,224+
lines) and cover:
- Wallet snapshot (multi-currency balances + 12 transactions)
- Lifecycle (trips with legs, gates, seats, weather, connections)
- Travel records (history + intents)
- Identity (score 754, history sparkline, factors)
- Recommendations + alerts + copilot history
- Planner trips, hotels, food, rides search
- Exchange rates, weather forecast, visa policies, insurance plans
- eSIM plans, loyalty, budget, fraud, safety, audit, intelligence

**DO NOT remove demo data** — the entire UX assumes it as the offline
backbone.

---

## 11. Dependencies (Flutter)

Key packages from `pubspec.yaml` (Flutter 3.27+, Dart 3.6+):

```yaml
go_router: ^14.6.2
flutter_riverpod: ^2.6.1
dio: ^5.7.0
shared_preferences: ^2.3.3
flutter_secure_storage: ^9.2.2
flutter_animate: ^4.5.2
cached_network_image: ^3.4.1
fl_chart: ^0.69.2
qr_flutter: ^4.1.0
lottie: ^3.1.3
mobile_scanner: ^6.0.2
google_mlkit_text_recognition: ^0.14.0
camera: ^0.11.0+2
image_picker: ^1.1.2
flutter_local_notifications: ^18.0.1
local_auth: ^2.3.0
share_plus: ^10.1.2
connectivity_plus: ^6.1.0
geolocator: ^13.0.2
speech_to_text: ^7.0.0
vibration: ^2.0.1
app_links: ^6.3.2
path_provider: ^2.1.5
sensors_plus: ^6.1.1
flutter_map: ^7.0.2
latlong2: ^0.9.1
flutter_form_builder: ^9.5.0
form_builder_validators: ^11.1.2
intl: ^0.19.0
crypto: ^3.0.6
decimal: ^3.0.2
collection: ^1.18.0
uuid: ^4.5.1
pdf: ^3.11.1
printing: ^5.13.4
toastification: ^2.3.0
```

### Android
- AGP / Gradle / Kotlin: latest stable compatible with Flutter 3.27+
  (managed by `flutter create` defaults).
- `google_mlkit_text_recognition` requires `minSdkVersion 21+`.
- `mobile_scanner` requires camera + INTERNET permissions in
  `AndroidManifest.xml`.
- ProGuard rules already present for ML Kit.

### iOS
- Min iOS 13.0 (mobile_scanner requirement).
- Required Info.plist keys: `NSCameraUsageDescription`,
  `NSPhotoLibraryUsageDescription`, `NSMicrophoneUsageDescription`,
  `NSLocationWhenInUseUsageDescription`, `NSFaceIDUsageDescription`.

### Web
- Builds; some plugins (camera, sensors) are no-ops or use
  `.handleError`.

---

## 12. Important design decisions

1. **5-tab nav + scan FAB > 6-tab nav.** The original TS app had a 6-tab
   bottom nav. Flutter uses 5 tabs (Home / Wallet / Travel / Services /
   Map) + a centered scan FAB. Identity is one tap away via the
   command palette (FAB long-press) and is also accessible from quick
   actions on Home.

2. **2D map > 3D globe (for now).** The original three.js globe is
   beautiful but expensive. Flutter ships with a 2D `flutter_map`
   fallback. The migration handoff explicitly accepts this trade-off.

3. **DemoData is mandatory, not a debug aid.** It powers the offline
   experience. The app never shows empty states for the network
   reason — only for "user has no trips yet" reasons.

4. **Theme-mode is per-user, persisted, with auto-time-of-day.** The
   top-right chrome cycles `system → light → dark`; long-press opens an
   accent quick-picker. Settings page exposes the full theme controls
   (high-contrast, reduce-transparency, density, quiet hours).

5. **Hero tags are unique per entity, owned by exactly one screen.**
   This is the rule that prevents the InheritedWidget assertion from
   PR #44.

6. **Every screen has a `RefreshIndicator` over a scrollable parent.**
   Pull-to-refresh is a universal gesture in this app.

7. **Every screen leaves 48px right padding on its top row** to avoid
   overlap with the floating top-right theme chrome.

8. **Animations honour `MediaQuery.disableAnimationsOf` and
   `ThemePrefs.reduceTransparency`** — the `AtmosphereLayer` falls back
   to two static blurred orbs when either is true.

---

## 13. Recommended next execution phases

Order matters. Each phase should ship as its own PR off `main`.

### Phase A — Visual depth (1–2 sessions)
1. Replace IntelligenceScreen / CopilotScreen / PlannerScreen with
   richer compositions (HUD strips, chat bubbles, multi-step wizard).
2. Globe screen: airport markers + arc layer on the 2D map fallback.
3. Onboarding cinematic: Lottie illustrations + product tour.
4. Add **device-class detection** for AtmosphereLayer (skip on low-RAM).

### Phase B — Sound + brightness (1 session)
1. Add `audioplayers` + a small sound bank (tap/expand/success/error).
2. Wire `screen_brightness` package into PassDetail open/close.

### Phase C — Voice + camera-MRZ live (1–2 sessions)
1. Voice-intents UI glue (microphone bubble + dictation overlay).
2. Live MRZ overlay during scanner streaming.

### Phase D — 3D globe (multi-session, optional)
1. Investigate Flutter GPU + custom shader for an actual earth sphere
   with day/night terminator + atmosphere.
2. Port `Globe.tsx` shader uniforms verbatim.
3. Port `FlightArcs.tsx` with Catmull-Rom curves.

### Phase E — Backend production (multi-session)
1. Replace DemoData fallback with a real API (FastAPI / Go service).
2. Add auth (OAuth + JWT refresh).
3. Server-side TripLifecycle state machine.

---

## 14. Important warnings & pitfalls

- **DO NOT** push directly to `main`. Always work on a `devin/<ts>-…`
  branch and open a PR.
- **DO NOT** force-push to anyone else's branch. `--force-with-lease`
  on your own branch is fine after a rebase.
- **DO NOT** commit secrets. Repo contains no `.env` for a reason.
- **DO NOT** remove DemoData. The whole UX depends on it.
- **DO NOT** add `.withOpacity()` calls — use `.withValues(alpha:…)`.
- **DO NOT** introduce new `Hero` tags without checking for collisions
  in other screens that may be visible during a route transition.
- **DO NOT** run `git add .` — adds unrelated files.
- **DO NOT** assume the user has an Android emulator running — verify
  builds via `flutter analyze` + `flutter test` + APK build only.
- **DO NOT** rely on the markdown docs alone — read the TS source.
- **DO NOT** stop at "compiles" — verify runtime behaviour mentally
  via reading the code, then push.

---

## 15. Verification checklist (before every PR)

```bash
cd flutter_app

# 1. Pub get
flutter pub get

# 2. Static analysis — must show 0 issues
flutter analyze

# 3. Unit + widget tests — must all pass
flutter test

# 4. (Optional but ideal) APK build to prove Android compiles
flutter build apk --debug
```

Then:
```bash
git add <only the files you intentionally changed>
git commit -m "<conventional commit message>"
git push -u origin <branch>
```

Then:
- `git_pr(action="fetch_template")`
- `git_pr(action="create", repo="Devanshisbroke/GlobeID-app-2.0", …)`
- `git(action="pr_checks", wait_mode="all")` — wait for CI green.
- Message the user with the PR URL.

---

## 16. Useful one-liners

```bash
# Find every Flutter screen
find flutter_app/lib/features -maxdepth 2 -name '*.dart' | sort

# Count lines per feature
find flutter_app/lib/features -name '*.dart' | xargs wc -l | sort -n

# Find every place that references the old API
grep -rn "withOpacity\|MaterialStateProperty" flutter_app/lib

# List all unique Hero tags (catch collision risk)
grep -rEh "Hero\(\s*tag:\s*'[^']+'" flutter_app/lib | sort -u

# See current branch's diff summary against main
git -C /home/ubuntu/repos/GlobeID-app-2.0 diff --stat main..HEAD
```

---

## 17. Contact / continuity

- **Original GitHub repo**: `Devanshisbroke/GlobeID-app-2.0`
- **Active migration target**: `flutter_app/`
- **Design tokens source of truth**: `flutter_app/lib/app/theme/app_tokens.dart`
- **Theme prefs source of truth**: `flutter_app/lib/features/settings/theme_prefs_provider.dart`
- **App shell source of truth**: `flutter_app/lib/app/app_shell.dart`
- **DemoData source of truth**: `flutter_app/lib/data/api/demo_data.dart`
- **Latest delta audit**: `flutter_app/ELEVATION_DELTA.md`
- **Original architecture**: `flutter_app/ARCHITECTURE.md`
- **Migration mapping**: `flutter_app/MIGRATION_MAPPING.md`
- **Backlog**: `flutter_app/BACKLOG.md`
- **Known gaps**: `flutter_app/REMAINING_GAPS.md`

---

> **TL;DR for the next session**: read this file → read
> `flutter_app/ARCHITECTURE.md` → skim `flutter_app/BACKLOG.md` →
> pick a phase from §13 → branch off `main` → ship.
