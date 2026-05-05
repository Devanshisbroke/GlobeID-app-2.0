# Remaining gaps — Flutter migration

Tracked honestly. The Flutter app compiles, `flutter analyze`
reports 0 issues, and all 25 routes resolve to real screens with
data wired through Riverpod + dio to the existing Hono backend.
The items below are scoped follow-ups, not blockers for the first
flight.

## Core systems still to land

- **Onboarding store hydration** — onboarding is a 4-slide carousel
  but the "completed" flag is not yet persisted, so the lock/onboarding
  router redirect always lets you in. Wire `onboardingProvider` to
  `SharedPreferences` like the other stores.
- **Auto-lock controller** — the React app auto-locks the vault after
  inactivity. `flutter_app` ships `LockScreen` + biometric, but the
  inactivity timer (background → resume → re-auth) needs a
  `WidgetsBindingObserver` controller plumbed from `AppShell`.
- **Deep links** — `globeid://trip/<id>` and `globeid://pass/<code>`
  need an `app_links` listener that pushes to the matching go_router
  path on cold-start *and* warm-start. The route table already
  contains the targets.
- **3D globe** — the React app uses Three.js + R3F. The Flutter port
  ships a 2D `flutter_map` with arcs as a tasteful fallback. A real 3D
  globe would need Skia shaders or a Rive scene; not blocking V1.
- **Biometric face mesh / kiosk simulator** — `KioskScreen` is a
  placeholder. The kiosk camera + face-mesh demo from the React app
  is not yet wired to the Flutter `local_auth` API.
- **Stripe Issuing card** — the dev "issue card" demo in the React app
  is gated on Stripe and is not part of the migration scope.
- **Y.js social sync** — collaborative trip planning via Y.js is not
  available in Flutter; would need a CRDT package. Punted.

## Screen depth

The following secondary screens render pulled data and the
section/empty-state design system, but their feature surface is
intentionally thinner than the React versions for V1:

- `SocialScreen` — empty-state only.
- `IntelligenceScreen` — lists raw insights map; React app has a
  curated "weekly briefing" layout.
- `PassportBookScreen` — grid of stamps; React app has tilt/flip
  animation per stamp (worth porting to a `Hero` + matrix transform).
- `ExploreScreen` / `FeedScreen` — list of items; React has a
  category-rail + pinch-zoom feed.
- Service sub-screens (`hotels/rides/food/activities/transport`)
  share `ServiceListScreen` and need per-vertical bespoke UIs.

## Test coverage

`test/domain_test.dart` covers airline brand resolution, airport
lookup, and identity-tier banding (6 tests). The React app has 316
unit tests across the same domain modules; we should mirror the rest
incrementally, especially:

- `boarding_pass.dart` HMAC sign/verify roundtrip.
- `mrz_parser.dart` TD1/TD3 fixtures + checksum-failure cases.
- `currency_engine.dart` rate snap + conversion edge cases.
- `connection_detector.dart` severity bands.
- `predictive_departure.dart` international + traffic penalty.

## Platform-specific work

- **iOS Info.plist** — needs `NSCameraUsageDescription`,
  `NSMicrophoneUsageDescription`, `NSFaceIDUsageDescription`,
  `NSLocationWhenInUseUsageDescription`. Ships with placeholders
  from `flutter create`; verify before TestFlight.
- **Android manifest** — same: `CAMERA`, `RECORD_AUDIO`,
  `USE_BIOMETRIC`, `ACCESS_FINE_LOCATION`, `INTERNET`. The default
  `flutter create` template covers most.
- **Android NDK** — `mobile_scanner` and `google_mlkit_text_recognition`
  pull in native libraries; first build will download additional
  Android SDK + NDK pieces.

## Performance

- Confirmed `flutter analyze` clean and `flutter test` green.
- Real-device 90/120 Hz testing is pending; Impeller (default on iOS,
  opt-in on Android) should give us flagship-feel motion as long as
  we don't blow the frame budget on parallax + blur on low-end devices.
  We respect `reduceTransparency` and disable blur layers when set.
