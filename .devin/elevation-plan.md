# GlobeID — Premium UI/UX Elevation Plan

**Run scope.** Massive UI/UX elevation, system orchestration, premium
interaction design across the Flutter app under `flutter_app/`. Globe
work deprioritized per the user direction. Goal: take the existing
already-substantial flagship Flutter migration and push it to elite
flagship-software polish — Apple/Google/Figma/Notion/OneUI/luxury-tech
quality.

---

## Audit summary

The Flutter migration is well past skeleton; it has a real production
shape:

- **Surface area.** `flutter_app/lib/` ships **165 Dart files,
  ~59k lines** across 50+ feature folders, 25+ go_router routes, 5
  bottom-nav tabs, full domain layer, demo data, and Riverpod stores.
- **Existing design system.** `app/theme/app_tokens.dart` defines a
  4pt grid, radius ladder, motion durations + curves, 8 brand
  accents, dark/light canvases, elevation ladder; `app_theme.dart`
  builds Material-3 themes with a `GlassExtension` for
  reduce-transparency / high-contrast, density scaling, tabular
  numerals.
- **Existing motion/cinematic infrastructure.**
  `motion/motion.dart` (premium slide+blur transition, haptic
  vocabulary, sound cue stub), `motion/spring_simulation.dart`
  (10 named spring descriptions + `SpringAnimationController`),
  `motion/haptic_choreography.dart` (sequenced impulse patterns:
  `tap`, `open`, `confirm`, `error`, `scrub`, `celebrate`, `warning`,
  `snap`, `reveal`, `scanSuccess`, `pourTick`),
  `motion/creative_motion.dart` (confetti, animated counter,
  breathing glow, scroll tint).
- **Existing premium widget vocabulary.** `HolographicFoil`,
  `TiltShimmer`, `DepthCard` (sensor-driven), `Tilt3D`,
  `IdleDriftTilt`, `PremiumCard` (3 factories), `GlassSurface`,
  `PillChip`, `CinematicButton`, `GlassButton`, `Pressable`,
  `CinematicHero`, `JourneyStrip`, `SectionHeader`, `Sparkline`,
  `AtmosphereLayer`, `AuroraLayer`, `PullDownSummoner`,
  `ScanOverlay`, `ConfettiOverlay`, `Skeletons`,
  `AnimatedAppearance`, `AnimatedNumber`, `AnimatedBlob`,
  `Starfield`, `GradientText`, `LoadingDots`, `Toast`.
- **Existing sensor layer.** `core/sensor_fusion.dart` —
  battery-aware singleton with reference-counted accelerometer
  acquisition, smoothed `tiltX`/`tiltY` with ±10° clamp.
- **Existing screens.** Wallet (1215 lines, 3D pass stack with
  fan-out + sensor tilt), Identity (1298 lines), Boarding pass live
  (1056 lines, holographic, flip QR, brightness ramp), Airport (478
  lines + 472-line orchestrator), Passport book (773 lines), Hotels /
  Flights / Restaurants detail (1025+ / 1337+ / 718+ lines),
  Super-services (2365 lines).
- **Baseline status (Flutter 3.41.9 / Dart 3.11.5).**
  `flutter analyze` = **9 issues** (1 error, 1 warning, 7 infos —
  introduced by SDK upgrade); `flutter test` = **13 pass / 3 fail**
  (3 voice-intent assertions). These are the pre-existing baseline
  we'll clean up first.

The existing app already has a strong cinematic foundation. The
elevation we run will not replace it — it will **deepen** it: more
sensor-driven micro-interactions, more spatial depth, more emotional
color, more contextual orchestration, more cinematic transitions,
more screens that genuinely feel alive.

---

## Design language synthesis

From the architecture, handoff, and existing widgets, the GlobeID
design language can be summarised as:

1. **Deterministic-first.** No LLM, no random output. Every "smart"
   surface is a pure function over local state.
2. **Layered glass over deep canvas.** `canvasDark 0x05060A` →
   `surfaceDark 0x0B0F1A` → `cardDark 0x111827` with 24σ blur on
   cards. Light theme is `0xFFF6F7FB` canvas, white cards with 0.6px
   hairline.
3. **Motion as a first-class primitive.** Every interaction has a
   spring description, a haptic sequence, and a sound cue — even
   when the cue is muted today.
4. **Reduce-motion / reduce-transparency / high-contrast are
   first-class.** Every animation site already checks
   `MediaQuery.disableAnimations` or the in-app override.
5. **Tabular numerals everywhere balances/scores/IATA codes appear.**
6. **Edge-to-edge, dynamic-island-aware, with a frosted floating
   bottom nav and a centered FAB scan.**
