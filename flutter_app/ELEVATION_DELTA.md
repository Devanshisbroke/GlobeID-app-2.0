# Flutter elevation delta — TS/Capacitor → Flutter audit

Cross-reference of the **original** React/Capacitor codebase under
`src/` against the current `flutter_app/` migration. Lists what's
already at parity and what still needs to be elevated to flagship.

## Coverage parity table

| Subsystem | Original (TS) | Flutter | Notes |
|---|---|---|---|
| Routes | 25 screens (App.tsx) | 25 screens (router.dart) | Parity |
| Tab bar | 6 tabs (Home/Identity/Wallet/Travel/Map/Services) | 5 tabs (Home/Wallet/Travel/Services/Map) + FAB | **Identity missing from tab bar** |
| Theme toggle | Top-right ThemeToggle in AppChrome | None (only via /profile) | **Missing** |
| Atmosphere layer | Animated orbs + particles + light ray | 2 static blooms | **Missing animation** |
| Command palette | Cmd-K, AppChrome wrapped in `CommandPaletteProvider` | FAB long-press → modal | OK |
| PassStack | Stacked peek + drag-cycle + layoutId hero | PageView + tilt + flip | **No peeked depth behind active card** |
| PassDetail | Brightness ramp + tilt + flip + QR + secureCopy | Tilt + flip + QR | OK; brightness ramp not native to Flutter |
| Atmosphere bg orbs | 3 animated orbs + light ray + 18 particles | 2 static blooms | **Big visible delta** |
| Theme accents | 8 brand swatches | 8 brand swatches | Parity |
| Theme density | compact / comfortable / spacious | comfortable / compact / cozy / spacious | Parity |
| Motion presets | spring.default / snap / softSpring | AppTokens easeOutSoft / easeOutBack | Parity |
| Dark canvas | layered tokens via CSS vars | `canvasDark` 0x05060A / `surfaceDark` 0x0B0F1A / `cardDark` 0x111827 | Parity (but no per-surface gradient) |
| Demo data fallback | demoData.ts | demo_data.dart 1224+ lines | **Better than original** |
| 3D globe | three.js earth + arcs + sun terminator | flutter_map 2D fallback | Acknowledged gap (handoff says hybrid 2D acceptable) |
| Onboarding cinematic | 3-page carousel + Lottie | 3-page carousel | OK |
| Scanner | mobile_scanner + MLKit + edge overlay | mobile_scanner + MLKit + edge overlay | Parity |

## Concrete elevation pass (this PR)

1. **Top-right theme toggle** in AppShell — cycles ThemeMode and surfaces
   a quick accent picker bottom-sheet on long-press.
2. **Cinematic atmosphere backdrop** — port `AtmosphereLayer.tsx` to a
   pure-Flutter widget: 3 drifting glow orbs + 18 floating particles +
   ambient light ray. Reduced-effects users get the existing 2-bloom
   fallback automatically.
3. **PassStack peek depth** — render up to 2 cards behind the active
   pass with peek offset + scale + opacity falloff (matches Apple Wallet).
4. **Cinematic dark canvas** — layered radial gradients per scaffold.
5. **Polish nav**: identity quick-pill in top-right when not on Identity.
