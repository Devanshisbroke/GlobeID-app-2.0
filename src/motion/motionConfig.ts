/**
 * GlobeID Motion Configuration
 * Premium animation presets for 120Hz-feel interactions
 */

import type { Transition, Variants } from "framer-motion";

/* ── Duration Presets ── */
export const duration = {
  instant: 0.08,
  fast: 0.16,
  smooth: 0.28,
  medium: 0.38,
  slow: 0.5,
  cinematic: 0.7,
  reveal: 1.0,
} as const;

/* ── Easing Curves ── */
export const easing = {
  spring: [0.22, 1, 0.36, 1] as [number, number, number, number],
  cinematic: [0.16, 1, 0.3, 1] as [number, number, number, number],
  snap: [0.2, 0, 0, 1] as [number, number, number, number],
  elastic: [0.34, 1.56, 0.64, 1] as [number, number, number, number],
  decel: [0, 0.55, 0.45, 1] as [number, number, number, number],
  bounce: [0.34, 1.3, 0.64, 1] as [number, number, number, number],
} as const;

/* ── Spring Presets ── */
export const spring = {
  gentle: { type: "spring" as const, stiffness: 120, damping: 20, mass: 1 },
  snappy: { type: "spring" as const, stiffness: 300, damping: 28, mass: 0.8 },
  bounce: { type: "spring" as const, stiffness: 400, damping: 22, mass: 0.6 },
  card: { type: "spring" as const, stiffness: 260, damping: 24, mass: 0.7 },
  page: { type: "spring" as const, stiffness: 280, damping: 32, mass: 0.9 },
  fab: { type: "spring" as const, stiffness: 350, damping: 18, mass: 0.5 },
  modal: { type: "spring" as const, stiffness: 200, damping: 25, mass: 0.8 },
} as const;

/* ── Transition Presets ── */
export const transition: Record<string, Transition> = {
  fast: { duration: duration.fast, ease: easing.spring },
  smooth: { duration: duration.smooth, ease: easing.cinematic },
  elastic: { duration: duration.medium, ease: easing.elastic },
  slowReveal: { duration: duration.reveal, ease: easing.decel },
  page: spring.page,
  card: spring.card,
};

/* ── Page Transition Variants ── */
export const pageSlide: Variants = {
  initial: { opacity: 0, x: 20, filter: "blur(4px)" },
  animate: { opacity: 1, x: 0, filter: "blur(0px)" },
  exit: { opacity: 0, x: -20, filter: "blur(4px)" },
};

export const pageFade: Variants = {
  initial: { opacity: 0, scale: 0.97 },
  animate: { opacity: 1, scale: 1 },
  exit: { opacity: 0, scale: 1.02 },
};

export const pageScale: Variants = {
  initial: { opacity: 0, scale: 0.92, y: 20 },
  animate: { opacity: 1, scale: 1, y: 0 },
  exit: { opacity: 0, scale: 0.95, y: -10 },
};

/* ── Stagger Children ── */
export const staggerContainer: Variants = {
  animate: {
    transition: { staggerChildren: 0.06, delayChildren: 0.1 },
  },
};

export const staggerItem: Variants = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0 },
};

/* ── Micro-interaction Presets ── */
export const press = {
  whileTap: { scale: 0.96, transition: { type: "spring", stiffness: 500, damping: 30 } },
};

export const hover = {
  whileHover: { y: -3, transition: spring.card },
};

export const hoverGlow = {
  whileHover: {
    y: -2,
    boxShadow: "0 8px 30px hsl(220 80% 56% / 0.2), 0 0 20px hsl(200 85% 58% / 0.1)",
    transition: spring.card,
  },
};

export const cardInteraction = {
  whileTap: { scale: 0.97, transition: { type: "spring", stiffness: 400, damping: 25 } },
  whileHover: { y: -2, transition: spring.card },
};

export const iconBounce = {
  whileTap: { scale: 0.85, rotate: -8, transition: { type: "spring", stiffness: 500, damping: 15 } },
};

/* ── Scroll-triggered ── */
export const scrollReveal: Variants = {
  hidden: { opacity: 0, y: 30 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: duration.medium, ease: easing.cinematic },
  },
};
