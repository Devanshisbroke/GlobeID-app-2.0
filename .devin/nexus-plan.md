# Nexus design system — execution plan

Canonical refs:
- https://globeid-travelos-nexus.lovable.app/os    (Travel OS)
- https://globeid-travelos-nexus.lovable.app/wallet (Global Wallet)

## Distilled design system

### Substrate
- **Pure OLED black** background. No big animated gradients on the substrate. Subtle vignette only.
- **Card surface**: near-black `#0A0A0C` panel with `0.5px` hairline border at `#FFFFFF12`. Rounded `20px`.
- Cards do **not** drop shadow. Hairline borders only.

### Typography (3 tracks)
1. **Display readout** — big numbers / countdowns ("$237,031", "02:14:45"). Refined sans with **tabular** numerals. Optical sizes 28 / 36 / 56.
2. **Title** — section titles ("Global Reserve", "Live Exchange") at 18–22 sans w500.
3. **Eyebrow** — tiny UPPERCASE w/ letter-spacing `+0.15em` ("AVAILABLE · USD", "TIER · 03", "GLOBEID"). 10–11 px.
4. **Mono** — IDs / tokens / codes ("GID-7Q4-8821-Λ"). Departure Mono w500.
5. **Body** — compact body, 14 px regular at 1.4 line height.

### Color tones (restrained)
- Foreground: `#F4F4F5` (high), `#A1A1AA` (mid), `#52525B` (low)
- Champagne / tier gold: `#C9A961` — used sparingly for tier marks + accent CTA
- Success: muted `#3FB68B`
- Warning: muted `#E0A85B`
- Critical: muted `#D55656`
- Cabin accent: `#7280A8` (cool steel)
- NO neon. NO cyan. NO violet glow.

### Layout rhythm
- Page edge padding `24px`.
- Card padding `20–24px`.
- Vertical rhythm: `4 · 8 · 12 · 16 · 24 · 32 · 48`.
- Cards separated by `12–16px` gaps.

### Components / chrome
- **Status bar**: clock + "Biometric · Verified" or "Wallet · Online" eyebrow. Edge to edge.
- **Section header**: eyebrow "GLOBE ID · TRAVEL OS" / "GLOBE ID · WALLET" + title.
- **Pipeline chips**: horizontal row of 5–7 state pills — current state highlighted with subtle fill + champagne border, others muted outline.
- **Boarding pass card**: dense data grid (passenger / cabin / route / gate / seat / group / board / token).
- **Currency card**: NFC chip glyph + "Available · USD" eyebrow + huge balance + masked card number + "GLOBEID" + small tier tag.
- **Quick action row**: 4 icon + label pills (Tap NFC · Scan Pay · Convert · Transfer).
- **Exchange card**: "USD → JPY" with send/receive split + rate line + 24h change.
- **Spend bars**: horizontal proportional bars (Lounge 42% · Dining 28% · Transit 18% · Other 12%) — restrained gradient fill.
- **Activity row**: tiny country code badge + merchant + amount (right) + small caption.
- **Authorize sheet**: pinned bottom sheet "Hold to pay · Face ID" + factor count + "Authorize" CTA.
- **Update banner**: pinned top banner "Gate change · B32 → B14" w/ Dismiss + Details.
- **Bottom nav**: 3-tab flat — Travel OS · Passport · Wallet.

### Motion language
- 200–400 ms cubic. Tight & deliberate.
- No big spring overshoots. No parallax fluff.
- Status pill state changes: 240 ms ease-out fade.
- Authorize CTA: subtle haptic + 1.04 scale pulse on press.
- Update banner: 320 ms slide-in from top w/ subtle fade.

### What to AVOID
- Heavy backdrop blur / "frosted glass" walls.
- Multi-stop animated atmosphere gradients.
- Neon glows, rainbow ribbons, holographic foil sweeps.
- Drop shadows.
- Dashboard density. Use whitespace.

## 30-task execution plan

### Foundation (lib/nexus/)
1. `nexus_tokens.dart` — substrate, ink ladder, tier gold, signal palette, spacing scale, radii, durations.
2. `nexus_typography.dart` — NText (display / title / eyebrow / body / mono / monoSmall).
3. `nexus_materials.dart` — NPanel (hairline card), NPanelTint (subtle tinted variant), NDivider, NHairline.
4. `nexus_haptics.dart` — `tap`, `confirm`, `warn` (HapticFeedback wrappers).
5. `nexus_motion.dart` — N curves + durations, scale-press wrapper, fade-slide transitions.

### Chrome (lib/nexus/chrome/)
6. `nexus_scaffold.dart` — NPageScaffold (status bar + eyebrow header + content + bottom nav slot).
7. `nexus_pipeline.dart` — NPipelineChips (Plan · Pack · Check-in · Security · Lounge · Board · Land).
8. `nexus_chip.dart` — NChip (selected / muted / warn variants), NPill.
9. `nexus_quick_actions.dart` — 4-pill quick action row.
10. `nexus_update_banner.dart` — pinned top banner.
11. `nexus_authorize_sheet.dart` — bottom hold-to-pay sheet.
12. `nexus_bottom_nav.dart` — 3-tab nav.
13. `nexus_kv_row.dart` — eyebrow-over-value row (passenger / cabin / route).

### Hero screens (lib/nexus/screens/)
14. `nexus_travel_os_screen.dart` — full Travel OS canonical screen.
15. `nexus_wallet_screen.dart` — full Global Wallet canonical screen.
16. `nexus_passport_screen.dart` — Passport in Nexus language (3rd nav tab).

### Specialty cards (lib/nexus/cards/)
17. `nexus_currency_card.dart` — currency card w/ NFC chip + balance + masked number.
18. `nexus_exchange_card.dart` — live FX converter.
19. `nexus_spend_bars.dart` — proportional category bars.
20. `nexus_activity_row.dart` — merchant timeline row.
21. `nexus_navigation_card.dart` — live walking-to-gate.
22. `nexus_lounge_card.dart` — lounge eligibility.
23. `nexus_baggage_card.dart` — synchronized baggage.
24. `nexus_immigration_card.dart` — readiness % + checklist.
25. `nexus_orion_card.dart` — AI concierge card.
26. `nexus_destination_card.dart` — destination weather + prep.
27. `nexus_boarding_pass_card.dart` — dense pass data grid.
28. `nexus_countdown_card.dart` — big "Departs in" display.

### Integration
29. Router wiring at `/nexus/os`, `/nexus/wallet`, `/nexus/passport` + bottom-nav-aware shell.
30. analyze + test + flutter build apk --release → PR.

## Verification gates
- `flutter analyze` → 0 issues.
- `flutter test` → all green.
- `flutter build apk --release` → clean APK artifact.
