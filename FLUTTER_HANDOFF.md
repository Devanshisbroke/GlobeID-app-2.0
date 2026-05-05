# GlobeID — Flutter Migration Handoff

> **Purpose.** This document is the single source of truth for an autonomous agent (e.g. Claude Opus 4.7) tasked with rebuilding GlobeID in Flutter. It covers the full architecture of the existing React/TypeScript app, every shipped feature, every known issue, every dependency, and a concrete migration strategy with package-level mappings to Flutter equivalents. Read it end-to-end before writing a single line of Dart.

---

## 0. TL;DR

- **What it is:** Cross-platform travel + identity super-app. Web (PWA) + Capacitor Android (iOS-ready). Single React/TypeScript codebase.
- **What's shipped:** 25 screens, 14+ Zustand stores, 75+ pure-function modules in `src/lib`, 25+ Hono REST endpoints, 3D globe via Three.js + R3F, deterministic AI insights, biometric vault, multi-currency wallet, boarding-pass HMAC system, voice-intent parser, 316/316 unit tests passing.
- **What's missing:** Real OAuth/SSO, true server push (currently polling/local), full Yale BSC star data, MediaPipe face-mesh hookup, Y.js multi-device sync, Stripe Issuing.
- **Why migrate to Flutter:** Native 60→120 fps animation, Skia/Impeller renderer, single binary across iOS/Android/desktop, simpler camera + biometric + sensors stack, smaller attack surface than a WebView.

---

## 1. Project Summary

GlobeID is a digital travel + identity assistant. A single user can:

1. Scan passports / IDs / visas / boarding passes via camera (MRZ + QR).
2. Store all documents in an encrypted on-device vault, gated by biometrics.
3. Plan multi-leg trips with weather, visa requirements, packing lists, lounge access, ride-hail deep-links, currency conversion, and budget tracking.
4. Watch a 3D globe with arcs of past/upcoming flights, day/night terminator, atmospheric scattering, bloom, stars, sparkles.
5. Use a multi-currency wallet for payments + boarding passes (Apple/Google-Wallet-style cards).
6. Talk to a deterministic voice intent parser ("show wallet", "book a hotel in Tokyo", "remind me to pack at 7pm").
7. Receive deterministic AI nudges (visa expiry, FX drops, frequent routes, spend anomalies, carbon footprint).
8. Open the app via deep links (`globeid://trip/<id>`, `globeid://pass/<code>`).

The app is **deterministic-first** — no LLM, no third-party AI APIs at runtime. All "intelligence" is pure-function logic over historical data + transactions.

---

## 2. Current Architecture

### 2.1 Frontend (React + TypeScript + Vite)

```
src/
├── App.tsx                      # Root, hydration chain, deep-link wiring
├── main.tsx                     # Boot: applyThemePrefs, ServiceWorker
├── screens/                     # 25 top-level routes
│   ├── Home.tsx
│   ├── Wallet.tsx
│   ├── Identity.tsx, IdentityVault.tsx, LockScreen.tsx
│   ├── Travel.tsx, TravelTimeline.tsx, TravelIntelligence.tsx
│   ├── TripDetail.tsx, TripPlanner.tsx
│   ├── DocumentVault.tsx, EntryReceipt.tsx
│   ├── Onboarding.tsx, Profile.tsx, UserProfile.tsx
│   ├── HybridScanner.tsx        # camera + MRZ + QR
│   ├── KioskSimulator.tsx       # boarding-pass HMAC verify
│   ├── GlobalMap.tsx, Explore.tsx, PlanetExplorer.tsx
│   ├── SocialFeed.tsx, SocialFeedV2.tsx
│   ├── ServicesHub.tsx, SuperServicesHub.tsx, services/
│   └── AnalyticsDashboard.tsx, MultiCurrency.tsx
├── components/
│   ├── ai/                      # AIAssistantSheet, button
│   ├── analytics/               # CategoryHeatmap, etc.
│   ├── animations/              # Lottie, page transitions
│   ├── dashboard/               # CarbonFootprintChart, TravelStats
│   ├── explorer/, identity/, intelligence/
│   ├── layout/                  # AppChrome, BottomNav, FAB, OfflineBanner, SyncBadge
│   │   └── v2/                  # Phase-7 chrome + CommandPalette
│   ├── map/                     # FlightArcs, Globe, Atmosphere, Terminator
│   ├── settings/                # AccentPicker, ThemePrefs UI
│   ├── system/                  # EmptyState, PullToRefresh, ErrorBoundary
│   ├── trip/                    # TripGlobePreview, TripCard
│   ├── ui/                      # design-system primitives (button, sheet, sonner, …)
│   │   ├── LazyImage.tsx        # M148 lazy + LQIP
│   │   └── VirtualList.tsx      # M155 windowed list
│   ├── voice/                   # voice command UI
│   └── wallet/                  # PassDetail, PassCard, BalanceCard
├── store/                       # Zustand persisted stores
│   ├── userStore.ts             # docs, profile, travelHistory
│   ├── walletStore.ts           # balances, txs, passes
│   ├── lifecycleStore.ts        # trip lifecycle (planning → active → past)
│   ├── tripPlannerStore.ts, tripNotesStore.ts
│   ├── insightsStore.ts, alertsStore.ts, recommendationsStore.ts
│   ├── safetyStore.ts, fraudStore.ts, scoreStore.ts
│   ├── socialStore.ts, userFeedStore.ts
│   ├── budgetStore.ts, contextStore.ts, copilotStore.ts
│   ├── loyaltyStore.ts, weatherStore.ts
│   ├── vaultAuditStore.ts       # immutable audit-event log
│   └── commandPaletteStore.ts   # recent commands
├── lib/                         # 75+ pure modules
│   ├── boardingPass.ts          # HMAC-SHA256 sign/verify
│   ├── mrzParser.ts, mrzToDocument.ts, ocrService.ts
│   ├── airports.ts              # IATA index, lat/lng
│   ├── airlineBrand.ts          # gradient from IATA code
│   ├── currencyEngine.ts        # FX conversion + history
│   ├── packingList.ts, visaRequirements.ts
│   ├── groundTransport.ts, loungeAccess.ts, weatherForecast.ts
│   ├── travelInsights.ts, travelPrediction.ts, travelSuggestions.ts
│   ├── connectionDetector.ts    # I107 tight connections
│   ├── predictiveDeparture.ts   # I110 leave-for-airport
│   ├── travelHeatmap.ts         # G86 5° lat/lng buckets
│   ├── cameraPresets.ts         # G88 home/next-trip/tracker
│   ├── starCatalog.ts           # G84 30 nav-grade stars
│   ├── voiceIntents.ts          # H95-100 intent parser
│   ├── achievements.ts          # K135 ladder + diff
│   ├── confetti.ts              # tiny canvas confetti
│   ├── transitions.ts           # K131/J116 spring + variant presets
│   ├── sheetSnap.ts             # J114 snap-point selector
│   ├── nativeBridge.ts          # Capacitor wrapper (haptics, share, file, …)
│   ├── deepLink helpers, signOut.ts (wipe-all)
│   ├── identityTier.ts, scoreFactorMeta.ts
│   ├── tokenService.ts, secureClipboard.ts, biometricAuth.ts
│   ├── auditLog.ts, syncEngine.ts
│   └── themePrefs.ts, themeAccents.ts, motion-tokens.ts, design-system.ts
├── hooks/                       # useReducedMotionMatch, useScrollTint, useDeviceTilt,
│                                # usePullToRefresh, useEdgeSwipeBack, useVaultAutoLock,
│                                # useVoiceControl, useVoiceCommands, …
├── services/                    # notificationService, paymentGateway
├── i18n/                        # i18next + locales
├── core/                        # cross-cutting types
└── test/                        # 53 vitest test files (316 tests)
```