7. **Sensor-reactive surfaces** (passes, foil, depth cards) over a
   shared `SensorFusion` singleton with reference counting so the
   accelerometer is off when nothing needs it.
8. **One haptic vocabulary** across the app — never call
   `HapticFeedback` directly outside `Haptics` / `HapticPatterns`.

The elevation work below extends each of these axes without
breaking any.

---

## Execution plan — 50 major tasks

Tasks are grouped into **waves** so we can ship-as-we-go and so
`flutter analyze` stays green between waves. Each task lands real
code (no placeholders) and is wired into a real call site.

### Wave 0 — Baseline hygiene (must land first)

1. **Clean `flutter analyze`** — fix the 9 issues in
   `motion/spring_simulation.dart`, `cinematic/document_substrate.dart`,
   `features/airport/airport_orchestrator.dart`,
   `features/arrival/local_mode_sheet.dart`,
   `features/identity/score_explainer_sheet.dart` (deprecation, unused
   `dart:ui` imports, missing `@override`, override signature mismatch,
   unused field, prefer-final-fields).
2. **Green `flutter test`** — fix the 3 voice-intent assertions
   (numbered trips, place+date compose, translate target) that
   regressed against the current parser. Strict no-cheat: fix the
   parser, not the test, unless the test is wrong.

### Wave 1 — Premium motion / sensor / haptics / surface foundation

3. **`MagneticPressable`** — pressable that pulls toward the touch
   point with spring physics; combines press scale, tilt, and a
   subtle parallax.  Used by primary CTAs, FABs, hero cards.
4. **`MagneticButton`** — flagship CTA built on `MagneticPressable`
   with adaptive gradient sheen, glow halo that breathes when
   focused, optional ripple-from-tap-point, integrated haptic
   `confirm` sequence.
5. **`KineticCardStack`** — generic stacked-pass scroller with
   peek depth, drag-cycle, fan-out, sensor-driven parallax,
   spring-snap. Replaces the inline `_PassStack` so it can be reused
   for identity credentials, trip stack, and concierge cards.
6. **`AmbientLightingLayer`** — time-of-day-aware tint over the app
   shell (predawn/dawn/morning/midday/golden/dusk/night) with a
   `SunPosition` integration so the canvas feels like it's lit by
   the user's actual local sun. Subscribes to `LifecycleProvider` so
   it warms on `active` trip stage.
7. **`EmotionalPalette` engine** — extend `app/theme/emotional_palette.dart`
   into a typed emotion → palette engine (`focus`, `calm`, `urgent`,
   `celebrate`, `warning`, `concierge`, `night`) so any screen can
   ask for `emotion: TripStage.boarding` and get a coherent gradient
   triad.
8. **`SensorPendulum`** — wrap any child in a gyroscope-driven
   pendulum motion that lazily idles when no motion is detected.
   Used by passport hero, identity card, trophy badges.
9. **`DepartureBoardFlap`** — Solari-board character flap animation
   (the airport split-flap board) for flight numbers, gate codes,
   IATA, prices, balances. Sensor-aware (tilts slightly with phone).
10. **`AirportFontStack`** — typography presets that reuse Inter
    but apply IATA / runway / clock-style spacing for hero numbers.
11. **`ContextualSurface`** — a contextual sheet that morphs its
    shape, tint, and elevation based on the surrounding scroll
    velocity, the active trip stage, and time-of-day.
12. **`CinematicRouteHero`** — shared-element hero ribbon system that
    connects two surfaces across a navigation push (e.g. wallet
    pass → boarding live, identity card → passport book).
13. **`SpatialDepthLayer`** — Z-depth simulator that takes a list of
    children and applies parallax-driven offset/scale based on
    accelerometer + scroll position. Used on home, wallet, identity,
    services hub heroes.
14. **`AdaptiveDensity`** — runtime density scaler that responds
    to viewport height *and* user density preference, so Pixel 6a
    and iPhone 16 Pro Max both render the wallet PassStack at the
    right relative scale.
15. **`PremiumLoadingSequence`** — cinematic global loading: arc
    sweep, soft glow rise, breathing dots, shimmer settle. Replaces
    the bare `CircularProgressIndicator` calls in wallet, identity,
    home loading states.
16. **`LiquidWaveSurface`** — animated liquid wave layer for the
    multi-currency conversion screen and the wallet balance hero.
17. **`HapticChoreography` (extend)** — add `magneticSnap`,
    `boardingPulse`, `paymentSwipe`, `arrivalChime`, `gatePing`,
    `passportSeal`, `currencyPourEnd`, `kioskScan` patterns.

### Wave 2 — Wallet UX redesign

18. **Wallet hero refresh** — replace the inline title row with a
    breathing balance hero: total balance in `DepartureBoardFlap`
    digits, last-7-day spend sparkline, accent-driven aurora wash,
    sensor-reactive depth tilt, `LiquidWaveSurface` ambient.
