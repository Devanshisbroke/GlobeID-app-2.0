# GlobeID

Travel identity, wallet, and trip companion — a Capacitor-packaged
React app that pairs a verifiable identity layer with a multi-currency
wallet, trip planner, document vault, and a service marketplace.

The stack is a Vite + React 18 + TypeScript frontend, a Fastify-style
TypeScript server in `server/`, and a Capacitor 8 Android shell that
ships the same web bundle inside a WebView.

## Highlights

- **Identity** — verifiable digital passport with QR session linking,
  identity score, kiosk simulator, and a session timeline.
- **Wallet** — Apple-Wallet-style stacked passes (`PassStack`),
  multi-currency balances with on-device FX rates, transaction list,
  and a recharts spending breakdown.
- **Trips** — single-source `TravelRecord` store; trip lifecycles
  (`upcoming` / `active` / `complete`) drive boarding passes, reminders,
  and a Three.js globe arc preview. Boarding passes are signed
  HMAC-SHA256 v1 demo payloads (verified by the bundled
  `KioskSimulator`).
- **Hybrid scanner** — QR via `@zxing/browser`, document OCR via
  Tesseract.js, MRZ parsing, plus an encrypted on-device document vault.
- **Services** — locale-aware service hub with hotels, rides, food,
  activities, transport, and a "Super" services view.
- **Voice** — speech-to-text command bar wired to navigation actions
  via `@capacitor-community/speech-recognition`.
- **Offline-first** — Dexie/IndexedDB-backed sync engine with retryable
  pending mutations on `userStore` and `walletStore`.

## Getting started

```bash
# Node 22 LTS is the development baseline.
nvm use 22

# Install all workspace dependencies (frontend + server).
npm ci

# Start the dev server (Vite on http://localhost:8080).
npm run dev

# Or start the API server.
npm --workspace globeid-server run dev
```

### Quality gates

The repo ships with a strict CI baseline. Each of these must pass before
opening a PR:

```bash
npm run lint        # eslint, --max-warnings=0
npm run typecheck   # tsc --noEmit (frontend + server)
npm test            # vitest run
npm run build       # vite build
```

`husky` + `lint-staged` enforce the same on every commit.

### Capacitor / Android

The release APK is built by the GitHub Actions workflow
`.github/workflows/android-apk.yml`. To reproduce locally:

```bash
npm run build                              # produce dist/
npx cap sync android                       # copy dist/ + plugins
cd android && ./gradlew assembleDebug      # requires Android SDK 36
```

## Project layout

```
src/                    React app (Vite + TS)
  App.tsx               Router + lazy boundaries
  components/
    layout/v2/          AppChromeV2, BottomNavV2, PageTransitionV2
    wallet/             PassStack, PassCard, PassDetail, currency cards
    trip/               QRBoardingPass, TripGlobePreview, ItineraryView
    travel/             TripCard, TripLifecycleBadge
    identity/           DigitalPassport, IdentityScoreCard, kiosk hooks
    services/           local services panel, ride/food/etc surfaces
    ai/                 TravelAssistant + AIAssistantSheet
  screens/              Top-level routes
  store/                Zustand stores (user, wallet, lifecycle, ...)
  lib/                  airports catalog, OCR pipeline, boarding pass HMAC
  i18n/                 i18next bundle (partial coverage)
server/                 TypeScript API + sync targets
shared/                 Schemas + types shared across frontend and server
android/                Capacitor Android shell
```

## Notes

- The boarding-pass QR is **demo-mode only** — verifiable inside
  `KioskSimulator` but never accepted by a real airline gate. The
  amber surface marker on every pass is required by the project's
  "no fake features" rule.
- Flight statuses on the trip detail view are deterministic mock data
  derived from the flight number + scheduled date so reloads stay
  repeatable across sessions.
