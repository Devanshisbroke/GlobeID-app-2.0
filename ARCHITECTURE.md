# GlobeID — Full Project Architecture

> **Single-file architecture reference.** This document is exhaustive. Every layer, every screen, every store, every library module, every hook, every API endpoint, every database table, every native bridge surface, every theme token, every build-config switch, and every test surface is enumerated. Skim with the table of contents; deep-dive section by section.
>
> Companion docs:
> - `BACKLOG.md` — 250-item product backlog with sprint slices.
> - `FLUTTER_HANDOFF.md` — full migration brief written for an autonomous coding agent rebuilding GlobeID in Flutter.

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Design Principles](#2-design-principles)
3. [High-Level Architecture](#3-high-level-architecture)
4. [Frontend — Repository Layout](#4-frontend--repository-layout)
5. [Screens (Routes)](#5-screens-routes)
6. [Components](#6-components)
7. [State Management — Zustand Stores](#7-state-management--zustand-stores)
8. [Hooks](#8-hooks)
9. [`lib/` — Pure Modules](#9-lib--pure-modules)
10. [Services Layer (Frontend)](#10-services-layer-frontend)
11. [Cinematic, Motion & Theming](#11-cinematic-motion--theming)
12. [Internationalisation (i18n)](#12-internationalisation-i18n)
13. [Native Bridge & Capacitor Plugins](#13-native-bridge--capacitor-plugins)
14. [Backend — Hono + SQLite + Drizzle](#14-backend--hono--sqlite--drizzle)
15. [Database Schema](#15-database-schema)
16. [API Surface](#16-api-surface)
17. [Routing & Deep Links](#17-routing--deep-links)
18. [Hydration & Sync Sequences](#18-hydration--sync-sequences)
19. [Boarding-Pass Cryptography](#19-boarding-pass-cryptography)
20. [Security Model](#20-security-model)
21. [Performance Model](#21-performance-model)
22. [Build, PWA, Capacitor & Vite Configs](#22-build-pwa-capacitor--vite-configs)
23. [Testing Strategy](#23-testing-strategy)
24. [CI / CD](#24-ci--cd)
25. [Telemetry & Observability](#25-telemetry--observability)
26. [Error Boundaries & Resilience](#26-error-boundaries--resilience)
27. [Asset Pipeline](#27-asset-pipeline)
28. [Audio Cues & Haptics](#28-audio-cues--haptics)
29. [Voice Pipeline](#29-voice-pipeline)
30. [Globe / 3D Pipeline](#30-globe--3d-pipeline)
31. [Notification Pipeline](#31-notification-pipeline)
32. [Offline / Sync Pipeline](#32-offline--sync-pipeline)
33. [Extension Points](#33-extension-points)
34. [Glossary](#34-glossary)

---

## 1. System Overview

GlobeID is a **cross-platform travel + identity super-app**:

- **Front-end**: React 18 + TypeScript SPA (Vite). Capacitor wraps it for Android (iOS-ready). Same bundle deploys as a PWA.
- **Back-end**: Hono on Node, persisting to local SQLite via Drizzle ORM. ~25 REST endpoints, all schema-validated with Zod.
- **3D**: Three.js + R3F for the cinematic globe; Postprocessing for bloom / vignette / chromatic aberration.
- **State**: 21 Zustand stores with `persist` middleware, plus React Query for server state.
- **Data**: ~75 pure modules in `src/lib`, ~316 unit + integration tests.

The app provides:

| Pillar | What the user does |
|---|---|
| **Identity** | Scans passport / ID / visa / boarding pass; biometric-gated vault stores docs encrypted on device. |
| **Travel** | Plans multi-leg trips with weather, visa, packing, lounges, rides, currency, and a 3D globe that lights up arcs of past + upcoming flights. |
| **Wallet** | Apple-Wallet-style boarding-pass cards with HMAC-signed QR; multi-currency balances; virtual-card placeholder. |
| **Intelligence** | Deterministic insights (visa expiry, FX drops, anomalous spend, frequent routes, carbon footprint, predictive leave-for-airport). |
| **Voice** | Regex-based intent parser ("trip 3", "remind me to pack at 7pm", "book a hotel in Tokyo for next Friday"). |
| **Services** | Hotels, rides, food, activities, transport, e-sim, insurance, exchange — all driven by deterministic engines. |

GlobeID is **deterministic-first**: no LLM, no cloud AI. Every "smart" feature is a pure-function transform over local + cached data.

---

## 2. Design Principles

1. **Determinism over magic.** No third-party AI calls at runtime. The "AI" in this app is a set of named pure modules (`smartSuggestions.ts`, `connectionDetector.ts`, `predictiveDeparture.ts`, …).
2. **Web parity with native.** Every Capacitor plugin is wrapped by `lib/nativeBridge.ts` with a web fallback so the PWA never crashes when a plugin is unavailable.
3. **State is local-first.** Zustand stores persist to `localStorage` under the `globeid:` namespace; the server is a *replica*, not the source of truth, until the user signs in.
4. **Pure modules are king.** Anything that can be a pure function lives in `src/lib/` and has unit tests. Components only render and dispatch.
5. **Reduced motion is a first-class citizen.** Every animation site checks `prefers-reduced-motion` (or the in-app override) before running.
6. **No deps for what we can write in 100 lines.** `confetti.ts`, `VirtualList.tsx`, `sheetSnap.ts`, etc. are zero-dep micro-libs.
7. **Type safety end to end.** `tsc --noEmit` is part of CI; Drizzle types reach the client via shared DTO shapes.
8. **Observability without telemetry SaaS.** A built-in audit log + sync timeline + event bus give the user introspection without sending data off-device.

---

## 3. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                       Capacitor / PWA Shell                        │
├─────────────────────────────────────────────────────────────────────┤
│                React + TypeScript + Vite Frontend                  │
│ ┌──────────────────┬─────────────────┬───────────────────────────┐  │
│ │  Screens (25)    │  Components     │  Cinematic / 3D (R3F)    │  │
│ ├──────────────────┴─────────────────┴───────────────────────────┤  │
│ │   Zustand Stores (21)    React Query Cache    EventBus         │  │
│ ├────────────────────────────────────────────────────────────────┤  │
│ │  lib/ — 75 pure modules (HMAC, MRZ, OCR, currency, packing,    │  │
│ │  visa, lounges, ground transport, weather, insights, voice,    │  │
│ │  achievements, transitions, sheet snap, star catalog, …)       │  │
│ ├────────────────────────────────────────────────────────────────┤  │
│ │  services/  notificationService.ts  paymentGateway.ts          │  │
│ ├────────────────────────────────────────────────────────────────┤  │
│ │  Native Bridge ← Capacitor plugins (camera, biometrics, share, │  │
│ │  haptics, notifications, geolocation, network, status, …)      │  │
│ └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ HTTPS JSON (Authorization: Bearer …)
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│   Hono REST API on Node      ──   Zod schema validation             │
│   ├── auth/  (demo HMAC token issuer)                               │
│   ├── routes/  (25 routers, see §16)                                │
│   └── lib/  (cache, geo, fraud, insights, intelligence, score, …)   │
├─────────────────────────────────────────────────────────────────────┤
│   Drizzle ORM ── better-sqlite3 ── globeid.db                       │
│   Tables: users, travel_records, planned_trips, wallet_balances,    │
│   wallet_transactions, wallet_state, alerts, copilot_messages,      │
│   emergency_contacts, loyalty_transactions, budget_caps             │
└─────────────────────────────────────────────────────────────────────┘
```

External services (all keyless or public domain):

- **Open-Meteo** — weather forecast (no key).
- **Unsplash** — destination hero images (URL-only).
- **NASA Visible Earth** — Earth diffuse / clouds / night-lights (public domain).
- **Airline-logo CDN** — IATA → SVG logo with offline fallback.

---

## 4. Frontend — Repository Layout

```
src/
├── App.tsx                        Root: routing, hydration chain, deep-links, shortcuts
├── main.tsx                       Boot: applyThemePrefs + SW register
│
├── screens/                       25 route-level views (§5)
│   ├── Home.tsx
│   ├── Identity.tsx, IdentityVault.tsx, LockScreen.tsx
│   ├── Wallet.tsx, MultiCurrency.tsx
│   ├── Travel.tsx, TravelTimeline.tsx, TravelIntelligence.tsx
│   ├── TripDetail.tsx, TripPlanner.tsx
│   ├── DocumentVault.tsx, EntryReceipt.tsx
│   ├── Onboarding.tsx, Profile.tsx, UserProfile.tsx
│   ├── HybridScanner.tsx, KioskSimulator.tsx
│   ├── GlobalMap.tsx, Explore.tsx, PlanetExplorer.tsx
│   ├── SocialFeed.tsx, SocialFeedV2.tsx
│   ├── ServicesHub.tsx, SuperServicesHub.tsx, AnalyticsDashboard.tsx
│   └── services/  (Hotels, Rides, Food, Activities, Transport)
│
├── components/                    Domain + design-system widgets (§6)
│   ├── ai/                        AIAssistantSheet, TravelCopilot, VoicePrompt
│   ├── analytics/                 CategoryHeatmap
│   ├── animations/                LottieView, animation index
│   ├── dashboard/                 ProfileCard, QuickActions, TravelStats, …
│   ├── explorer/                  DestinationCard, DiscoveryFeed, ExplorerHUD
│   ├── identity/                  IdentityScoreCard, PassportScanner, QRDisplay
│   ├── intelligence/              IntelligenceHUD, PredictiveNextTripCard
│   ├── layout/                    AppChrome (legacy + v2), BottomNav, FAB, OfflineBanner, SyncBadge, PageTransition, Splash
│   │   └── v2/                    AppChromeV2, CommandPalette, BottomNav v2
│   ├── map/                       Globe, FlightArcs, AirportMarkers, Atmosphere, Starfield, …
│   ├── maps/                      MiniMap (2D leaflet)
│   ├── payments/                  QRPayment, QRScanner
│   ├── services/                  ServiceCard, BudgetPanel, RidesPanel, …
│   ├── settings/                  AccentPicker, AppearanceSettings
│   ├── simulation/                Simulation HUD, SpeedControl
│   ├── social/                    PostCard, CreatePost, StoriesBar, Notifications
│   ├── system/                    EmptyState, ErrorBoundary, PullToRefresh, Coachmark, EdgeSwipeBack, NativeBackButton
│   ├── travel/                    TripCard, TripLifecycleBadge, FlightStatusCard
│   ├── trip/                      ItineraryView, TripGlobePreview, TripNotes, RouteBuilder
│   ├── ui/                        shadcn/Radix primitives (button, sheet, etc.) + Globe-specific (LazyImage, VirtualList)
│   ├── voice/                     VoiceCommandButton
│   └── wallet/                    PassDetail, PassStack, CurrencyCard, TransactionList
│
├── store/                         21 Zustand stores (§7)
├── hooks/                         18 hooks (§8)
├── lib/                           75 pure modules (§9)
├── services/                      Stateful service singletons (§10)
├── cinematic/                     Atmospheric layers, particle field, motion engine (§11)
├── motion/                        motionConfig.ts (canonical token bag)
├── core/                          Cross-cutting "engines"
├── i18n/                          i18next bootstrap + en/hi locales
├── styles/                        global CSS (Phase 7 vars, animation rules)
├── utils/                         haptics utilities
└── test/                          53 vitest test files (§23)
```

---

## 5. Screens (Routes)

Every screen below is a React function component. All but `Home` are React.lazy-loaded so the initial bundle stays small.

| Path | Screen | Role | Key dependencies |
|---|---|---|---|
| `/` | `Home.tsx` | Dashboard with smart suggestions, trip preview, quick actions | `insightsStore`, `recommendationsStore`, `useScrollTint`, `Suggestions` |
| `/identity` | `Identity.tsx` | Identity score + tier badge + score-factor drawer | `scoreStore`, `IdentityScoreCard`, `ScoreFactorDrawer`, `IdentityScoreSparkline` |
| `/wallet` | `Wallet.tsx` | Pass stack + multi-currency cards + transactions | `walletStore`, `userStore`, `PassStack`, `CurrencyCard`, `TransactionList` |
| `/travel` | `Travel.tsx` | Past/upcoming trips browser | `userStore`, `lifecycleStore`, `TripCard` |
| `/services` | `ServicesHub.tsx` | All travel-services entry point | `serviceFavorites`, `ServiceCard`, panels |
| `/services/super` | `SuperServicesHub.tsx` | Power-user services hub with full panel set | All `*Panel.tsx` components |
| `/services/hotels` | `services/HotelBooking.tsx` | Affiliate-link hotel discovery | `HotelsPanel`, `serviceEngine` |
| `/services/rides` | `services/RideBooking.tsx` | Ride-hail deep-link picker | `groundTransport.ts`, `RidesPanel` |
| `/services/food` | `services/FoodDiscovery.tsx` | Food discovery | `FoodPanel`, `LocalServicesPanel` |
| `/services/activities` | `services/Activities.tsx` | Activity finder | `serviceEngine`, `LocalServicesPanel` |
| `/services/transport` | `services/Transport.tsx` | Surface + rail/transit | `groundTransport`, `LocalServicesPanel` |
| `/map` | `GlobalMap.tsx` | 3D globe with arcs, terminator, atmosphere | R3F + `components/map/*` |
| `/explore` | `Explore.tsx` | Destination discovery feed | `explorerData.ts`, `DestinationCard`, `DiscoveryFeed` |
| `/explorer` | `PlanetExplorer.tsx` | Globe-only deep-dive view | `Globe`, `Starfield`, `Atmosphere` |
| `/social` | `SocialFeed.tsx` | Legacy social feed | `socialStore` |
| `/feed` | `SocialFeedV2.tsx` | IndexedDB-backed feed v2 | `userFeedStore`, `socialDB` |
| `/profile` | `Profile.tsx` | Current-user profile + settings | `userStore`, `AppearanceSettings` |
| `/profile/:userId` | `UserProfile.tsx` | Public profile view | `socialStore`, `userStore` |
| `/lock` | `LockScreen.tsx` | Biometric phase machine | `biometricAuth.ts`, `useVaultAutoLock`, `useEdgeSwipeBack` |
| `/onboarding` | `Onboarding.tsx` | First-run carousel + permission prompts | `onboarding.ts`, `applyThemePrefs` |
| `/scan` | `HybridScanner.tsx` | Camera + MRZ + QR hybrid scanner | `mobile_scanner` analogue, `mrzParser`, `qrEncoder` |
| `/passport-book` | `IdentityVault.tsx` | Encrypted document vault | `documentVault`, `vaultAuditStore`, `useVaultAutoLock` |
| `/vault` | `DocumentVault.tsx` | Tag-filtered vault browser | `documentVault`, drag-reorder via `@dnd-kit` |
| `/timeline` | `TravelTimeline.tsx` | Animated chronological timeline | `travelTimeline.ts`, `cinematic/` |
| `/intelligence` | `TravelIntelligence.tsx` | AI nudges hub | `insightsStore`, `IntelligenceHUD` |
| `/trip/:tripId` | `TripDetail.tsx` | Full trip dossier (weather, packing, lounges, transport, notes) | All `lib/` enrichment modules + `Tiptap` |
| `/planner` | `TripPlanner.tsx` | Multi-leg planner with drag-to-reorder | `tripPlannerStore`, `@dnd-kit/sortable` |
| `/copilot` | `TravelCopilot.tsx` (component) | Streaming Q&A chat | `copilotStore`, `apiClient` |
| `/kiosk-sim` | `KioskSimulator.tsx` | Boarding-pass HMAC verification | `boardingPass.ts`, `qrEncoder`, `audioCues` |
| `/receipt` | `EntryReceipt.tsx` | Border-entry receipt | `BorderEntrySimulation` |
| `/multi-currency` | `MultiCurrency.tsx` | Currency portfolio + best-route convert | `currencyEngine`, `walletStore` |
| `/analytics` | `AnalyticsDashboard.tsx` | recharts dashboard | `analytics.ts`, `CategoryHeatmap` |

`*` → `/` (catch-all redirect).

### 5.1 First-run gating

`FirstRunGate` (defined in `App.tsx`) reads `localStorage["globeid:onboarded"]` and force-redirects to `/onboarding` if absent. Allow-listed paths: `/onboarding`, `/lock`.

### 5.2 Lazy-load + suspense

- `Home` is **eager** (instant first paint).
- All other 24 screens are `React.lazy(...)`; wrapped in `<Suspense fallback={<RouteSkeleton />}>` and `<RouteErrorBoundary>`.
- Lazy chunks resolve from same-origin (no CDN) so on Capacitor they read off the local APK assets.

---

## 6. Components

### 6.1 Design-system primitives — `src/components/ui/`

shadcn/Radix-based:

`accordion`, `alert`, `alert-dialog`, `aspect-ratio`, `avatar`, `badge`, `breadcrumb`, `button`, `calendar`, `card`, `carousel`, `chart`, `checkbox`, `collapsible`, `command`, `context-menu`, `dialog`, `drawer`, `dropdown-menu`, `form`, `hover-card`, `input`, `input-otp`, `label`, `menubar`, `navigation-menu`, `pagination`, `popover`, `progress`, `radio-group`, `resizable`, `scroll-area`, `select`, `separator`, `sheet`, `sidebar`, `skeleton`, `slider`, `sonner`, `switch`, `table`, `tabs`, `textarea`, `toast`, `toaster`, `toggle`, `toggle-group`, `tooltip`.

Custom-built primitives sit alongside:

- `AnimatedNumber.tsx` — easing-tween a numeric value (used for wallet balance, identity score, trip count).
- `CinematicLoader.tsx` — branded full-screen loader.
- `GlassCard.tsx`, `UltraGlass.tsx` — glassmorphism wrappers (toggleable for reduce-transparency mode).
- `IdentityScore.tsx` — circular score gauge.
- `InitialsAvatar.tsx` — fallback avatar from initials.
- `KeyboardShortcuts.tsx` — global hotkeys component (Cmd-K palette, /vault, etc.).
- `LazyImage.tsx` — native lazy-load + LQIP placeholder + onError fallback.
- `Skeleton.tsx`, `SkeletonLoader.tsx` — multi-line skeleton blocks.
- `VirtualList.tsx` — minimal fixed-height windowing.

### 6.2 Feature components

| Domain | Files | Purpose |
|---|---|---|
| `ai/` | `AIAssistantButton`, `AIAssistantSheet`, `TravelAssistant`, `TravelCopilot`, `TripPlanCard`, `VoicePrompt` | Floating AI sheet + voice prompt + plan cards. |
| `analytics/` | `CategoryHeatmap` | visx hex heatmap for category × time. |
| `animations/` | `LottieView`, `index` | Wrapper for `lottie-react` plus shared registry. |
| `dashboard/` | `CarbonFootprintChart`, `ProfileCard`, `QuickActions`, `Suggestions`, `TravelAlerts`, `TravelStats`, `UpcomingTrips` | Home-screen tiles. |
| `explorer/` | `DestinationCard`, `DestinationStory`, `DiscoveryAchievements`, `DiscoveryFeed`, `ExplorerHUD`, `CultureHighlights`, `PopularityIndicator` | Explore-screen UI. |
| `identity/` | 15 components incl. `BorderEntrySimulation`, `CredentialCard`, `DigitalPassport`, `DocExpiryChip`, `EntryStamp`, `IdentityScoreCard`, `IdentityScoreSparkline`, `IdentityTimeline`, `LiveCameraScanner`, `PassportBook`, `PassportScanner`, `QRDisplay`, `ScoreFactorDrawer`, `SecurityStatus`, `SessionStatus`, `VerificationFlow`, `WelcomeOverlay` | Identity score, vault, scanner, gauges, sparkline. |
| `intelligence/` | `AutomationFlagList`, `ContextBanner`, `DestinationCard`, `IntelligenceHUD`, `PredictiveNextTripCard`, `TravelTrends` | AI nudge surfaces. |
| `layout/` | `AnimatedPage`, `FAB`, `OfflineBanner`, `SyncBadge`, plus `v2/AppChrome`, `v2/BottomNav`, `v2/CommandPalette`, `v2/PageTransition`, `v2/Splash`, `v2/use-command-palette` | App chrome + nav + FAB. |
| `map/` | 23 components incl. `Globe`, `GlobeScene`, `FlightArcs`, `AirportMarkers`, `AirTrafficLayer`, `CinematicCamera`, `GlobalFlightFlows`, `GlobalHeatmap`, `IdentityMapLayer`, `LandmarkMarkers`, `Map2DView`, `MapControls`, `PassengerNetwork`, `PassengerParticles`, `RegionalDensity`, `RouteInsights`, `RouteNetwork`, `RoutePlayback`, `Starfield`, `TravelParticles`, `TravelStreams`, `UserLocation`, `DestinationMarkers`, `ExplorerPaths` | The R3F globe + every layer. |
| `maps/` | `MiniMap` | Leaflet 2D (Trip detail). |
| `payments/` | `QRPayment`, `QRScanner` | Payment QR flows. |
| `services/` | 16 panels (Budget, Esim, Exchange, Food, Fraud, Hotels, Insurance, IntelligencePanel, LocalServicesPanel, Loyalty, Rides, Safety, ScorePanel, ServiceCard, VisaPanel, WeatherPanel) | Each services-hub tile. |
| `settings/` | `AccentPicker`, `AppearanceSettings` | Theme picker + density toggle. |
| `simulation/` | `ContinentTraffic`, `SimulationHUD`, `SpeedControl`, `TravelTimeline` | Globe simulation overlays. |
| `social/` | `CreatePost`, `Notifications`, `PostCard`, `StoriesBar` | Social-feed UI. |
| `system/` | `Coachmark`, `EdgeSwipeBack`, `EmptyState`, `ErrorBoundary`, `LazyMount`, `NativeBackButton`, `PullToRefresh`, `RouteErrorBoundary` | Cross-cutting infra components. |
| `travel/` | `CountryInsights`, `FlightStatusCard`, `TripCard`, `TripLifecycleBadge`, `TripLifecycleCard` | Trip browsing UI. |
| `trip/` | `DestinationPicker`, `ItineraryDay`, `ItineraryView`, `QRBoardingPass`, `RouteBuilder`, `TripGlobePreview`, `TripIntelSection`, `TripNotes`, `TripNotesEditor`, `TripProgressBar`, `TripSummary` | Trip-detail subviews. |
| `voice/` | `VoiceCommandButton` | Floating mic button. |
| `wallet/` | `CurrencyCard`, `CurrencyConverter`, `DocumentCard`, `PassDetail`, `PassStack`, `SpendingAnalytics`, `TransactionList` | Wallet UI. |

---

## 7. State Management — Zustand Stores

All 21 stores live in `src/store/`. Persisted stores write to `localStorage` under the `globeid:<storeName>` key with `createJSONStorage(() => localStorage)`.

| Store | File | Persist? | Shape (canonical) | Responsibility |
|---|---|---|---|---|
| `useUserStore` | `userStore.ts` | yes | `{ profile, documents: TravelDocument[], travelHistory: TravelRecord[], pinned: string[] }` | User profile + document inventory + flight history. |
| `useWalletStore` | `walletStore.ts` | yes | `{ balances, transactions, passes, syncStatus }` | Multi-currency wallet + boarding-pass list. Debounced server sync. |
| `useLifecycleStore` | `lifecycleStore.ts` | yes | `{ trips, activeTripId, status }` | Trip lifecycle (planning → active → past). |
| `useTripPlannerStore` | `tripPlannerStore.ts` | yes | `{ trips: PlannedTrip[], pendingMutations[] }` | Multi-leg planner + offline mutation queue. |
| `useTripNotesStore` | `tripNotesStore.ts` | yes | `{ notesByTripId: Record<string, JSONContent> }` | Per-trip Tiptap rich-text notes. |
| `useInsightsStore` | `insightsStore.ts` | no | `{ insights, status, lastFetched }` | Server-driven AI nudges. React-Query-friendly. |
| `useAlertsStore` | `alertsStore.ts` | yes | `{ alerts, syncStatus, mutations }` | Travel alerts + read/dismissed state. |
| `useRecommendationsStore` | `recommendationsStore.ts` | yes | `{ recs, status, lastFetched }` | Personalised recs (destinations, services). |
| `useSafetyStore` | `safetyStore.ts` | yes | `{ contacts: EmergencyContact[], suspiciousFlags[] }` | Emergency contacts + impossible-travel detector. |
| `useScoreStore` | `scoreStore.ts` | yes | `{ score, factors, history }` | Identity score (Tier 0–3). |
| `useSocialStore` | `socialStore.ts` | yes | `{ users, posts, comments, follows }` | Social-feed v1 in-memory store. |
| `useUserFeedStore` | `userFeedStore.ts` | yes (idb) | `{ posts, mutations }` | Social-feed v2 (IndexedDB-backed via `socialDB`). |
| `useBudgetStore` | `budgetStore.ts` | yes | `{ caps, byScope }` | Budget caps per (user, scope). |
| `useContextStore` | `contextStore.ts` | no | `{ context, status }` | Live context (current city, time-zone, weather). |
| `useCopilotStore` | `copilotStore.ts` | yes | `{ messages, syncStatus, pending }` | Copilot conversation log. |
| `useFraudStore` | `fraudStore.ts` | yes | `{ flags, lastChecked }` | Fraud + suspicious-spend detector. |
| `useLoyaltyStore` | `loyaltyStore.ts` | yes | `{ balances, ledger }` | Loyalty earn/redeem ledger. |
| `useServiceFavoritesStore` | `serviceFavorites.ts` | yes | `{ favorites: string[] }` | Pinned service tiles. |
| `useVaultAuditStore` | `vaultAuditStore.ts` | yes | `{ events: AuditEvent[] }` | Append-only audit log (max 100). |
| `useWeatherStore` | `weatherStore.ts` | no (TTL 15 min) | `{ byCity, lastFetched }` | TTL-cached Open-Meteo fetches. |
| `useCommandPaletteStore` | `commandPaletteStore.ts` | yes | `{ recents: string[] }` | Last 5 invoked commands. |

### 7.1 Store conventions

- **Action naming**: `set<Thing>`, `add<Thing>`, `remove<Thing>`, `clear`, `hydrate`, `sync`.
- **Sync status enum**: `"idle" \| "loading" \| "synced" \| "offline-pending" \| "error"`.
- **Pending mutations**: stored alongside the canonical state; replayed on next successful sync.
- **Reset**: `lib/signOut.ts` calls each store's `clear()` on sign-out.

### 7.2 Key store excerpts

`commandPaletteStore.ts` (representative pattern):

```ts
export const useCommandPaletteStore = create<CommandPaletteState>()(
  persist(
    (set) => ({
      recents: [],
      push: (id) => set((s) => {
        const next = [id, ...s.recents.filter((r) => r !== id)];
        if (next.length > MAX_RECENT) next.length = MAX_RECENT;
        return { recents: next };
      }),
      clear: () => set({ recents: [] }),
    }),
    { name: "globeid:commandPalette", storage: createJSONStorage(() => localStorage) },
  ),
);
```

---

## 8. Hooks

| Hook | File | Purpose |
|---|---|---|
| `useAI` | `useAI.ts` | Convenience wrapper that exposes Copilot + intent helpers. |
| `useDeviceTilt` | `useDeviceTilt.ts` | Subscribes to `deviceorientation`; returns clamped β/γ for parallax. |
| `useMobileDetect` / `use-mobile` | `useMobileDetect.ts`, `use-mobile.tsx` | Viewport-width based detection (≤768 px). |
| `useMotion` | `useMotion.ts` | Resolves the active spring preset from `surfaceSprings`. |
| `usePermissions` | `usePermissions.ts` | Centralised permission acquisition (camera, mic, geolocation, notifications). |
| `usePullToRefresh` | `usePullToRefresh.ts` | Touch-gesture state machine for the `PullToRefresh` wrapper. |
| `useReducedEffects` | `useReducedEffects.ts` | Boolean — reduce particle counts, disable bloom, etc. |
| `useReducedMotionMatch` | `useReducedMotionMatch.ts` | Mirrors `prefers-reduced-motion` + the in-app override. |
| `useScrollTint` | `useScrollTint.ts` | rAF-throttled scroll progress → CSS hue offset. |
| `useTravelContext` | `useTravelContext.ts` | Pulls current trip leg + city from `lifecycleStore` + `contextStore`. |
| `useVaultAutoLock` | `useVaultAutoLock.ts` | Idle 5 min + background 30 s → navigate `/lock`. |
| `useVerificationSession` | `useVerificationSession.ts` | Manages a multi-step ID verification flow. |
| `useVisibleClock` | `useVisibleClock.ts` | rAF clock that pauses when the page is hidden. |
| `useVoiceCommands` | `useVoiceCommands.ts` | Wires the speech-recognition plugin → `voiceIntents.parseIntent`. |
| `useVoiceControl` | `useVoiceControl.ts` | Higher-level voice control surface (start/stop/listen). |
| `useWeatherForecast` | `useWeatherForecast.ts` | TTL-cached Open-Meteo wrapper. |
| `use-toast` | `use-toast.ts` | shadcn toast bus. |

---

## 9. `lib/` — Pure Modules

75 modules. Each is a tested, side-effect-free unit (where possible). Below: name → purpose → notes.

### 9.1 Domain primitives

| Module | Purpose | Notes |
|---|---|---|
| `airports.ts` | IATA → `{ code, name, city, country, lat, lng }` | Const map; ~600 entries. |
| `airlineBrand.ts` | Deterministic gradient + tone from IATA | Used for boarding-pass theming. |
| `boardingPass.ts` | HMAC-SHA256 sign + verify of pass payloads | WebCrypto-based. |
| `mrzParser.ts` | TD3 / TD2 / TD1 MRZ parser | Pure, RegExp-driven. |
| `mrzToDocument.ts` | Maps parsed MRZ → `TravelDocument` shape | |
| `qrEncoder.ts` | Encodes a JSON payload as a QR data URL | wraps `qrcode`. |
| `currencyEngine.ts` | FX conversion + history snapshot | Optional remote rate refresh. |
| `documentExpiry.ts` | Days until doc expires + tier | |
| `documentVault.ts` | Encrypt/decrypt vault entries via WebCrypto AES-GCM | Master key derived from biometric session. |
| `auditLog.ts` | Append-only event helpers | Used by `vaultAuditStore`. |
| `biometricAuth.ts` | Capacitor wrapper + FSM | (idle → prompting → verified). |
| `secureClipboard.ts` | Copy + auto-clear after 30 s | |

### 9.2 Travel intelligence

| Module | Purpose |
|---|---|
| `achievements.ts` | Threshold ladder for trips/scans/countries/continents + `diffAchievements` |
| `connectionDetector.ts` | IATA MCT thresholds → `tight` / `missed` flags |
| `predictiveDeparture.ts` | Leave-time computer (commute + buffer + traffic factor) |
| `travelHeatmap.ts` | 5° lat/lng buckets with normalised intensity |
| `cameraPresets.ts` | Globe camera targets (home / next-trip / tracker) + haversine + great-circle midpoint |
| `travelInsights.ts` | Spend anomaly, frequent-route, travel-pattern detector |
| `travelPrediction.ts` | Predicts next trip from history |
| `travelSuggestions.ts` | Surface-aware suggestion picker |
| `tripIntel.ts` | Aggregates per-trip intel (visa, packing, lounges) |
| `tripGenerator.ts` | Deterministic seed trips (demo/onboarding) |
| `tripLifecycle.ts` | State machine (planning → active → past) |
| `smartSuggestions.ts` | Home-screen nudges (visa expiry, FX drop, etc.) |
| `passOrdering.ts` | Auto-pin pass within 24 h of departure |
| `weatherForecast.ts` | Open-Meteo HTTP client + 7-day model |
| `visaEngine.ts`, `visaRequirements.ts` | Citizen → destination visa lookup |
| `groundTransport.ts` | 9 ride providers, country-mapped |
| `loungeAccess.ts` | 14 lounges × 12 hub airports |
| `packingList.ts` | Climate + activity + precip aware list |
| `destinationAnalytics.ts` | Country/destination metrics |
| `distanceEngine.ts` | Haversine + bearing + step segments |
| `locationEngine.ts` | Geolocation wrapper + city resolver |
| `countries.ts`, `countryThemes.ts` | ISO 3166 metadata + per-country accent |
| `sunPosition.ts` | Sub-solar lat/lng for terminator |
| `starCatalog.ts` | 30 nav-grade stars, equatorial→Cartesian |
| `travelTimeline.ts` | Buckets + lays out animated timeline |

### 9.3 UI / motion / theming

| Module | Purpose |
|---|---|
| `motion-tokens.ts` | Canonical motion tokens (durations, easings) |
| `transitions.ts` | 7 page-transition presets + 5 surface-spring presets |
| `sheetSnap.ts` | Velocity-aware bottom-sheet snap selector |
| `themePrefs.ts` | Theme prefs persisted to localStorage + `applyThemePrefs` |
| `themeAccents.ts` | 8 brand accents (HSL triads) |
| `confetti.ts` | Tiny canvas confetti burst |
| `iconMap.ts` | Domain → lucide icon map |

### 9.4 OCR / camera

| Module | Purpose |
|---|---|
| `ocrService.ts` | Tesseract.js wrapper + worker mode |
| `ocrPreprocess.ts` | Greyscale + contrast bump for MRZ |
| `imageEdge.ts` | Sobel filter for edge overlay |
| `imageVariance.ts` | Steady-frame detector for auto-capture |
| `cameraCapture.ts` | Camera plugin wrapper + permissions |

### 9.5 Notifications + scheduling

| Module | Purpose |
|---|---|
| `notificationChannels.ts` | Channel taxonomy (boarding/delays/digests/marketing) |
| `countdown.ts` | rAF-driven countdown hook |
| `relativeDate.ts` | "in 3 days" / "2 hours ago" formatter |

### 9.6 Voice

| Module | Purpose |
|---|---|
| `voiceIntents.ts` | Regex grammar; `parseIntent`, `suggestIntents` |

### 9.7 Sync / data

| Module | Purpose |
|---|---|
| `apiClient.ts` | `fetch` wrapper with auth header injection |
| `syncEngine.ts` | Pull/push reconciliation orchestrator |
| `eventBus.ts` | Tiny pub-sub for cross-store events |
| `tokenService.ts` | Demo token storage + refresh stub |
| `socialDB.ts` | Dexie schema for social v2 |
| `signOut.ts` | Wipe all stores + clear notifications |

### 9.8 Misc / infra

| Module | Purpose |
|---|---|
| `analytics.ts` | Local-only event collector (no telemetry SaaS) |
| `audioCues.ts`, `audioFeedback.ts` | Tone.js cues for scan / verify |
| `confetti.ts` | (see UI) |
| `demoData.ts`, `demoServices.ts` | Seed datasets for first launch |
| `explorerData.ts` | Destination catalog |
| `ics.ts` | ICS calendar export |
| `nativeBridge.ts` | Capacitor abstraction (see §13) |
| `onboarding.ts` | First-run helpers |
| `receiptRenderer.ts` | Lazy-loaded jspdf renderer |
| `shareSheet.ts` | Capacitor Share wrapper |
| `verificationSession.ts` | ID verification session FSM |
| `identityTier.ts` | Tier 0/1/2/3 mapping by score + factors |
| `utils.ts` | `cn`, `clsx`, etc. |

---

## 10. Services Layer (Frontend)

`src/services/`:

- **`notificationService.ts`** — wraps `@capacitor/local-notifications`. Functions:
  - `ensurePermission()`
  - `scheduleBoardingAlarm(legId, departureIso)`
  - `scheduleLeaveForAirport(legId, departureIso, { commuteMinutes, buffer })`
  - `scheduleDailyDigest({ hour, minute })`
  - `scheduleSnooze(notifId, minutesAhead)`
  - `cancelLeg(legId)`, `cancelAll()`
  - Quiet-hours filter (23:00–07:00 user-local).

- **`paymentGateway.ts`** — mock payment processor (Stripe-like adapter).

`src/screens/services/` — service screens (Hotels, Rides, Food, Activities, Transport).

`src/core/` — long-lived engines:

| File | Purpose |
|---|---|
| `contextEngine.ts` | Builds the live context object (city, weather, time-zone). |
| `contextBackgroundLoop.ts` | Polls context every 5 min. |
| `notificationsEngine.ts` | Cron-like scheduler over `notificationService`. |
| `scheduledJobs.ts` | Daily digest + nightly expiry check. |
| `serviceEngine.ts` | Service catalog + ranking. |
| `travelEngine.ts` | Cross-store derivations (next-flight, recent-trip). |
| `useIntelligence.ts` | Hook entry point bundling AI nudges. |

---

## 11. Cinematic, Motion & Theming

### 11.1 Cinematic layers — `src/cinematic/`

- `AtmosphereLayer.tsx` — Fresnel + Rayleigh scattering shell around globe.
- `DepthParallax.tsx` — multi-layer parallax for hero sections.
- `IconMotion.tsx` — animated icon reveal.
- `ParticleField.tsx` — drei `<Sparkles />` wrapper with reduced-motion gate.
- `ScrollCinematics.ts` — scroll-driven choreography helpers.
- `UILighting.tsx` — accent-aware lighting tokens.
- `cinematicColors.ts` — palette ramps.
- `motionEngine.ts`, `motionOrchestrator.ts` — coordinator that serialises route-enter / FAB-collapse / banner-show into a single timeline.
- `uiSound.ts` — Tone.js cue registry.

### 11.2 Motion presets — `src/lib/transitions.ts`

```ts
export const surfaceSprings = {
  navigate: { type: "spring", stiffness: 320, damping: 32, mass: 0.6 },
  modal:    { type: "spring", stiffness: 280, damping: 28, mass: 0.7 },
  sheet:    { type: "spring", stiffness: 360, damping: 38, mass: 0.5 },
  fab:      { type: "spring", stiffness: 420, damping: 28, mass: 0.4 },
  toast:    { type: "spring", stiffness: 380, damping: 30, mass: 0.5 },
} as const;

export type TransitionPresetId =
  | "slide-up" | "slide-right" | "slide-left"
  | "fade" | "scale-from-anchor" | "rise" | "drop";
```

Reduced-motion fallback substitutes opacity-only variants.

### 11.3 Theme — `src/lib/themePrefs.ts` + `themeAccents.ts`

CSS vars on `<html>`:

- `--p7-brand` (HSL accent triple)
- `--p7-scroll-tint` (scroll-driven hue offset, deg)
- `--p7-surface-1`..`--p7-surface-5`
- `--p7-foreground`, `--p7-background`, `--p7-muted`, `--p7-border`, `--p7-warning`, `--p7-success`, `--p7-destructive`
- `--p7-radius-sm/md/lg`
- `--p7-density` (compact / comfortable / spacious)

HTML data attrs: `data-theme="atmosphere|paper"`, `data-density`, `data-high-contrast`, `data-reduce-transparency`, `data-auto-theme`.

`applyThemePrefs()` runs in `main.tsx` before React mounts to prevent FOUC.

### 11.4 Tailwind + design tokens — `tailwind.config.ts`

- Reads CSS vars (`hsl(var(--primary))`) for every colour family.
- Container centred, 2xl breakpoint at 1400 px.
- `tailwind-merge` + `class-variance-authority` for variant composition.
- `tailwindcss-animate` for keyframe utilities.

---

## 12. Internationalisation (i18n)

- `src/i18n/i18n.ts` — i18next bootstrap with `i18next-browser-languagedetector`.
- `src/i18n/locales/en.json` — English (canonical).
- `src/i18n/locales/hi.json` — Hindi.
- Used via `useTranslation()` in components. Default fallback: `en`.

---

## 13. Native Bridge & Capacitor Plugins

### 13.1 `src/lib/nativeBridge.ts`

Single file fronts every native call. Functions (selected):

- `applyNativeChrome()` — sets `<StatusBar>` style, locks orientation.
- `wireAppStateListener()` — subscribes to `App.addListener("appStateChange")`. Re-hydrates stores on foreground.
- `wireNetworkListener()` — toggles `OfflineBanner`.
- `wireUrlOpenListener()` — handles `globeid://...` deep links.
- `deepLinkToPath(url)` — pure URL → router path.
- `share({ title, text, url })` — Capacitor Share with `navigator.share` fallback.
- `vibrate(pattern)` — Haptics feedback (`selection`, `success`, `error`, `medium`, `heavy`, `light`).
- `pickPhoto()` — Camera plugin, web fallback to `<input type=file accept=image>`.
- `getCurrentPosition()` — Geolocation with timeout.
- `setBrightness(value)` / `restoreBrightness()` — screen-brightness plugin.
- `secureFlag(set)` — Android `setSecureFlag` for screenshot block (PassDetail).
- `notify(args)` — local notification.
- `requestNotificationPermission()`.
- `requestBiometric()` — biometric phase machine entry.

Every call has a web fallback (no-op or DOM-equivalent) so the PWA build works.

### 13.2 Plugins enumerated

| Plugin | Use site |
|---|---|
| `@capacitor/app` | `App.addListener("appStateChange" / "appUrlOpen")` |
| `@capacitor/camera` | `cameraCapture.ts`, `HybridScanner.tsx` |
| `@capacitor/filesystem` | `receiptRenderer.ts` |
| `@capacitor/geolocation` | `locationEngine.ts`, `useTravelContext` |
| `@capacitor/haptics` | every interactive surface; `nativeBridge.vibrate` |
| `@capacitor/local-notifications` | `notificationService.ts` |
| `@capacitor/network` | `OfflineBanner.tsx` |
| `@capacitor/preferences` | `tokenService.ts` (key store) |
| `@capacitor/share` | `shareSheet.ts` |
| `@capacitor/splash-screen` | branded splash on cold boot |
| `@capacitor/status-bar` | `applyNativeChrome` |
| `@aparajita/capacitor-biometric-auth` | `biometricAuth.ts`, `LockScreen.tsx`, `useVaultAutoLock` |
| `@capacitor-community/speech-recognition` | `useVoiceCommands` |

---

## 14. Backend — Hono + SQLite + Drizzle

### 14.1 Boot sequence (`server/src/index.ts`)

1. Hono app + CORS (allowlisted origins from `ALLOWED_ORIGIN`).
2. Hono `logger()` middleware.
3. Mount `api` sub-app at `/api/v1`.
4. `api.get("/health")` returns `{ status: "ok", uptime }`.
5. `api.post("/auth/demo")` returns demo HMAC token bound to `DEMO_USER_ID`.
6. Mount 25 routers (`/user`, `/trips`, `/insights`, …). See §16.
7. `seedIfEmpty()` populates DB on first launch.
8. `serve({ fetch: app.fetch, port })`.

### 14.2 Auth (`server/src/auth/`)

Demo only:

- `token.ts` — `issueToken(userId)` returns HMAC-signed envelope `<userId>.<sig>`. `verifyToken(token)` validates against `AUTH_SECRET`.
- No magic link, no SSO, no JWT lifecycle. Real auth is BACKLOG item Q179.

### 14.3 Server libraries (`server/src/lib/`)

| File | Purpose |
|---|---|
| `validate.ts` | `ok(c, body)`, `bad(c, msg)` JSON helpers + Zod parse-and-throw. |
| `cache.ts` | TTL in-memory cache. |
| `geo.ts` | Country / IATA helpers. |
| `flightStatus.ts` | Mock flight-status producer. |
| `fraud.ts` | Anomaly detector helpers. |
| `insights.ts` | Server-side insight derivation. |
| `intelligence.ts` | Combined deterministic recs. |
| `lifecycle.ts` | Trip lifecycle state machine. |
| `loyalty.ts` | Earn/redeem ledger maths. |
| `score.ts` | Score factor computation. |
| `weather.ts` | Open-Meteo proxy + cache. |

---

## 15. Database Schema

SQLite via `better-sqlite3`. Schema mirrored in `server/src/db/schema.ts` (Drizzle) **and** as raw DDL applied on boot.

### 15.1 Tables

#### `users`
- `id` TEXT PK
- `email` TEXT UNIQUE NOT NULL
- `full_name` TEXT NOT NULL
- `nationality` TEXT NOT NULL
- `passport_no` TEXT NULL
- `date_of_birth` TEXT NULL
- `created_at` INTEGER NOT NULL

#### `travel_records`
- `id` TEXT PK
- `user_id` TEXT FK→users
- `from_iata`, `to_iata`, `date`, `airline`, `duration` TEXT NOT NULL
- `type` TEXT CHECK (`upcoming` | `past` | `current`)
- `flight_number` TEXT NULL
- `source` TEXT CHECK (`history` | `planner`)
- `trip_id` TEXT NULL
- `created_at` INTEGER NOT NULL
- Indexes: `(user_id)`, `(trip_id)`

#### `planned_trips`
- `id` TEXT PK
- `user_id` FK→users
- `name` TEXT
- `theme` TEXT CHECK (`vacation`|`business`|`backpacking`|`world_tour`)
- `destinations` TEXT (JSON-encoded)
- `created_at` INTEGER

#### `wallet_balances`
- composite PK `(user_id, currency)`
- `amount`, `rate` REAL
- `flag` TEXT (emoji)

#### `wallet_transactions`
- `id` PK
- `user_id` FK
- `currency`, `amount`, `kind` (`credit`|`debit`), `description`, `date`, `created_at`
- `idempotency_key` (unique per user)
- `tx_type` (`payment`|`send`|`receive`|`convert`|`refund`)
- `merchant`, `category`, `country`, `country_flag`, `icon`, `reference`
- Indexes: `(user_id, created_at DESC)`; UNIQUE `(user_id, idempotency_key)`

#### `wallet_state`
- `user_id` PK
- `active_country`, `default_currency`

#### `alerts`
- `id`, `user_id`
- `category`, `title`, `message`
- `severity` (`low`|`medium`|`high`)
- `source` (`seed`|`system`)
- `signature` (idempotent dedup key)
- `created_at`, `read_at`, `dismissed`
- Index: UNIQUE `(user_id, signature)` partial

#### `copilot_messages`
- `id`, `user_id`
- `role` (`user`|`assistant`)
- `content`, `created_at`

#### `emergency_contacts`
- `id`, `user_id`
- `name`, `relationship`, `phone_e164`, `email`
- `is_primary`, `created_at`

#### `loyalty_transactions`
- `id`, `user_id`
- `points` (negative = redemption)
- `kind` (`wallet_payment`|`trip_completion`|`signup_bonus`|`redemption`|`adjustment`)
- `description`, `reference`, `idempotency_key`, `created_at`

#### `budget_caps`
- composite PK `(user_id, scope)`
- `cap_amount`, `currency`, `alert_threshold`, `period`
- `updated_at`

### 15.2 Migration strategy

- Initial DDL is applied verbatim on boot via `seed.ts` (no migrations dir yet).
- Future migrations will live in `server/drizzle/` under `drizzle-kit`.

---

## 16. API Surface

Mounted at `/api/v1`.

| Route | Method | Purpose | DTO |
|---|---|---|---|
| `/health` | GET | Liveness | `{ status: "ok", uptime: number }` |
| `/auth/demo` | POST | Issue demo token | `{ token, userId }` |
| `/user` | GET, PATCH | Profile read/update | `User` |
| `/trips` | GET, POST, PATCH, DELETE | Travel-record CRUD | `TravelRecord[]` |
| `/insights` | GET | Server-derived nudges | `Insight[]` |
| `/recommendations` | GET | Personalised recs | `Rec[]` |
| `/alerts` | GET, POST, PATCH | Alerts CRUD | `Alert[]` |
| `/copilot` | GET, POST | Conversation history + send | `CopilotMessage[]` |
| `/planner/trips` | GET, POST, PATCH, DELETE | Multi-leg planner CRUD | `PlannedTrip[]` |
| `/context` | GET | Live context (city, time-zone, weather) | `Context` |
| `/lifecycle` | GET, POST | Trip lifecycle transitions | `LifecycleEvent[]` |
| `/wallet` | GET, POST, PATCH | Balances + tx ledger | `WalletState` |
| `/loyalty` | GET, POST | Loyalty ledger | `LoyaltyEvent[]` |
| `/safety` | GET, POST, DELETE | Emergency contacts + safety flags | `EmergencyContact[]` |
| `/score` | GET | Identity score + factors | `Score` |
| `/weather` | GET | Open-Meteo proxy | `Forecast` |
| `/budget` | GET, PUT | Budget caps + projected spend | `BudgetCap[]` |
| `/fraud` | GET | Suspicious-spend flags | `FraudFlag[]` |
| `/exchange` | GET | FX rates | `Rates` |
| `/visa` | GET | Citizen → destination requirements | `Requirement` |
| `/insurance` | GET | Insurance recs | `InsuranceQuote[]` |
| `/esim` | GET | eSIM marketplace | `EsimPlan[]` |
| `/hotels` | GET | Hotels (affiliate) | `HotelOption[]` |
| `/food` | GET | Food + restaurants | `FoodOption[]` |
| `/rides` | GET | Ride-hail providers + deep-links | `RideProvider[]` |
| `/local` | GET | Local services | `LocalService[]` |

All routes:
- Authenticate via `Authorization: Bearer <token>` (demo HMAC).
- Validate request body/query with Zod schemas defined in the router.
- Return `{ ok: true, data }` or `{ ok: false, error }` envelopes via `lib/validate.ts:ok/bad`.

---

## 17. Routing & Deep Links

### 17.1 `react-router-dom@6.30`

Router tree (rendered in `App.tsx`):

```
<BrowserRouter>
  <KeyboardShortcuts />
  <NativeBackButton />
  <EdgeSwipeBack />
  <Routes>
    <Route path="/lock" element={<LockScreen />} />
    <Route path="/onboarding" element={<Onboarding />} />
    <Route path="/__v2" element={<Phase7Showcase />} />
    <Route element={<AppChromeV2 />}>
      <RouteErrorBoundary>
        <Suspense fallback={<RouteSkeleton />}>
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/identity" element={<Identity />} />
            ...                                          (see §5)
          </Routes>
        </Suspense>
      </RouteErrorBoundary>
    </Route>
  </Routes>
</BrowserRouter>
```

### 17.2 Deep links

`globeid://` scheme. Handled by `wireUrlOpenListener` → `deepLinkToPath`:

| URI | Maps to |
|---|---|
| `globeid://home` | `/` |
| `globeid://trip/<id>` | `/trip/<id>` |
| `globeid://pass/<code>` | `/wallet?pass=<code>` |
| `globeid://scan` | `/scan` |
| `globeid://lock` | `/lock` |
| `globeid://identity` | `/identity` |

---

## 18. Hydration & Sync Sequences

### 18.1 Cold boot

```
main.tsx
   ↓
applyThemePrefs()                    sets CSS vars synchronously
   ↓
SW.register() (browser only)         skipped on Capacitor
   ↓
<App /> mounts
   ↓
useUserStore.persist hydrates from localStorage
   ↓
applyNativeChrome()                  status-bar tint + orientation
   ↓
wireAppStateListener / wireNetworkListener / wireUrlOpenListener
   ↓
FirstRunGate                         redirect to /onboarding if not done
   ↓
Route renders → screens fetch via React Query
```

### 18.2 Foreground re-hydrate

```
App.addListener("appStateChange") → isActive=true
   ↓
nativeBridge.wireAppStateListener
   ↓
each store with .hydrate() pulled fresh:
  alerts, insights, recs, copilot, context, lifecycle, wallet
   ↓
syncEngine.run() drains pendingMutations queue
```

### 18.3 Wallet pass save

```
HybridScanner OCR → mrzToDocument → user accepts
   ↓
walletStore.addPass(payload)
   ↓
boardingPass.sign(payload, hmacKey)
   ↓
QR encoded + persisted
   ↓
notificationService.scheduleBoardingAlarm(legId, depIso)
   ↓
notificationService.scheduleLeaveForAirport(legId, depIso, { commute })
   ↓
optimistic UI; pendingMutations queued
   ↓
syncEngine pushes to /wallet endpoint
```

### 18.4 Sign-out

```
signOut()
   ├── userStore.clear()
   ├── walletStore.clear()
   ├── lifecycleStore.clear()
   ├── tripPlannerStore.clear()
   ├── notificationService.cancelAll()
   ├── tokenService.revoke()
   ├── localStorage delete globeid:* keys (selective)
   ↓
navigate("/onboarding", replace)
```

---

## 19. Boarding-Pass Cryptography

`src/lib/boardingPass.ts`.

- HMAC-SHA256 over canonical-string of pass payload (`subtle.crypto.sign("HMAC", key, data)`).
- Issuer secret currently a build-time const (`AUTH_SECRET`); future: KMS-backed rotation (BACKLOG item Q179).
- QR encodes a `bp://<base64url-payload>.<base64url-sig>` URI.
- Verifier (`KioskSimulator.tsx`) parses → recomputes HMAC → compares signatures with constant-time check (`subtle.crypto.verify`).

```
sign(payload):
  const data = canonicalize(payload)             # JSON.stringify with sorted keys
  const sig  = HMAC-SHA256(secret, data)         # WebCrypto subtle
  return `${b64u(payload)}.${b64u(sig)}`
verify(token):
  const [p, s] = token.split(".")
  const ok = HMAC.verify(secret, b64u_decode(p), b64u_decode(s))
  return ok ? JSON.parse(p) : null
```

---

## 20. Security Model

| Concern | Mitigation |
|---|---|
| Vault data at rest | WebCrypto AES-GCM; key derived from biometric session. |
| Vault unauthorised access | Auto-lock after 5 min idle / 30 s background; biometric phase machine. |
| Vault audit trail | `vaultAuditStore` immutable append-only log (max 100 events). |
| Pass forgery | HMAC-SHA256 on every boarding-pass payload. |
| Clipboard leakage | `secureClipboard.copy()` clears after 30 s. |
| Screenshot leakage | Android `setSecureFlag` on PassDetail. |
| Suspicious travel pattern | `travelInsights` impossible-travel detector → re-auth prompt. |
| API token | Demo HMAC token in `Authorization: Bearer …`. |
| Idempotency on writes | `idempotency_key` UNIQUE indexes on `wallet_transactions`, `loyalty_transactions`, `alerts.signature`. |
| CORS | Allow-listed via `ALLOWED_ORIGIN` env var. |

`docs/THREAT_MODEL.md` contains the STRIDE table.

---

## 21. Performance Model

### 21.1 Front-end budgets

| Metric | Target | Method |
|---|---|---|
| First Contentful Paint | < 1.5 s | eager Home, lazy everything else |
| Largest Contentful Paint | < 2.5 s | LQIP via `LazyImage`, font-display: swap |
| Total JS (initial chunk) | < 350 KB gzip | route-level `lazy()`, `jspdf` lazy-loaded |
| Frame budget | 16.6 ms mobile, 8.3 ms 120 Hz | rAF-throttled scroll, useDeferredValue audit |
| Globe FPS | 60+ on mid-tier | `dpr={[1,2]}` adaptive, instanced markers, reduced-effects gate |

### 21.2 Concrete optimisations (already shipped)

- `FlightArcs` route-list memoised (`useMemo` keyed on routes hash).
- `jspdf` import via dynamic `import()` inside `receiptRenderer.ts`.
- `LazyImage` native `loading="lazy"` + `decoding="async"` + LQIP placeholder.
- `VirtualList` zero-dep windowing; rAF scroll throttle.
- `useScrollTint` rAF throttle + 0.01 progress tolerance.
- `useReducedEffects` reduces particle counts on low-end devices.
- Workbox precache strategy: `globIgnores: ["**/textures/earth-clouds*"]` plus runtime `CacheFirst` for NASA layers.
- Service worker: only registered in browser builds (Capacitor sets `VITE_NATIVE_BUILD=true`).

### 21.3 Long-tail (BACKLOG)

- Web Workers for OCR (Tesseract worker mode).
- Wasm SIMD for arc/curve generation.
- React 19 compiler / `useDeferredValue` audit.
- WebGPU path via R3F 9.

---

## 22. Build, PWA, Capacitor & Vite Configs

### 22.1 `vite.config.ts`

- React plugin (`@vitejs/plugin-react-swc`).
- VitePWA plugin:
  - `registerType: "autoUpdate"`
  - `globPatterns: ["**/*.{js,css,html,ico,png,svg,woff2}"]`
  - `globIgnores: ["**/textures/earth-clouds*"]`
  - Runtime caching for NASA/Earth textures (CacheFirst, 30-day expiration).
- Server: host `::`, port `8080`, HMR overlay disabled.
- Production guard: warn loudly if `VITE_API_BASE_URL` is unset.

### 22.2 `capacitor.config.ts`

```ts
{
  appId: 'com.terracore.globeid',
  appName: 'GlobeID',
  webDir: 'dist',
}
```

### 22.3 `eslint.config.js`

- `js.configs.recommended` + `tseslint.configs.recommended`.
- `react-hooks` + `react-refresh` plugins.
- `react-refresh/only-export-components: warn { allowConstantExport: true }`.
- `@typescript-eslint/no-unused-vars: off` (TS already covers).

### 22.4 `tailwind.config.ts`

- darkMode: `"class"`.
- Colors all driven by CSS vars (`hsl(var(--primary))`, etc.).
- Container centred, `2xl` at 1400 px.
- Plugins: `tailwindcss-animate`, `@tailwindcss/typography`.

### 22.5 `package.json` scripts

| Script | Command |
|---|---|
| `dev` | `vite` |
| `dev:server` | `npm --workspace globeid-server run dev` |
| `dev:all` | `npm-run-all -p dev:server dev` |
| `build` | `vite build` |
| `build:dev` | `vite build --mode development` |
| `build:server` | `npm --workspace globeid-server run build` |
| `lint` | `eslint .` |
| `preview` | `vite preview` |
| `test` | `vitest run` |
| `test:watch` | `vitest` |
| `typecheck` | `tsc --noEmit && npm --workspace globeid-server run typecheck` |
| `prepare` | `husky` |

### 22.6 PWA manifest — `public/manifest.json`

- Display: standalone
- Icons: 192, 512, maskable
- Background: #0b0e1a (Atmosphere theme)
- Theme: derived from Phase-7 `--p7-brand`

---

## 23. Testing Strategy

53 vitest test files. **316/316 tests passing** as of the most recent merged PR.

### 23.1 Coverage matrix

| Layer | Test surface |
|---|---|
| Pure modules (`lib/`) | `airlineBrand`, `boardingPass`, `mrzParser`, `mrzToDocument`, `currencyEngine`, `documentExpiry`, `documentVault`, `relativeDate`, `voiceIntents`, `travelInsights`, `travelHeatmap`, `cameraPresets`, `connectionDetector`, `predictiveDeparture`, `sheetSnap`, `starCatalog`, `achievements`, `confetti`, `audioFeedback`, `themePrefs`, `themeAccents`, `groundTransport`, `loungeAccess`, `packingList`, `visaRequirements`, `passOrdering`, `secureClipboard`, `signOut`, `auditLog`, `identityTier`, `analytics`, `transitions`, `tripGenerator`, `tripIntel`, `tripLifecycle`, `notificationChannels`, … |
| Stores | `walletStore` (sync + idempotency), `lifecycleStore`, `tripPlannerStore` (offline queue), `vaultAuditStore`, `commandPaletteStore` |
| Components | `AnimatedNumber`, `LazyImage`, `VirtualList`, `EmptyState`, `PullToRefresh`, `IdentityScoreCard`, `QRDisplay`, `PassportScanner` |
| Hooks | `useScrollTint`, `useVaultAutoLock`, `useReducedMotionMatch`, `useDeviceTilt`, `usePullToRefresh`, `useVoiceCommands` |
| Integration | `airlineBrand`-from-pass, `documentVault` end-to-end encrypt/decrypt, `boardingPass` sign/verify roundtrip, `KioskSimulator` flow |

### 23.2 Test environment

- `jsdom`
- `@testing-library/react@16` + `@testing-library/jest-dom`
- `fake-indexeddb` for IndexedDB tests
- Custom global mocks: `crypto.subtle` (Node WebCrypto), `matchMedia`, `IntersectionObserver`, `ResizeObserver`.

### 23.3 Convention

- One test file per module: `src/test/<module>.test.ts`.
- Tests mirror module surface; group by `describe(module name)`, then `it(behaviour)`.
- Pure modules require ≥ 5 tests (happy + edge + clamp + invariant).
- Stores tested via `act()` + spies on `setItem` / `getItem`.

---

## 24. CI / CD

(Workflow files: `.github/workflows/`.)

| Workflow | Trigger | Steps |
|---|---|---|
| `lint-test.yml` | push, PR | `npm ci` → `npm run lint` → `npm run test` → `npm run typecheck` |
| `android-apk.yml` | PR | `npm ci` → `npx cap sync android` → `./gradlew assembleDebug` → upload APK artifact |
| `release.yml` | tag `v*` | bump version → build APK + web → GitHub Release |

Future (BACKLOG section T):

- Lighthouse CI per PR
- Playwright visual + e2e
- Cache `~/.npm` and `node_modules` keyed on lockfile hash
- Renovate + stale-PR cleanup

---

## 25. Telemetry & Observability

- `lib/analytics.ts` collects events to a local ring buffer. No SaaS by default.
- `lib/eventBus.ts` provides cross-store pub/sub for surfaces like `SyncBadge`.
- Sync history accessible via `Profile → Sync timeline` (last 20 events).
- Server logs via Hono's `logger()` middleware → stdout.

---

## 26. Error Boundaries & Resilience

- `RouteErrorBoundary` wraps every routed surface; renders a recoverable state with "Retry" CTA.
- `ErrorBoundary` is a generic primitive used inside heavy components (Globe, Scanner) to keep crashes localised.
- React Query: `retry: 2`, `staleTime: 30s` defaults; per-query overrides.
- `OfflineBanner` exposes a "Retry sync" affordance backed by `syncEngine.run()`.
- `SyncBadge` shows per-store status: `synced`, `pending`, `offline`, `error`.

---

## 27. Asset Pipeline

- `public/textures/` — NASA Earth diffuse + clouds + night-lights (~6 MB).
- `public/icons/` — PWA icon set.
- `src/assets/lottie/` — JSON Lottie animations (success-check, etc.).
- `@fontsource-variable/inter` + `@fontsource-variable/jetbrains-mono` self-hosted fonts.
- Lucide icons tree-shaken.

---

## 28. Audio Cues & Haptics

- `lib/audioCues.ts` — Tone.js polyphonic synth; named cues (`scan-start`, `scan-success`, `scan-fail`, `verify-success`, `verify-fail`).
- `lib/audioFeedback.ts` — wraps cues with a global mute toggle.
- `utils/haptics.ts` — typed haptic patterns (`tap`, `select`, `success`, `warn`, `error`).
- Every interactive surface (long-press, swipe action, confirm) calls `haptics.medium()` or stronger.

---

## 29. Voice Pipeline

```
useVoiceCommands → @capacitor-community/speech-recognition
                 → onTranscript → voiceIntents.parseIntent
                 → if unknown: voiceIntents.suggestIntents (3 best)
                 → dispatch: navigate / action / query / search /
                             numeric / translate / remind / compose
```

Wake-word strip: regex `^(hey|okay) (globe|globeid|guide)\b`.

Grammar:
- `navigate`: "go to wallet", "open identity", "show home"
- `action`: "scan", "book hotel", "verify"
- `query`: "what's my next flight", "current time in Tokyo"
- `search`: "find a hotel", "find a ride"
- `numeric`: "trip 3", "pass 2", "document 5"
- `translate`: "translate this to french" (12-lang code map)
- `remind`: "remind me to pack at 7pm" (HH:MM with am/pm)
- `compose`: "book a hotel in tokyo for next friday"

---

## 30. Globe / 3D Pipeline

```
<Canvas dpr={[1,2]} adaptive>
  <Lights />
  <EarthMesh>
    <Diffuse /> <Specular /> <NightLights />
  </EarthMesh>
  <CloudsLayer />        ← independent rotation
  <Atmosphere />         ← Fresnel + Rayleigh shader
  <Terminator />         ← driven by sunPosition.ts (UTC now)
  <Stars />              ← projectStars(starCatalog) + drei <Stars />
  <Sparkles />           ← drei
  <FlightArcs>
    <Arc />              ← cubic Bezier on the sphere
    <Plane>              ← sprite traversal along arc
      <Contrail />       ← tapering trail
    </Plane>
  </FlightArcs>
  <AirportMarkers />     ← instanced meshes (10k friendly)
  <UserLocation />
  <PostProcessing>       ← Bloom + Vignette + ChromaticAberration
</Canvas>
```

Camera presets via `lib/cameraPresets.ts`:

- `homeView()` — centred over user's home airport, zoom 3.
- `nextTripView(origin, destination)` — great-circle midpoint, zoom by haversine distance bands (< 800 km → z=2, < 4000 → 3, < 9000 → 4, else 5).
- `flightTrackerView(current)` — tight z=1.5 over the live position.

`useReducedEffects` switches Bloom off, halves star count, drops particle field on low-end / battery saver.

---

## 31. Notification Pipeline

- Each leg has up to 3 scheduled notifications: boarding alarm, leave-for-airport, daily digest.
- `notificationChannels.ts` taxonomy: `boarding`, `delays`, `digests`, `marketing`.
- Quiet hours filter (23:00–07:00 user-local).
- Snooze: `1h`, `3h`, `morning`.
- All schedule operations are idempotent by `legId` (re-running upserts).
- Cancel-on-delete: `lifecycleStore.delete(tripId)` calls `notificationService.cancelLeg` for every leg.

---

## 32. Offline / Sync Pipeline

- `pendingMutations` queues live in `walletStore`, `tripPlannerStore`, `alertsStore`.
- On app foreground OR network online, `syncEngine.run()` drains queues:
  1. Replay each mutation against the server endpoint.
  2. Merge server response back into store.
  3. Clear successful mutations; mark failures with `retryAfter`.
- Conflict policy: last-write-wins by `created_at` (server-side `idempotency_key` uniqueness avoids dupes).
- Future (BACKLOG N 158): persist queue to IndexedDB via `dexie`/`idb`.

---

## 33. Extension Points

Where to add a new feature without rewriting:

| Feature category | Add it here |
|---|---|
| New voice intent | `lib/voiceIntents.ts` `RULES` array. Add a regex + `build` function. |
| New page transition | `lib/transitions.ts` `motionPresets` map. |
| New surface spring | `lib/transitions.ts` `surfaceSprings`. |
| New camera preset | `lib/cameraPresets.ts` (export a new builder). |
| New deterministic insight | `lib/travelInsights.ts` (export a new producer). |
| New service tile | `components/services/<NewPanel>.tsx` + register in `ServicesHub`. |
| New API endpoint | `server/src/routes/<route>.ts` + mount in `server/src/index.ts`. |
| New persisted store | `src/store/<feature>Store.ts` with `name: "globeid:<feature>"`. |
| New notification | `services/notificationService.ts` (`schedule<X>`). |
| New design-system primitive | `components/ui/<thing>.tsx`; register tokens in `tailwind.config.ts`. |
| New theme accent | `lib/themeAccents.ts` (HSL triple). |
| New language pack | `src/i18n/locales/<code>.json`. |
| New native plugin | `lib/nativeBridge.ts` (add wrapper + web fallback) + install plugin. |

---

## 34. Glossary

| Term | Definition |
|---|---|
| Phase 7 | Current design system (fluid type, motion tokens, `--p7-*` CSS vars) |
| Atmosphere / Paper | Dark / Light theme identifiers |
| Slice (A, B, …, G) | Internal sprint slices in the codebase commit history |
| Hydration chain | Tiered re-hydrate of stores on cold start + foreground |
| HMAC pass | Boarding-pass payload signed with HMAC-SHA256 |
| MRZ | Machine-readable zone on a passport (TD1/TD2/TD3) |
| MCT | Minimum connection time (IATA) |
| LQIP | Low-quality image placeholder |
| FSM | Finite state machine (e.g. biometric phase machine) |
| DPR | Device pixel ratio |
| TravelRecord | Canonical data shape for flights across UI modules |
| Vault audit | Append-only immutable event log of vault accesses |
| `globeid:` | localStorage key namespace |
| Surface spring | Per-surface motion spring config (navigate/modal/sheet/fab/toast) |
| Deterministic-first | Project rule: no LLM/cloud-AI at runtime; all "intelligence" is pure |

---

## Appendix A — Authoritative File Manifest

The following is a fully-enumerated snapshot of the **frontend** at the time of writing (excluding `node_modules`, `dist`, `android/`):

- `src/App.tsx`, `src/main.tsx`, `src/index.css`
- 25 files in `src/screens/` (+ 5 in `src/screens/services/`)
- 21 files in `src/store/`
- 18 files in `src/hooks/`
- 75 files in `src/lib/`
- 2 files in `src/services/` (notificationService, paymentGateway)
- 9 files in `src/cinematic/`
- 1 file in `src/motion/`
- 6 files in `src/core/`
- 2 files in `src/i18n/locales/` + bootstrap
- 53 test files in `src/test/`
- ~150 components across `src/components/<domain>/`

Backend:

- `server/src/index.ts`
- 25 routers in `server/src/routes/`
- `server/src/db/{client,schema,seed}.ts`
- 11 helper files in `server/src/lib/`
- `server/src/auth/token.ts`

Configs:

- `package.json`, `package-lock.json`, `server/package.json`
- `vite.config.ts`, `tailwind.config.ts`, `postcss.config.js`
- `eslint.config.js`, `tsconfig*.json`
- `capacitor.config.ts`, `android/`
- `.env.production.example`
- `.husky/`, `.lintstagedrc`

Docs:

- `README.md`
- `BACKLOG.md`
- `FLUTTER_HANDOFF.md`
- `ARCHITECTURE.md` (this file)
- `docs/THREAT_MODEL.md`
- `docs/MOBILE_UX.md`
- `docs/DESIGN_TOKENS.md`
- `docs/PHASE_7.md`

---

## Appendix B — Data-flow Diagrams (text)

### B.1 Trip-detail render path

```
TripDetail.tsx
  ├── lifecycleStore.find(tripId)       (Zustand)
  ├── tripIntel.build(trip)             (lib pure)
  │     ├── visaRequirements.lookup
  │     ├── packingList.generate
  │     ├── loungeAccess.findByAirport
  │     ├── groundTransport.matchByCountry
  │     ├── weatherForecast.fetch         (TTL cache)
  │     ├── connectionDetector.detect
  │     └── predictiveDeparture.predict
  ├── tripNotesStore.notesByTripId      (Tiptap content)
  └── render
       ├── TripSummary
       ├── ItineraryView
       ├── TripIntelSection
       │     ├── Weather card
       │     ├── Visa card
       │     ├── Packing checklist
       │     ├── Lounges list
       │     ├── Ground transport list
       │     ├── Tight-connection warnings
       │     └── Leave-for-airport prediction
       ├── MiniMap (leaflet)
       ├── TripGlobePreview (R3F)
       └── TripNotesEditor (Tiptap)
```

### B.2 Pass scan + add path

```
HybridScanner.tsx
  ├── usePermissions("camera")
  ├── @capacitor/camera or web getUserMedia
  ├── ocrPreprocess.greyscale(frame)
  ├── ocrService.recognise(frame)
  ├── mrzParser.parse(text)
  ├── mrzToDocument.convert(parsed)
  ├── show preview → user accepts
  ├── walletStore.addPass({...})
  ├── boardingPass.sign(payload)        (HMAC-SHA256)
  ├── qrEncoder.encode(token)
  ├── notificationService.scheduleBoardingAlarm
  ├── notificationService.scheduleLeaveForAirport
  ├── vaultAuditStore.push("scan-success")
  └── navigate("/wallet?pass=<id>")
```

### B.3 Voice intent path

```
VoiceCommandButton click
  ├── @capacitor-community/speech-recognition.start()
  ├── onTranscript(text)
  ├── voiceIntents.parseIntent(stripWakeWord(text))
  │     ├── if known → dispatch:
  │     │     navigate / action / search / numeric / translate / remind / compose
  │     └── if unknown → voiceIntents.suggestIntents(text)
  └── show suggestion sheet
```

---

## Appendix C — Default Theme Tokens

```
:root[data-theme="atmosphere"] {
  --p7-brand: 252 95% 65%;
  --p7-background: 230 30% 6%;
  --p7-foreground: 0 0% 98%;
  --p7-muted: 240 10% 15%;
  --p7-border: 240 10% 22%;
  --p7-success: 142 71% 45%;
  --p7-warning: 38  92% 50%;
  --p7-destructive: 0 84% 60%;
  --p7-radius-sm: 0.5rem;
  --p7-radius-md: 0.75rem;
  --p7-radius-lg: 1rem;
  --p7-density: 1; /* 0=compact, 1=comfortable, 2=spacious */
}

:root[data-theme="paper"] { /* light counterpart */ }
:root[data-high-contrast="true"] { /* AA+ palette */ }
:root[data-reduce-transparency="true"] { /* solid surfaces */ }
```

---

## Appendix D — `globeid:` localStorage namespace

| Key | Owner |
|---|---|
| `globeid:onboarded` | first-run gate |
| `globeid:themePrefs` | `themePrefs.ts` |
| `globeid:user` | `userStore` |
| `globeid:wallet` | `walletStore` |
| `globeid:lifecycle` | `lifecycleStore` |
| `globeid:tripPlanner` | `tripPlannerStore` |
| `globeid:tripNotes` | `tripNotesStore` |
| `globeid:alerts` | `alertsStore` |
| `globeid:recommendations` | `recommendationsStore` |
| `globeid:safety` | `safetyStore` |
| `globeid:score` | `scoreStore` |
| `globeid:social` | `socialStore` |
| `globeid:userFeed` | `userFeedStore` |
| `globeid:budget` | `budgetStore` |
| `globeid:copilot` | `copilotStore` |
| `globeid:fraud` | `fraudStore` |
| `globeid:loyalty` | `loyaltyStore` |
| `globeid:serviceFavorites` | `serviceFavorites` |
| `globeid:vaultAudit` | `vaultAuditStore` |
| `globeid:commandPalette` | `commandPaletteStore` |

---

## Appendix E — Per-screen Cognitive-Load Budget

Goal: ≤ 3 primary actions per surface (Apple HIG / Material 3 alignment).

| Screen | Primary actions | Secondary |
|---|---|---|
| Home | 1) Open AI sheet 2) Add trip 3) Scan | Smart suggestions, quick actions, upcoming trips |
| Wallet | 1) Add pass 2) Send 3) Convert | Pass detail, transactions, currency cards |
| Identity | 1) View score 2) Open vault 3) Improve score | Sparkline, audit |
| Travel | 1) Plan trip 2) Open trip 3) View timeline | Trip cards, lifecycle badges |
| Trip detail | 1) Add to wallet 2) Notes 3) Share | Weather, packing, lounges, transport |
| Scanner | 1) Capture 2) Manual entry 3) Cancel | Edge overlay, MRZ preview |
| Lock | 1) Authenticate | (no secondaries) |

---

## Appendix F — Cross-store derivations

These cross-cut multiple stores via `core/travelEngine.ts` / `useTravelContext`:

| Derivation | Inputs |
|---|---|
| `nextLeg` | userStore.travelHistory + lifecycleStore.activeTripId |
| `currentCity` | contextStore.location + countries.lookup |
| `walletBalanceInDefaultCurrency` | walletStore.balances + currencyEngine.convert |
| `homeView` camera target | userStore.homeIata → airports.lookup → cameraPresets.homeView |
| `tightConnectionFlags` | lifecycleStore.activeTripId → connectionDetector.detect |

---

## Appendix G — Error Taxonomy

| Code | Where raised | Recovery |
|---|---|---|
| `NETWORK_OFFLINE` | apiClient | queue mutation, show OfflineBanner |
| `AUTH_INVALID_TOKEN` | server middleware | redirect to /lock |
| `BIOMETRIC_NOT_AVAILABLE` | biometricAuth | show fallback PIN/passphrase prompt |
| `CAMERA_PERMISSION_DENIED` | cameraCapture | show settings deep-link |
| `MRZ_PARSE_FAILED` | mrzParser | retry capture or manual entry |
| `HMAC_VERIFY_FAILED` | KioskSimulator | reject pass, audit log entry |
| `VAULT_DECRYPT_FAILED` | documentVault | force re-auth |
| `SYNC_CONFLICT` | syncEngine | server timestamp wins; local marked `error` |

---

## Appendix H — Future Targets (high level only — see BACKLOG.md for the 250-item list)

1. Real authentication: Lucia / better-auth + magic link or SSO.
2. WebSocket push for flight status + sync invalidation.
3. Postgres adapter parity layer (Drizzle supports it; switchable).
4. Background-sync with `workbox-background-sync` + IndexedDB queue.
5. Multi-traveller mode (family / group identity vault).
6. AR boarding-pass scan, NFC passport read, Live Activities.
7. Stripe Issuing virtual cards.
8. eSIM provisioning.
9. Translator overlay (camera + on-device translation).
10. Lighthouse-CI + Playwright e2e + bundle-budget enforcement.

---

## Appendix I — Full Production Dependency Map

Sourced from `package.json` (versions truncated to majors for readability; lockfile is canonical).

### I.1 Runtime — UI

| Package | Version | Role |
|---|---|---|
| `react` / `react-dom` | 18.3 | UI runtime |
| `react-router-dom` | 6.30 | Routing |
| `framer-motion` | 11 | Spring + tween animations |
| `motion` | 12.38 | New unified Motion lib (used in v2 layout) |
| `gsap` | 3.15 | Heavy timelines + cinematic chains |
| `lottie-react` | 2.4 | Lottie player |
| `@rive-app/react-canvas` | 4.28 | Reserved for future Rive controllers |
| `tinykeys` | 3.0 | Cmd-K shortcut binding |
| `cmdk` | 1.1 | Command palette UI |
| `vaul` | 0.9 | Bottom sheet primitive |
| `@use-gesture/react` | 10.3 | Drag/pinch gestures |
| `embla-carousel-react` | 8.6 | Onboarding carousel |
| `next-themes` | 0.3 | Initial theme bootstrap (replaced by `themePrefs`) |

### I.2 Runtime — Design system

| Package | Role |
|---|---|
| `@radix-ui/react-*` (32 packages) | Headless primitives |
| `lucide-react` 0.462 | Iconography |
| `class-variance-authority` 0.7 | Variant composition |
| `clsx` + `tailwind-merge` | Class composition |
| `tailwindcss` 3.4 + `tailwindcss-animate` | Styling |
| `@tailwindcss/typography` | `prose` class |
| `culori` | OKLCH / HSL conversions for accent picker |
| `sonner` | Toast lib (alt to shadcn toaster) |

### I.3 Runtime — 3D / Visualisation

| Package | Role |
|---|---|
| `three` 0.160 | 3D engine |
| `@react-three/fiber` 8.18 | React renderer for Three |
| `@react-three/drei` 9.122 | R3F helpers (Stars, Sparkles, Html, …) |
| `@react-three/postprocessing` 2.19 | Bloom / Vignette / Chromatic Aberration |
| `postprocessing` 6.34 | Underlying postprocessing engine |
| `recharts` 2.15 | 2D charts (analytics dashboard) |
| `@visx/heatmap` + `@visx/scale` + `@visx/group` + `@visx/text` + `@visx/tooltip` | Custom heatmaps |
| `leaflet` + `react-leaflet` | Mini 2D map for Trip detail |

### I.4 Runtime — Data + state

| Package | Role |
|---|---|
| `zustand` 4.5 | Store engine |
| `@tanstack/react-query` 5.83 | Server-state cache |
| `@tanstack/react-virtual` 3.13 | Virtualisation (alt to in-house `VirtualList`) |
| `dexie` 4.4 + `idb` 8.0 | IndexedDB |
| `yjs` + `y-indexeddb` | CRDT scaffold (TripNotes → multi-traveller in future) |
| `react-hook-form` + `@hookform/resolvers` + `zod` | Form layer |

### I.5 Runtime — Travel-domain

| Package | Role |
|---|---|
| `tesseract.js` 7.0 | OCR (passport / receipt) |
| `@mediapipe/tasks-vision` | Reserved for future face/liveness detection |
| `@zxing/browser` + `@zxing/library` | QR / barcode |
| `qrcode` | QR generation |
| `jspdf` 4.2 | Receipt + dossier export (lazy-loaded) |
| `tone` 15.1 | Audio cue engine |
| `date-fns` 3.6 | Time/date formatting |
| `i18next` + `react-i18next` + `i18next-browser-languagedetector` | i18n |

### I.6 Runtime — Native / Capacitor

See §13.2 — full plugin list.

### I.7 Runtime — Editor

| Package | Role |
|---|---|
| `@tiptap/react` 3.22 + `@tiptap/pm` + `@tiptap/starter-kit` | Trip notes rich-text editor |
| `@dnd-kit/core` + `@dnd-kit/sortable` + `@dnd-kit/utilities` | Drag-to-reorder (planner, vault) |

### I.8 Build + DX

| Package | Role |
|---|---|
| `vite` 5.4 + `@vitejs/plugin-react-swc` 3.11 | Dev server + builder |
| `vite-plugin-pwa` 1.2 | Service worker + manifest |
| `typescript` 5.8 | Type checker |
| `eslint` 9.32 + `typescript-eslint` 8.38 + `eslint-plugin-react-hooks` + `eslint-plugin-react-refresh` | Linting |
| `vitest` 3.2 + `jsdom` 20 + `fake-indexeddb` + `@testing-library/react` 16 + `@testing-library/jest-dom` | Tests |
| `husky` 9 + `lint-staged` 16 | Git hooks |
| `npm-run-all` | Parallel scripts |

### I.9 Backend (`server/package.json`)

| Package | Role |
|---|---|
| `hono` | HTTP framework |
| `@hono/node-server` | Node adapter |
| `drizzle-orm` | ORM |
| `better-sqlite3` | Engine |
| `zod` | Validation |
| `tsx` | Dev runtime |
| `vitest` | Tests |

---

## Appendix J — Component Responsibilities (Top 30 by impact)

Each entry: name → responsibility → key dependencies → render gotchas.

1. **`Home.tsx`** — dashboard. Pulls `insightsStore`, `recommendationsStore`, `useScrollTint`. *Gotcha*: must remain eager (initial paint).
2. **`AppChromeV2`** — top-level shell. Renders status bar gradient, bottom nav, FAB, offline banner, sync badge. *Gotcha*: subscribes to `wireNetworkListener` once.
3. **`BottomNav`** — 5-tab nav. Matches active route via `useLocation`. *Gotcha*: uses `viewTransition` API on supported browsers.
4. **`FAB`** — primary action floater. Behaves as a radial menu when expanded. *Gotcha*: collapses on route change via `motionOrchestrator`.
5. **`PassDetail`** — pass card with parallax tilt + dim brightness on enter / restore on exit. *Gotcha*: subscribes to `useDeviceTilt`.
6. **`PassStack`** — paginated trip-wallet group. *Gotcha*: auto-pins pass within 24h via `passOrdering.ts`.
7. **`Globe`** — R3F canvas. *Gotcha*: lazy-mount via `IntersectionObserver`; `dpr={[1,2]}` adaptive.
8. **`FlightArcs`** — `useMemo`-keyed cubic bezier producer. *Gotcha*: stable-hash routes before generating.
9. **`AirportMarkers`** — instanced meshes. *Gotcha*: 10k+ markers must be instanced.
10. **`Atmosphere`** — Fresnel + scattering shader. *Gotcha*: gated by `useReducedEffects`.
11. **`Terminator`** — sun position from `sunPosition.ts`. *Gotcha*: must update on a low-frequency timer (every 5 min), not every frame.
12. **`PassportScanner`** — Tesseract OCR + MRZ post-process. *Gotcha*: runs OCR in worker mode.
13. **`HybridScanner.tsx`** — camera + OCR + QR. *Gotcha*: cleans up media tracks on unmount.
14. **`KioskSimulator.tsx`** — HMAC verify flow. *Gotcha*: constant-time compare via WebCrypto verify.
15. **`TripDetail.tsx`** — trip dossier. *Gotcha*: composes from many `lib/*` enrichments; coordinates Tiptap state.
16. **`TripPlanner.tsx`** — drag-to-reorder planner. *Gotcha*: pendingMutations queue must survive offline.
17. **`Onboarding.tsx`** — first-run carousel. *Gotcha*: writes `globeid:onboarded` only on completion.
18. **`LockScreen.tsx`** — biometric phase machine. *Gotcha*: must clear timers on unmount; falls back to passphrase.
19. **`AIAssistantSheet.tsx`** — voice + intent dispatcher. *Gotcha*: subscribes to `voiceIntents` rules.
20. **`CommandPalette.tsx`** (v2) — Cmd-K palette. *Gotcha*: pulls recents from `commandPaletteStore`.
21. **`EmptyState.tsx`** — universal empty placeholder. *Gotcha*: requires illustration + CTA.
22. **`PullToRefresh.tsx`** — wrapping scroller. *Gotcha*: uses `usePullToRefresh` state machine.
23. **`OfflineBanner.tsx`** — listens on `Network` plugin. *Gotcha*: rate-limits flicker on flaky networks (debounce 1500ms).
24. **`SyncBadge.tsx`** — overall sync status pill. *Gotcha*: aggregates store sync states.
25. **`SmartSuggestions`** (component shape inside `Suggestions.tsx`) — surfaces output of `smartSuggestions.ts`. *Gotcha*: dedups by `signature`.
26. **`IdentityScoreCard.tsx`** — animated number + tier ring. *Gotcha*: degrades to static number under reduced motion.
27. **`IdentityScoreSparkline.tsx`** — last 7 weeks line. *Gotcha*: SVG with `vector-effect: non-scaling-stroke`.
28. **`Confetti`** — bound to `lib/confetti.ts`. *Gotcha*: clamps particle count under reduced motion.
29. **`AccentPicker.tsx`** — 8 brand HSL options + custom slider. *Gotcha*: writes through `themePrefs.ts` so all surfaces re-tint.
30. **`PageTransition.tsx`** — wraps route subtree. *Gotcha*: variant choice driven by route metadata + reduced-motion override.

---

## Appendix K — Store Action Signatures (Authoritative)

All sigs below are the canonical contract. Implementation files contain the truth.

### `userStore`

```ts
export interface TravelDocument {
  id: string; type: "passport" | "id" | "visa" | "boarding-pass";
  fields: Record<string, string>; addedAt: number; expiresAt?: number;
}
export interface TravelRecord {
  id: string; from: string; to: string; date: string; airline: string;
  flightNumber?: string; type: "past" | "upcoming" | "current";
}
type Actions =
  | { setProfile(p: UserProfile): void }
  | { addDocument(d: TravelDocument): void }
  | { removeDocument(id: string): void }
  | { addTravelRecord(r: TravelRecord): void }
  | { hydrate(): Promise<void> }
  | { clear(): void };
```

### `walletStore`

```ts
type Actions =
  | { addPass(p: Pass): void }
  | { removePass(id: string): void }
  | { setBalance(currency: string, amount: number): void }
  | { recordTransaction(tx: WalletTransaction, idempotencyKey?: string): void }
  | { setSyncStatus(s: SyncStatus): void }
  | { syncNow(): Promise<void> }
  | { clear(): void };
```

### `lifecycleStore`

```ts
type Actions =
  | { addTrip(t: Trip): string }
  | { removeTrip(id: string): void }
  | { updateLeg(id: string, leg: Leg): void }
  | { setActiveTrip(id?: string): void }
  | { advance(id: string): void }            // planning → active → past
  | { hydrate(): Promise<void> }
  | { clear(): void };
```

### `tripPlannerStore`

```ts
type Actions =
  | { addTrip(input: NewPlannedTrip): string }
  | { reorderLegs(tripId: string, fromIdx: number, toIdx: number): void }
  | { setBudget(tripId: string, amount: number, currency: string): void }
  | { commitPending(): Promise<void> }
  | { clear(): void };
```

### `vaultAuditStore`

```ts
type AuditEventKind =
  | "vault-unlock" | "vault-lock-auto" | "vault-lock-manual"
  | "doc-view" | "doc-add" | "doc-delete" | "doc-export"
  | "scan-success" | "scan-fail" | "biometric-fallback";

type Actions =
  | { record(kind: AuditEventKind, meta?: Record<string, unknown>): void }
  | { recent(limit: number): AuditEvent[] }
  | { clear(): void };
```

### `commandPaletteStore`

```ts
type Actions =
  | { push(commandId: string): void }       // de-dups + caps at 5
  | { clear(): void };
```

---

## Appendix L — Server Router Shapes

Every route below matches `[METHOD] /api/v1<path>`.

### `wallet` (`server/src/routes/wallet.ts`)

| Method | Path | Body / query | Response |
|---|---|---|---|
| GET | `/wallet/` | – | `{ balances: Balance[], transactions: Tx[], state: WalletState }` |
| POST | `/wallet/transactions` | `{ currency, amount, kind, description, date, idempotencyKey?, txType?, merchant?, category?, country?, reference? }` | `{ ok: true, tx }` (idempotent on `idempotencyKey`) |
| POST | `/wallet/convert` | `{ from, to, amount }` | `{ ok: true, fromTx, toTx }` (atomic two-leg ledger insert) |

### `trips` (`server/src/routes/trips.ts`)

| Method | Path | Body | Response |
|---|---|---|---|
| GET | `/trips/` | – | `{ records: TravelRecord[] }` |
| POST | `/trips/` | `TravelRecord` | `{ ok: true, record }` |
| DELETE | `/trips/:id` | – | `{ ok: true }` |

### `planner` (`server/src/routes/planner.ts`)

| Method | Path | Body | Response |
|---|---|---|---|
| GET | `/planner/trips/` | – | `{ trips: PlannedTrip[] }` |
| POST | `/planner/trips/` | `{ name, theme, destinations: IATA[] }` | `{ ok: true, trip }` |
| DELETE | `/planner/trips/:id` | – | `{ ok: true }` |

### `budget` (`server/src/routes/budget.ts`)

| Method | Path | Body | Response |
|---|---|---|---|
| GET | `/budget/` | `?scope=` | `{ caps: BudgetCap[], aggregates: Record<scope, ProjectedSpend> }` |
| PUT | `/budget/caps` | `{ scope, capAmount, currency, alertThreshold, period }` | `{ ok: true, cap }` |
| DELETE | `/budget/caps/:scope` | – | `{ ok: true }` |

### Auth pattern

Every route enforces this middleware (typed):

```ts
function requireUser(c: Context, next: () => Promise<void>) {
  const auth = c.req.header("authorization");
  if (!auth?.startsWith("Bearer ")) return c.json({ ok: false, error: "auth" }, 401);
  const userId = verifyToken(auth.slice(7));
  if (!userId) return c.json({ ok: false, error: "auth" }, 401);
  c.set("userId", userId);
  return next();
}
```

---

## Appendix M — Phase 7 Design System

### M.1 Fluid type

```css
:root {
  --p7-text-2xs: clamp(0.625rem, 0.6rem + 0.1vw, 0.75rem);
  --p7-text-xs:  clamp(0.75rem,  0.7rem + 0.15vw, 0.875rem);
  --p7-text-sm:  clamp(0.875rem, 0.8rem + 0.25vw, 1rem);
  --p7-text-base:clamp(1rem,     0.95rem + 0.25vw, 1.125rem);
  --p7-text-lg:  clamp(1.125rem, 1.05rem + 0.4vw, 1.375rem);
  --p7-text-xl:  clamp(1.25rem,  1.15rem + 0.5vw, 1.625rem);
  --p7-text-2xl: clamp(1.5rem,   1.3rem + 0.8vw,  2rem);
  --p7-text-3xl: clamp(1.875rem, 1.6rem + 1vw,    2.5rem);
  --p7-text-4xl: clamp(2.25rem,  1.8rem + 1.6vw,  3rem);
}
```

### M.2 Motion tokens

```ts
export const motionTokens = {
  duration: { fast: 120, base: 220, slow: 360, scene: 600 },
  ease: {
    out:    [0.22, 1, 0.36, 1],
    inOut:  [0.65, 0, 0.35, 1],
    spring: { type: "spring", stiffness: 320, damping: 32 },
  },
  surfaceSprings,
} as const;
```

### M.3 Z-index ladder

| Layer | Index |
|---|---|
| Toast | 100 |
| Sheet | 80 |
| Modal / Dialog | 70 |
| Top Bar / Status | 60 |
| Bottom Nav | 50 |
| FAB | 45 |
| Banner / Offline | 40 |
| Scroll-tinted overlay | 30 |
| Globe HUD | 20 |
| Globe canvas | 0 |

`tailwind.config.ts` exposes these as utilities so ad-hoc `z-[60]` is no longer needed.

### M.4 Density levels

`html[data-density="compact"]` → padding × 0.75, gap × 0.85, radius × 0.85.
`html[data-density="spacious"]` → padding × 1.25, gap × 1.2, radius × 1.15.

### M.5 Typography stack

```
--p7-font-sans: "Inter Variable", "Inter", system-ui, …;
--p7-font-mono: "JetBrains Mono Variable", "JetBrains Mono", ui-monospace, …;
--p7-font-display: "Inter Variable" with feature-settings 'ss01','cv05';
```

---

## Appendix N — File-by-file walk: critical paths

### N.1 `lib/boardingPass.ts` (HMAC pipeline)

Responsibilities:
- `signPassPayload(payload, secret)` → `{ token, b64Payload, b64Sig }`
- `verifyPassToken(token, secret)` → `{ ok: boolean, payload?: Payload }`
- Constant-time compare via `subtle.crypto.verify("HMAC", key, sig, data)`.
- `canonicalize(payload)` sorts keys before stringify so the signature is reproducible across producers/verifiers.
- Secret rotation: keys are versioned (`v=1`); verify accepts the last 2 versions.

### N.2 `lib/voiceIntents.ts` (Voice grammar)

Public types:

```ts
type Intent =
  | { kind: "navigate"; route: string }
  | { kind: "action"; action: string }
  | { kind: "search"; query: string }
  | { kind: "query"; query: string }
  | { kind: "numeric"; surface: "trip" | "pass" | "document"; index: number }
  | { kind: "translate"; targetLang: string }
  | { kind: "remind"; what: string; whenIso: string }
  | { kind: "compose"; service: "hotel" | "flight" | "ride" | "trip"; place?: string; whenLabel?: string }
  | null;

export function parseIntent(text: string): Intent;
export function suggestIntents(text: string): Intent[];
```

Compose rule (corrected during this sprint):

```ts
/\b(book|find|plan)\s+(?:a\s+)?(hotel|flight|ride|trip)\b\s+(?:in|to)\s+([a-z\s]+?)(?:\s+for\s+([a-z0-9\s]+?))?$/i
```

### N.3 `lib/cameraPresets.ts` (Globe camera)

Functions:

```ts
homeView(homeIata): { target: [x,y,z], zoom: number }
nextTripView(originIata, destIata): same
flightTrackerView(currentLat, currentLng): same
```

Zoom bands (haversine km):

| Distance | Zoom |
|---|---|
| < 800 | 2 |
| < 4000 | 3 |
| < 9000 | 4 |
| ≥ 9000 | 5 |

### N.4 `lib/predictiveDeparture.ts`

```ts
function predict({
  departureIso, commuteMinutes, bufferMinutes = 90, now = Date.now(),
}): { leaveAt: number, status: "on-time" | "leave-now" | "should-have-left" };
```

Deterministic — no live traffic at runtime; commute time is supplied by the caller (Maps or user-edited).

### N.5 `lib/connectionDetector.ts`

```ts
function detect(legs: Leg[]): Array<
  | { kind: "tight"; legIndex: number; gapMinutes: number; mctMinutes: number }
  | { kind: "missed"; legIndex: number; gapMinutes: number; mctMinutes: number }
>;
```

MCT table: per-airport min connection time (defaults 60 min domestic, 90 min international, hub overrides for ATL, AMS, DOH, DXB, …).

### N.6 `lib/sheetSnap.ts` (Velocity-aware bottom sheet)

Surface contract:

```ts
function pickSnap({
  fractions: number[], // sorted, e.g. [0.25, 0.6, 0.95]
  current: number,     // 0..1, current open fraction
  velocity: number,    // px/ms; >0 means moving down (closing)
}): number /* fraction to settle to */;
```

Direction semantics: positive velocity = closing = pick a *lower* index.

### N.7 `lib/achievements.ts`

```ts
type Achievement =
  | "first-trip" | "first-scan"
  | "trips-10" | "trips-25" | "trips-100"
  | "scans-10" | "scans-50"
  | "countries-5" | "countries-10" | "countries-25"
  | "continents-5" | "continents-7";

function diffAchievements(prev: Stats, next: Stats): Achievement[];
```

Used by `Travel.tsx`, `Identity.tsx`, `HybridScanner.tsx` to fire `confetti()` on cross.

---

## Appendix O — Onboarding Flow

```
Carousel
  ├── slide 1: "Your travel identity, on you" + Lottie
  ├── slide 2: "Scan, sign, and walk through" + Lottie
  ├── slide 3: "Plan trips with deterministic intelligence" + Lottie
  └── slide 4: "Permissions"
        ├── Camera   (required for HybridScanner)
        ├── Location (optional, used for context)
        ├── Notifications (recommended)
        └── Biometric  (optional, recommended)
Then: applyThemePrefs() → set localStorage.globeid:onboarded = 1
       → navigate("/", replace)
```

---

## Appendix P — Lock Screen FSM

```
State: "idle"
Trigger: route enters /lock
Action: requestBiometric()
   ↓
State: "prompting"
   ├── success → State: "verified" → navigate(returnTo ?? "/")
   ├── unsupported  → toast "Use passphrase" → show passphrase input
   ├── unenrolled   → toast "Enrol biometric in Settings" → show passphrase
   ├── lockout      → 30s cooldown timer → retry
   └── failure      → toast "Try again" → State: "idle"
```

Auto-lock triggers (`useVaultAutoLock`):
- Idle ≥ 5 min
- Background ≥ 30 s
- Manual Lock CTA

---

## Appendix Q — Trip lifecycle states

```
Planning → Active → Past
   │         │        │
   │         │        └── archived (read-only)
   │         └── delayed | rescheduled | missed-connection (sub-states)
   └── ready (all docs verified, boarding pass downloaded)
```

`tripLifecycle.ts` exposes:

```ts
function advance(trip: Trip, now = Date.now()): Trip;        // pure FSM step
function eligibleForBoardingPass(trip: Trip): boolean;       // 24h before departure
function lifecyclePhase(trip: Trip, now = Date.now()): Phase;
```

---

## Appendix R — Vault audit event taxonomy

Recorded by `vaultAuditStore.record(kind, meta)`.

| Kind | When fired |
|---|---|
| `vault-unlock` | `LockScreen` → biometric verify success |
| `vault-lock-auto` | `useVaultAutoLock` triggers |
| `vault-lock-manual` | User taps Lock |
| `doc-view` | DocumentVault detail opened |
| `doc-add` | New scan saved |
| `doc-delete` | Doc removed |
| `doc-export` | Encrypted backup zipped |
| `scan-success` | HybridScanner OCR resolved |
| `scan-fail` | HybridScanner OCR failed |
| `biometric-fallback` | Biometric prompt declined → passphrase used |

Stored as `{ kind, ts, meta }` with a hard cap of 100 (FIFO eviction).

---

## Appendix S — Audit of `globeid:` namespace at runtime

To list at runtime:

```js
Object.keys(localStorage).filter(k => k.startsWith("globeid:"))
```

Sign-out (`signOut.ts`) explicitly removes only the keys above; other libraries' keys are preserved.

---

## Appendix T — Notable invariants

1. **Wallet ledger never holds a denormalised balance.** Balance = SUM(transactions) per (user, currency).
2. **Pass payloads are canonicalised** before signing. Verifier must canonicalise too.
3. **Stores never re-trigger sync from inside React render.** All `syncNow()` calls happen in event handlers / effects / engine ticks.
4. **`Trip → Pass`** ID linkage is reciprocal: `Pass.tripId` and `Trip.passIds[]` are kept in sync.
5. **Idempotent writes** for any append-only ledger row (wallet, loyalty, alerts) — `idempotency_key` UNIQUE INDEX (partial).
6. **Reduced-motion gate is global**: every animation site queries `useReducedMotionMatch` (or the orchestrator) before running.
7. **Vault encryption key never crosses a process boundary.** Derived per-session from biometric output and lives only in memory.
8. **No animation library inside the cinematic engine.** GSAP runs all timelines so every effect can be subscribed/cancelled centrally.

---

## Appendix U — Patterns used heavily

### U.1 "Pure function + thin component" pattern

```
lib/<feature>.ts             ← pure logic + tests
hooks/use<Feature>.ts        ← optional adaptor with state
components/<dir>/<X>.tsx     ← rendering + dispatch
```

Every "smart" surface reduces to: hook fetches state → pure module derives view-model → component renders.

### U.2 "Event signature" pattern

For any side-effect that should be idempotent across replays (alerts, notifications, audit), the producer attaches a stable `signature` (or `idempotency_key`). Stores reject duplicates by signature.

### U.3 "Web fallback for every native call"

Every entry point in `nativeBridge.ts` returns a sensible web result if Capacitor's plugin is unavailable, so the PWA build is fully usable.

### U.4 "Single hydration entry per store"

Each store exposes `hydrate(): Promise<void>` (when applicable) that loads from localStorage then optionally syncs from server. App.tsx calls them in sequence on cold start; `wireAppStateListener` re-runs them on foreground.

---

## Appendix V — Server `lib/` helpers

| File | Highlights |
|---|---|
| `validate.ts` | `ok(c, body)`, `bad(c, msg, status?)`, `parseBody(c, schema)`. |
| `cache.ts` | `inMemoryCache<T>(ttlMs)` with `get/set/clear`. |
| `geo.ts` | IATA → country resolver, ICAO ↔ IATA. |
| `flightStatus.ts` | Mock flight-status producer (deterministic by flight number + date). |
| `fraud.ts` | Z-score over last-N transactions per merchant; `flagAnomalies(rows)`. |
| `insights.ts` | Server-side mirror of `travelInsights.ts`. |
| `intelligence.ts` | Combines insights + recommendations. |
| `lifecycle.ts` | Server-side trip lifecycle state machine. |
| `loyalty.ts` | `earnFromPayment`, `redeem`, `currentBalance`. |
| `score.ts` | Identity score + factor breakdown. |
| `weather.ts` | Open-Meteo proxy + cache. |

---

## Appendix W — Test file inventory (representative)

```
src/test/
  airlineBrand.test.ts
  airports.test.ts
  achievements.test.ts
  audioFeedback.test.ts
  auditLog.test.ts
  boardingPass.test.ts
  budgetStore.test.ts
  cameraPresets.test.ts
  commandPaletteStore.test.ts
  confetti.test.ts
  connectionDetector.test.ts
  countdown.test.ts
  countries.test.ts
  countryThemes.test.ts
  currencyEngine.test.ts
  documentExpiry.test.ts
  documentVault.test.ts
  groundTransport.test.ts
  identityTier.test.ts
  loungeAccess.test.ts
  mrzParser.test.ts
  mrzToDocument.test.ts
  notificationChannels.test.ts
  packingList.test.ts
  passOrdering.test.ts
  predictiveDeparture.test.ts
  qrEncoder.test.ts
  relativeDate.test.ts
  secureClipboard.test.ts
  sheetSnap.test.ts
  signOut.test.ts
  smartSuggestions.test.ts
  starCatalog.test.ts
  themeAccents.test.ts
  themePrefs.test.ts
  transitions.test.ts
  travelHeatmap.test.ts
  travelInsights.test.ts
  tripGenerator.test.ts
  tripLifecycle.test.ts
  visaRequirements.test.ts
  voiceIntents.test.ts
  walletStore.test.ts
  ...
  (53 total)
```

---

## Appendix X — Where to start reading

For a new contributor (or coding agent) coming into this repo cold:

1. `README.md` — scope + quick start.
2. `ARCHITECTURE.md` — this file.
3. `BACKLOG.md` — what's next.
4. `src/App.tsx` — wiring + routes.
5. `src/lib/nativeBridge.ts` — every native call goes through here.
6. `src/lib/boardingPass.ts` + `src/screens/KioskSimulator.tsx` — full crypto loop.
7. `src/lib/voiceIntents.ts` + `src/hooks/useVoiceCommands.ts` — voice path.
8. `src/screens/TripDetail.tsx` + `src/lib/tripIntel.ts` — heaviest cross-store render path.
9. `server/src/index.ts` + `server/src/routes/wallet.ts` — server wiring + canonical router.
10. `vite.config.ts` + `capacitor.config.ts` — build + native shell.

After those ten files you have all the mental models needed to extend any feature in the app.

---

## End of document.

If anything in this file is contradicted by the source tree, the source tree wins. Treat this doc as the *intended* architecture; verify with `git grep` before touching anything.