19. **`PassStack` upgrade** — extract the inline `_PassStack` into
    `KineticCardStack`, swap to spring-physics page snapping, add
    layered backdrop reflection per active card, add a "fan out
    (long-press)" overlay that re-uses the new
    `SpatialDepthLayer`.
20. **PassDetail elevation** — add `HolographicFoil` at higher
    intensity around the QR, integrate `DepartureBoardFlap` for the
    seat / gate / boarding-zone fields, add a brightness ramp veil
    that auto-engages when the QR side is shown for ≥ 2 seconds, add
    `passportSeal` haptic on secure-copy success.
21. **`MultiCurrency` premium flow** — `LiquidWaveSurface` between
    source and target balances during conversion, magnetic CTA,
    haptic `currencyPourEnd` on settle, `DepartureBoardFlap` for the
    converted amount.
22. **Wallet FX ticker** — convert the static row into a horizontal
    auto-scrolling marquee with magnetic peeks on hover/press,
    sensor-tilt parallax.

### Wave 3 — Identity / passport UX redesign

23. **Identity hero refresh** — score becomes a `DepartureBoardFlap`
    counter with concentric breathing rings keyed to tier; tier
    badge gets a `HolographicFoil` overlay scaled by tier (Standard
    → Plus → Elite → Premier).
24. **Identity systems grid** — replace the static 6-tile grid with
    a `KineticCardStack` of glanceable cards that each respond to
    sensor tilt and emit emotional color from the trip stage.
25. **Credentials gallery** — port the React tilt/flip per-stamp
    animation noted in `REMAINING_GAPS.md`; each credential becomes
    a `SensorPendulum`-wrapped tile with `HolographicFoil` + metallic
    foil layer.
26. **Passport book** — the existing `passport_book_screen.dart` (773
    lines) is upgraded with `MetallicReflectionLayer`, ambient page
    crinkle, sensor-driven page-edge shadow, and a stamp arrival
    animation that uses `HapticPatterns.passportSeal`.
27. **Passport live screen** — sensor-driven foil shimmer is already
    present; add `AmbientLightingLayer` so the cover tone shifts
    with time-of-day, add a `SpatialDepthLayer`-based emboss on the
    coat-of-arms, integrate Departure-board for issue/expiry dates.

### Wave 4 — Travel lifecycle + boarding

28. **Travel lifecycle hero** — top of `travel_screen.dart` becomes a
    `CinematicRouteHero` that ribbons through Plan → Pack → Travel →
    At Gate → In Flight → Arrived → Reflect, each stage with its own
    `EmotionalPalette` and ambient overlay.
29. **Boarding pass live screen elevation** — wire the existing
    1056-line screen through `EmotionalPalette` (boarding gold
    palette), add the ambient airport sound-cue stub binding, plug
    `DepartureBoardFlap` for the live countdown, plug
    `HapticPatterns.boardingPulse` for the 60s/30s/now alerts.
30. **Trip detail timeline** — premium vertical lifeline using the
    `JourneyStrip` extended into a vertical variant, with `ContextualSurface`
    cards per leg and a `MagneticPressable` boarding-pass button.
31. **`ArrivalWelcomeScreen` cinematic** — first-frame cinematic:
    aurora wash → "Welcome to Tokyo" `DepartureBoardFlap` → contextual
    cards (currency, weather, eSIM, rides) descending with stagger.
32. **PreTripIntel cards** — port the existing `pre_trip_intel.dart`
    cards into `ContextualSurface` with sensor-reactive depth.

### Wave 5 — Airport mode / orchestrator

33. **`AirportScreen` redesign** — wire the boarding lifecycle
    (`Check-in → Security → Lounge → Gate → Board → Depart`) into a
    `CinematicRouteHero` with stage-emotion gradients; add a
    `SpatialDepthLayer`-based terminal-map overlay that responds to
    gyroscope; add `gatePing` haptic when the active stage updates.
34. **`AirportOrchestratorScreen`** — add an ambient sound-stub layer
    (PA chime / runway hum) that fades in around `boarding`; promote
    the orchestrator to use `EmotionalPalette` so the page tints
    differ from departure (cool steel) → boarding (warm gold) →
    in-flight (deep night).
35. **`KioskScreen` elevation** — face-mesh placeholder upgraded to
    a deterministic shimmer scan overlay using
    `HapticPatterns.kioskScan` and a confidence-meter built on
    `DepartureBoardFlap`.

### Wave 6 — Payments / confirmation flow