### 2.2 Backend (`server/` — Hono + SQLite + Drizzle)

```
server/src/
├── index.ts                     # Hono app, CORS, request logging
├── auth/                        # demo auth (email-only)
├── db/                          # Drizzle schema + migrations
├── lib/                         # shared helpers
└── routes/
    ├── alerts.ts, budget.ts, context.ts, copilot.ts, esim.ts,
    ├── exchange.ts, food.ts, fraud.ts, hotels.ts, insights.ts,
    ├── insurance.ts, lifecycle.ts, local.ts, loyalty.ts, planner.ts,
    ├── recommendations.ts, rides.ts, safety.ts, score.ts, trips.ts,
    ├── user.ts, visa.ts, wallet.ts, weather.ts
```

- 25 REST endpoints. All return JSON, all schema-validated with Zod.
- SQLite is the only persistence layer. Drizzle ORM is the typed surface.
- **Demo auth only**: there is no real user system yet (item Q179 in BACKLOG.md).

### 2.3 State, persistence, hydration

- **Client state**: Zustand stores with `persist` middleware → `localStorage` keys prefixed `globeid:`. 14 stores, all typed.
- **Server state**: TanStack React Query for fetches + cache invalidation.
- **Optimistic UI**: `pendingMutations` queue inside specific stores (currently in-memory).
- **Hydration chain**: `App.tsx` re-hydrates stores on `appStateChange` → foreground (Capacitor App plugin). PR #34 added this.

### 2.4 Native bridge (Capacitor)

Plugins in use:

| Plugin | Used for |
|---|---|
| `@capacitor/app` | appStateChange, appUrlOpen (deep-links) |
| `@capacitor/camera` | Document scan |
| `@capacitor/filesystem` | PDF receipt save |
| `@capacitor/geolocation` | Current city, time-zone delta |
| `@capacitor/haptics` | Selection / success / error patterns |
| `@capacitor/local-notifications` | Boarding alarm, leave-for-airport, daily digest |
| `@capacitor/network` | Offline banner |
| `@capacitor/preferences` | Native key-value (biometric-gated) |
| `@capacitor/share` | Share-sheet |
| `@capacitor/splash-screen` | Branded splash |
| `@capacitor/status-bar` | Tint with active screen |
| `@aparajita/capacitor-biometric-auth` | Lock screen + vault gate |
| `@capacitor-community/speech-recognition` | Voice intents |

---

## 3. Implemented Systems & Features

### 3.1 Identity & Vault

- **Onboarding**: 4-step carousel; permission prompts (camera, notifications, biometric).
- **Lock screen**: biometric phase machine (idle → prompting → verified) with explicit fallback toasts (no enrolment, lockout, unsupported).
- **Document vault**: passport, ID, visa, boarding pass, generic. Tag/filter chips. Scan-and-link auto-categoriser.
- **Audit log**: immutable append-only event stream (`vaultAuditStore`), max 100 events, kinds: `view`, `unlock`, `idle-timeout`, `background-timeout`, `delete`.
- **Auto-lock** (`useVaultAutoLock`): 5 min idle + 30 s background → navigate `/lock` and log audit event.
- **Identity score** (`scoreStore`): factors with weights + sparkline + tier badge (Tier 0/1/2/3) + "how to improve" drawer.
- **Sign-out** (`lib/signOut.ts`): wipes user/wallet/lifecycle stores, clears notification read state, revokes cached tokens.

### 3.2 Wallet

- **Boarding passes**: HMAC-SHA256 signed payloads. Issuer JWT-like envelope. QR encodes a bp:// URI.
- **Pass cards** with airline-brand gradient deterministic from IATA.
- **Pass parallax tilt**: deviceorientation API, ±10° clamp, iOS permission gating, reduced-motion safe.
- **Pass haptic pulse**: QR-display fires `haptics.selection()` on processing, `success()` on verified, `error()` on fail.
- **Dim-on-screen-off** for PassDetail (best-effort screen-brightness plugin).
- **Multi-currency**: balances per ISO 4217 code; conversion via `currencyEngine.ts`.
- **Receipt PDF**: lazy-loaded `jspdf` (only on download).
- **Empty state**: inline "Scan a document" CTA on empty pass stack (Apple-Wallet pattern).

### 3.3 Trips

