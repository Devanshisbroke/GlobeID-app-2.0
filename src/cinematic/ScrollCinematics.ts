/**
 * GlobeID Scroll Cinematics
 * Utilities for cinematic scroll-triggered reveals
 */

import type { Variants } from "framer-motion";
import { cinematicEase, cinematicDuration } from "./motionEngine";

/* ── Scroll reveal with zoom ── */
export const scrollRevealZoom: Variants = {
  hidden: { opacity: 0, scale: 0.92, y: 30, filter: "blur(6px)" },
  visible: {
    opacity: 1,
    scale: 1,
    y: 0,
    filter: "blur(0px)",
    transition: { duration: cinematicDuration.cinematic, ease: cinematicEase },
  },
};

/* ── Scroll reveal slide from left ── */
export const scrollRevealLeft: Variants = {
  hidden: { opacity: 0, x: -40, filter: "blur(4px)" },
  visible: {
    opacity: 1,
    x: 0,
    filter: "blur(0px)",
    transition: { duration: cinematicDuration.cinematic, ease: cinematicEase },
  },
};

/* ── Scroll reveal slide from right ── */
export const scrollRevealRight: Variants = {
  hidden: { opacity: 0, x: 40, filter: "blur(4px)" },
  visible: {
    opacity: 1,
    x: 0,
    filter: "blur(0px)",
    transition: { duration: cinematicDuration.cinematic, ease: cinematicEase },
  },
};

/* ── Scroll section stagger ── */
export const scrollStagger: Variants = {
  hidden: {},
  visible: {
    transition: { staggerChildren: 0.1, delayChildren: 0.05 },
  },
};

export const scrollStaggerItem: Variants = {
  hidden: { opacity: 0, y: 24 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: cinematicDuration.cinematic, ease: cinematicEase },
  },
};

/* ── Viewport options for InView ── */
export const scrollViewport = {
  once: true,
  margin: "-60px 0px",
  amount: 0.15 as const,
};
