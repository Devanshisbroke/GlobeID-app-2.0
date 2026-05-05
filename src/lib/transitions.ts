/**
 * Named page-transition presets (BACKLOG J 116).
 *
 * Slot-in `initial` / `animate` / `exit` triplets for `<motion.div>` so
 * route shells can pick a transition without re-deriving the curves.
 *
 * All presets respect `prefers-reduced-motion: reduce` — when reduced,
 * caller should swap to `motionPresetsReduced`.
 *
 * Curves come from the design-system motion tokens — keep these aligned
 * with `src/lib/motion-tokens.ts` so animations across the app feel
 * cohesive.
 */
import type { Variants } from "motion/react";

const SPRING_NAV = { type: "spring", stiffness: 320, damping: 32, mass: 0.6 } as const;
const SPRING_MODAL = { type: "spring", stiffness: 280, damping: 28, mass: 0.7 } as const;
const SPRING_SHEET = { type: "spring", stiffness: 360, damping: 38, mass: 0.5 } as const;
const SPRING_FAB = { type: "spring", stiffness: 420, damping: 28, mass: 0.4 } as const;

export type TransitionPresetId =
  | "slide-up"
  | "slide-right"
  | "slide-left"
  | "fade"
  | "scale-from-anchor"
  | "rise"
  | "drop";

export const motionPresets: Record<TransitionPresetId, Variants> = {
  "slide-up": {
    initial: { y: 24, opacity: 0 },
    animate: { y: 0, opacity: 1, transition: SPRING_NAV },
    exit: { y: -24, opacity: 0, transition: { duration: 0.18 } },
  },
  "slide-right": {
    initial: { x: 32, opacity: 0 },
    animate: { x: 0, opacity: 1, transition: SPRING_NAV },
    exit: { x: -32, opacity: 0, transition: { duration: 0.18 } },
  },
  "slide-left": {
    initial: { x: -32, opacity: 0 },
    animate: { x: 0, opacity: 1, transition: SPRING_NAV },
    exit: { x: 32, opacity: 0, transition: { duration: 0.18 } },
  },
  fade: {
    initial: { opacity: 0 },
    animate: { opacity: 1, transition: { duration: 0.22 } },
    exit: { opacity: 0, transition: { duration: 0.16 } },
  },
  "scale-from-anchor": {
    initial: { scale: 0.92, opacity: 0 },
    animate: { scale: 1, opacity: 1, transition: SPRING_MODAL },
    exit: { scale: 0.96, opacity: 0, transition: { duration: 0.18 } },
  },
  rise: {
    initial: { y: 80, opacity: 0 },
    animate: { y: 0, opacity: 1, transition: SPRING_SHEET },
    exit: { y: 80, opacity: 0, transition: { duration: 0.22 } },
  },
  drop: {
    initial: { y: -32, opacity: 0 },
    animate: { y: 0, opacity: 1, transition: SPRING_FAB },
    exit: { y: -16, opacity: 0, transition: { duration: 0.18 } },
  },
};

/** Reduced-motion variant — collapses to opacity-only. */
export const motionPresetsReduced: Variants = {
  initial: { opacity: 0 },
  animate: { opacity: 1, transition: { duration: 0.12 } },
  exit: { opacity: 0, transition: { duration: 0.1 } },
};

/**
 * Spring-config presets per surface (BACKLOG K 131).
 *
 * Centralising these so callers don't keep redefining stiffness/damping
 * values inline. Each is hand-tuned for the surface category.
 */
export const surfaceSprings = {
  navigate: SPRING_NAV,
  modal: SPRING_MODAL,
  sheet: SPRING_SHEET,
  fab: SPRING_FAB,
  toast: { type: "spring", stiffness: 380, damping: 30, mass: 0.5 },
} as const;

export type SurfaceSpringId = keyof typeof surfaceSprings;