- **Lifecycle**: planning → active → past, with deletion cancelling scheduled notifications.
- **Trip planner**: multi-leg + drag-to-reorder (`@dnd-kit`).
- **Trip detail enrichments**:
  - Weather: Open-Meteo no-key API
  - Time-zone delta + local-time
  - Visa requirements: deterministic lookup table
  - Packing list: climate-aware, activity-aware, precip-aware (`packingList.ts`)
  - Lounge access: 14 lounges, 12 hub airports, membership-filtered
  - Ground transport: 9 ride providers, country-mapped (`groundTransport.ts`)
  - Budget per-leg breakdown
  - Tight-connection detector (`connectionDetector.ts`)
  - Predictive leave-for-airport (`predictiveDeparture.ts`)
- **Tiptap notes pane** in TripDetail (rich-text + slash commands).
- **Trip card**: hero image (Unsplash by IATA) + airline-logo badge.

### 3.4 3D Globe

- React-Three-Fiber 8 + drei + postprocessing.
- **Layers**: NASA Visible Earth diffuse, cloud overlay (independent rotation), night-lights map synced to terminator.
- **Effects**: Bloom, Vignette, ChromaticAberration, Stars, Sparkles.
- **Atmosphere**: Fresnel + Rayleigh-ish scattering shader.
- **Flight arcs**: cubic Bezier in lat/lng → 3D, with airplane sprite traversal + contrail.
- **Star catalog** (`starCatalog.ts`): 30 nav-grade stars, J2000 RA/Dec, equatorial→Cartesian projector, magnitude→size.
- **Travel heatmap** (`travelHeatmap.ts`): 5° lat/lng buckets with normalised intensity.
- **Camera presets** (`cameraPresets.ts`): home / next-trip (great-circle midpoint w/ haversine zoom) / flight-tracker.

### 3.5 AI / Intelligence (deterministic only)

- **Smart suggestions** on Home (`smartSuggestions.ts`): visa expiry, FX drop, etc.
- **Trip recap** weekly digest (scheduled local notification).
- **Spend anomaly detector** (3σ weekly merchant pattern).
- **Travel-pattern insight** ("You spend most in Tokyo on weekends").
- **Itinerary tight-connection detector** with IATA-derived MCT.
- **Carbon footprint** per-flight + monthly chart (recharts).
- **Frequent-route detector** + save-route CTA.
- **Predictive leave-for-airport** with traffic-factor scaling.

### 3.6 Voice

- `voiceIntents.ts` deterministic regex grammar.
- Intents: `navigate`, `action`, `query`, `search`, `numeric`, `translate`, `remind`, `compose`, `unknown`.
- Wake-word stripper for "hey globe / hey globeid / ok globe / okay guide".
- `suggestIntents()` overlap-scored "did you mean" for unknowns.
- Speech-recognition plugin gates always-listening; permission flow respected.

### 3.7 UX / Motion

- Phase-7 design tokens: `tailwind.config.ts` + `lib/motion-tokens.ts` + `lib/design-system.ts`.
- 7 page-transition presets + 5 surface-spring presets (`lib/transitions.ts`).
- Reduced-motion fallback on all motion sites (`useReducedMotionMatch`).
- Pull-to-refresh primitive (`usePullToRefresh` + `PullToRefresh` component).
- Bottom-sheet snap-point selector (`sheetSnap.ts`) — velocity-aware.
- Command palette (Cmd-K / Ctrl-K) with persistent **Recent** group.
- Coachmarks (first-launch).
- Empty-state primitive `<EmptyState />` with tone + CTA.
- Skeleton-loading on Wallet / Insights / Feed.
- Confetti on achievements (`achievements.ts` + `confetti.ts`).
- Scroll-driven theme tint (`useScrollTint`).

### 3.8 Theme

- 8 brand accents + custom HSL slider.
- Auto theme by time of day (light 06:00–19:00, dark otherwise — re-checked every 5 min).
- High-contrast mode, reduce-transparency mode, density (compact/comfortable/spacious).
- Per-screen theme tweaks (Wallet warmer, Identity cooler).

### 3.9 Notifications & Reminders

- Quiet hours (no notifications 23:00–07:00 user-local).
- Per-channel preferences (boarding / delays / digests / marketing).
- Leave-for-airport alarm.
- Daily digest at chosen time.
- Trip reminder snooze (1h / 3h / morning).

### 3.10 Performance

- `<LazyImage />` native lazy-load + LQIP.
- `<VirtualList />` minimal windowed list.
- FlightArcs route-list memoised.
- jspdf lazy-loaded.
- Globe lazy-mountable via IntersectionObserver.
- PWA precache (Workbox 6 MB default lifted for NASA layers).

### 3.11 Security

- Biometric vault re-lock after 5 min idle.
- Screen-recording / screenshot block on PassDetail (Android `setSecureFlag`).
- Vault audit log.
- Secure clipboard (auto-clear after 30 s).
- HMAC-signed boarding passes.
- Suspicious-trip detector (impossible-travel pattern → re-auth).

---

## 4. Known Bugs & Incomplete Areas

- **Q179 — Real auth missing.** Server uses demo email-only login. No magic-link, no SSO.
- **N157/N158 — Background sync queue is in-memory.** Workbox-background-sync + IndexedDB queue not yet wired.
- **G93 — WebGPU path** scaffolded but not enabled by default.
- **F73 — paddleocr-wasm fallback** for non-Latin OCR not yet wired.
- **G84 — full Yale BSC** (~9k stars) not shipped; 30-star seed only.
- **G82 — animated airplane sprite + contrail** present but the contrail fade-out can flicker on low-end GPUs.
- **C 27 / C 28 — pkpass / Google Pay export** not implemented.
- **D 53 — live flight tracking visual** scaffolded only.
- **MediaPipe FaceLandmarker** dep installed but not wired into LiveCameraScanner.
- **Y.js / IndexedDB CRDT** dep installed but no store migration done.
- **Tone.js** dep installed but only a small set of cues are wired.

### Bugs fixed this session series (PR #28–35)

