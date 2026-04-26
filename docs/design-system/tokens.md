# Phase 7 — Token Reference

> Companion to `phase7-audit.md`. This file documents every `--p7-*` design
> token introduced by **PR-α** (token foundation) so that PR-β / γ / δ / ε / ζ
> can consume them consistently. **PR-α is intentionally a visually-neutral
> diff** — these tokens are added alongside the existing semantic tokens, not
> instead of them, so legacy shadcn primitives keep rendering identically.

## 1. Color tokens

Every color token is defined twice: once in `:root` (light = "Paper") and once
in `.dark` (dark = "Atmosphere"). The two palettes are **not inversions** of
each other — they have different temperatures (Q3, locked).

### Surface tier

| Token | Light (Paper) | Dark (Atmosphere) | Tailwind class |
| --- | --- | --- | --- |
| `--p7-surface-base` | `#FAF8F4` (warm paper) | `#06070A` (OLED-near-black) | `bg-surface-base` |
| `--p7-surface-elevated` | `#FFFFFF` (pure white) | `#0E1014` (warm graphite) | `bg-surface-elevated` |
| `--p7-surface-overlay` | `#F0EDE6` (deep paper) | `#171922` (graphite-rise) | `bg-surface-overlay` |
| `--p7-surface-hairline` | cool grey 88% | warm graphite 22% | `border-surface-hairline` |
| `--p7-glass-tint` | `surface-base / 0.72` | `surface-base / 0.72` | applied via `Surface` v2 component |

### Ink tier

| Token | Light | Dark | Tailwind class |
| --- | --- | --- | --- |
| `--p7-ink-primary` | `#1A1B20` | `#F5F6F8` | `text-ink-primary` |
| `--p7-ink-secondary` | `#5A5F6E` | `#9DA3B4` | `text-ink-secondary` |
| `--p7-ink-tertiary` | `#9095A5` | `#5A6175` | `text-ink-tertiary` |
| `--p7-ink-on-brand` | `#FFFFFF` | `#FFFFFF` | `text-ink-on-brand` |

### Brand & state

| Token | Light | Dark | Tailwind class |
| --- | --- | --- | --- |
| `--p7-brand` | `#3B6FD9` (deep sapphire) | `#5B8DEF` (lifted sapphire) | `bg-brand`, `text-brand` |
| `--p7-brand-strong` | `#1F50C2` | `#7CA4F2` | `bg-brand-strong` |
| `--p7-brand-soft` | brand @ 10% | brand @ 16% | `bg-brand-soft` |
| `--p7-accent` (state) | `#1FA67E` (deep mint) | `#3DD8B0` (lifted mint) | `bg-state-accent`, `text-state-accent` |
| `--p7-accent-soft` | accent @ 10% | accent @ 16% | `bg-state-accent-soft` |
| `--p7-warning` | `#D8821A` | `#F5A623` | (use existing `text-warning`) |
| `--p7-critical` | `#D14460` | `#FF5C7A` | `bg-critical`, `text-critical` |
| `--p7-critical-soft` | critical @ 10% | critical @ 16% | `bg-critical-soft` |

### Shadow tier

Designed for the warm-paper light tier and the OLED-black dark tier — **not**
the same recipe scaled up. Light shadows use a cool-grey shadow tint; dark
shadows use pure black with much higher opacity.

| Token | Tailwind class | Use for |
| --- | --- | --- |
| `--p7-shadow-sm` | `shadow-p7-sm` | Hover pop, focus ring offset |
| `--p7-shadow-md` | `shadow-p7-md` | Card lift, elevated surface |
| `--p7-shadow-lg` | `shadow-p7-lg` | Sheet, modal, dropdown |
| `--p7-shadow-overlay` | `shadow-p7-overlay` | Command palette, top-most overlays |

## 2. Type tokens

Single Inter Variable stack with optical sizing handles the entire scale —
no separate "Inter Display" file is shipped (Inter v4+ embeds the optical
axis directly in the variable woff2). JetBrains Mono Variable is reserved
for technical IDs (MRZ, transaction hashes, route codes).

