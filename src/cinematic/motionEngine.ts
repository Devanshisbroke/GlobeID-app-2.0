/**
 * GlobeID Cinematic Motion Engine
 * Premium animation presets for immersive UI experiences
 */

import type { Variants, Transition } from "framer-motion";

/* ── Cinematic Easing ── */
export const cinematicEase = [0.22, 1, 0.36, 1] as [number, number, number, number];
export const cinematicEaseOut = [0.16, 1, 0.3, 1] as [number, number, number, number];
export const cinematicEaseIn = [0.55, 0, 1, 0.45] as [number, number, number, number];
export const cinematicBounce = [0.34, 1.3, 0.64, 1] as [number, number, number, number];

/* ── Duration Tokens ── */
export const cinematicDuration = {
  short: 0.12,
  medium: 0.22,
  cinematic: 0.35,
  hero: 0.55,
  epic: 0.8,
} as const;

/* ── Cinematic Transition Presets ── */
export const cinematicTransition: Record<string, Transition> = {
  short: { duration: cinematicDuration.short, ease: cinematicEase },
  medium: { duration: cinematicDuration.medium, ease: cinematicEase },
  cinematic: { duration: cinematicDuration.cinematic, ease: cinematicEase },
  hero: { duration: cinematicDuration.hero, ease: cinematicEaseOut },
  epic: { duration: cinematicDuration.epic, ease: cinematicEaseOut },
};

/* ── Cinematic Fade ── */
export const cinematicFade: Variants = {
  initial: { opacity: 0 },
  animate: { opacity: 1, transition: { duration: cinematicDuration.cinematic, ease: cinematicEase } },
  exit: { opacity: 0, transition: { duration: cinematicDuration.medium, ease: cinematicEaseIn } },
};

/* ── Cinematic Reveal (blur + fade + slide) ── */
export const cinematicReveal: Variants = {
  initial: { opacity: 0, y: 16 },
  animate: {
    opacity: 1,
    y: 0,
    transition: { duration: cinematicDuration.cinematic, ease: cinematicEase },
  },
  exit: {
    opacity: 0,
    y: -8,
    transition: { duration: cinematicDuration.medium, ease: cinematicEaseIn },
  },
};

/* ── Cinematic Slide ── */
export const cinematicSlide: Variants = {
  initial: { opacity: 0, x: 40, filter: "blur(4px)" },
  animate: {
    opacity: 1,
    x: 0,
    filter: "blur(0px)",
    transition: { duration: cinematicDuration.cinematic, ease: cinematicEase },
  },
  exit: {
    opacity: 0,
    x: -20,
    filter: "blur(3px)",
    transition: { duration: cinematicDuration.medium, ease: cinematicEaseIn },
  },
};

/* ── Cinematic Scale (zoom in from center) ── */
export const cinematicScale: Variants = {
  initial: { opacity: 0, scale: 0.88, filter: "blur(6px)" },
  animate: {
    opacity: 1,
    scale: 1,
    filter: "blur(0px)",
    transition: { duration: cinematicDuration.cinematic, ease: cinematicEase },
  },
  exit: {
    opacity: 0,
    scale: 1.05,
    filter: "blur(4px)",
    transition: { duration: cinematicDuration.medium, ease: cinematicEaseIn },
  },
};

/* ── Cinematic Zoom (subtle zoom forward) ── */
export const cinematicZoom: Variants = {
  initial: { opacity: 0, scale: 1.08 },
  animate: {
    opacity: 1,
    scale: 1,
    transition: { duration: cinematicDuration.hero, ease: cinematicEase },
  },
  exit: {
    opacity: 0,
    scale: 0.95,
    transition: { duration: cinematicDuration.medium, ease: cinematicEaseIn },
  },
};

/* ── Cinematic Depth (parallax-style entrance) ── */
export const cinematicDepth: Variants = {
  initial: { opacity: 0, y: 40, scale: 0.95, rotateX: 4 },
  animate: {
    opacity: 1,
    y: 0,
    scale: 1,
    rotateX: 0,
    transition: { duration: cinematicDuration.hero, ease: cinematicEase },
  },
  exit: {
    opacity: 0,
    y: -20,
    scale: 0.98,
    transition: { duration: cinematicDuration.medium, ease: cinematicEaseIn },
  },
};

/* ── Stagger Container for cinematic reveals ── */
export const cinematicStagger: Variants = {
  initial: {},
  animate: {
    transition: { staggerChildren: 0.08, delayChildren: 0.15 },
  },
};

/* ── Stagger Item ── */
export const cinematicStaggerItem: Variants = {
  initial: { opacity: 0, y: 20, filter: "blur(4px)" },
  animate: {
    opacity: 1,
    y: 0,
    filter: "blur(0px)",
    transition: { duration: cinematicDuration.cinematic, ease: cinematicEase },
  },
};

/* ── Button interaction presets ── */
export const cinematicButton = {
  whileHover: {
    y: -2,
    scale: 1.02,
    transition: { duration: cinematicDuration.short, ease: cinematicEase },
  },
  whileTap: {
    scale: 0.96,
    y: 0,
    transition: { duration: 0.1, ease: cinematicEase },
  },
};

/* ── Card interaction presets ── */
export const cinematicCard = {
  whileHover: {
    y: -3,
    scale: 1.01,
    transition: { duration: cinematicDuration.medium, ease: cinematicEase },
  },
  whileTap: {
    scale: 0.98,
    transition: { duration: 0.1, ease: cinematicEase },
  },
};

/* ── Hero text reveal ── */
export const heroTextReveal: Variants = {
  initial: { opacity: 0, y: 30, letterSpacing: "0.1em" },
  animate: {
    opacity: 1,
    y: 0,
    letterSpacing: "-0.02em",
    transition: { duration: cinematicDuration.hero, ease: cinematicEase },
  },
};