- Wallet crash when adding a boarding pass with `flightNumber: null`. Fix: defensive null-guard in `airlineBrand.ts` + type widened end-to-end + refused-with-toast on save when missing. Regression test added.
- Travel feed not loading — partially mitigated, but the V1 SocialFeed deprecated in favour of SocialFeedV2 (use V2 going forward).
- Premature "Identity Confirmed" frame on LockScreen — replaced with a 3-state phase machine.
- Workbox build failure on NASA cloud PNG (4.9 MB > 2 MB default) — runtime CacheFirst strategy added.
- Deep-link URL double-encoding bug in `nativeBridge.deepLinkToPath` — fixed with `decodeURIComponent` + scheme detection.
- Various drag/scroll capture audits, button-in-button audits, z-index ladder unification.

---

## 5. UI/UX State and Issues

- **Density**: comfortable by default, but a few cards in Wallet still feel slightly tight on small screens (≤375 px).
- **Iconography**: lucide-react throughout. All ≥24 px, stroke 1.8.
- **Touch targets**: 44×44 token enforced via `iconButtonSize`. Verified everywhere.
- **Safe-area**: most fixed chrome respects safe-area inset; a few legacy banners (`OfflineBanner`, `SyncBadge`) still need a final pass.
- **z-index ladder** (final, audit-pass): `toast > sheet > nav > FAB > banner`. Single ladder source of truth in CSS vars.
- **Reduced-motion**: applied to Atmosphere, Globe, BottomNav, FAB, Skeleton, useScrollTint, useDeviceTilt.
- **Pull-to-refresh**: present on Wallet, Trips, Documents, Notifications. SocialFeedV2 has it; Feed V1 does not.
- **Toast**: Sonner-based; glass tint + accent border per type (info/success/warning/error).
- **Empty states**: present on Wallet, Documents, Trips, Notifications, Feed. Each has a tertiary CTA.
- **Skeletons**: Wallet first paint, Insights, Feed, Notifications.
- **Edge-swipe-back**: `useEdgeSwipeBack` verified on TripDetail + PassDetail.

### Top remaining UX nits

- Onboarding refresh to a 4-screen carousel with Lottie + permission prompts (J 120) — partial.
- Tutorial coachmarks for Globe interaction — exist for general app, not Globe-specific.
- Pinch-to-zoom + two-finger rotate on globe — not yet implemented (currently single-finger drag + wheel).

---

## 6. Integrations

