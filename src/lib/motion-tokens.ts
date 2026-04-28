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
 * Spring catalog — 4 tokens, each tuned for a specific role.
 *
 *  - `snap`        Tap response, toggle, segmented control. Crisp.
 *  - `default`     Modal entry, sheet drag, page transition. Calm.
 *  - `soft`        Hover-pop, list-item enter. Easygoing.
 *  - `overshoot`   Hero entrance only. Slight bounce. Reserved.
 *
 * Use one of these; do NOT inline ad-hoc stiffness numbers in screen code.
 */
export const spring: Readonly<Record<"snap" | "default" | "soft" | "overshoot", SpringPhysics>> = Object.freeze({
  snap:      { type: "spring", stiffness: 480, damping: 38, mass: 1 },
  default:   { type: "spring", stiffness: 320, damping: 32, mass: 1 },
  soft:      { type: "spring", stiffness: 220, damping: 28, mass: 1 },
  overshoot: { type: "spring", stiffness: 380, damping: 22, mass: 1 },
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
export const duration = Object.freeze({
  tap: 0.12,
  pop: 0.2,
  page: 0.32,
  hero: 0.52,
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
