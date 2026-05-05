# GlobeID — React → Flutter migration mapping

This document maps every existing TypeScript/React subsystem in
`src/` to its new Dart/Flutter equivalent under `flutter_app/lib/`.

## High-level architecture

| Layer        | React (existing)                | Flutter (new)                                  |
|--------------|----------------------------------|------------------------------------------------|
| State        | Zustand stores (`src/store/*`)  | Riverpod `Notifier` + `FutureProvider`         |
| Persistence  | `localStorage` `globeid:*` keys | `SharedPreferences` `globeid:*` namespace      |
| HTTP         | `fetch` + `apiClient.ts` envelope | `dio` + `ApiClient` envelope                   |
| Routing      | React Router v6                  | `go_router` + `ShellRoute` (5 core tabs)       |
| Theming      | `themePrefs.ts` + Tailwind       | `ThemePrefsController` + Material 3 + tokens   |
| Camera/OCR   | `mediaDevices` + `tesseract.js`  | `mobile_scanner` + `google_mlkit_text_recognition` |
| QR           | `react-qr-code`                  | `qr_flutter`                                   |
| Charts       | `recharts`                       | `fl_chart`                                     |
| Maps         | `react-three-fiber` (3D globe)   | `flutter_map` + OpenStreetMap (2D fallback)    |
| Biometric    | WebAuthn (deferred)              | `local_auth`                                   |
| Notifications| Web Notifications API            | `flutter_local_notifications`                  |
| Voice        | Web Speech API                   | `speech_to_text`                               |

## Routes

| React path                   | Flutter route                        |
|------------------------------|--------------------------------------|
| `/`                          | `/`            → `HomeScreen`        |
| `/identity`                  | `/identity`    → `IdentityScreen`    |
| `/wallet`                    | `/wallet`      → `WalletScreen`      |
| `/travel`                    | `/travel`      → `TravelScreen`      |
| `/services`                  | `/services`    → `ServicesHubScreen` |
| `/services/{hotels,...}`     | `/services/<id>` → 5 sub-screens     |
| `/map`                       | `/map`         → `MapScreen`         |
| `/profile`                   | `/profile`     → `ProfileScreen`     |
| `/kiosk-sim`                 | `/kiosk-sim`   → `KioskScreen`       |
| `/receipt`                   | `/receipt`     → `ReceiptScreen`     |
| `/timeline`                  | `/timeline`    → `TimelineScreen`    |
| `/planner`                   | `/planner`     → `PlannerScreen`     |
| `/copilot`                   | `/copilot`     → `CopilotScreen`     |
| `/social`                    | `/social`      → `SocialScreen`      |
| `/explore`                   | `/explore`     → `ExploreScreen`     |
| `/passport-book`             | `/passport-book` → `PassportBookScreen` |
| `/intelligence`              | `/intelligence` → `IntelligenceScreen` |
| `/vault`                     | `/vault`       → `VaultScreen`       |
| `/feed`                      | `/feed`        → `FeedScreen`        |
| `/multi-currency`            | `/multi-currency` → `MultiCurrencyScreen` |
| `/scan`                      | `/scan`        → `ScannerScreen`     |
| `/analytics`                 | `/analytics`   → `AnalyticsScreen`   |
| `/trip/:id`                  | `/trip/:tripId` → `TripDetailScreen` |
| `/lock`                      | `/lock`        → `LockScreen`        |
| `/onboarding`                | `/onboarding`  → `OnboardingScreen`  |

## Stores

| Zustand store               | Riverpod provider                                      |
|-----------------------------|--------------------------------------------------------|
| `userStore`                 | `userProvider` (`UserController` + `UserState`)        |
| `walletStore`               | `walletProvider` (`WalletController` + `WalletStateView`) |
| `lifecycleStore`            | `lifecycleProvider` (`LifecycleController`)            |
| `themePrefs`                | `themePrefsProvider` (`ThemePrefsController`)          |
| `score` (read-only)         | `scoreProvider` (`FutureProvider<TravelScore>`)        |
| `insights` (read-only)      | `travelInsightsProvider`, `walletInsightsProvider`,    |
|                             | `activityInsightsProvider`, `recommendationsProvider`, |
|                             | `alertsProvider`, `loyaltyProvider`, `fraudProvider`,  |
|                             | `budgetProvider`, `contextProvider`                    |

## Domain modules (pure ports)

| TS module                  | Dart port                              |
|----------------------------|----------------------------------------|
| `lib/boardingPass.ts`      | `domain/boarding_pass.dart`            |
| `lib/mrz.ts`               | `domain/mrz_parser.dart`               |
| `lib/airlineBrand.ts`      | `domain/airline_brand.dart`            |
| `lib/airports.ts`          | `domain/airports.dart`                 |
| `lib/auditLog.ts`          | `domain/audit_log.dart`                |
| `lib/connectionDetector.ts`| `domain/connection_detector.dart`      |
| `lib/currencyEngine.ts`    | `domain/currency_engine.dart`          |
| `lib/identityTier.ts`      | `domain/identity_tier.dart`            |
| `lib/packingList.ts`       | `domain/packing_list.dart`             |
| `lib/predictiveDeparture.ts` | `domain/predictive_departure.dart`   |
| `lib/sunPosition.ts`       | `domain/sun_position.dart`             |
| `lib/visaRequirements.ts`  | `domain/visa_requirements.dart`        |
| `lib/voiceIntents.ts`      | `domain/voice_intents.dart`            |

## API client

`src/lib/apiClient.ts` (25 endpoints) → `lib/data/api/globeid_api.dart`
(strongly-typed Dart methods on `GlobeIdApi`, plus an `ApiClient`
wrapper that handles the `{ ok, data | error }` envelope, demo-token
bootstrap, and 401 retry).

## Premium UX upgrades vs the React app

- **PassCard**: parallax tilt via `sensors_plus` accelerometer stream,
  airline-deterministic 3-stop gradient (`AirlineBrand.resolve`),
  glass blur, QR flip with `HapticFeedback.lightImpact`.
- **Hero transitions**: shared-element passes for trip cards
  (`Hero(tag: 'trip-<id>')`) and profile avatar.
- **Frosted bottom nav**: `BackdropFilter` (sigma 24) with morphing
  active indicator and a centered FAB scan button with spring shadow.
- **Spring + staggered reveals** via `flutter_animate`.
- **Reduced-motion / reduced-transparency / high-contrast** via the
  `GlassExtension` theme extension.
- **Edge-to-edge** layouts honoring dynamic island + safe areas.
- **Tabular numerals** on balances, scores, IATA codes via
  `FontFeature.tabularFigures`.

## Build & quality gates

```sh
cd flutter_app
flutter pub get
flutter analyze         # 0 issues
dart format lib/ test/
flutter test            # 6 unit tests pass
flutter run             # mobile (emulator)
```
