# GlobeID — UI/UX Bible

> _An operating system for Earth, worn in your pocket._
>
> This document is the master design vision for GlobeID. It is opinionated, exhaustive, and deliberately ambitious. It defines not only how GlobeID *looks*, but how it *feels*, *moves*, *responds*, *breathes* — and how every surface in the ecosystem connects emotionally to every other.
>
> Read this end-to-end before shipping anything that touches a pixel, a curve, a haptic, or a gradient.

---

## Table of Contents

1. [Manifesto — what GlobeID IS](#1-manifesto--what-globeid-is)
2. [Emotional Spine — the four states GlobeID makes you feel](#2-emotional-spine)
3. [Worldview — the Earth OS metaphor](#3-worldview--the-earth-os-metaphor)
4. [Visual Language](#4-visual-language)
   - 4.1 Color Architecture
   - 4.2 Typography System
   - 4.3 Material System (glass, foil, paper, vellum, metal)
   - 4.4 Lighting Model
   - 4.5 Iconography
   - 4.6 Spacing & Density
5. [Motion System](#5-motion-system)
   - 5.1 Curves
   - 5.2 Choreography
   - 5.3 Transition Library
   - 5.4 Idle / Ambient Motion
6. [Haptic Choreography](#6-haptic-choreography)
7. [Sonic Identity](#7-sonic-identity)
8. [Spatial / Depth / Shader Systems](#8-spatial--depth--shader-systems)
9. [Gesture & Navigation Architecture](#9-gesture--navigation-architecture)
10. [Component Ecosystem](#10-component-ecosystem)
11. [Screen-by-Screen Cinematic Briefs](#11-screen-by-screen-cinematic-briefs)
    - 11.1 Onboarding — _The Awakening_
    - 11.2 Home / Today — _The Living Dashboard_
    - 11.3 Identity / Passport — _The Holographic Document_
    - 11.4 Visa Readiness — _The Diplomatic Lens_
    - 11.5 Wallet — _The Multi-Currency Pour_
    - 11.6 Trip Detail — _The Itinerary Engine_
    - 11.7 Boarding Pass Live — _The Cinematic Gate_
    - 11.8 Globe — _The Cassini View_
    - 11.9 Services — _The Concierge Floor_
    - 11.10 Lounge — _The Velvet Room_
    - 11.11 Arrival / Local Mode — _The Soft Landing_
    - 11.12 Kiosk Sim — _The Border Theatre_
    - 11.13 Lock / Emergency — _The Calm Shield_
    - 11.14 Settings — _The Atelier_
12. [Flagship Interaction Systems](#12-flagship-interaction-systems)
13. [Ambient & Environmental Intelligence](#13-ambient--environmental-intelligence)
14. [Adaptive Density & Accessibility](#14-adaptive-density--accessibility)
15. [Performance Tiers (RenderQuality)](#15-performance-tiers)
16. [The Cinematic Pipeline (production discipline)](#16-the-cinematic-pipeline)
17. [Aspirational R&D — moonshot ideas](#17-aspirational-rd--moonshots)
18. [Anti-Patterns — what GlobeID will never be](#18-anti-patterns)
19. [Glossary of Bespoke Terms](#19-glossary)

---

## 1. Manifesto — what GlobeID IS

GlobeID is not an "app." It is a **handheld embassy**. It is the **passport, the boarding pass, the wallet, the concierge, and the atlas**, all collapsed into a single pane of glass that lives in your pocket.

When you open GlobeID, you are not opening a screen. You are stepping into a **continuum** — a living surface that knows where you are, where you have been, where you are going, what hour it is locally and at home, what your money is doing, what your documents are doing, what your health is doing, and what the planet outside this rectangle is doing right now.

It must feel like:

- the cabin lights of a long-haul flight at 3 a.m. — dimmed, intentional, gentle
- the hush of the duty-free corridor — frictionless, polished, slow
- the click of a stamped passport — a small, satisfying punctuation mark
- the moment a window-seat sunrise hits the wing of your aircraft — earned, awe-shaped, brief
- a museum-grade currency cabinet — every artefact precious, none cluttered
- a Cassini probe's slow orbit — you are not in control of the universe, but you are watching it move

GlobeID is **calm software for restless humans**. It is software for people who cross borders, currencies, languages, and timezones — and need a single object that holds all of that without asking them to think about it.

Every interaction must answer two questions, in this order:

1. **Did this just make travel feel easier?**
2. **Did this just make travel feel more beautiful?**

Anything that fails (1) is shipped as a bug. Anything that fails (2) is shipped as a regret.

---

## 2. Emotional Spine

GlobeID is engineered to make a user feel **exactly one of four emotions** at any given moment, depending on the context. We name them. We design for them. We never accidentally land between them.

| State | Trigger | Visual register | Motion register | Haptic register |
| --- | --- | --- | --- | --- |
| **Stillness** | Idle, lock screen, between trips | Deep midnight gradients, slow orbital motion, sparse UI | Drifts under 4 fps perceived | None, or single pulse on touch |
| **Anticipation** | Pre-trip, packing, visa pending | Warm dusk gradients, gentle glow, countdowns | Slow pendulum oscillations, delayed reveals | Soft tap on tap, tick on slider |
| **Activation** | Boarding, kiosk, scan, payment | High contrast, bold typography, kinetic motion | Snappy springs, percussive transitions | Medium impact on commit, heavy on confirm |
| **Recovery** | Arrival, lounge, journal, recap | Sunlit pastels, ambient particles, golden-hour light | Floaty, exhaling, low-frequency drift | Selection clicks, gentle ticks |

**The emotional spine is non-negotiable.** A boarding-pass screen must NEVER feel like a journal screen. A lock screen must NEVER feel like a wallet screen. We design the *register* first, and the components inherit from the register.

---

## 3. Worldview — the Earth OS Metaphor

GlobeID treats the planet itself as the **root navigation surface**. Every screen in the app sits at some altitude above the globe:

- **Geosynchronous (~36,000 km)** — Globe screen, Cassini orbit, planetary view. Continents are abstract gradients. Cities are pinpricks of light.
- **Stratospheric (~12 km)** — Travel screen, Trip detail. You see flight paths, weather bands, jet-stream arcs.
- **Tower altitude (~300 m)** — Airport mode, boarding pass, kiosk. Architecture matters: gates, jet bridges, runway numbers.
- **Pedestrian (~1.7 m)** — Local mode, lounges, services, restaurants. Materials matter: marble, brass, fabric, neon.
- **Intimate (~30 cm)** — Identity, passport, wallet, vault. Documents matter: paper grain, foil, micro-text, chip contacts.

**Every transition in the app implicitly moves the camera up or down this altitude stack.** Going from the Globe screen to the boarding pass is a *descent*. Returning from the wallet to the home screen is a gentle *climb*. This altitude metaphor governs:

- Which axis transitions slide along (vertical = altitude change, horizontal = lateral journey).
- How much blur the outgoing screen receives (more altitude change = more atmosphere between layers = more blur).
- How fast or slow the transition curves are (high-altitude moves are slower; intimate moves are snappier).

The user never sees this metaphor explained. They feel it.

---

## 4. Visual Language

### 4.1 Color Architecture

GlobeID's palette is **emotional, not branded**. Color is never decorative — it is always a temperature reading.

**Three concentric color systems:**

1. **Substrate palette** — the deep backgrounds, the "atmosphere" the UI floats in.
   - `Midnight Indigo` `#05060A` — root background (lock, globe, deep sleep).
   - `Cabin Charcoal` `#0E1117` — interior surfaces at altitude.
   - `Tarmac Slate` `#161A22` — ground-level screens.
   - `Vellum Bone` `#F4EFE6` — paper-light surfaces (passport, journal).
   - `Snowfield White` `#FBFBFD` — boarding-pass paper, document substrate.

2. **Tone palette** — the contextual accent colors, drawn from the *type of moment* the screen represents.
   - **Identity / passport** — `Diplomatic Garnet` `#7A1D2E`, `Foil Gold` `#B8902B`, `Stamp Ink` `#0B1B3A`.
   - **Wallet / payments** — `Treasury Green` `#0E7A4F`, `Wax Crimson` `#A02B3C`, `Mint Glass` `#7FE3C4`.
   - **Travel / boarding** — `Jet Cyan` `#0EA5E9`, `Aurora Violet` `#7C3AED`, `Runway Amber` `#F59E0B`.
   - **Globe / map** — `Equator Teal` `#10B981`, `Horizon Coral` `#FB7185`, `Polar Blue` `#3B82F6`.
   - **Lounge / arrival** — `Champagne Sand` `#D9C19A`, `Velvet Mauve` `#8B5A6E`, `Honey Amber` `#E0A85B`.

3. **Signal palette** — purely functional, used sparingly.
   - Success `#16A34A` · Warning `#F59E0B` · Error `#DC2626` · Info `#0EA5E9`.

**The rule:** any single screen uses **one substrate, one tone, and at most one signal**. Three colors total. Anything more is a regression.

**Living gradients** — backgrounds are never flat. Every surface uses a *4-stop gradient* with one slowly-animated stop, so the screen breathes. The animation period is 30–90 seconds — too slow to be noticed consciously, but fast enough that a returning glance feels different.

### 4.2 Typography System

Three typefaces, each with a job:

- **`Atlas Grotesk` (display, headlines, hero numerals)** — geometric, slightly humanist, with a custom *travel ligature* set: `LHR→JFK`, `09:42 GMT+1`, `€/¥/$` framed kerning.
- **`Söhne` or equivalent (body, labels, dense data)** — neutral, high legibility, opens up at 13/16/20 px.
- **`Departure Mono` (custom — flight numbers, MRZ lines, gate codes, currency tickers)** — monospaced with a *split-flap variant* used for animated boards.

**Custom variants we maintain:**

- A *MRZ font* tuned to OCR-B but shaped for the screen's pixel grid.
- A *board-flap font* for split-flap-style transitions on numeric / alphabetic changes (gate, time, FX).
- A *handwritten warmth font* for the journal, postcards, and letters home.

**Type as motion** — numerals don't fade or slide when they change. They **flap**, like a Solari board at Frankfurt Hbf. This is GlobeID's most distinctive type behavior and must appear on every screen that displays a changing number (FX, countdown, balance, gate, time).

**Ligature events** — when the app recognises a known travel string (`LHR-JFK`, `EUR/USD`, `UTC+9`), it auto-promotes it to a *ligature* with a custom kerning + tone-tinted underline. This makes raw data feel typographically curated.

### 4.3 Material System

GlobeID renders five distinct **materials**. Every surface is one of these, and they never mix:

1. **Glass (cabin window)** — backdrop blur σ=14, white tint @ 6 % alpha, internal hairline border at 12 % alpha. Used for: nav bar, sheets, modal dialogs.
2. **Foil (passport / loyalty cards)** — gradient sheen that responds to gyroscope tilt; a moving hot-spot tracks the device orientation. Used for: passport bio page, premium cards, identity hero.
3. **Paper (vellum / boarding pass)** — paper-grain noise texture, very subtle drop shadow, 0 px blur. Used for: boarding pass, receipts, journal pages.
4. **Metal (chip / kiosk)** — brushed-aluminum gradient with anisotropic highlight. Used for: chip indicators, kiosk frame, embossed seals.
5. **Atmosphere (sky / globe)** — layered radial gradients with parallax depth. Used for: globe, lock screen, onboarding.

Materials are **physically grounded**: glass blurs what's behind it, paper does not. Foil reflects light, paper absorbs it. Metal reflects sharply, glass diffusely. The user never sees the rule, but they feel its absence when broken.

### 4.4 Lighting Model

GlobeID has a **single virtual light source** per screen, defined by an angle and an intensity.

- Identity / passport: light from upper-left (museum case lighting, 45°, soft).
- Wallet: light from above (treasury vault, 90°, neutral).
- Boarding pass: light from upper-right (airport apron afternoon, 30°, warm).
- Globe: directional sun that follows real-world solar position based on user's local time.
- Lounge: light from lower-left (table lamp, 200°, very warm).

This light source casts:

- A **subtle drop shadow** on raised cards (offset matches the angle).
- A **highlight** on foil materials (specular sweep matches the angle).
- A **gradient bias** on backgrounds (the warm side of the gradient sits opposite the light source).

When the user tilts the device, the light source stays fixed in world-space, so foil highlights *travel across the surface* in real time. This is the difference between an app that feels designed and an app that feels *lit*.

### 4.5 Iconography

Two icon systems, never mixed:

- **`Atlas Line`** — 1.5 px stroke, geometric, monoline. Used for nav, settings, dense lists.
- **`Atlas Solid`** — filled, with a 2 % gradient overlay matched to the screen's tone palette. Used for hero CTAs, confirmation screens, status badges.

Custom glyphs:

- A *boarding pass tear-off* glyph for transit moments.
- A *passport book* with the spine as the active state.
- A *globe with a single longitude line* — the universal "you are here" mark.
- A *currency cabinet* (small drawer) for wallet sections.
- A *velvet rope* for premium / lounge.
- A *kinegram* (animated holographic shape) for verified states.

### 4.6 Spacing & Density

GlobeID uses a **modular 4-px grid** internally, exposed as design tokens at:

- `space1 = 4`, `space2 = 8`, `space3 = 12`, `space4 = 16`, `space5 = 24`, `space6 = 32`, `space7 = 40`, `space8 = 56`, `space9 = 80`.

Three density tiers:

- **Cabin (compact)** — for high-density data (FX board, transactions, kiosk diagnostics).
- **Concourse (standard)** — default. Used everywhere unless a density override applies.
- **Atrium (generous)** — for hero screens, onboarding, lounge, golden-hour moments.

Density is selected by the *emotional register* (see §2), not by the data volume. A wallet at rest uses Atrium; a wallet in mid-transaction collapses to Cabin. The transition between density tiers is animated as a *room change*: spacing tokens interpolate over 360 ms with the standard ease-out-soft curve.

---

## 5. Motion System

### 5.1 Curves

GlobeID uses **five curves**, named like aircraft maneuvers:

- **`takeoff`** `Cubic(0.16, 1.0, 0.30, 1.0)` — ease-out-back-soft. Default entrance.
- **`cruise`** `Curves.easeInOutCubic` — neutral, used for layout shifts.
- **`bank`** `Cubic(0.34, 1.56, 0.64, 1.0)` — over-bouncy, for chip taps and selection.
- **`descent`** `Curves.easeInCubic` — exits, dismissals.
- **`taxi`** `Cubic(0.45, 0.0, 0.55, 1.0)` — settles, used for state collapse.

**No screen uses Material's default `Curves.linear` for anything except progress indicators. Linear is dead motion.**

### 5.2 Choreography

Every screen has a **choreography sheet** — a stagger graph of when each element appears, in what order, with what curve, on what delay.

The default cascade:

- Hero element: 0 ms, `takeoff`.
- Section header: +120 ms, `takeoff`.
- First card: +160 ms, `takeoff`.
- Subsequent cards: +60 ms each (so 6 cards finish entering by ~640 ms).
- Floating chrome (FAB, chip rail): +320 ms, `bank`.
- Background ambient (gradient bloom, particles): +0 ms, but interpolates over 1.6 s.

Motion is **never simultaneous on more than 3 elements at once**. If 8 cards arrive together, they are forced into a 60 ms-spaced stagger — even on slow devices.

### 5.3 Transition Library

Eight named transitions. Routes opt into one explicitly.

1. **`riseTransition`** — slide up 12 %, fade in, scale from 0.94. Used for sheets, secondary screens.
2. **`scaleFromAnchor(anchor)`** — scale from a tapped point. Used for hero card → detail.
3. **`morphTransition`** — cross-fade with concurrent scale-down of exiting page. Used for tab equivalents.
4. **`dropTransition`** — slide down with bounce. Used for notifications, alerts, kiosk overlays.
5. **`blurFadeTransition`** — incoming fades in while background blurs from σ=8→0. Used for modal-grade presentations.
6. **`slideLateralTransition`** — iOS push from right with parallax depth on exit. Used for back-navigable detail flows.
7. **`reducedMotionTransition`** — pure crossfade. Used for accessibility opt-out.
8. **`atmosphericDescent`** — used only for descending the altitude stack (Globe → Travel → Trip → Boarding). Vertical slide + scale + 200 ms blur lens + soft chromatic aberration that resolves on land.

### 5.4 Idle / Ambient Motion

The app is **never still**. When idle:

- Lock screen: orbital sweep on the biometric ring, period 8 s.
- Globe: Cassini auto-rotate, 0.003 rad/tick, with a sine-modulated pitch oscillation period 30 s.
- Home: gradient bloom slowly migrates 30 px diagonally over 60 s, then reverses.
- Boarding pass: barcode breathes (1.2 % brightness oscillation, period 4 s) — borrowed from real Apple Wallet behavior so it scans more reliably under tired retail scanners.
- FX ticker: numbers flap at rate determined by real volatility data; flat markets = slower flaps, crashes = denser flaps.

Ambient motion is the difference between an app that's running and an app that's *alive*. We never disable it without a reduced-motion accessibility flag.

---

## 6. Haptic Choreography

Haptics are a **fifth UI channel**, peer to color, type, motion, and sound. Every gesture has a haptic.

| Vocabulary | Pattern | Where |
| --- | --- | --- |
| `tap` | `selectionClick` | Chip taps, tab switches, list item highlight |
| `select` | `selectionClick` | Tab bar, radio, checkbox, picker scrub |
| `press` | `lightImpact` | FAB, primary button, card press |
| `success` | `mediumImpact` | Payment confirmed, scan success, identity verified |
| `warning` | `heavyImpact` | Approaching limit, expiry warning |
| `error` | `heavyImpact` | Decline, scan failure, auth rejection |
| `lock` | `heavyImpact` | Mode lock, biometric gate, session lock engaged |
| `tick` | `selectionClick` | Scrubber detents, value picker, slider |

Special multi-stage haptics:

- **Boarding scan success:** light → medium → heavy, spaced 80 ms — feels like a turnstile latching.
- **Currency conversion confirm:** medium tap synced to the visible coin pour animation, with a final heavy on settle.
- **Identity gate unlock:** soft pulse every 600 ms during the biometric scan, ending in a single heavy on success.
- **Error:** double heavy 120 ms apart — never single, so the user feels it's distinctly negative.

All haptics route through a single `Haptics` engine that can be **muted** by a user preference (Settings → Motion & feel → Reduce haptics). When muted, the equivalent sonic cue takes over (see §7).

---

## 7. Sonic Identity

GlobeID has a **library of 12 audio cues**, all under 800 ms, all custom-composed. Sound is muted by default and opt-in.

- **`tap`** — soft tactile click, hint of brass.
- **`open`** — quick airy whoosh, cabin door opening.
- **`close`** — softer reverse whoosh.
- **`confirm`** — single resonant chime, A6, with a half-second ambient tail.
- **`error`** — descending two-note minor third, F→D.
- **`navigate`** — sub-bass pop with a high tick.
- **`boarding`** — three-note major chord arpeggio, used only on boarding pass open.
- **`stamp`** — wet-ink thud, used when a passport stamp is awarded.
- **`arrival`** — distant chime + soft wind, used on arrival mode entry.
- **`unlock`** — single ascending pluck, used on session unlock.
- **`fxtick`** — quiet xylophone note, randomised between 5 nearby pitches, used per FX flap.
- **`emergency`** — low alarm pulse, only on emergency overlay summon.

Sound design rule: GlobeID sounds **never overlap**. If a haptic + sound + transition all fire, the sound is the last one in the queue — it lands *after* the haptic. This sequencing is the difference between a chime that feels musical and a chime that feels rushed.

---

## 8. Spatial / Depth / Shader Systems

### 8.1 Parallax + gyro-reactive surfaces

Every premium card responds to `accelerometer` and `gyroscope` data. Surfaces have *depth slots*:

- `slot 0` — background gradient, parallaxes at 0.05× device tilt.
- `slot 1` — substrate / paper, parallaxes at 0.15×.
- `slot 2` — content (text, numbers, photo), parallaxes at 0.30×.
- `slot 3` — foil sheen / specular highlight, parallaxes at 0.65×.
- `slot 4` — chip / hologram element, parallaxes at 0.85×, almost glued to gravity.

When the user tilts the phone, light moves across foil at slot 3, the photo nudges in slot 2, and the background drifts in slot 0. This produces the "holographic passport" effect — but generalises to wallet cards, boarding passes, lounge passes, and identity badges.

### 8.2 Depth-reactive shaders

Cards have a custom `_HoloFoilShader` that takes the gyroscope tilt vector and produces:

- A **moving hot-spot** of brightness (Gaussian falloff, σ tied to tilt magnitude).
- A **chromatic separation** at the hot-spot edge (R/G/B offset by 0.5 px each in the tilt direction).
- A **rainbow band** for true holograms (wallet premium tier, identity gold tier).

When `RenderQuality.reduced` is active, shaders fall back to a single static gradient. When `RenderQuality.max`, shaders include an additional *normal map* layer that simulates raised foil edges around the chip and crest.

### 8.3 Procedural lighting

The single virtual light source (§4.4) is computed per-frame and shared across all foil/metal materials on screen. It interpolates smoothly when the device orientation changes — no popping. The light's color is biased by:

- Time of day at the user's location (cool morning → warm afternoon → blue evening).
- The screen's emotional register (recovery screens always bias warmer; activation screens always bias whiter).

### 8.4 Atmosphere & particles

Three particle systems, each with strict limits:

- **`stardust`** — 0.3 px points, low density, always-on background for lock/globe. Drifts at 1 px/s.
- **`aurora`** — flowing color bands, used on globe at high render quality only.
- **`papercut`** — falling stamp/ticket fragments, triggered as a celebration burst on boarding success or visa approval.

Particles never exceed 60 active instances at `normal` tier, 120 at `max`, 0 at `reduced`. We measure and enforce this; particles are the easiest place to silently destroy frame budgets.

### 8.5 Liquid transitions

For currency conversions, the wallet uses a **liquid pour animation**:

- Source amount sits at the top of a glass cylinder.
- Tap "Convert" → the source liquid drains *down a curved channel*, tinting from source-currency color to destination-currency color mid-pour.
- The destination cylinder fills with a wave that overshoots, then settles — `bank` curve.
- A final droplet falls from the channel into the destination, with a sound + medium haptic.

This is engineered, not stock. It is one of GlobeID's signature flagship moments.

---

## 9. Gesture & Navigation Architecture

### 9.1 Gesture Vocabulary

- **Tap** — primary action (button, card, list item).
- **Long press** — reveal command palette (anywhere on the home screen FAB).
- **Pull down (from any non-scrolling surface)** — summon a contextual sheet (lock → emergency, identity → biometric, wallet → FX board).
- **Pull up (from bottom sheet handle)** — expand the sheet to full screen.
- **Edge swipe right** — back. Universal, always works.
- **Two-finger pinch (globe screen only)** — zoom altitude.
- **Three-finger swipe down** — capture a screenshot stamped with a GlobeID watermark + timestamp + IATA of current location.
- **Shake** — toggle the dev/debug overlay (debug builds only). In production, shake is reserved for "Something feels off" — opens the help / report sheet.

### 9.2 Navigation Stack

Six bottom-nav tabs (Home, Identity, Wallet, Travel, Services, Map) form the **Shell**. Every other screen pushes onto the shell as a modal-grade or full-screen route, with a transition selected from §5.3.

**The Shell is sacred.** It never disappears mid-flow. Even on the boarding pass screen, where chrome is hidden, the shell underlies — a single edge swipe brings it back.

### 9.3 Deep links

GlobeID accepts 30+ deep-link schemes that map 1:1 to the route table. Every scheme is also a **shareable canonical URL** (a recap, a trip, a boarding pass, a lounge pass) — clicked from a friend, it lands inside the right screen with the right context.

### 9.4 The Command Palette

Long-press the home FAB → a Spotlight-grade overlay rises from the bottom with a fuzzy search across:

- Routes (`Go to wallet`, `Open boarding pass`).
- Actions (`Convert 200 USD to JPY`, `Add a new trip`, `Lock the app`).
- Documents (`Find my Schengen visa`, `Show last receipt`).
- Contacts (`Call consulate Paris`).
- Recent searches.

This is the **power-user spine** of GlobeID. It must be reachable in two interactions from anywhere: long-press → type.

---

## 10. Component Ecosystem

A non-exhaustive map of the named components every screen draws from. Each is documented in code; this section describes their *intent*.

- **`PageScaffold`** — the canonical screen frame: title, subtitle, body, frosted nav, safe area. Every shell screen uses it.
- **`PremiumCard`** — glass surface with hairline border, radius `2xl`, 4-stop ambient gradient.
- **`Pressable`** — every tappable surface. Built-in scale-on-press (0.985), haptic, and ripple. **No raw `GestureDetector` ever.**
- **`CinematicButton`** — primary CTA. Gradient, icon, label, optional shimmer. Used for hero actions only.
- **`MagneticButton`** — secondary CTA with a subtle attraction-to-finger effect when nearby.
- **`AnimatedAppearance`** — the staggered entrance wrapper. Default delay set by section position.
- **`SectionHeader`** — section heading. Two density modes (default + dense).
- **`PremiumHud`** — the floating glass pill used as an in-screen heads-up display (active flight, active currency, active gate).
- **`DepartureBoardText`** — split-flap animated text.
- **`AnimatedNumber`** — currency / counter animation with comma grouping and decimal preservation.
- **`Sparkline` / `PremiumSparkline`** — 60-point series with gradient stroke and shadow.
- **`PremiumPulseStrip`** — horizontal context strip (like Apple's Now Playing strip).
- **`PremiumInfoRail`** — vertical context bar for hero screens.
- **`CredentialGallery3D`** — passport/visa/loyalty cards stacked with z-axis depth, swipe-through.
- **`KineticCardStack`** — secondary cards behind a primary, gentle parallax on tilt.
- **`LiquidWaveSurface`** — the pour-channel surface used in wallet conversions.
- **`AmbientLightingLayer`** — the screen-wide soft bloom backdrop.
- **`ContextualSurface`** — content surface that adapts opacity and blur to current emotional register.
- **`SensorPendulum`** — gyro-driven pendulum used in onboarding and hotel galleries.
- **`SpatialDepth`** — wraps a child in a multi-slot parallax stack.
- **`PremiumLoadingSequence`** — the standard loading animation: orbital ring, soft glow, optional caption.
- **`Tilt3D`** — gyro-tilt wrapper for hero cards.
- **`AnimatedBlob`** — morphing organic backdrop.
- **`GlowPulse`** — pulsing halo for active states.
- **`GradientText`** — masked gradient text for hero numerals.
- **`LoadingDots`** — minimal three-dot loader.
- **`DocumentSubstrate`** — guilloché + microtext + paper grain background for documents.
- **`GlobeInteractionOverlay`** — globe HUD (time scrubber, layer toggle, city tap target).
- **`GlobeCameraController`** — Cassini camera with auto-rotate, fly-to, momentum.
- **`PullDownSummoner`** — vertical pull-down gesture wrapper that summons a contextual sheet.
- **`VoiceCommandOrb`** — floating bottom-left orb that summons voice mode.
- **`PaymentConfirmSheet`** — the canonical payment confirmation modal.
- **`AgentActionCard`** — copilot recent-moves card.
- **`PreTripIntel`** — destination intelligence sections (visa, currency, weather, customs).
- **`LocalModeSheet`** — arrival mode bottom sheet.
- **`TravelRecapCard`** — social feed recap card.
- **`WeeklyDigestCard`** — social feed weekly digest.
- **`AppToast`** — branded toast (top-anchored, glass, with icon).
- **`PremiumSheet`** — magnetic bottom sheet that responds to pull-distance.

The component ecosystem is a **closed set**. Adding a new component is a *design event*, not a *coding event* — it requires a written brief, a visual reference, a motion sketch, and a haptic plan.

---

## 11. Screen-by-Screen Cinematic Briefs

Each brief describes the screen's **emotional register, hero moment, motion choreography, sonic cue, and signature interaction**. Read this section like a director's notebook.

### 11.1 Onboarding — _The Awakening_

**Register:** Stillness → Anticipation.

**Hero moment:** A slowly rotating gyroscope-aware globe hovers above the user's name field. As they type their name, characters drift in from the upper-left like meteors entering atmosphere, settling into typed letters with a `bank` curve.

**Choreography:** Five chapters, each a full-screen slide:
1. _Welcome_ — globe appears, parallax-tilt enabled.
2. _Identity_ — passport book emerges from below, opens to the bio page, awaits photo capture.
3. _Wallet_ — currency cabinet drawer slides open, user picks home currency.
4. _Permissions_ — three glass plates rise (location, biometric, notifications); each tap dims its plate and lights up the next.
5. _Departure_ — transitions to home with `atmosphericDescent`, simulating a landing into the dashboard.

**Sonic cue:** The globe hums a soft subbass during the entire flow; each chapter ends with a single `confirm` chime.

**Signature interaction:** Tilting the phone tilts the floating globe. The photo capture in chapter 2 uses gyroscope-stabilised live preview that *only* unlocks the shutter when the device is held within 3° of vertical for 700 ms. This is the difference between "selfie capture" and "passport photo capture."

### 11.2 Home / Today — _The Living Dashboard_

**Register:** Stillness with bursts of Anticipation.

**Hero moment:** A `_GreetingHeader` greets the user with their first name, time-of-day-aware copy, and an avatar that glows when a notification waits. To the right, a `PremiumHud` pill displays *the single most relevant context*: next flight, current city, or last received payment — chosen by a deterministic priority function.

**Choreography:**
- Greeting drops in.
- Today's flight card flips into view with split-flap animation.
- Wallet runway strip (FX + balance) flows in from the right.
- Trip cards stagger in below.
- Floating concierge orb pulses softly bottom-right.

**Signature interaction:** Long-press the FAB to summon the **Command Palette** (§9.4). Pull-down on any non-scrolling area summons the **agentic chip rail** with three contextual actions ("Open boarding pass," "Convert €200 → ¥," "Plan dinner in Tokyo").

**Living detail:** The greeting copy rotates daily through a curated voice library — never robotic, never random. A travel writer wrote 90 days of variants. We expand this every quarter.

### 11.3 Identity / Passport — _The Holographic Document_

**Register:** Intimate Stillness.

**Hero moment:** Passport book appears closed, embossed crest centered, foil text catching light. A long-press opens it with a **page-turn animation** — the cover rotates around its spine, the bio page is revealed underneath the leather.

**Choreography:**
- Tap → cover lifts 4° (foil sheen sweeps).
- Hold → cover continues to 25°, MRZ shimmer activates.
- Release at <25° → snap closed.
- Release at ≥25° → open all the way, reveal bio page with `riseTransition` of MRZ data.

**Signature interaction:** While the bio page is open, **gyroscope tilt drives**:
- Foil hologram movement (§8.2).
- Page slight curl on edges (vertices displaced by tilt magnitude).
- Photo parallax in slot 2 (§8.1).
- Light source movement on the embossed crest.

Pages 2+ are stamp pages. Each stamp is rendered at slightly different rotation, with paper-grain background (`DocumentSubstrate`), and an audible *thump* when first revealed.

**Visa drawer:** Below the passport, a horizontal gallery of visa cards (`CredentialGallery3D`) stacks with z-depth. Tapping a visa expands it in `scaleFromAnchor` and reveals readiness ring, expiry, embassy contact, and a "Begin renewal" CTA.

### 11.4 Visa Readiness — _The Diplomatic Lens_

**Register:** Anticipation.

**Hero moment:** A circular readiness ring fills as the user completes prerequisites (photo, application form, embassy appointment, fee paid). The ring is split into colored arcs per requirement, each arc breathing slowly until completed; on completion, the arc *settles* with a confirmation chime.

**Signature interaction:** Tilting the phone reveals "consular shadows" — translated text behind the ring fades in/out as if backlit by a moving lamp. This is theatrical, never required for function.

### 11.5 Wallet — _The Multi-Currency Pour_

**Register:** Activation, briefly Recovery on settle.

**Hero moment:** Five glass cylinders, each holding a different currency, lined up like decanters on a shelf. Each cylinder fills proportionally to the balance held. The active cylinder glows.

**Signature interaction:** Drag from one cylinder to another to convert. As the finger drags, the source liquid *follows the finger* along a curved channel; the destination cylinder fills with a wave that overshoots and settles. FX rate is shown live above the channel in `Departure Mono`. Releasing the drag commits the conversion with `success` haptic + `confirm` chime.

**Choreography:**
- Cylinders enter staggered from the left.
- Sparkline of last 30 days appears below.
- "Send / Receive / Convert / Scan" hero buttons rise from the bottom.
- Recent transactions list flows below.

### 11.6 Trip Detail — _The Itinerary Engine_

**Register:** Anticipation.

**Hero moment:** A vertical timeline of legs, each with a flight callsign board, gate, and time. The first upcoming leg is *raised* on the z-axis, slightly larger, with active foil sheen.

**Sub-sections:**
- Currency card — destination FX with sparkline.
- Timezone card — origin/destination clock pair with offset pill.
- Pre-trip intel — visa, weather, vaccine, customs, etiquette.
- Ground operations — hotel, transfer, lounge, eSIM.
- Wallet sandbox — projected spending in destination currency.
- Packing list — checklist with weather-aware suggestions.

**Signature interaction:** Tap the active leg → expands into a **boarding pass live screen** with `atmosphericDescent`.

### 11.7 Boarding Pass Live — _The Cinematic Gate_

**Register:** Activation.

**Hero moment:** A boarding pass occupies the entire screen, paper material, foil airline logo upper-left, departure board fonts for flight number and gate. The barcode glows softly and *breathes* (§5.4).

**Brightness boost:** Tapping the barcode triggers an instant **screen-brightness override** + a white scrim — simulating Apple Wallet's scanner-friendly mode. Tap again to exit.

**Pull-down to dismiss:** A vertical drag downward shrinks the pass and dims the brand backdrop proportionally; release past 140 px commits dismiss with `descent` curve.

**Foil + tilt:** Same gyro-reactive foil as the passport. The airline logo and gate code catch light as the device moves.

**Sonic:** On open, a single `boarding` chord arpeggio. On dismiss, soft `close` whoosh.

### 11.8 Globe — _The Cassini View_

**Register:** Stillness with bursts of Anticipation when a destination is tapped.

**Hero moment:** A 3D-rendered Earth slowly rotates with realistic terminator (day/night line driven by user's local time). Major cities appear as pinpricks of light, brighter on the night side.

**Camera:** Driven by `GlobeCameraController` — auto-rotate when idle, fly-to on city tap with a smooth orbital arc. Pinch zooms altitude.

**Layers:** Toggleable via `GlobeInteractionOverlay`:
- Air corridors (live flight paths).
- Currency strength heatmap.
- Weather bands.
- Friend pins (social).
- News pulse (geopolitical events).

**Signature interaction:** Tapping a city flies the camera there, then surfaces a **city info card** (local time, weather, tone, "Explore" CTA) that slides in from the bottom.

### 11.9 Services — _The Concierge Floor_

**Register:** Anticipation.

**Hero moment:** A grid of square service tiles (Hotels, Food, Transport, Activities, Lounge, Airport, Visa, Trip wallet). Each tile is a glass surface with a tone-tinted gradient and an `Atlas Solid` icon.

**Featured rail:** A horizontal scroll of *currently relevant* services chosen by context engine (e.g., if a flight lands in 4 hours, lounge + transfer + eSIM rise to the top).

**Signature interaction:** Long-press a tile → reveal a **mini concierge card** with 3 instant actions ("Reserve a table at 19:30," "Book airport transfer," "Compare 3 hotels"). One-tap commit.

### 11.10 Lounge — _The Velvet Room_

**Register:** Recovery.

**Hero moment:** A wide cinematic photograph of the lounge, scrubbable on tilt (slot 2 parallax). Below: a circular *capacity meter* showing crowdedness in real time, gradient from green to amber to red.

**Sub-sections:**
- Hours, location, walking time from current gate.
- Amenities (showers, dining, sleep pods, working booths) as a chip rail.
- A *sensory rating* card: noise level, lighting tone, seating density. This is GlobeID-original — no other travel app rates lounges this way.

**Signature interaction:** Pull-down to summon a "Reserve a sleep pod" sheet with gyro-tilt-reactive image of the pod.

### 11.11 Arrival / Local Mode — _The Soft Landing_

**Register:** Recovery.

**Hero moment:** A welcome card with the destination flag, city name in `Atlas Grotesk Display`, and the local time spelled out warmly ("Dusk in Tokyo · 19:42 JST"). Backdrop is a slow gradient drawn from the destination tone palette.

**Choreography:** Soft chime on entry. Three CTAs cascade in:
1. Open Travel OS (full local context).
2. Browse local mode (LocalModeSheet — district guides, neighborhoods).
3. Open boarding-pass-as-souvenir (the just-completed flight is preserved as a stamped artifact).

**Signature interaction:** A single tap on the welcome card spawns a **paper plane animation** that flies across the screen and disappears into the next leg or "Plan something" CTA.

### 11.12 Kiosk Sim — _The Border Theatre_

**Register:** Activation.

**Hero moment:** A simulated airport kiosk frame fills the screen. A `DepartureBoardText` displays "GATE STATUS · IDLE" → "SCANNING" → "VERIFIED." Live sparkline below shows scan confidence.

**Choreography:**
- Tap "Begin scan" → kiosk light goes amber, biometric ring pulses.
- Hold the front camera up to the user → ring fills; on completion, light goes green, board flaps to "VERIFIED," fireworks of `papercut` particles burst.
- Failed scan → board flaps to "RETRY," ring shakes laterally with `error` haptic.

**Sonic:** Real airport beep on scan start, real chime on success, soft alarm on failure. We licensed (or cleanly recreated) airport audio for these.

### 11.13 Lock / Emergency — _The Calm Shield_

**Register:** Stillness, with one Activation path.

**Hero moment:** Centered biometric ring orbiting a faint "GlobeID" wordmark. Backdrop is `Midnight Indigo` with a soft radial bloom in the device's accent color.

**Pull-down summon:** Pulling the screen down ≥96 px summons the **Emergency overlay** — a tone-gradient sheet with two CTAs: "Call consulate" and "Share location." This is the only place in the app where a heavy haptic fires from a passive surface — because the user *needs* to feel it land.

**Signature interaction:** Once unlocked, the ring *constructs* into the home greeting via a sweep animation: the orbit becomes a horizontal motion vector that carries you forward into the dashboard. Lock and unlock are a single continuous experience.

### 11.14 Settings — _The Atelier_

**Register:** Stillness.

**Hero moment:** A vertical list of dense rows, no decoration except the row icons. The Atelier is GlobeID's *calmest* screen — no animation, no ambient motion, no foil. It is the only screen where the user is *behind the curtain.*

**Sub-sections:** Appearance (theme, accent, density, motion, **render quality**), Notifications, Privacy, Connected services, Travel preferences, Wallet preferences, Identity vault, Security, About.

**Signature interaction:** Tapping a section pushes a sub-screen with `slideLateralTransition` (iOS-classic). No flair. Settings is the one place we let the OS feel like an OS.

---

## 12. Flagship Interaction Systems

These are the 12 set-piece interactions that define GlobeID. Each must be production-quality, signed off by design, and feature-flagged so we can A/B-test variants without breaking the rest of the ecosystem.

### 12.1 The Holographic Passport
Already described in §11.3. Combines gyroscope, accelerometer, foil shader, page curl, MRZ shimmer, and audio thud. The single most reproduced GIF of GlobeID.

### 12.2 The Liquid Currency Pour
§5/§11.5. The wallet conversion flow is GlobeID's "Apple Pay moment."

### 12.3 The Cassini Globe Fly-To
§11.8. Smooth orbital arc to a city tap, with `atmosphericDescent` chaining into the city info sheet.

### 12.4 The Kiosk Theatre
§11.12. Departure board flaps + biometric ring + airport audio.

### 12.5 The Cinematic Boarding Pass
§11.7. Brightness override, breathing barcode, pull-down dismiss, foil tilt.

### 12.6 The Pull-Down Emergency Summon
§11.13. The only passive surface that fires a heavy haptic.

### 12.7 The Command Palette
§9.4. Long-press FAB → fuzzy search across the entire ecosystem.

### 12.8 The Voice Orb
A floating glass orb in the bottom-left of every shell route. Tap → enters voice mode with waveform visualisation and on-device transcript. Voice intents resolve to deep links: "open my last receipt," "convert two hundred euros to yen," "what's the weather in Tokyo?"

### 12.9 The Sensory Lounge Profile
§11.10. Crowdedness meter + sensory rating. GlobeID's claim to actually understanding the *texture* of travel, not just the logistics.

### 12.10 The Departure Board Numerals
§4.2 Type-as-motion. Every number that changes flaps. This is GlobeID's most recognised motion signature.

### 12.11 The Trip Recap as Souvenir
After a trip ends, a generated recap card appears in the social feed. It includes:
- Flight callsign board.
- Total distance flown (animated `AnimatedNumber`).
- Currencies used (mini-cylinders).
- Stamps awarded (papercut burst).
- A single hero photo from the trip (auto-selected, tilt-reactive).
- A handwritten typeface caption.

This card is shareable as a deep link. Tapping it from a friend's chat opens GlobeID *into the recap*, with all context intact.

### 12.12 The Gyro-Reactive Globe Lock Screen
The lock screen is not static. The biometric ring orbits a faint globe that responds to the device tilt. Combined with a gyroscope-driven gradient bloom, the lock screen is the most-seen surface and therefore must be the most beautiful.

---

## 13. Ambient & Environmental Intelligence

GlobeID *knows where you are* — and the UI reflects it.

- **Time of day** — gradients warm/cool with local solar position.
- **Altitude** — when the user is on a flight, the home screen subtly desaturates and adopts a "cabin" register (lower brightness, more glass).
- **Network** — when offline, glass becomes more opaque, gradients flatten, and an ambient "satellite-search" particle drift appears top-right.
- **Battery** — under 20 %, the FX ticker calms, ambient particles cap at 30 instances, and any non-essential animation downgrades to `RenderQuality.reduced`.
- **Thermal** — under sustained heat, render profile auto-drops a tier with a soft notification at the top.
- **Weather** — at landing, gentle environmental hints appear on the welcome card (light rain → faint streaks across the photo; sun → warmer gradient bias).
- **Local language** — UI accent text auto-adopts a local greeting on the welcome card.

These are subtle, almost-invisible adjustments. The user does not see "GlobeID is in cabin mode." They feel that the app is *with them*.

---

## 14. Adaptive Density & Accessibility

GlobeID is **WCAG-AA-compliant by default**, with three layered preference systems:

1. **Dynamic Type** — every typography token is a function of the user's text scale (system).
2. **Reduce motion** — disables ambient motion, downgrades transitions to `reducedMotionTransition`, removes departure-board flaps in favor of crossfade.
3. **High contrast** — increases hairline border opacity to 24 %, removes glass blur, biases gradients toward solid colors.
4. **Reduce transparency** — kills glass blur entirely; surfaces become solid with the substrate color.
5. **Reduce haptics** — routes haptics to sonic equivalents.

Every screen is tested with all five preference combinations active. We do not ship a screen that breaks any of them.

---

## 15. Performance Tiers (RenderQuality)

Three render tiers, exposed in Settings → Appearance → Render quality:

- **Reduced** — no blur, no particles, no shaders, single static gradient backgrounds, all transitions become `reducedMotionTransition`. Frame budget: 16.6 ms guaranteed at 60 Hz on a 5-year-old mid-tier device.
- **Normal** (default) — moderate blur (σ=14), 60 active particles max, single-pass shaders, all transitions enabled. Frame budget: 16.6 ms on current-gen mid-tier.
- **Max** — full blur stacks, 120 active particles, multi-pass shaders, optional ProMotion 120 Hz / 90 Hz on supporting devices.

A `PerformanceMonitor` runs in debug to surface FPS and ticker counts. In production, sustained sub-50 FPS auto-drops the tier with a soft notification.

---

## 16. The Cinematic Pipeline

Every flagship interaction follows this pipeline before it ships:

1. **Brief** — a one-page document describing the moment, the emotion, the metaphor.
2. **Reference reel** — a video moodboard of analogous moments from film, automotive HMI, or other apps.
3. **Storyboard** — frame-by-frame sketches of the start, mid, and end states.
4. **Motion sketch** — an After Effects or Rive prototype with timing, curves, and transitions.
5. **Haptic plan** — a document mapping every motion landmark to a haptic event.
6. **Audio plan** — an audio cue plan if applicable.
7. **Implementation** — Flutter implementation with feature-flag.
8. **Polish round** — at least one full pass with the design lead present.
9. **Ship behind a flag** — A/B-test with measured engagement and frame budget.
10. **Document** — entry added to this Bible's appendix.

This pipeline is what separates a flagship moment from "we built it last sprint."

---

## 17. Aspirational R&D — Moonshots

These are the ideas we have NOT shipped — yet. Some are years away. They belong in the Bible because the Bible defines the *direction*, not the current build.

### 17.1 The Spatial Passport (visionOS / spatial AR)
The passport leaves the screen. On a Vision-class device, the passport book hovers in front of the user, full size, foil reactive to head movement, page curl driven by hand pinch. The user "shows" their passport to a virtual immigration counter to demo a future SDK.

### 17.2 The Holographic Boarding Pass (under-glass laser etching)
With on-device near-infrared depth sensing, the boarding pass appears to have a *physical etched layer beneath the surface*. This requires a depth-aware shader that we prototype but do not ship in V1.

### 17.3 The Earth OS Globe (real terrain + real clouds)
The globe upgrades from stylised continents to real terrain (lit Mapbox terrain) + real cloud cover (live satellite). Camera flies between cities along true great-circle routes. Performance budget reserves this for `RenderQuality.max` only, on M-class chips.

### 17.4 The Walk-Through Airport
At the airport, the app overlays a live AR walking guide from the user's location to their gate — using Apple ARKit's room-scale tracking + airport floor-plan partnerships. Glass arrows hover at eye level, fading in based on distance.

### 17.5 The Currency Cabinet Drawer (haptic-only)
Convert via *physical drawer pull* haptics — a long press with Taptic-engine-based "weight" and "click" patterns that simulate pulling open a drawer. Every currency drawer has its own haptic signature.

### 17.6 The Embassy in Your Pocket
A real-time secure video link to consular services for citizens in distress. UI is a single calm room with an empty chair that fills when an officer joins. Background never moves. The most important screen we will ever ship.

### 17.7 The Living Passport Photo
With consent, the user's bio-page photo subtly animates — a shallow 3D head model nods imperceptibly, blinks every 6–10 s, glances toward the device's bezel. This is a *subliminal* effect, not a feature. Either we ship it perfectly or not at all.

### 17.8 The Trip Time Capsule
Years after a trip, the recap card resurfaces on the home screen on the anniversary. The card has aged: the foil is slightly tarnished, the paper has a hint of yellow, the photo grain is heavier. A simple caption: "5 years ago today, you flew Tokyo → Kyoto." Tap → opens the original recap, restored. We do not market this; we let users find it.

### 17.9 The Multi-Device Continuity
GlobeID flows between devices. Open the boarding pass on the phone; raise your wrist, and it lives on the watch. Sit at your tablet; the trip detail expands across the larger canvas. Same animation, same foil, same haptics. The passport is the user, not the device.

### 17.10 The Haptic Locale
Each city has a unique haptic signature on landing. Tokyo: three light taps in rhythm. Paris: two soft + one medium. This is sub-perceptual but cumulative — frequent travelers begin to *recognise cities by feel* before the welcome card appears. Mocked but never shipped without longitudinal user research.

---

## 18. Anti-Patterns

Things GlobeID will **never** do, written down so we can refer back when tempted.

- **Material Design defaults.** No raw `FloatingActionButton`, `BottomNavigationBar`, `AppBar` without our scaffold. Every component is bespoke.
- **`Curves.linear`** for any animation that isn't a progress bar.
- **Native iOS / Android dialogs.** All confirmations route through `PaymentConfirmSheet`, `PremiumSheet`, or `AppToast`.
- **Stock icons.** No raw `Icons.flight`, `Icons.attach_money` without a tone tint and `Atlas Line/Solid` rule.
- **Scroll-bouncing without RefreshIndicator.** If you can pull to refresh, do it; otherwise lock the bounce.
- **Empty `onTap: () {}`.** A button with no handler does not ship.
- **More than one accent color per screen.** §4.1 rule.
- **More than 3 simultaneously animating elements.** §5.2 rule.
- **Skeumorphic photoreal textures.** GlobeID is *cinematic*, not skeumorphic. We render glass; we do not paint glass.
- **AI-generated stock illustrations.** Every illustration is hand-crafted or procedurally rendered.
- **Generic stock photography.** Hero photos are licensed from named photographers or AI-augmented from licensed plates.
- **System-stock typography.** Roboto, San Francisco, and the like are debugging fallbacks only.
- **Toggle switches with default labels.** Every toggle has a contextual subtitle ("Disable backdrop blur in cards"), never just "On/Off."
- **Tooltips.** GlobeID does not explain itself. If a screen needs a tooltip, the screen is wrong.
- **Loading spinners.** We use `PremiumLoadingSequence` or `LoadingDots`. Never the system spinner.
- **Splash screens.** Onboarding *is* the splash screen. Returning users skip it.
- **Force-portrait-only.** GlobeID supports landscape on tablets and adapts (specifically: trip detail and globe expand into split-pane).

---

## 19. Glossary

- **Atrium** — the most generous density tier, used on hero screens and golden-hour moments.
- **Bank** — the over-bouncy curve, used for chip taps and selection.
- **Cabin** — the most compact density tier, used during data-dense moments.
- **Cassini** — the auto-rotating orbital camera mode on the globe.
- **Concourse** — the default density tier.
- **Departure Mono** — GlobeID's monospaced typeface for flight numbers, FX, codes.
- **Earth OS** — the worldview that the planet is the root navigation surface.
- **Foil** — the gyro-reactive specular material used on premium cards.
- **Liquid pour** — the wallet conversion animation.
- **Living gradient** — a 4-stop gradient with one slowly-animated stop.
- **MRZ shimmer** — the foil hot-spot effect on passport machine-readable zones.
- **`papercut`** — celebratory falling-paper particle burst.
- **Pull-down summoner** — gesture that summons a contextual sheet from the top.
- **`riseTransition` / `dropTransition` / `morphTransition`** — named transition library entries.
- **`stardust`** — low-density background particle system.
- **Substrate palette** — the deep-background color system.
- **Takeoff** — the default ease-out-back-soft entrance curve.
- **Tone palette** — the contextual accent palette per screen type.
- **Velvet rope** — the visual marker for premium / lounge access.

---

## Closing — The Pact

This document exists to keep GlobeID **honest.**

Every shipped pixel passes through this Bible. When we are tempted to ship something that "works" but is generic, we open this file. When we are tempted to copy a competitor, we open this file. When the deadline is short and the temptation is to fall back on Material defaults, we open this file.

GlobeID is the first software product where the world's most cinematic operating systems, luxury HMIs, and museum-grade documents are *the baseline*. Everything in here is achievable. Everything in here is what people will remember about GlobeID a decade from now.

Build accordingly.

---

_— The GlobeID Design Council_