| Token | Pixel size | Weight | Tracking | Tailwind class | Use for |
| --- | --- | --- | --- | --- | --- |
| `--p7-text-display` | 40 | 600 | -0.04em | `text-p7-display` | Hero / page entry titles |
| `--p7-text-title-1` | 28 | 600 | -0.025em | `text-p7-title-1` | Page title |
| `--p7-text-title-2` | 22 | 600 | -0.02em | `text-p7-title-2` | Section title |
| `--p7-text-title-3` | 17 | 600 | -0.01em | `text-p7-title-3` | Subsection / list-group title |
| `--p7-text-body` | 15 | 400 | -0.005em | `text-p7-body` | Paragraph, list-item description |
| `--p7-text-body` (em) | 15 | 500 | -0.005em | `text-p7-body-em` | Emphasized body / list-item title |
| `--p7-text-callout` | 14 | 400 | 0 | `text-p7-callout` | Inline meta, secondary copy |
| `--p7-text-caption-1` | 12 | 400 | 0.005em | `text-p7-caption-1` | Timestamps, file paths |
| `--p7-text-caption-2` | 11 | 500 | 0.02em | `text-p7-caption-2` | Pill labels, microcopy |

Each Tailwind utility carries `lineHeight`, `letterSpacing`, and
`fontWeight` so a single class name communicates the full type intent —
no need to stack `text-sm font-semibold tracking-tight leading-snug`.

### Font families

| Token | Stack | Tailwind class |
| --- | --- | --- |
| `--p7-font-display` | Inter Variable → Inter → system | `font-display` |
| `--p7-font-sans` | Inter Variable → Inter → system | `font-sans` |
| `--p7-font-mono` | JBM Variable → JBM → ui-monospace | `font-mono` |

All three are loaded locally via `@fontsource-variable/*` so the Capacitor
APK has zero font network dependency on first launch.

## 3. Spacing & radius tokens

Strict 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64 px scale (no other values). 5
named radii.

| Token | Pixel | Tailwind class |
| --- | --- | --- |
| `--p7-space-1` | 4 | `p-1` (Tailwind already maps this) |
| `--p7-space-2` | 8 | `p-2` |
| `--p7-space-3` | 12 | `p-3` |
| `--p7-space-4` | 16 | `p-4` |
| `--p7-space-6` | 24 | `p-6` |
| `--p7-space-8` | 32 | `p-8` |
| `--p7-space-12` | 48 | `p-12` |
| `--p7-space-16` | 64 | `p-16` |

| Radius | Pixel | Tailwind class | Use for |
| --- | --- | --- | --- |
| `--p7-radius-chip` | 4 | `rounded-p7-chip` | Tags, status pills |
| `--p7-radius-input` | 10 | `rounded-p7-input` | Buttons, inputs, segmented controls |
| `--p7-radius-surface` | 16 | `rounded-p7-surface` | Cards, list groups |
| `--p7-radius-sheet` | 24 | `rounded-p7-sheet` | Bottom sheet, top of modal |
| `--p7-radius-pill` | 9999 | (use `rounded-full`) | Avatars, progress tracks |

## 4. Motion tokens

### Spring catalog (live in `src/lib/motion-tokens.ts`)

| Name | Stiffness | Damping | Mass | Use for |
| --- | --- | --- | --- | --- |
| `spring.snap` | 480 | 38 | 1 | Tap response, toggle, segmented control |
| `spring.default` | 320 | 32 | 1 | Modal entry, sheet drag, page transition |
| `spring.soft` | 220 | 28 | 1 | Hover-pop, list-item enter |
| `spring.overshoot` | 380 | 22 | 1 | Hero entrance only — reserved |

Use one of these tuples; **do NOT inline ad-hoc stiffness numbers in screen
code.** `motion`/`framer-motion` accept the tuple via:

```ts
<motion.div transition={spring.snap} />
```