36. **`PaymentConfirmSheet`** — new bottom-sheet primitive: from any
    pay flow (rides / hotels / food), present a magnetic-CTA confirm
    sheet that uses haptic `paymentSwipe` (light → medium → heavy
    on settle), `LiquidWaveSurface` between charge → success, and a
    final `HapticPatterns.confirm` sequence.
37. **Payments confetti** — wire `ConfettiOverlay` to fire on
    successful payment (in `ride_live_screen.dart`,
    `restaurant_detail_screen.dart`, `hotel_detail_screen.dart`).
38. **`MultiCurrency` premium pour** — already in Wave 2 part 21,
    but add the receipt strip animation.

### Wave 7 — Concierge / copilot / AI surfaces

39. **`CopilotScreen` premium chat surface** — frosted-glass message
    bubbles with `EmotionalPalette` per intent, magnetic send button,
    haptic `tap` on agent reply, `BreathingGlow` on the agent
    avatar.
40. **`AgentActionCard` upgrade** — the existing card becomes a
    `KineticCardStack` entry with `MagneticPressable` confirm
    affordance.
41. **Concierge command surface** — extend `command_palette.dart`
    with a magnetic search field, IntelligentInput placeholder, and
    haptic `scrub` while scrolling results.

### Wave 8 — Services / hotels / flights / eSIM / visa / lounge

42. **Services hub adaptive grid** — replace the existing static grid
    with an `AdaptiveDensity` grid and `ContextualSurface` tiles that
    tint by the user's active trip stage.
43. **Hotel detail premium** — sensor-reactive cover photo with
    `SpatialDepthLayer`, `MagneticButton` for "Book", contextual
    bottom-sheet with `LiquidWaveSurface` price reveal.
44. **Flights screen premium** — `DepartureBoardFlap` on flight
    numbers/times/gates, `EmotionalPalette` for delays/cancellation
    states, magnetic filter chips.
45. **eSIM screen elevation** — frosted plan tiles, `MagneticButton`,
    `BreathingGlow` for active plan, `HapticPatterns.confirm` on
    activation.
46. **Visa requirements card upgrade** — emotional color (green / amber
    / red bands) tied to the new `EmotionalPalette` `urgent` /
    `warning` / `calm` palettes.
47. **Lounge screen** — sensor-reactive lounge photo header,
    `MagneticButton` for entry pass.

### Wave 9 — Notifications / inbox / settings / onboarding / polish

48. **Inbox UX** — group by lifecycle stage, magnetic swipe-to-
    archive, `HapticPatterns.scanSuccess` on action, ambient color
    bar per group.
49. **Onboarding cinematic** — extend the existing 4-slide carousel
    with `AmbientLightingLayer`, `DepartureBoardFlap` on the welcome
    title, and a final `MagneticButton` "Begin" CTA. Persist
    completion (covers `REMAINING_GAPS.md` item #1).
50. **Settings + global polish** — refresh `settings_screen.dart`
    typography rhythm, every cell becomes `MagneticPressable`,
    accent-picker becomes a `KineticCardStack`, every secondary CTA
    moves to `MagneticButton`. Add a `SensorsLab` demo route entry
    that previews every new widget primitive in one place — handy
    for design review.

### Wave 10 — Validation, build, PR

51. `flutter analyze` clean.
52. `flutter test` green.
53. `flutter build apk --release` produces an APK without errors.
54. Create PR with detailed description, summary of waves, before/
    after screenshots if test mode is approved, and CI green.

---

## Performance discipline

- All sensor consumers go through `SensorFusion.acquire/release`.
- All animations clamp to a single `AnimationController` per widget,
  reused across multiple paints; new painter classes implement
  `shouldRepaint` correctly.
- `RepaintBoundary` wraps every multi-layer hero / KineticCardStack
  / DepartureBoardFlap so neighbour repaints don't cascade.
- `BackdropFilter` (24σ) is gated by `GlassExtension.reduceTransparency`.
- `MediaQuery.disableAnimations` short-circuits idle drifts and
  ambient layers; everything keeps a static fallback.
- 120 Hz target: no allocation in tick loops; all gradients live as
  `LinearGradient`/`RadialGradient` static instances or built once
  per layout pass.

## Quality gates

- `flutter analyze` = 0 issues at end of run.
- `flutter test` = green.
- `flutter build apk --release` succeeds.
- Pre-commit hook (`npx lint-staged`) still passes for any TS/JS
  changes that may sneak into the repo.

## Out of scope (this run)

- Real 3D globe (`flutter_map` 2D fallback stays — globe deprioritized
  per user direction).
- Y.js multi-device sync, Stripe Issuing, real OAuth/SSO.
- iOS Info.plist / Android manifest permission descriptions (covered
  by `REMAINING_GAPS.md`, not a UI/UX elevation concern).
- Backend changes — server/ stays untouched.
