# GlobeID — Future Expansion Bible

> *The master roadmap for evolving GlobeID into a civilization-scale universal super-app — the operating system of human movement, identity, and exchange.*

This document is the long-horizon design and engineering charter for GlobeID. It is **not** a sprint plan. It is the canonical reference for every future commit, every new product line, every architectural decision, and every aesthetic instinct. When in doubt about whether something is "in scope" for GlobeID, this file is the answer.

The reader is assumed to already understand:
- The Flutter app at `flutter_app/`
- The TypeScript / Capacitor app at the repo root
- `CODEX_HANDOFF.md`, `ARCHITECTURE.md`, `FLUTTER_HANDOFF.md`, `BACKLOG.md`
- The existing identity, wallet, travel, and globe systems

This file extends those — it does not repeat them.

---

## Table of contents

1. [North star: what GlobeID becomes](#1-north-star)
2. [Civilization-scale design principles](#2-civilization-scale-design-principles)
3. [Identity ecosystem — the human key](#3-identity-ecosystem)
4. [Document & credential systems — hyper-realistic](#4-document--credential-systems)
5. [Wallet & payments — universal value layer](#5-wallet--payments)
6. [Travel ecosystem — the operating system of movement](#6-travel-ecosystem)
7. [Globe system — the cinematic core](#7-globe-system)
8. [Flutter rendering, shaders, physics, and motion](#8-flutter-rendering-shaders-physics-motion)
9. [AGI-style orchestration & on-device intelligence](#9-agi-orchestration)
10. [Sensors, device fusion, and ambient computing](#10-sensors-device-fusion)
11. [Cinematic interaction systems](#11-cinematic-interaction-systems)
12. [Premium onboarding & long-tail lifecycle](#12-premium-onboarding)
13. [Social, community, and the travel graph](#13-social--travel-graph)
14. [Automation & autonomous flows](#14-automation--autonomous-flows)
15. [Airport, airline, and aviation ecosystem](#15-airport-airline-aviation)
16. [Immigration, kiosk, and border ecosystem](#16-immigration-kiosk-border)
17. [Discovery, intelligence, and content surfaces](#17-discovery-intelligence)
18. [Multi-device, wearable, AR, VR, spatial](#18-multi-device-wearable-ar-vr)
19. [Offline intelligence & resilience](#19-offline-intelligence)
20. [Architecture evolution & service mesh](#20-architecture-evolution)
21. [Performance engineering at flagship scale](#21-performance-engineering)
22. [Scalability, sharding, and global infrastructure](#22-scalability--global-infrastructure)
23. [Security, cryptography, and zero-trust](#23-security--cryptography)
24. [Data, privacy, and sovereignty](#24-data-privacy-sovereignty)
25. [Monetization, business model, and ecosystem partners](#25-monetization--business-model)
26. [Super-app orchestration & meta-platforming](#26-super-app-orchestration)
27. [Sci-fi expansion track — civilization-scale concepts](#27-sci-fi-expansion-track)
28. [Phase roadmap: 12 phases, 5+ years](#28-phase-roadmap)
29. [Engineering rituals & culture](#29-engineering-rituals)
30. [Closing manifesto](#30-closing-manifesto)

---

## 1. North star

GlobeID is the **universal operating system for humanity's movement, identity, and exchange**.

It is one app that quietly replaces dozens. It is the layer between a person and the world's institutions — airlines, governments, banks, hotels, telecoms, cities, embassies, marketplaces, and increasingly, agents acting on behalf of those institutions and on behalf of the user.

Three pillars define everything:

1. **You are sovereign.** Your identity, credentials, money, and history live with you. Institutions verify; they do not own.
2. **The world is one stage.** Every flight, every hotel, every transit hop, every payment, every border, every signal — collapses onto a single cinematic surface that feels alive.
3. **Software does the work.** GlobeID's intelligence layer plans, books, settles, defends, recovers, translates, and advocates. The user provides intent; the system executes.

If a feature does not strengthen one of those pillars, it does not belong in GlobeID.

---

## 2. Civilization-scale design principles

These principles override every other design instinct. They are the immune system of GlobeID's quality.

- **Calm at the surface, infinite underneath.** First glance: 1 question, 1 action, 1 status. Second glance: 4 layered surfaces. Tenth glance: hours of explorable depth. Density is earned by attention, not pushed by default.
- **Every pixel routes somewhere.** No dead UI. Every surface is a verb. Every chip, badge, glyph, region of glass leads to another layer.
- **Motion is meaning.** Animations are never decorative. Every transition encodes a relationship — origin, hierarchy, time, importance. If a motion does not communicate, it is removed.
- **Tactile by default.** Haptics, sound, brightness, color, temperature, and weight are first-class. The app is a physical instrument.
- **Trust is rendered, not asserted.** The user sees their data being signed, verified, encrypted. Cryptography is animated and visible.
- **Premium without preciousness.** The app respects the user's time more than its own beauty. If a flagship animation is in the way of completing a task, the task wins.
- **Local-first, cloud-augmented.** Everything works offline. Cloud accelerates, never gates.
- **Scale-invariant.** The same systems work for 1,000 users and 1,000,000,000 users. No design decision reads "fine for now."
- **Open at the seams.** Every subsystem is replaceable. Identity, wallet, travel, intelligence — each can be extracted and embedded into other software.
- **No lock-in.** A user can leave GlobeID with all of their identity, history, and credentials in a single signed export. The product wins on quality, not captivity.
- **Anti-spec.** Specs are reference points, not finish lines. Features ship when they *feel* right, not when a checklist is satisfied.

---

## 3. Identity ecosystem

### 3.1 The Living Identity

The current Identity hub becomes a **Living Identity** — a continuously updated, multi-issuer, cryptographically signed human profile.

- **Issuer mesh.** Governments, airlines, employers, schools, banks, hotels, and clubs become *issuers* who can attest to specific facts about you. Each attestation is a signed verifiable credential (W3C VC) anchored to a decentralized identifier (DID).
- **Composable proofs.** "I am over 21" is a zero-knowledge proof from your passport. "I am a Lufthansa Senator" is a VC from Lufthansa. Each can be presented independently without revealing surrounding data.
- **Score evolution timeline.** A scrubbable history of every event that moved your tier — visa stamp, biometric verify, employer attestation, fraud-clean record, network endorsement.
- **Tier ladder.** Member → Verified → Premium → Sovereign → Diplomat. Each tier unlocks faster lanes (visa-on-arrival queues, instant kiosk pass, automatic lounge access, embassy concierge).

### 3.2 Identity surfaces to add

- **Living Passport book** with page-turn motion, holographic foil that reflects ambient light via accelerometer, anti-counterfeit watermarks rendered in shaders, and live MRZ readouts.
- **Identity timeline** — every credential add, refresh, expiry, and revocation animated as a Notion-style stream.
- **Issuer registry** — searchable directory of all issuers (Lufthansa, German Federal Police, US State Dept, Marriott, etc.) with their public keys, signing policies, and revocation feeds.
- **Trust graph** — visualization of which institutions trust which, with you at the center, edges weighted by attestation strength.
- **Recovery guardians** — Apple-Family-style social recovery: 5 guardians can unlock your identity if you lose your device, requiring 3-of-5 cryptographic signatures.

### 3.3 Privacy primitives

- **Selective disclosure.** Default to revealing the minimum: airport scanners get "valid-for-travel" not your DOB. Hotels get "over-18" not your full name unless required.
- **Per-relying-party pseudonymous IDs.** Each relying party sees a different stable identifier so they cannot collude.
- **Unlinkable presentation.** Two presentations of the same credential cannot be correlated unless you opt-in.
- **Consent ledger.** Every disclosure is recorded locally and visible in the audit log; the user can revoke access prospectively.

### 3.4 Anti-fraud and recovery

- **Biometric duress modes.** A specific finger or face expression silently triggers a "fake unlock" that surfaces a sanitized profile while alerting trusted contacts.
- **Geographic anomaly detection.** If a credential is presented in two distant locations within an impossible time window, both are flagged.
- **Dead-man's switch.** Inactive 30 days → optional release of a sealed message + asset directives to designated recipients.
- **Stolen-device dance.** Lost device flow = remote wipe + identity rotation + re-issuer notification + insurance claim packet generation, all in one tap.

---

## 4. Document & credential systems

### 4.1 Hyper-realistic rendering

Every document inside GlobeID should feel **better than the physical original** — not skeuomorphic kitsch, but a respectful, more legible, more secure rendition.

- **Substrate physics.** Each document type (passport, ID card, license, boarding pass, vaccination card, insurance card, visa) gets a custom substrate shader: paper grain, polycarbonate refraction, foil anisotropy, vellum translucency, holographic dot patterns.
- **Anti-counterfeit overlays.** Microtext, guilloché patterns, UV-only watermarks (revealed on long-press in a "verify" mode), kinegrams, and OVI (optically variable ink) effects.
- **Page turn physics.** Real bend-and-curl using a custom CustomPainter + spring physics for the passport book, with an audio cue from a recorded paper page rustle.
- **Stamp simulation.** Visa stamps fall onto pages with ink-spread shaders, accumulate over time, and can be inspected with pinch-zoom.
- **Wear simulation.** Older documents subtly accumulate texture (fold marks, edge softness) so the document feels lived-in.

### 4.2 New credential classes

- **Health credentials** — vaccination, insurance, blood type, allergies, prescriptions; presentable to airline medical desks, customs in pandemic events, hospitals abroad.
- **Driving / transport credentials** — auto, motorcycle, drone, boat, pilot license; with FAA/EASA-grade attestation flow.
- **Education / professional** — degree, certifications (medicine, law, engineering), conference accreditations.
- **Property / asset credentials** — vehicle ownership, real estate deeds, art provenance.
- **Pet credentials** — vaccination, microchip, breed registration; presented at borders.
- **Family credentials** — proof of relationship, custody, guardianship; for unaccompanied minors and elder-care travel.

### 4.3 Document workflows

- **One-tap renewal.** Detects approaching expiry, pre-fills application, schedules consulate appointment, locks calendar, gathers needed photos via guided capture, files digitally where supported.
- **Lost-document flow.** Detect loss → generate a digital affidavit → produce a temporary travel proof signed by GlobeID's emergency-issuer trust → guide user to nearest consulate with appointment booked.
- **Translation layer.** Any credential rendered in any of 60+ languages with certified-translator attestation chained in.

---

## 5. Wallet & payments

### 5.1 Universal value layer

GlobeID is a **multi-asset, multi-rail wallet** that works at any merchant, any airport, any country, online, offline, and across borders without friction.

- **Rails supported.** Local cards (Visa/MC/AmEx/UnionPay/Rupay/Mir), bank push (FedNow, SEPA Instant, FPS, UPI, PIX), tap-to-pay (NFC), open banking, stablecoins, crypto, CBDCs, airline miles, hotel points, kiosk-issued vouchers.
- **Liquid currency.** Holdings appear in a single visual list — €, $, £, ¥, BTC, ETH, USDC, miles, points. Tap-to-convert between any of them at live mid-market with transparent spread.
- **Just-in-time conversion.** Pay in any currency, settle in another, with zero balance friction — the wallet routes via the cheapest combined-fee path.

### 5.2 Spending intelligence

- **Caps.** Per-category, per-merchant, per-day, per-trip, per-currency. Visualized as concentric rings around the spend dial.
- **Receipts.** Every transaction gets an automatic line-itemized receipt (parsed from email or scanned), categorized, currency-normalized, and tax-tagged.
- **Tax mode.** Toggle a trip into "business" — every spend produces a deductible record; export at year-end as a single PDF + CSV bundle pre-classified for the user's jurisdiction.
- **Concierge spend.** "Get me a SIM, espresso, and an Uber to the hotel" — agent finds nearest options, books, pays, reports back.

### 5.3 New payment surfaces

- **Apple Wallet / Google Wallet / Samsung Pay parity.** Pass cards live in those native wallets too with full pass updates.
- **Kiosk pay.** GlobeID becomes a recognized payment rail at airport kiosks, lounges, and immigration cafes.
- **Family wallet.** Parent issues child sub-wallet with caps, geofences, and curfews. Child sees their own balance and earns "experience points" for budget discipline.
- **Trip wallet.** Each trip auto-spawns its own envelope; spend after trip end is excluded; pre-trip is tagged "preparation."
- **Group pay.** Split bills with friends, with auto-suggestion based on who consumed what (parsed from receipt).

### 5.4 Wallet-as-a-platform

- **Programmable money.** Users write "rules": *"If I land in Tokyo, auto-buy 10,000 JPY. If FX moves +1%, alert. If I haven't spent in 3 days, transfer surplus to savings."*
- **Settlements API.** Enterprises (employers, expense platforms) push instant per-diem to any user wallet by GlobeID DID.
- **Insurance auto-claims.** Flight delayed > 3h → wallet automatically files the claim, attaches boarding pass, and credits payout when approved.

---

## 6. Travel ecosystem

GlobeID is the **operating system of movement**. From "I want to go" to "I'm home" the app handles everything.

### 6.1 Lifecycle pipeline (expanded)

```
Inspiration → Planning → Pricing → Booking → Pre-trip prep → Boarding → In-flight →
Layover → Arrival → Ground transit → Stay → Daily → Departure → Return → Memory
```

Every stage is a fully designed surface with its own micro-affordances.

### 6.2 Inspiration & planning

- **Mood-driven discovery.** "Show me places with cherry blossoms in 6 weeks" → GlobeID predicts bloom windows + flight + accommodation + visa + cost; lays them on the globe with a haze layer per match score.
- **Constraint solver.** "I want a 5-day trip in April under €1,200, no jet lag, beach" → genetic algorithm over a graph of possible destinations + flight + hotel combos surfaces the top 12 with rationale.
- **Travel companions.** Suggestions tuned per companion (kids, partner, friends, parents, business team) — different tolerance for connections, lounges, walking, etc.

### 6.3 Booking

- **Atomic booking.** Flight + hotel + ground transport + lounge + eSIM committed atomically; if any fails, rollback.
- **Negotiation agent.** Background agent watches prices and fights for upgrades using loyalty status + payment partner deals.
- **Voucher reuse.** Idle airline vouchers, hotel credits, miles — all surfaced and combined at booking.
- **Carbon overlay.** Every option shows CO₂ cost; user can opt for offsetting with one tap.

### 6.4 Pre-trip prep

- **Smart packing list** based on destination weather, length of stay, activities, formality, and existing wardrobe (long-term: photo-tagged closet integration).
- **Vaccination checks.** Flagged via WHO + CDC + ECDC feeds.
- **Document checks.** Visa requirements per passport, expiry, blank-page count, transit visas.
- **Currency pre-loading.** Wallet auto-converts a recommended amount to local currency at the cheapest window in the next 14 days.
- **Connection rehearsal.** Walking distances at hub airports, predicted gate-to-gate time, alternative routes if delay > X minutes.

### 6.5 In-flight

- **Live flight twin.** Real-time aircraft state — altitude, speed, heading, track on the globe. Pinch to view altitude graph, fuel curve, ETA prediction, weather along route.
- **Cabin crew handshake.** Optional — cabin crew can ping the pass for VIP/medical/special-meal preferences.
- **Onboard wallet.** Buy WiFi, food, duty-free using the offline-signed pass without re-authenticating.

### 6.6 Layover & ground

- **Lounge map.** Live capacity, queue length, food refresh times, amenities (showers, sleep pods, kids zones), walking time from current gate.
- **Connection optimizer.** Predicts whether to walk, run, take the inter-terminal train, or rebook proactively.
- **Local mode.** On arrival: city map auto-rotates to walking orientation, language pack auto-loaded, transit cards auto-issued, currency auto-cached.

### 6.7 Stay

- **Hotel handshake.** Walk-in check-in via NFC pass; room-key in Apple/Google Wallet; concierge requests routed to the property's PMS; reviews captured automatically.
- **Local concierge.** AI agent that knows the city, the user's taste, and the time of day — books restaurants, secures hard-to-get reservations.
- **Daily rhythm.** Morning brief (weather, news, agenda), midday adjust (walking distances, energy), evening recap (photos, spend, miles).

### 6.8 Memory

- **Trip Atlas.** After a trip ends, GlobeID compiles a Notion-quality recap: route on globe, photos, spend, distance, miles earned, people met, food eaten, kilometers walked, words learned.
- **Yearly travelogue.** End-of-year cinematic montage exportable as a 60-second video.

---

## 7. Globe system

The globe is **the emotional centerpiece** of GlobeID. Everything else orbits it.

### 7.1 Renderer rewrite goals

The current Flutter globe is a custom-painter + sphere approximation. The future globe is a **multi-pass GPU pipeline** rivaling MapLibre 3D, Google Earth, and Apple Globe.

- **Custom render pipeline** built on `flutter_gpu` or a Skia-backed compute pipeline, optionally falling back to a `dart:ui.Scene`-based composite for low-end devices.
- **Six render layers, composited in this order:**
  1. Starfield (parallax-aware, with Milky Way band)
  2. Atmosphere (Rayleigh + Mie scattering shader)
  3. Sphere base (terrain, bathymetry, displacement-mapped)
  4. Cloud band (animated noise texture, scrolling at 1/4 sphere rotation)
  5. Country borders + city lights (additive blend, day/night masked)
  6. Live overlays (arcs, particles, hubs, region focus, weather, ash plumes, fire fronts)

### 7.2 Cinematic camera

- **Smooth-cam curves.** All camera motion uses ease-in-out-cubic + decoupled rotation/zoom/tilt animations.
- **Tap-to-focus.** Tapping a city smoothly arcs the camera to ~600km altitude with a hero animation, while neighboring labels fade in.
- **Cinematic auto-rotate.** Idle for >8s → camera begins a slow Cassini-style orbit with subtle bloom.
- **Free fall.** Pinch-out very fast → camera "falls back" into space with a dolly-zoom effect, revealing the entire planet.

### 7.3 Live data overlays

- **Air traffic.** Live plane positions (ADS-B feed) shown as glowing dots tracing arcs; tap to see flight detail card.
- **Weather.** Cloud cover, fronts, storms; toggleable.
- **Sun terminator.** Day/night line with realistic atmospheric scattering at the rim.
- **Aurora bands.** When solar activity is high, render dancing green/violet ribbons over polar regions.
- **Earthquakes / volcanic activity.** Pulsing markers fade by recency.
- **Migration / movement density.** Aggregated, anonymized — total people in motion right now per region.
- **Internet / Starlink coverage.** Optional layer.
- **Cable network.** Submarine internet cables traced as glowing lines.

### 7.4 Interaction depth

- **Time scrubber.** Drag the time-of-day slider → entire globe lighting, cloud positions, plane positions reflow.
- **Time travel.** Drag months back to see your own travel history replayed; drag years forward to see scheduled trips.
- **Layered story mode.** Tap a story (e.g., "your last business trip") → camera flies the route, arcs draw, audio narration reads the recap.

### 7.5 Performance targets

- **120fps on flagship**, 90fps on mid-tier, 60fps on low-tier with graceful layer disablement.
- **Power-aware mode.** When battery <20% or thermal throttling, automatically drop cloud + atmosphere passes.
- **Background suspend.** Renderer pauses when not visible; all controllers tear down their tickers.

---

## 8. Flutter rendering, shaders, physics, motion

GlobeID will push Flutter's rendering capabilities to their absolute limit. This section is the engineering charter for that effort.

### 8.1 Custom shaders

- **Foil shader.** Anisotropic reflection layer for boarding passes, IDs, and tier badges. Uses tilt + ambient light estimate.
- **Atmosphere shader.** Rayleigh + Mie scattering for the globe rim.
- **Ice/glass shader.** For the lock screen's frosted overlay and the wallet stack's blurred upper layers.
- **Liquid shader.** For pull-to-refresh and the Wallet "balance" visualization where the surface ripples on tap.
- **Holographic shader.** Spectral interference patterns for premium tier badges, kiosk-issued passes, and the membership card.
- **Volumetric shader.** For storm cells on the globe and aurora bands — true volumetric raymarching where supported.

### 8.2 Physics

- **Spring system everywhere.** All transitions snap with critical damping; no easeOut linear motion.
- **Cloth physics.** Currency notes, boarding pass paper edge — small mesh deformation when handled.
- **Particle systems.** Confetti for tier upgrades, dust trails for plane arcs, sparks for biometric verify success.
- **Magnetic snap.** Cards in the wallet stack physically pull together; the globe equator has a soft snap when scrubbing.

### 8.3 Motion design

- **Motion hierarchy.** Three tiers: macro (page transitions, 360–600ms), meso (panel reveals, 220–360ms), micro (toggle, chip, haptic, 80–160ms). All curves co-designed with the haptic vocabulary.
- **Audio coupling.** Every motion has a paired sound asset (bell, paper, mechanical click, ambient sweep). Sounds sit at -36 dB, optional, and respect Silent Mode.
- **Adaptive density.** When `MediaQuery.disableAnimations` or "Reduce Motion" is on, animations collapse to opacity crossfades only.

### 8.4 Rendering budget

- **Frame budget.** 8.3ms (120fps), 11.1ms (90fps), 16.6ms (60fps). Every screen has an upper bound documented in code.
- **RepaintBoundary discipline.** Every animating CustomPaint sits in its own RepaintBoundary. Every list tile that paints decoration is wrapped.
- **Picture caching.** Static decorative layers (starfields, noise fields, cloud bands) cached as `dart:ui.Picture` and replayed.
- **Texture atlas.** All small icons and brand glyphs compiled into a single SVG-sprite atlas to reduce path uploads.

### 8.5 Adaptive quality manager

A `RenderProfileNotifier` watches:
- Frame timings (`SchedulerBinding.instance.addTimingsCallback`)
- Battery state, thermal state, charge state
- Device tier (RAM, GPU)
- User preference (auto / max / battery)

…and dynamically adjusts the active render layer set, particle counts, blur sigmas, and animation depth. Every screen subscribes to the profile and degrades visually but never functionally.

---

## 9. AGI orchestration

GlobeID's intelligence layer evolves from a single chat assistant into a **multi-agent orchestration system** running mostly on-device.

### 9.1 Agent roster

- **Concierge** — front-line conversational agent; knows the user, routes intents.
- **Travel agent** — books flights, hotels, ground transit; negotiates upgrades.
- **Wallet agent** — manages balances, watches FX, settles.
- **Document agent** — reads receipts, extracts MRZ, files claims, renews credentials.
- **Border agent** — pre-files customs declarations, watches visa rules, books appointments.
- **Health agent** — vaccinations, prescriptions, medical translations.
- **Social agent** — checks in, drafts replies, suggests companions.
- **Defender** — anti-fraud, anti-phishing, anti-impersonation; runs always-on.
- **Recovery** — cold-storage of social-recovery state, dead-man rules.
- **Memory keeper** — assembles trip atlases and yearly travelogues.

### 9.2 Architecture

- **Small local LLM** (e.g., quantized 3B or 7B model) handles everyday intent + extractive tasks on-device via `mediapipe-llm` or `llama.cpp`-via-FFI.
- **Specialized models.** OCR (passport/MRZ), receipt parsing, CV for activity detection, ASR for voice, TTS for replies, all on-device when possible.
- **Cloud frontier model** for hard reasoning (planning a 14-country trip), invoked only with explicit consent and with the prompt + response logged to the consent ledger.
- **Tool-using agents.** Each agent has a registered tool list (`search_flights`, `convert_currency`, `submit_visa_app`, `lookup_visa_rules`). The orchestrator chooses tools deterministically when possible.

### 9.3 Memory model

- **Episodic memory.** Every interaction is logged locally, encrypted at rest with a per-user key.
- **Semantic memory.** Embeddings of conversations and documents searchable via on-device vector DB.
- **Profile memory.** Stable preferences (cabin, seat, meal, hotel chains, dietary restrictions, allergies, accessibility needs).
- **Forgetting policy.** User can scrub any memory bucket, time-windowed.

### 9.4 Trust and safety

- **No hallucination on facts.** Travel data, document data, financial data are *never* generated by an LLM — they are looked up from authoritative sources and cited.
- **Explainability.** Every agent decision can be expanded to show its reasoning chain ("I rebooked you because flight 401 was delayed >2h, you have a Senator status, and the next flight had Y-class seats available.").
- **Dual-key actions.** High-stakes (book a $5000 flight, transfer >$1000) require biometric + explicit confirmation step.
- **Adversarial mode.** Periodically the Defender agent runs simulated phishing/social-engineering drills against the user and scores their resilience.

### 9.5 Voice and ambient

- **Wake word.** "Hey GlobeID" optional, on-device.
- **Whisper mode.** App listens only after a tap, processes locally, never streams audio off-device.
- **Continuous brief.** Driver/headphone mode: hourly audio briefings in the user's voice, mixed with ambient cues (gate change chime, weather chord).

---

## 10. Sensors, device fusion

GlobeID becomes **sensor-aware** at every surface.

- **Accelerometer + gyro + magnetometer** — already used for foil + parallax; future: continuous walking-step detection, jet-lag tracking, motion sickness mitigation overlays.
- **Barometer** — altitude-aware in flight, weather change prediction.
- **Ambient light** — dynamic theme switch, foil reflectance, brightness boost on QR.
- **Proximity** — silence haptics when phone is at ear (call mode).
- **Compass** — passport map orientation, walking AR overlays.
- **GPS** — geofence trips, automatic check-in, anti-fraud "is the device where the credential is being presented?"
- **Microphone** — only on explicit tap, only on-device, for voice commands and ambient context (airport noise → suggest lounge).
- **Camera** — passport scan, QR scan, biometric verify, document capture, room-photo tagging, AR overlays.
- **NFC** — pass tap, hotel key, transit card, payment.
- **UWB** (Ultra Wideband, where available) — precise gate location, lounge proximity, indoor wayfinding.
- **Biometric sensors** — Face ID, Touch ID, Optic ID (on Vision Pro), heart rate (on Watch).
- **Health sensors via HealthKit/Health Connect** — fatigue tracking, jet-lag interventions, exercise during long-haul.

### 10.1 Sensor fusion examples

- **"You're walking through a customs zone"** — geofence + accelerometer + altitude → auto-open the customs declaration card.
- **"You're sitting in a lounge"** — geofence + low motion + WiFi SSID → silently mark lounge attendance, accumulate Priority Pass visits.
- **"You're sleeping on a long-haul"** — heart rate + low motion + airline gate sensor → mute notifications, dim screen, set wake at 30 min before landing.
- **"You're stressed at security"** — heart rate spike + airport geofence → auto-show the relevant security tips, language pack, and fast-track lane info.

---

## 11. Cinematic interaction systems

Everything tactile, everything cinematic, everything intentional.

### 11.1 Vocabulary

- **Frosted glass** — for transient surfaces (modals, HUDs, lounge picker)
- **Solid card** — for owned data (pass, document, wallet)
- **Glow** — for active state (selected chip, current trip, primary CTA)
- **Bloom** — for celebration (tier upgrade, payment success)
- **Shadow ripple** — for confirmation (button press, toggle)
- **Lens flare** — for cinematic emphasis (globe aurora, pass present)
- **Particles** — for transitions (boarding accepted, kiosk handshake)

### 11.2 Long-press depth

Long-pressing any object opens a **contextual prism** — a 3D-tilted glass card with quick actions, related entities, recent activity, and a "more" affordance. Mirrors Apple's iOS context menu, but layered with brand-tinted glass.

### 11.3 Pull-down summoning

- Pull down on Home → command palette + recent activity + agent suggestions.
- Pull down on Wallet → live FX board.
- Pull down on Identity → recent attestations + expiring credentials.
- Pull down on Trip → live flight tracker + connection rehearsal.

### 11.4 Edge gestures

- **Left edge swipe** → back, with a horizontal page-curl preview.
- **Right edge swipe** → forward (rare).
- **Top edge pull** → notifications inbox.
- **Bottom edge swipe-up** → command palette.
- **Diagonal pinch from corner** → mini map of all open contexts.

### 11.5 The "Reveal" pattern

A signature GlobeID interaction: tap a sealed object (document, credential, pass) → the seal animates (foil unwraps, paper unfolds, hologram resolves) → the object is presented. This pattern is used everywhere data is private/protected.

### 11.6 Audio design

- **Brand chord** — three notes, played on app open (configurable, off by default).
- **Mode switches** — different chords for travel / wallet / identity / discover modes.
- **Status chimes** — flight on time, gate change, payment received, document expiring.
- **Ambient stems** — when in a particular context (long-haul flight = subtle engine hum; airport lounge = soft murmur), the app blends an ambient bed under the UI sounds.

---

## 12. Premium onboarding & lifecycle

### 12.1 Onboarding evolution

The current 10-slide onboarding evolves into a **lived progression** spanning months.

- **Day 0** — passport scan + biometric bind + first credential.
- **Day 1** — first wallet load + first agent conversation + globe orientation.
- **Day 2–7** — guided tour of one new system per day (intelligence, memory, recovery, social).
- **Week 2** — first trip plan + first booking.
- **Week 4** — score check-in, tier briefing.
- **Quarter** — yearly review preview, trust graph update.
- **Year 1** — first travelogue cinematic.

Every milestone is a beautifully designed surface, not a checklist.

### 12.2 Lifecycle re-engagement

- **Inactive 7 days** — agent sends a tasteful "I noticed your visa expires in 38 days" or "FX moved in your favor, want to convert?"
- **Inactive 30 days** — agent compiles a "what's new" cinematic and offers to plan the next trip.
- **Annual recap** — December cinematic montage of the year's travel.

### 12.3 Progressive disclosure

The app reveals new sections only when the user is ready. A first-time user does not see "AGI agents" or "deferred recovery rules" — those surface contextually after foundational setup.

---

## 13. Social & travel graph

GlobeID is also a **social ecosystem** where people share travel signals, recommendations, and presence — opt-in only.

### 13.1 Travel graph primitives

- **Friends.** Direct mutual contacts. See real-time presence (city-level), trip overlap suggestions, lounge proximity ("Mira is 2 gates away — say hi?").
- **Companions.** Frequent travel pairings.
- **Crews.** Group accounts for families, business teams, travel circles.
- **Followers.** Public trip sharing for creators / personalities.

### 13.2 Surfaces

- **People near you (in transit).** A privacy-preserving feed: friends arriving in your city, friends at the same airport, friends on the same flight.
- **Recommendation graph.** "5 of your friends recommend this restaurant." Powered by their actual visits, not paid placements.
- **Trip exchange.** Two friends planning conflicting trips → app surfaces a 3-day overlap in Lisbon.
- **Skill graph.** "Mira speaks Japanese and is in Tokyo when you arrive — connect for help?" Opt-in skill tagging.

### 13.3 Social privacy

- Default visibility is **city-level**, never precise location.
- Presence sharing is per-friend, per-time-window — "share for the next 3 hours" granularity.
- Every share is logged in the consent ledger.

### 13.4 Communities

- **Frequent fliers** — by program (Star Alliance Senator, Marriott Bonvoy Plat).
- **Region clubs** — Tokyo regulars, Lisbon residents, etc.
- **Special interest** — solo travelers, pilots, surfers, climbers.
- **Embassy / expat forums** — for citizens of country X living abroad.

---

## 14. Automation & autonomous flows

GlobeID's autonomy ranges from **assistive** (suggest) to **agentic** (do, with confirmation) to **autonomous** (do, by policy).

### 14.1 Examples

- **Auto-rebook on delay.** Threshold: delay >2h on a paid economy → agent finds the next flight, books, refunds the original, updates everyone.
- **Auto-currency hedge.** "If EUR/USD drops >1%, convert €500 to USDC for the upcoming trip."
- **Auto-customs declaration.** Photo of the customs form + voice confirmation → declaration submitted via official portal.
- **Auto-claim on flight delay.** EU261 / DOT rules detected → claim drafted with passport + boarding pass attached.
- **Auto-checkin.** Online check-in opens 24h before — agent does it, picks the seat per stored preference.
- **Auto-itinerary stitching.** Plane lands at JFK 22:00 → agent rebooks the airport-to-Manhattan car for 23:30, hotel late check-in confirmed, breakfast adjusted.

### 14.2 Policy engine

User-authored rules, like:
- "If trip total > €5000, require 2FA + biometric."
- "Don't book any flight via Russian airspace."
- "Always pay in USDC if available."
- "Always upgrade if cost <€200."

A simple visual rule editor surfaces the rules; advanced users can write them in a small DSL.

### 14.3 Audit trail

Every autonomous action is logged with: trigger, decision, alternatives considered, outcome, and reversibility window. Reversibility window means the user has, e.g., 90 minutes to undo before the action becomes permanent.

---

## 15. Airport, airline, aviation

### 15.1 Airline partnerships

GlobeID becomes a **first-class airline integration target** alongside Apple Wallet and Google Wallet.

- **Live PNR sync.** Airline pushes seat changes, gate changes, equipment swaps directly to the user's pass.
- **Loyalty handshake.** Tier match recognized; lounge access auto-issued.
- **Crew handshake.** Cabin crew tablet recognizes GlobeID pass; can flag VIP/medical/dietary preferences.
- **Boarding signature.** Gate scanner reads HMAC-signed pass; offline-verifiable.

### 15.2 Airport integrations

- **Indoor map.** UWB + WiFi RTT + visual positioning → meter-precise indoor map of major hubs.
- **Wayfinding.** Turn-by-turn from drop-off to gate, including security wait estimate.
- **Restroom queue, ATM, water-station, charging-port maps.** All overlay-able.
- **Family lanes, accessibility lanes.** Auto-suggested by user profile.

### 15.3 Aviation overlays

- **Live aircraft database.** Tap your plane → see registration, age, seat map (real, not generic), recent flights, maintenance status (where public).
- **In-flight services menu.** Order food, WiFi, blankets through the pass.
- **Pilot's view (cinematic mode).** A premium "look outside" view that simulates current flight conditions: altitude, weather, sun position, terrain below — pure entertainment.

### 15.4 Airline ops support

- **Disruption assistance.** When weather grounds a flight, GlobeID becomes the airline's overflow customer service: rebooks, hotel-vouchers, meal-vouchers, all within the app.
- **Crew rest mode.** Airline staff who use GlobeID get a "crew" mode with rest periods, scheduling, layover hotel data.

---

## 16. Immigration, kiosk, border

### 16.1 Kiosk handshake protocol

A formal protocol — `GIDKiosk` — for one-tap recognition at:
- Immigration kiosks
- Border crossings
- Hotel front desks
- Embassy reception
- Airline counters

The user taps phone to kiosk; kiosk receives a one-time-use, scoped credential set + biometric template; kiosk verifies against the source issuer (airline, government); session opens.

### 16.2 Pre-clearance

For users with verified identity + low-risk profile + history, GlobeID negotiates **pre-clearance** with cooperating governments: by the time you land, you're already cleared.

### 16.3 Biometric corridor

Airports with cooperating GlobeID infrastructure get a **biometric corridor** — walk through a corridor with face + iris + gait recognition; identity confirmed without stopping. (Long-term, requires partnership with airport authorities.)

### 16.4 Refugee/diaspora mode

A respectful mode for users whose passports may not be recognized everywhere: the app surfaces alternative travel documents (UN laissez-passer, refugee certificates, emergency passports) and the institutions that accept them.

### 16.5 Diplomatic mode

For diplomats and consular staff: cryptographically signed accreditations, embassy directory, fast-lane protocols.

---

## 17. Discovery, intelligence, content

### 17.1 Briefings

- **Morning briefing.** Weather, news, agenda, FX, flights, friends nearby, security alerts, all narrated in 90 seconds.
- **Region briefing.** Activate when entering a new country: politics, currency, etiquette, common scams, useful phrases, emergency numbers.
- **Industry briefing.** For business travelers, news + market signals tied to the region they're entering.

### 17.2 Intelligence streams

The Discover tab evolves into a **multi-source intelligence feed** — visa changes, geopolitical shifts, climate events, currency moves, route announcements — all curated, signed, and traceable.

### 17.3 Content partnerships

- **Editorial.** Long-form travel pieces from premier publishers, surfaced contextually.
- **Creators.** GlobeID-verified creators publish guides, walking tours, audio narrations, signed by their DID.
- **Live events.** Airline launches, embassy events, sporting events, festivals — tied to the calendar and globe.

---

## 18. Multi-device, wearable, AR, VR, spatial

### 18.1 Watch

- **GlobeID Watch app.** Boarding pass on wrist, gate change buzz, FX rate ticker, identity score glance, walking-distance to gate.
- **Tap-to-pay** with glance confirmation.
- **Kiosk handshake** via NFC.

### 18.2 Earbuds

- **Spatial audio briefings.** Morning/evening summaries in 3D audio.
- **Whisper translation.** Real-time translation of nearby speech, whispered into the user's ear.
- **Conversation mode.** Tap; the other person speaks into your phone; their language is translated; you reply; their phone reads your reply in their language.

### 18.3 AR phone

- **Wayfinding.** Camera up → arrows to your gate.
- **Document overlay.** Camera at a sign in another language → instant translation overlay.
- **Currency overlay.** Camera at a price tag → live conversion.
- **Lounge / restaurant overlay.** Camera around → ratings, queue length, menus.

### 18.4 AR glasses (Vision Pro, future glasses)

- **Heads-up GlobeID HUD.** Always-on identity glance, current step in your trip pipeline, upcoming deadline.
- **Globe at your desk.** Pinch in space to summon a 3D globe with your routes.
- **Holographic boarding pass.** Pinned in physical space at the gate.

### 18.5 VR / spatial

- **Trip preview in VR.** Walk a hotel before booking; explore a museum; rehearse a complex airport transfer.
- **Travelogue replay.** Re-experience past trips immersively — your routes, your photos, your moments.

### 18.6 Cars

- **CarPlay / Android Auto.** Trip lifecycle in driving mode; ETA, fuel/charging stops, currency conversion, customs warnings near borders.
- **EV charging.** Network-agnostic charging via the universal wallet.

### 18.7 Home

- **macOS / Windows / Linux companion.** Big-screen identity dashboard, document vault, travel planner.
- **Apple TV / Android TV.** Travelogues, family trip planner.

---

## 19. Offline intelligence

GlobeID's lethal advantage is that it **works offline**. When a user is mid-flight, in a remote region, or in a hostile network environment, GlobeID stays useful.

### 19.1 Offline budget

- **Documents.** All credentials cached and offline-verifiable for ≥30 days via cached issuer keys.
- **Wallet.** Balance and last 90 days of transactions.
- **Globe.** Last viewed regions cached as vector tiles + raster.
- **Maps.** Offline pack auto-downloaded for any city the user is heading to.
- **Translation.** Offline language packs for the next destination.
- **Briefings.** Pre-downloaded morning briefing.
- **Agent.** Local LLM handles all routine tasks offline.

### 19.2 Sync model

- **Vector clocks** per subsystem for conflict-free sync on reconnect.
- **CRDTs** for collaborative pieces (group trip planning, family wallet).
- **Eventual consistency** as a contract; the UI never shows a spinner for sync.

### 19.3 Hostile network mode

When in a high-risk network (jurisdictionally hostile, public WiFi at a sensitive airport):
- TLS pinning to GlobeID infrastructure.
- DNS-over-HTTPS to a curated resolver.
- Onion routing for sensitive ops.
- Local-first execution; cloud calls only when essential.

---

## 20. Architecture evolution

### 20.1 From monorepo to platform

```
globeid/
  packages/
    flutter_app/              ← consumer mobile (Flutter)
    flutter_watch/            ← watch app
    flutter_tv/               ← TV companion
    web_app/                  ← admin / desktop companion
    visionos_app/             ← spatial
    server/                   ← Fastify + workers
    server-edge/              ← edge functions (KV, signing)
    server-agents/            ← agent runtime (Python + JS)
  apis/
    identity/                 ← VC + DID
    wallet/                   ← payments + FX + ledger
    travel/                   ← booking + lifecycle
    docs/                     ← document store + OCR
    intel/                    ← briefings + streams
    social/                   ← graph + presence
    globe/                    ← tiles + arcs + overlays
  protocols/
    gid-kiosk/                ← kiosk handshake
    gid-issuer/               ← issuer protocol
    gid-presentation/         ← VC presentation
  partners/
    airlines/
    governments/
    hotels/
    payment-rails/
  tools/
    sdk-flutter/              ← public Flutter SDK for partners
    sdk-web/                  ← JS SDK
    sdk-issuer/               ← Issuer SDK
```

Each package is independently versionable and releasable.

### 20.2 Service mesh

- Fastify (or HTTP/2 alternative) gateways → gRPC internal services.
- Agent runtime as a separate service (Temporal-style workflow engine).
- Issuer trust registry as a public, signed, versioned feed.

### 20.3 Data layer

- **Postgres** for transactional data.
- **TimescaleDB / ClickHouse** for time-series (positions, FX, signals).
- **Vector DB** (e.g. Qdrant, pgvector) for semantic memory.
- **Redis** for rate limiting, hot caches.
- **S3-compatible object store** for documents, signed and encrypted at rest.
- **Per-user encrypted store.** User-scoped DEK derived from device key + recovery factors.

### 20.4 Eventing

- **Event bus.** All cross-service communication is event-driven (Kafka or NATS Jetstream).
- **Outbox pattern** for reliable side-effects.
- **CDC** (change-data-capture) for downstream materialized views.

### 20.5 Multi-tenant isolation

Even if "tenant = user," the architecture is multi-tenant from day one — clean boundary between user data, system data, and partner data. This makes future B2B (employer-issued GlobeID, embassy-issued GlobeID) trivial.

---

## 21. Performance engineering

### 21.1 App startup

- **Cold start** target: 800ms to first interactive, 1.6s to fully ready.
- **Warm start** target: 250ms.
- **Splash discipline.** Splash transitions directly into the home screen with a hero animation.

### 21.2 Frame pacing

- **Custom scheduling.** Heavy CPU work (OCR, FX update, briefing compose) sits behind `Scheduler.scheduleTask` at idle priority.
- **Microtask budget.** Per frame, never spend more than 4ms on Dart side. Anything heavier is offloaded.
- **Isolate pool.** A managed pool of 4 worker isolates handles parsing, signing, FX math, OCR, ASR, anything blocking.

### 21.3 Memory

- **Image cache discipline.** Pre-decode, cap, recycle.
- **Texture lifecycle.** Globe textures evicted when out of view.
- **Document vault.** Lazy-decrypt-on-access; never hold cleartext beyond view.

### 21.4 Network

- **HTTP/3 first**, with HTTP/2 fallback.
- **Persistent connections** to GlobeID infrastructure with mTLS.
- **Request coalescing** — multiple sub-requests batched per RTT.
- **Retry with jitter, exponential backoff, idempotency keys.**

### 21.5 Battery

- **Sensor sampling adaptive** — accelerometer at 50ms during foil view, off otherwise.
- **GPS economical** — only when geofence boundary nears.
- **Animation collapse** when the device thermally throttles or battery is critical.

---

## 22. Scalability & global infrastructure

GlobeID will serve **billions of credentials, hundreds of millions of trips, trillions of payment events** over its lifetime. Architecture decisions must reflect that.

### 22.1 Geo-distributed core

- **Region-pinned data.** EU users' data stays in EU; US in US; Asia in APAC; sovereign jurisdictions in their own clouds.
- **Edge presence** in 30+ locations for issuer-key serving, light reads, signed-pass verification.
- **Active-active across regions.** Failover under 30 seconds globally.

### 22.2 Sharding

- **User-keyed sharding.** Postgres shards by user-id hash; cross-shard reads via federated query.
- **Time-shard for time-series.** Partitions per month for FX, positions, signals.

### 22.3 Read replicas everywhere

- **Eventually consistent reads.** UI reads from local replica with staleness budget visible in dev mode.

### 22.4 Capacity targets

- 1B daily authentications
- 100M concurrent travelers during peak (Christmas + Lunar New Year + Eid + Diwali)
- 10B daily payment events
- 100PB total data
- 99.99% availability per service

### 22.5 Cost model

- **Variable cost per active user**: <$0.10/month at scale (compute + bandwidth).
- **Fixed engineering cost per region**: amortized via partner revenue.

---

## 23. Security & cryptography

### 23.1 Cryptographic primitives

- **DIDs** (W3C did:key, did:web, did:plc, did:gid).
- **VCs** (W3C VC v2, BBS+ for selective disclosure).
- **Signatures**: Ed25519 (performance), P-256 (interop), Dilithium (post-quantum, dual-signed).
- **Hashing**: BLAKE3 (perf), SHA-256 (compat).
- **Encryption**: AES-256-GCM at rest, ChaCha20-Poly1305 in transit (alongside TLS).

### 23.2 Key management

- **Hardware-backed keys** wherever possible (Secure Enclave, StrongBox, TPM).
- **Per-credential keypair** to prevent linking.
- **Recovery mnemonic** (BIP-39 + custom wordlist) plus social-recovery shares.

### 23.3 Threat model

GlobeID assumes adversaries that include:
- Phishing operators
- Advanced phishers (deepfake voice/face)
- State-level actors (APT)
- Compromised cloud providers
- Malicious browser extensions and OS exploits
- Insider threats inside GlobeID itself

…and is designed so that no single compromise unlocks more than a single user's day-of-travel data.

### 23.4 Zero-trust runtime

- **No long-lived secrets** in the client.
- **Workload attestation.** Every server pod attests to its identity via SPIFFE.
- **mTLS everywhere** including inside the cluster.
- **Audit log immutable.** Append-only, externally verifiable.

### 23.5 Post-quantum readiness

GlobeID dual-signs everything important with a classical scheme (Ed25519) **and** a post-quantum scheme (Dilithium / SPHINCS+). Migration path is in place for the day quantum threat materializes.

---

## 24. Data, privacy, sovereignty

### 24.1 Data minimization

- The app collects what is needed for the function in the moment.
- Aggregate analytics are differentially private at the source.
- Long-term retention requires explicit user consent, in plain language.

### 24.2 Sovereignty

- **Per-jurisdiction data residency.** GDPR (EU), DPDP (India), PIPEDA (Canada), POPIA (SA), etc.
- **Data export.** A single, signed, machine-readable bundle with all user data.
- **Right to be forgotten.** Cryptographic erasure: encryption keys are destroyed; data becomes mathematically inaccessible.

### 24.3 Identity sovereignty

- The user's DID is **theirs forever**. Even if GlobeID disappears, the user can take their DID, credentials, and history to any other VC-compatible wallet.

### 24.4 Encrypted by default

- Data at rest, in transit, in backup, in logs.
- Per-user encryption keys; GlobeID employees cannot read user data without explicit user-granted access.

---

## 25. Monetization & business model

### 25.1 Tiers

- **Free.** Identity, basic wallet, basic travel, basic globe.
- **Plus** (€11.99/mo). Concierge agent, lounge access, priority support, advanced briefings, global eSIM allowance.
- **Pro** (€29.99/mo). Premium concierge, multi-currency wallet, business expense suite, priority booking with airline/hotel partners, family sharing.
- **Sovereign** (custom). Diplomats, executives, frequent global movers; dedicated concierge, private kiosk lanes, embassy support.

### 25.2 Revenue streams

- Subscription (above)
- Transaction fees (FX, payment, settlement) — lowest in the industry, transparent
- Travel partner referrals (airlines, hotels, transit) with full disclosure to user
- Insurance affiliate
- Embassy / government B2B (issuer fees, infrastructure)
- Partner SDK licensing
- Hardware accessories (premium NFC fobs, branded passport sleeves)

### 25.3 Anti-models

What GlobeID will **never** do:
- Sell user data
- Inject ads
- Surface paid placements without label
- Share location with third parties without explicit per-event consent
- Lock features behind tier when those features are essential to safety

### 25.4 Partner ecosystem

- **Airlines** receive an integration kit; in exchange for issuing recognized credentials, they get a richer customer surface.
- **Governments** receive a digital-credential-issuance kit; in exchange, they unlock a vast, secure verification network.
- **Hotels** integrate room keys + check-in.
- **Payment rails** integrate at clearing layer.
- **Telecom** integrates eSIM.
- **Insurance** integrates auto-claims.

---

## 26. Super-app orchestration

GlobeID is not just a super-app — it is a **super-app platform**. Other apps embed GlobeID; GlobeID embeds nothing.

### 26.1 Embed GlobeID

Any app can embed:
- **Sign in with GlobeID** (SSO + verifiable identity).
- **Pay with GlobeID** (universal wallet).
- **Verify with GlobeID** (selective disclosure).
- **Travel with GlobeID** (trip plumbing).

Each embedding is a signed, scoped permission grant managed by the user.

### 26.2 GlobeID as identity bus

When a user authenticates anywhere using GlobeID, the relying party gets:
- A scoped pseudonymous DID
- A signed presentation of only the requested claims
- A revocable session token

When the user revokes the session, every relying party that respected the protocol logs the user out.

### 26.3 Mini-apps

Trusted partners can publish **mini-apps** running inside GlobeID's secure runtime — airline check-in, hotel room control, embassy form filing — sandboxed, signed, distributed via GlobeID's app catalog.

### 26.4 Personal API

The user themselves has an API: `gid://you/...` that they can present to other software (their accountant's tool, a tax filing service, an insurance broker) with strictly scoped, time-limited grants.

---

## 27. Sci-fi expansion track

These are not next-quarter features. They are **directional bets** that anchor long-horizon design choices.

### 27.1 Personal AGI envoy

A digital twin of the user — runs on the user's hardware (phone + watch + future neural pendant) — handles all routine interactions on the user's behalf: booking, negotiating, scheduling, replying. It inherits the user's preferences, ethics, and fluency. The user delegates entire days to it.

### 27.2 Mesh travel

When two users with GlobeID are physically near each other and an internet outage occurs, their devices form a **local mesh** (UWB / BLE / WiFi Direct) and continue functioning — exchanging signed credentials, presenting to airline staff, completing payments — with eventual consistency when networks return.

### 27.3 Climate-aware planning

- **Carbon ledger** tracks personal carbon over a lifetime.
- **Greenest itinerary** — a planning option weighted by emissions, reroutes, and offsets.
- **Climate-impact alerts** — flooding, wildfires, hurricanes auto-rebook around hazards.

### 27.4 Universal entry

A formal protocol for **borderless arrival**: cooperating jurisdictions accept GlobeID's pre-clearance such that physical immigration is replaced by a digital handshake, with random spot-checks for compliance. Decades-long path.

### 27.5 Genetic identity

Where law allows and the user opts in: cryptographically committed genetic markers (no plaintext genetic data ever stored) that can be selectively disclosed for medical care abroad.

### 27.6 Space travel

When commercial spaceflight matures: orbital boarding passes, life-support credentials, microgravity-compatible UI for use on station.

### 27.7 Beyond-the-self credentials

Credentials about:
- Family relationships (with consent)
- Estate / inheritance (with legal attestation)
- Pets and dependents
- Property
- Vehicle (with manufacturer attestation)

### 27.8 Universal identity for the underserved

Refugees, stateless persons, undocumented migrants — GlobeID partners with UN agencies and NGOs to issue verified-presence credentials that can be used for medical care, banking, schooling, and travel where bilateral agreements exist.

### 27.9 The "Civilization Briefing"

Daily, optional, AI-curated briefing of meaningful global events (births, deaths, treaties, eclipses, breakthroughs, anniversaries) — a respectful planetary news layer.

### 27.10 Ambient calm

The app actively measures the user's stress (HR, HRV, voice tension) and proactively reduces friction — quieter UI, slower pacing, softer haptics, supportive language — when the user is overloaded. The opposite when the user is energized.

---

## 28. Phase roadmap

### Phase 1 — Stabilization (Q1)
- Performance pass: 90fps everywhere, RepaintBoundary discipline, Isolate pool
- Settings, profile, inbox, discover surfaces fully wired
- Globe HUD wired into renderer

### Phase 2 — Hyper-realism (Q2)
- Document substrate shaders, foil shader, anti-counterfeit overlays
- Passport book v2 with page physics
- Boarding pass v2 with airport-grade UX
- Wallet stack v2 with magnetic pull

### Phase 3 — Globe as core (Q3)
- Multi-pass globe pipeline
- Live air traffic, weather, terminator, aurora
- Cinematic camera

### Phase 4 — Intelligence layer (Q4)
- Local LLM agent runtime
- Tool-using agents
- Memory, profile, semantic recall

### Phase 5 — Identity ecosystem (Y2 Q1)
- W3C VC + DID foundation
- Issuer mesh (first 5 partners)
- Selective disclosure proofs

### Phase 6 — Wallet expansion (Y2 Q2)
- Multi-rail (cards + bank push + stablecoins + miles)
- FX engine + spending intelligence
- Family wallet, group pay

### Phase 7 — Travel orchestration (Y2 Q3)
- Atomic booking
- Auto-rebook
- Auto-claim
- Concierge agent

### Phase 8 — Multi-device (Y2 Q4)
- Watch, earbuds, AR phone
- macOS / Windows companion

### Phase 9 — Spatial (Y3)
- Vision Pro / future glasses
- VR trip preview

### Phase 10 — Government / kiosk (Y3 Q3)
- GIDKiosk protocol
- First sovereign partner
- Pre-clearance pilot

### Phase 11 — Civilization-scale (Y4)
- Mesh travel
- Climate-aware planning
- Personal API
- Mini-app platform

### Phase 12 — Sovereign (Y5+)
- Universal entry
- Personal AGI envoy
- Multi-jurisdiction sovereignty

---

## 29. Engineering rituals

### 29.1 Definition of done

A feature is **done** when:
1. It compiles, lints, and types with zero warnings on all targets.
2. It passes its unit + integration + golden tests.
3. It runs at the target framerate on the lowest-tier supported device.
4. It works offline (or its offline behavior is explicitly documented).
5. It has a haptic + sound design pass.
6. It has been used in a real test trip end-to-end.
7. It has accessibility coverage (text scale, screen reader, reduced motion).
8. It has telemetry hooked up — but only to metrics, never to PII.
9. It has a rollback plan.
10. It has been reviewed by a non-author.

### 29.2 Reviewing aesthetic

The reviewer asks four questions:
1. **Does this feel like the original GlobeID vision?**
2. **Could this be simpler without losing depth?**
3. **What do we lose if we remove this?**
4. **Does this delight, or merely inform?**

### 29.3 Demo culture

Every two weeks, the team gathers and **uses the app in real travel scenarios** — booking real trips, paying real bills, presenting real credentials. No PowerPoint. The product is the deck.

### 29.4 Long-form writing

Major design decisions are written up in a 6-page memo (Bezos / Stripe style) and read in silence at the start of the meeting. Slides come second.

### 29.5 Aesthetic council

A small group reviews every visual change against the GlobeID vocabulary. Their role is **conservative** — they preserve the soul of the app against drift.

### 29.6 No magic numbers

Every constant in the codebase has a named token. Every duration, every blur sigma, every padding. Tokens evolve through a single source of truth.

---

## 30. Closing manifesto

GlobeID is, at its highest abstraction, a **promise**:

> Wherever you go, whoever you meet, whatever the institutions ask of you — your identity, your credentials, your money, your history, your intelligence, and your dignity travel with you.

The app is the visible layer. The protocol is the invisible layer. The vision is what holds them together.

Every commit, every shader, every haptic, every line of copy — should ask itself one question:

**Does this honor the promise?**

If yes, ship it. If no, rework it.

We are building software that, in a thousand small ways, becomes the connective tissue of a planetary civilization — and it must feel that way at every glance, every tap, every screen.

The road is long. The standard is ruthless. The destination is worth it.

— *GlobeID*