### Cubic-bezier eases (CSS variable + TS export + Tailwind class)

| Name | Curve | CSS var | Tailwind class | Use for |
| --- | --- | --- | --- | --- |
| `ease.standard` | (0.32, 0.72, 0, 1) | `--p7-ease-standard` | `ease-p7-standard` | Default for opacity, cross-fade |
| `ease.emphasized` | (0.2, 0, 0, 1) | `--p7-ease-emphasized` | `ease-p7-emphasized` | Strong attention pull |
| `ease.decelerated` | (0, 0, 0.2, 1) | `--p7-ease-decelerated` | `ease-p7-decelerated` | Element entering view |
| `ease.accelerated` | (0.4, 0, 1, 1) | `--p7-ease-accelerated` | `ease-p7-accelerated` | Element leaving view |

### Duration tokens

| Name | Value | CSS var | Tailwind class | Use for |
| --- | --- | --- | --- | --- |
| `duration.tap` | 120 ms | `--p7-dur-tap` | `duration-p7-tap` | Press feedback |
| `duration.pop` | 200 ms | `--p7-dur-pop` | `duration-p7-pop` | Toggle, popover |
| `duration.page` | 320 ms | `--p7-dur-page` | `duration-p7-page` | Page transition |
| `duration.hero` | 520 ms | `--p7-dur-hero` | `duration-p7-hero` | Hero entrance |
| `duration.splash` | 1400 ms | `--p7-dur-splash` | (splash only) | Splash sequence |

### Stagger choreography

| Name | Value | Use for |
| --- | --- | --- |
| `stagger.tight` | 30 ms | Densely-packed list items |
| `stagger.default` | 50 ms | Standard list / grid |
| `stagger.loose` | 80 ms | Hero clusters (3–4 large surfaces) |

## 5. Library inventory after PR-α

| Package | Version | Status |
| --- | --- | --- |
| `motion` | ^12 | **Newly installed.** Used by v2 components from PR-β onward. |
| `framer-motion` | ^11 | **Kept.** Legacy components keep importing it; migrated component-by-component starting PR-β. |
| `@fontsource-variable/inter` | ^5 | **Newly installed.** Self-hosted Inter Variable. |
| `@fontsource-variable/jetbrains-mono` | ^5 | **Newly installed.** Self-hosted JBM Variable. |
| `@radix-ui/*` | (existing) | Continues to provide unstyled primitives that v2 components wrap. |
| `cmdk` | ^1.1.1 | **Already installed, currently unused.** Will provide the global command palette in PR-γ. |

## 6. What PR-α does NOT do

- ❌ Does not change any existing semantic token (`--background`, `--primary`, …).
- ❌ Does not migrate any existing component to consume `--p7-*` tokens.
- ❌ Does not change any existing Tailwind utility (`text-xs`, `bg-card`, `rounded-xl`, …).
- ❌ Does not replace `framer-motion` imports in any component.
- ❌ Does not introduce v2 primitives (those land in PR-β).
- ❌ Does not change the splash, navigation, or any screen visually.

PR-α is the **plumbing**. The visible reinvention starts in PR-β as v2
primitives begin to consume these tokens, and accelerates through PR-γ / δ /
ε / ζ as each screen migrates.

## 7. Verification checklist for PR-α

- [x] `npm run typecheck` clean (frontend + server)
- [x] `npm run lint` ≤ 7 pre-existing warnings (no new ones)
- [x] `npm run build` succeeds; bundle size delta ≤ +5 KB gzipped before fonts
- [x] Browser cold-launch renders Home / Identity / Wallet / Travel / Map / Services identically to pre-α main (visual diff: zero)
- [x] `--p7-*` tokens visible in `:root` and `.dark` via DevTools
- [x] `bg-surface-base`, `text-ink-secondary`, `font-display`, `text-p7-title-1` all resolve when used in a smoke test
- [x] Inter Variable + JBM Variable load from local URLs (no network requests to fonts.googleapis.com / rsms.me)
