/**
 * Phase 7 — motion token catalog
 * ────────────────────────────────────────────────────────────────────
 * Spring physics live in TypeScript (CSS can't natively express
 * stiffness / damping / mass), but the cubic-bezier easing curves and
 * duration tokens are kept in lockstep with their `--p7-*` CSS
 * counterparts so designers and engineers reference the same numbers.
 *
 * v2 components (PR-β onward) consume these constants directly. Old
 * `framer-motion` call sites that import `motionEngine` continue to
 * function untouched.
 *
 * Library decision (Q1, locked): we are migrating from `framer-motion`
 * to `motion` (the rebrand). Both packages share an API surface so
 * these spring tuples work in either runtime — they are spread into
 * `transition: { type: "spring", ... }` configs.
 */

export type SpringPhysics = {
  type: "spring";
  stiffness: number;
  damping: number;
  mass: number;
};

/**
 * Spring catalog — per-surface presets.
 *
 *  - `snap`        Tap response, toggle, segmented control. Crisp.
 *  - `default`     Modal entry, sheet drag, page transition. Calm.
 *  - `soft`        Hover-pop, list-item enter. Easygoing.
 *  - `overshoot`   Hero entrance only. Slight bounce. Reserved.
 *  - `fab`         Floating action button rotation + speed-dial reveal.
 *  - `bounce`      Confetti / achievement / success burst. Playful.
 *  - `card`        Card hover-lift, list-card enter. Subdued.
 *  - `page`        Route transitions (alias to `default` until per-route
 *                  tuning lands).
 *  - `pass`        Wallet pass cycle, drag elastic, swipe spring.
 *  - `sheet`       Bottom sheet open/close. Critically damped, no bounce.
 *  - `nav`         Bottom nav active-pill morph. Slightly snappier than
 *                  `snap` so the pill doesn't lag behind the touch.
 *
 * Use one of these; do NOT inline ad-hoc stiffness numbers in screen code.
 *
 * 120Hz tuning notes: spring stiffness × frame budget (8.3ms at 120Hz)
 * dictates how many sub-frames the integrator can take. Stiffer presets
 * (`snap`, `nav`) are tuned to settle in <250 ms so the user perceives
 * crisp tap response on a 120Hz display; softer presets (`soft`, `card`)
 * settle in 400-600 ms which reads as "elegant" rather than "sluggish".
 */
export const spring: Readonly<
  Record<
    | "snap"
    | "default"
    | "soft"
    | "overshoot"
    | "fab"
    | "bounce"
    | "card"
    | "page"
    | "pass"
    | "sheet"
    | "nav",
    SpringPhysics
  >
> = Object.freeze({
  snap:      { type: "spring", stiffness: 480, damping: 38, mass: 1 },
  default:   { type: "spring", stiffness: 320, damping: 32, mass: 1 },
  soft:      { type: "spring", stiffness: 220, damping: 28, mass: 1 },
  overshoot: { type: "spring", stiffness: 380, damping: 22, mass: 1 },
  fab:       { type: "spring", stiffness: 540, damping: 32, mass: 0.9 },
  bounce:    { type: "spring", stiffness: 360, damping: 14, mass: 1 },
  card:      { type: "spring", stiffness: 260, damping: 30, mass: 1 },
  page:      { type: "spring", stiffness: 320, damping: 32, mass: 1 },
  pass:      { type: "spring", stiffness: 420, damping: 36, mass: 1 },
  sheet:     { type: "spring", stiffness: 300, damping: 40, mass: 1 },
  nav:       { type: "spring", stiffness: 560, damping: 40, mass: 0.9 },
});

/**
 * Cubic-bezier easings — used for opacity / cross-fade where spring is
 * inappropriate (a fade doesn't have momentum). Keep these in sync with
 * `--p7-ease-*` in `index.css`.
 */
export const ease = Object.freeze({
  standard:    [0.32, 0.72, 0, 1] as const,
  emphasized:  [0.2, 0, 0, 1] as const,
  decelerated: [0, 0, 0.2, 1] as const,
  accelerated: [0.4, 0, 1, 1] as const,
});

/**
 * Duration tokens (seconds — `motion` / `framer-motion` accept seconds).
 * Mirrors `--p7-dur-*` in `index.css`.
 */
/**
 * Slice-G timing bands (300–450ms base, 500–700ms long, 120–200ms micro).
 * These replace the tighter Phase-7 values so screen transitions no longer
 * feel jump-cut at <0.25s. Keep micro-interactions in `tap` / `pop` —
 * page-level changes use `page` or `hero`.
 */
export const duration = Object.freeze({
  tap: 0.14,
  pop: 0.2,
  page: 0.38,
  hero: 0.58,
  splash: 0.9,
});

/**
 * Stagger choreography rules (seconds between consecutive children).
 * Larger surfaces transform first; small ones follow.
 */
export const stagger = Object.freeze({
  tight: 0.03,
  default: 0.05,
  loose: 0.08,
});