| Area | Library / Service | Status |
|---|---|---|
| MRZ OCR | tesseract.js | working (eng pack only) |
| QR | @zxing/browser, @zxing/library | working |
| 3D | three, @react-three/fiber, @react-three/drei, @react-three/postprocessing | working |
| Maps 2D | leaflet, react-leaflet | working |
| Charts | recharts, @visx/* | working |
| Animation | framer-motion, motion, gsap, lottie-react, @rive-app/react-canvas | working (rive scaffolded) |
| Voice | @capacitor-community/speech-recognition | working |
| Biometrics | @aparajita/capacitor-biometric-auth | working |
| Native | @capacitor/* | see §2.4 |
| Storage | zustand+persist (localStorage), idb, dexie | working |
| CRDT | yjs, y-indexeddb | scaffolded |
| Forms | react-hook-form, @hookform/resolvers, zod | working |
| i18n | i18next, react-i18next, i18next-browser-languagedetector | working |
| Audio | tone.js | partial |
| PDF | jspdf | working (lazy-loaded) |
| Background bg-sync | workbox-background-sync (via vite-plugin-pwa) | scaffolded |

External APIs:
- **Open-Meteo** (no key) — weather forecast.
- **Unsplash** — destination hero (URL-only, no SDK).
- **NASA Visible Earth** — public-domain Earth textures.
- No real auth provider (demo only).
- No real payment gateway (mock `paymentGateway.ts`).

---

## 7. Dependencies and Tech Stack

### 7.1 Production runtime (frontend)

```
react@18.3, react-dom@18.3, react-router-dom@6.30
typescript@5.8, vite@5.4
tailwindcss@3.4, tailwind-merge, tailwindcss-animate
zustand@4.5, @tanstack/react-query@5.83, @tanstack/react-virtual@3.13
framer-motion@11, motion@12.38, gsap@3.15, lottie-react@2.4, @rive-app/react-canvas@4.28
three@0.160, @react-three/fiber@8.18, @react-three/drei@9.122, @react-three/postprocessing@2.19, postprocessing@6.34
date-fns@3.6, culori@4.0
recharts@2.15, @visx/heatmap, @visx/scale, @visx/text, @visx/tooltip, @visx/group@3.12
react-hook-form@7.61, @hookform/resolvers@3.10, zod@3.25
@radix-ui/* (full set), cmdk@1.1, sonner@1.7, vaul@0.9
i18next@26, react-i18next@17
tesseract.js@7, jspdf@4.2, qrcode@1.5, @zxing/browser@0.2, @zxing/library@0.22
leaflet@1.9, react-leaflet@4.2
idb@8, dexie@4.4, yjs@13.6, y-indexeddb@9.0
@dnd-kit/core@6.3, @dnd-kit/sortable@10
@tiptap/react@3.22, @tiptap/starter-kit, @tiptap/pm
@use-gesture/react@10.3, tinykeys@3
input-otp, embla-carousel-react, react-day-picker, react-resizable-panels
@capacitor/core@8.2 + plugins (see §2.4), @aparajita/capacitor-biometric-auth, @capacitor-community/speech-recognition
@mediapipe/tasks-vision@0.10
@fontsource-variable/inter, @fontsource-variable/jetbrains-mono
class-variance-authority, clsx, lucide-react, next-themes
tone@15
vite-plugin-pwa@1.2
```

### 7.2 Dev / build

```
@vitejs/plugin-react-swc, vitest@3.2, @testing-library/react@16, @testing-library/jest-dom@6
typescript-eslint@8.38, eslint@9.32, eslint-plugin-react-hooks, eslint-plugin-react-refresh
husky@9, lint-staged@16, npm-run-all
postcss, autoprefixer
fake-indexeddb, jsdom
```

### 7.3 Backend

```
hono@4.6, @hono/node-server@1.13
better-sqlite3@11.5, drizzle-orm@0.36
zod@3.25
tsx, typescript
```

---

## 8. What Was Fixed / Shipped This Session Series

(Across PR #28–35, all merged into main.)

- 30+ items from BACKLOG.md including (numbered against §A-V):
  - Critical fixes: 1, 4, 6, 7, 8, 9
  - Wallet depth: 25, 31, 32 (parallax tilt, dim-on-screen-off, QR haptic)
  - Trip depth: 41, 42, 43, 45, 46, 48, 49, 50
  - Identity: 58, 59, 68, 134 (sparkline, auto-lock, tier ladder, animated score)
  - AI: 105, 106, 107, 108, 109, 110
  - Globe: 84, 86, 88
  - UX: 113, 114, 117, 118, 119, 123, 124
  - Motion: 131, 133, 135
  - Theme: 136, 137, 138, 139, 140, 141, 142
  - Perf: 144, 145, 146, 148, 155
  - Notifications: 163, 164, 167, 168, 169
  - Security: 175
  - Capacitor wiring: 20, 21
  - Cross-system: 15, 17

- 53 new test files; 263 → 316 unit/integration tests passing.
- All lint + typecheck green throughout.
- Workbox precache strategy fixed for NASA layers.
- Wallet crash + deep-link encoding bug + LockScreen phase machine bugs — fixed.

---

## 9. Still Broken or Partially Working

- **Real auth** — server is demo only. (Q 179.)
- **Background sync queue** — in-memory, not persistent. (N 158.)
- **Live flight tracking** — visual scaffold only.
- **MediaPipe face mesh** — dep installed, not wired.
- **Y.js multi-device** — dep installed, not migrated.
- **Pinch-to-zoom + two-finger rotate on globe** — not implemented.
- **iOS Live Activity / Android Live Notification** — not implemented.
- **Stripe Issuing virtual cards** — not implemented.
- **eSIM marketplace** — not implemented.
- **Translator overlay** — voice intent recognises "translate to <lang>", but the screen overlay that captures camera + does on-device translation is not built.
- **AR boarding pass scan** — not explored.
- **NFC passport read** — not implemented.

---

## 10. Migration: How the React App Works (for the Flutter agent)

### 10.1 The mental model

Every screen mounts a Zustand-backed view. State lives in 14 stores; each store has a small typed API and is hydrated lazily on first read. Server data is fetched via TanStack React Query with cache invalidation on store mutations. Deterministic feature modules in `src/lib` are pure — they take inputs and return outputs with no IO. They are the heart of the app.

### 10.2 Boot sequence

1. `main.tsx` runs `applyThemePrefs()` to set CSS vars from `globeid:themePrefs`.
2. ServiceWorker registers (Workbox precache + runtime cache).
3. `<App />` mounts, hydrates Zustand stores from `localStorage`.
4. `App.tsx` wires Capacitor `appStateChange` (re-hydrate on foreground) and `appUrlOpen` (deep-link router).
5. React Router sends user to `/` (Home).
6. Home queries summary endpoints (`/insights`, `/score`, `/recommendations`).
7. User can navigate via BottomNav, FAB, or Cmd-K.

### 10.3 Cross-cutting concerns

- **Theme**: CSS vars on `<html>` (`--p7-brand`, etc.) + `data-density`, `data-high-contrast`, `data-reduce-transparency` attrs. Tailwind reads them.
- **Motion**: framer-motion variants from `lib/transitions.ts`. Reduced-motion swaps to opacity-only.
- **Routing**: react-router v6 with lazy routes. Each route wrapped in `<ErrorBoundary>` + `<Suspense fallback={<RouteSkeleton />}>`.
- **Native bridge**: every Capacitor call is wrapped in `lib/nativeBridge.ts` with web fallbacks (so the web build never crashes).

### 10.4 Pure modules to port verbatim (no rewrite needed)

These are deterministic, framework-agnostic, and 1:1 portable to Dart:

```
boardingPass.ts         → Dart, with package:crypto for HMAC-SHA256
mrzParser.ts            → Dart strings + RegExp
airports.ts             → const Map<String, Airport>
airlineBrand.ts         → const Map<String, Gradient>
currencyEngine.ts       → Dart, http for FX
packingList.ts          → Dart pure
visaRequirements.ts     → Dart const Map
groundTransport.ts      → Dart const Map
loungeAccess.ts         → Dart const Map
weatherForecast.ts      → Dart, http for Open-Meteo
travelInsights.ts       → Dart pure
travelHeatmap.ts        → Dart pure
cameraPresets.ts        → Dart pure (math)
starCatalog.ts          → Dart pure
voiceIntents.ts         → Dart with RegExp (mostly drop-in)
achievements.ts         → Dart pure
connectionDetector.ts   → Dart pure
predictiveDeparture.ts  → Dart pure
sheetSnap.ts            → Dart pure
identityTier.ts         → Dart pure
auditLog.ts             → Dart pure
sunPosition.ts          → Dart pure (astronomy)
```

These are the 22 modules that the Flutter agent should port first — they unlock the whole feature surface and have unit tests.

---

## 11. Feature → Flutter Equivalents (1:1 mapping)

| Web stack | Flutter recommendation | Notes |
|---|---|---|
| React 18 + TS | Flutter 3.27+ + Dart 3 | use sound null-safety |
| Vite | flutter build/flutter run | dev: hot reload |
| Tailwind / CSS vars | `ThemeData` + custom `ThemeExtension`s | port `themePrefs.ts` to a `ThemeController` (ChangeNotifier) |
| Zustand | `Riverpod 2.x` (`Notifier`/`AsyncNotifier`) | preferred over Provider/BLoC for store-per-feature parity |
| TanStack React Query | `riverpod_annotation` + `dio` + `freezed` | use `@riverpod future` providers |
| zod | `freezed` + `json_serializable` + custom validators | `dart_mappable` is a fine alternative |
| react-router v6 | `go_router` 14+ | declarative + deep-link friendly |
| framer-motion | `flutter_animate` + native `AnimatedBuilder` + `flutter_hooks` | for spring physics, use `flutter_physics` or rebuild via `SpringSimulation` |
| GSAP | `flutter_animate` | timeline coordinator |
| Lottie | `lottie` package (1.4+) | direct JSON support |
| Rive | `rive` package | first-class on Flutter |
| three + R3F + drei | `flutter_gpu` (experimental) **or** `flutter_3d_controller` (model_viewer alt) | for the Globe, see §11.3 |
| postprocessing (Bloom, etc.) | Custom `Shader` (Impeller fragment shaders) | full pipeline via FragmentProgram |
| leaflet / react-leaflet | `flutter_map` 7+ | OpenStreetMap tiles |
| recharts / visx | `fl_chart` | covers line, bar, pie, heatmap, sparkline |
| framer Drawer / vaul | `draggable_scrollable_sheet` + `SnappingSheet` | port `sheetSnap.ts` to the snap callback |
| cmdk | `flutter_command_palette` (or build with `Autocomplete` + `RawKeyboardListener`) |
| sonner toasts | `another_flushbar` or `toastification` | glass tint + accent achievable |
| react-hook-form | `flutter_form_builder` + `form_builder_validators` |
| i18next | `flutter_localizations` + `intl` + ARB files | full ICU support |
| tesseract.js | `google_mlkit_text_recognition` (preferred) or `flutter_tesseract_ocr` |
| @zxing | `mobile_scanner` (Apple Vision + ML Kit) |
| @capacitor/camera | `camera` package + `image_picker` |
| @capacitor/haptics | `vibration` + `haptic_feedback` |
| @capacitor/local-notifications | `flutter_local_notifications` |
| @capacitor/share | `share_plus` |
| @capacitor/filesystem | `path_provider` + `dart:io` |
| @capacitor/preferences | `shared_preferences` (or `hive` for richer types) |
| @capacitor/network | `connectivity_plus` |
| @capacitor/geolocation | `geolocator` |
| @capacitor/status-bar | `flutter/services.dart` SystemChrome |
| @capacitor/splash-screen | `flutter_native_splash` |
| @capacitor/app appStateChange / appUrlOpen | `WidgetsBindingObserver` (lifecycle) + `app_links` (universal/deep links) |
| @aparajita/capacitor-biometric-auth | `local_auth` |
| @capacitor-community/speech-recognition | `speech_to_text` + `flutter_tts` |
| @mediapipe/tasks-vision | `google_mlkit_face_detection` (and face_mesh fork) |
| jspdf | `pdf` package + `printing` |
| QR encode | `qr_flutter` |
| HMAC + crypto | `crypto` package (built-in) |
| zustand persist (localStorage) | `hive` or `isar` (preferred for perf + queries) |
| idb / dexie | `isar` 3+ |
| yjs CRDT | `flutter_data` + `local_first_storage` (or `automerge_dart` if mature) |
| AR boarding pass | `arcore_flutter_plugin` + `arkit_plugin` |
| NFC passport | `nfc_manager` + custom MRTD parser |
| Stripe Issuing | `flutter_stripe` |
| eSIM | platform channels (no first-class plugin yet) |

### 11.1 Recommended state mgmt

**Riverpod 2 with code-gen (`riverpod_annotation`).** Each Zustand store maps cleanly to a `@riverpod class` `AsyncNotifier`. Persistence via `hive` (per-store box). Hydration via a `@riverpod` `appBoot` provider that awaits all box opens before yielding `child`.

### 11.2 Recommended routing

**`go_router 14+`** with type-safe routes via `go_router_builder`. Maps directly onto react-router v6. Deep-link parser for `globeid://trip/<id>` etc. is a single `redirect` callback.

### 11.3 The Globe (the trickiest piece)

Three options, in order of preference:

1. **Flutter GPU + custom shader** (Impeller). Implement Earth mesh + atmosphere + arcs + stars natively. Highest perf, hardest to write.
2. **`model_viewer_plus`** (WebView under the hood) for the 3D scene only. Lower perf but reuses the existing R3F scene.
3. **Hybrid**: render the globe in a native Skia 2D view by projecting lat/lng → screen with an orthographic projection. Lose true 3D rotation but gain 60→120 fps trivially. Acceptable for a "travel map" view.

For first-pass parity, recommend (3); upgrade to (1) post-MVP.

### 11.4 Recommended Flutter architecture

```
lib/
├── main.dart
├── app/
│   ├── router.dart                  # go_router with all routes
│   ├── theme/                       # ThemeData + extensions
│   └── observers.dart               # lifecycle, audit, telemetry
├── core/
│   ├── nativebridge/                # native_bridge.dart, fallbacks
│   ├── errors/, logging/, storage/
│   └── env/                         # flavors, feature flags
├── data/
│   ├── api/                         # dio client + interceptors
│   ├── models/                      # freezed DTOs (mirror server/zod)
│   └── repositories/                # one repo per server route
├── domain/
│   ├── boarding_pass.dart           # HMAC sign/verify
│   ├── mrz_parser.dart
│   ├── currency_engine.dart
│   ├── packing_list.dart
│   ├── visa_requirements.dart
│   ├── camera_presets.dart
│   ├── travel_heatmap.dart
│   ├── star_catalog.dart
│   ├── voice_intents.dart
│   ├── achievements.dart
│   ├── connection_detector.dart
│   ├── predictive_departure.dart
│   ├── sheet_snap.dart
│   └── … (all pure modules; one Dart file each, with unit tests)
├── features/
│   ├── home/                        # screen + state + widgets
│   ├── wallet/
│   ├── identity/
│   ├── vault/
│   ├── trips/
│   ├── trip_detail/
│   ├── scanner/
│   ├── kiosk/
│   ├── globe/                       # 3D / 2D map view
│   ├── voice/
│   ├── settings/
│   ├── onboarding/
│   ├── lock/
│   ├── command_palette/
│   └── social_feed/
├── widgets/                         # design-system primitives
│   ├── empty_state.dart
│   ├── lazy_image.dart              # CachedNetworkImage + LQIP
│   ├── virtual_list.dart            # ListView.builder is already virtualised
│   ├── pass_card.dart
│   └── …
└── i18n/                            # ARB files
```

---

## 12. Migration Strategy (step-by-step)

> Order matters: each step builds on the one before. The agent should treat each step as a self-contained PR.

### Step 1 — Project scaffold (1 day)

- `flutter create globeid --org io.globeid --platforms=ios,android,web,macos,windows,linux`
- Add core deps: `riverpod`, `riverpod_annotation`, `freezed`, `json_serializable`, `go_router`, `dio`, `hive`, `flutter_animate`, `flutter_local_notifications`, `local_auth`, `speech_to_text`, `mobile_scanner`, `google_mlkit_text_recognition`, `lottie`, `rive`, `share_plus`, `connectivity_plus`, `geolocator`, `path_provider`, `app_links`, `flutter_form_builder`, `intl`, `flutter_localizations`, `crypto`, `qr_flutter`, `pdf`, `printing`, `cached_network_image`, `flutter_map`, `fl_chart`.
- Set up flavors (dev / staging / prod).
- Wire CI: `flutter test`, `flutter analyze`, `flutter build apk --release`, `flutter build ipa --no-codesign`.

### Step 2 — Domain layer port (2 days)

Port the 22 pure modules listed in §10.4. **Each module gets a Dart file + a unit-test file.** Achieve parity on the existing 316 tests (plus or minus boilerplate differences). Use `crypto` for HMAC; `decimal` for currency math.

### Step 3 — Data + storage (1 day)

- Define freezed models for every API response shape (mirror Hono Zod schemas).
- One Hive `box` per persisted store (14 boxes).
- Hydration `appBoot` provider opens all boxes + applies theme prefs.

### Step 4 — Theming (0.5 day)

Port `themePrefs.ts` to a `ThemeController` (`ChangeNotifier` or Riverpod `Notifier`). Implement:
- 8 brand accents + custom HSL slider.
- Auto theme by time-of-day (Timer.periodic 5 min).
- High-contrast / reduce-transparency / density extensions.
- 7 page-transition presets via `flutter_animate`.

### Step 5 — Routing + shell (0.5 day)

- `go_router` with all 25 routes.
- `BottomNav` + `AppBar` shell that swaps content via `ShellRoute`.
- Deep-link redirect for `globeid://...`.

### Step 6 — Design system primitives (1 day)

- Surface, Pill, Pass, Toast (use `another_flushbar` or `toastification`).
- `EmptyState`, `LazyImage` (`CachedNetworkImage` + LQIP placeholder), `VirtualList` (just `ListView.builder`).
- `BottomSheet` with `chooseSnap` integration.
- `CommandPalette` overlay (Cmd-K / Ctrl-K on desktop, gesture on mobile).

### Step 7 — Identity + Vault + Lock (1.5 days)

- `local_auth` for biometric phase machine.
- `flutter_secure_storage` for vault contents.
- Audit log writer.
- Auto-lock controller (`Timer` + `WidgetsBindingObserver` for background timer).
- Identity score sparkline (`fl_chart`).
- Tier badge.

### Step 8 — Scanner (1.5 days)

- `mobile_scanner` for QR.
- `google_mlkit_text_recognition` for MRZ. Port `mrzParser.ts` decoder.
- Edge-detection overlay via `CustomPaint`.
- Auto-capture on steady frame (use `image` package + Sobel filter on a downscaled frame).

### Step 9 — Wallet (1.5 days)

- Boarding-pass model + HMAC sign/verify (`crypto`).
- `PassCard` widget with airline-brand gradient.
- Parallax tilt: `sensors_plus` accelerometer (clamp ±10°).
- QR display (`qr_flutter`) + haptic transitions.
- Receipt PDF (`pdf` + `printing`).

### Step 10 — Trips (2 days)

- Trip planner with reorderable list (`ReorderableListView`).
- Trip detail enrichments (port packing list, weather, visa, lounges, ground transport, budget, tight-connection, predictive-departure).
- Tiptap notes → `flutter_quill` rich-text editor.

### Step 11 — Globe (3 days)

Start with the hybrid 2D Skia approach (§11.3 option 3):
- `CustomPainter` projects lat/lng → screen.
- Arcs as cubic Bezier curves on the sphere projection.
- Star catalog projected as `Points`.
- Travel heatmap as filled circles.
- Day/night terminator via shader.

If time permits, upgrade to Impeller fragment shaders + Flutter GPU.

### Step 12 — AI / intelligence (1 day)

Port the deterministic AI modules + wire to home (`smartSuggestions`, `travelInsights`, `connectionDetector`, `predictiveDeparture`, `achievements`).

### Step 13 — Voice (1 day)

- `speech_to_text` for recognition.
- Port `voiceIntents.ts` regex grammar to Dart (drop-in).
- `flutter_tts` for response speech.
- Wake-word strip + intent parse + suggest pipeline.

### Step 14 — Notifications & reminders (0.5 day)

`flutter_local_notifications` for boarding alarm, leave-for-airport, daily digest, snooze. Port `notificationService.ts`.

### Step 15 — Server (parallel — optional rewrite or keep)

Easiest path: **keep the Hono server**. Flutter consumes it via `dio` + freezed DTOs.

If a rewrite is desired: port to **Dart Frog** or **Serverpod**. Both have first-class Drizzle-equivalent ORMs (or use `drift` directly).

### Step 16 — Final polish (1 day)

- Confetti + scroll tint via `flutter_animate`.
- Pull-to-refresh: `RefreshIndicator`.
- Edge-swipe-back: native iOS, custom on Android.
- Theme parity audit across light/dark/high-contrast.
- Lighthouse-style perf check.

**Estimated total**: 18–20 working days for a single experienced agent.

---

## 13. FLUTTER EXTENSION + FUTURE EXPANSION

The Flutter rewrite unlocks capabilities the React/PWA stack can't hit. Use this section as the "what to build next" roadmap once parity is achieved.

### 13.1 UI / UX upgrades

1. **120 fps Impeller everywhere.** Animations should feel butter-smooth on iPhone 15 Pro, Pixel 9 Pro, S25.
2. **True parallax with sensor fusion.** Combine accelerometer + gyroscope (`sensors_plus`) for realistic depth on PassCard and hero tiles.
3. **Custom paint everywhere.** Replace SVG icon stacks with `CustomPainter` + `Path`s for sharp infinite-scaling icons.
4. **Material You + Cupertino auto-adapt.** Tokens render natively per platform.
5. **Edge-to-edge layouts** with proper notch + dynamic-island handling.
6. **Live Activity / Dynamic Island** integration for the active flight (iOS 16+).
7. **Android 14 predictive back gesture** wired natively.
8. **Wear OS + watchOS companion** apps for the active boarding pass + identity score (Flutter for Wear OS; Swift for watchOS).
9. **Desktop builds**: macOS / Windows / Linux native shells for the GlobeID kiosk.
10. **Adaptive layouts** on tablet / fold / desktop with `LayoutBuilder` + `MediaQuery.sizeOf`.

### 13.2 Animation improvements

1. **Hero transitions** native Flutter — port the React `layoutId` shared-element trick to `Hero` widgets.
2. **Spring physics** with `SpringSimulation` for true momentum-based motion (rather than time-based curves).
3. **Choreography** via `flutter_animate` timelines — coordinate route enter/exit, FAB collapse, banner show in a single timeline.
4. **Rive interactive controllers** as upgrade path for any complex micro-interaction (sign-in success, scanning bumper, achievement burst).
5. **Lottie 6+** with state machines.
6. **Particle systems** native `CustomPaint` (confetti / sparkles).

### 13.3 Performance enhancements

1. **Impeller** by default → no compile-time shader stutter on iOS; consistent 120 fps where the panel supports it.
2. **isolates** for OCR + heavy filters (move tesseract-equivalent into `compute()`).
3. **Native concurrency** for image decode, MRZ parse, HMAC sign.
4. **Smaller bundle** — Flutter app starts at ~9 MB, well below the current Capacitor + WebView footprint.
5. **First-class virtualisation** with `ListView.builder` / `SliverList` (no need for our `VirtualList` shim).
6. **AOT compilation** for production — startup measured in milliseconds.
7. **Built-in gradient + path caching** in Skia/Impeller.

### 13.4 New features Flutter unlocks

1. **AR boarding pass scan** via `arcore_flutter_plugin` / `arkit_plugin`. Point camera at gate sign → live overlay with flight info.
2. **NFC passport read** via `nfc_manager` + custom MRTD parser. Eliminates the OCR fallback for ePassports.
3. **Full Yale BSC star catalog** (~9k stars) shipped as a binary asset — easy with Flutter's asset pipeline.
4. **Mediapipe Face Mesh** for liveness via `google_mlkit_face_detection`. Real selfie liveness check.
5. **Live Activity** for active flight (gate change, boarding-soon, delay).
6. **Stripe Issuing** virtual cards via `flutter_stripe`. Tap-to-pay, Apple Pay, Google Pay.
7. **eSIM provisioning** through native channels (carrier platform APIs).
8. **Background location** with `geolocator` "always" permission for predictive leave-for-airport based on real-time traffic.
9. **CarPlay / Android Auto** — show next-flight + boarding alarm on the head unit.
10. **Spatial audio** via `tone_dart` or platform channels for passenger announcements.
11. **Health integration** — `health` package to track travel-day fitness / sleep.
12. **HomeKit / Google Home** — "Hey Siri / Hey Google, am I packed?" via Intents framework.

### 13.5 Architectural upgrades

1. **Local-first data with `isar` + `automerge_dart`** — true offline-first multi-device sync.
2. **Plugin-based feature flags** with `firebase_remote_config` or `getandi`.
3. **Telemetry** via `sentry_flutter` for crash + performance.
4. **A/B testing harness** with `firebase_remote_config`.
5. **Server-driven UI** via JSON-rendered `flutter_staged` for marketing pages, so the app team can iterate without store releases.
6. **Native widgets** (iOS Widgets + Android App Widgets) for the next-flight card.

### 13.6 Recommended additions beyond current scope

1. **Multi-traveller mode**: family/group identity vault with role-based access (parent reads child's passport).
2. **Insurance claim auto-filer**: tap + claim in 30 s using stored receipts.
3. **Loyalty aggregator**: link FF programs, show tier progress + status-match opportunities.
4. **Cross-trip analytics**: spend per country per category over time, with predictive budget alerts.
5. **Embassy SOS**: GPS + destination → embassy address + emergency phone in 1 tap.
6. **Vaccination passport**: ISO 18013-5 mDL + SMART Health Card.
7. **Group expense splitter**: Splitwise-class flow on shared trips.
8. **Carbon offset purchase**: link CO₂ chart → Gold Standard offset purchase.
9. **In-app eSIM marketplace**: Airalo / Saily affiliate.
10. **Localised dining / activities recommender** built on the deterministic insight engine.

---

## 14. References

- Repo: https://github.com/Devanshisbroke/GlobeID-app-2.0
- BACKLOG.md (in repo) — full 250-item backlog with sprint slice annotations.
- README.md (in repo) — boot-up + dev instructions.
- docs/THREAT_MODEL.md — STRIDE table for the security review.
- PR history (28 → 35) — chronicled increments; every PR has a per-feature checklist.

## 15. Glossary

| Term | Meaning |
|---|---|
| Phase 7 | Current design system (fluid type, motion tokens, `--p7-*` CSS vars) |
| Atmosphere / Paper | Dark / Light theme identifiers |
| Hydration chain | Tiered re-hydrate of stores on cold start + foreground |
| HMAC pass | Boarding pass payload signed with HMAC-SHA256 |
| MRZ | Machine-readable zone on a passport |
| MCT | Minimum connection time (IATA) |
| LQIP | Low-quality image placeholder |
| FSM | Finite state machine (e.g. biometric phase machine) |
| DPR | Device pixel ratio |
| Slice-G | Motion specification for cinematic easing + staggered reveals |
| TravelRecord | Canonical data shape for flights across UI modules |
| Vault audit | Append-only immutable event log of vault accesses |
