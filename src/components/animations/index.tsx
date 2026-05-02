/**
 * Motion-driven animation primitives.
 *
 * We deliberately did NOT pull in `lottie-web` / `@lottiefiles/dotlottie-react`
 * (~80–120 KB minified just for the runtime, plus per-animation JSON
 * blobs) for these specific use cases. Each of the 5 animations below is
 * a small, hand-tuned SVG + framer-motion piece. They share the same
 * "feels expensive" quality as a Lottie animation while:
 *
 *   1. Adding zero new dependencies.
 *   2. Theming with `currentColor` so they pick up the surface accent.
 *   3. Respecting `prefers-reduced-motion` (motion handles this for us
 *      by collapsing transitions).
 *   4. Working out of the box on Capacitor/Android Studio (no WASM,
 *      no fetch-on-mount JSON).
 *
 * The 5 animations:
 *  - `<SuccessCheck />`   — circular tick, used after wallet add /
 *                           pass save / form submit.
 *  - `<LoadingOrbit />`   — three-dot orbit, replaces generic spinner.
 *  - `<ErrorPulse />`     — "x" with a soft red pulse, used in toasts.
 *  - `<EmptyExplore />`   — telescope/compass empty-state for empty
 *                           lists (Wallet / Documents / Trips).
 *  - `<ConfettiBurst />`  — celebratory radial particles for milestones.
 */

import React from "react";
import { motion } from "motion/react";
import { spring } from "@/lib/motion-tokens";

interface AnimationProps {
  size?: number;
  /** CSS color or token. Defaults to `currentColor`. */
  color?: string;
  className?: string;
}

/* ─── 1. Success check ───────────────────────────────────────────── */

export const SuccessCheck: React.FC<AnimationProps> = ({
  size = 64,
  color = "currentColor",
  className,
}) => (
  <motion.svg
    width={size}
    height={size}
    viewBox="0 0 64 64"
    className={className}
    initial="hidden"
    animate="visible"
  >
    <motion.circle
      cx="32"
      cy="32"
      r="28"
      fill="none"
      stroke={color}
      strokeWidth="3"
      variants={{
        hidden: { pathLength: 0, opacity: 0 },
        visible: { pathLength: 1, opacity: 1 },
      }}
      transition={{ duration: 0.45, ease: [0.32, 0.72, 0, 1] }}
    />
    <motion.path
      d="M19 33 L29 43 L46 24"
      fill="none"
      stroke={color}
      strokeWidth="3.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      variants={{
        hidden: { pathLength: 0 },
        visible: { pathLength: 1 },
      }}
      transition={{ delay: 0.25, duration: 0.32, ease: [0.32, 0.72, 0, 1] }}
    />
  </motion.svg>
);

/* ─── 2. Loading orbit ───────────────────────────────────────────── */

export const LoadingOrbit: React.FC<AnimationProps> = ({
  size = 48,
  color = "currentColor",
  className,
}) => {
  const radius = size * 0.34;
  const dotRadius = size * 0.06;
  return (
    <motion.svg
      width={size}
      height={size}
      viewBox={`0 0 ${size} ${size}`}
      className={className}
      animate={{ rotate: 360 }}
      transition={{ repeat: Infinity, duration: 1.4, ease: "linear" }}
      role="status"
      aria-label="Loading"
    >
      {[0, 1, 2].map((i) => {
        const angle = (i * 2 * Math.PI) / 3;
        const cx = size / 2 + radius * Math.cos(angle);
        const cy = size / 2 + radius * Math.sin(angle);
        return (
          <motion.circle
            key={i}
            cx={cx}
            cy={cy}
            r={dotRadius}
            fill={color}
            initial={{ opacity: 0.25 }}
            animate={{ opacity: [0.25, 1, 0.25] }}
            transition={{
              repeat: Infinity,
              duration: 1.2,
              delay: i * 0.16,
              ease: "easeInOut",
            }}
          />
        );
      })}
    </motion.svg>
  );
};

/* ─── 3. Error pulse ─────────────────────────────────────────────── */

export const ErrorPulse: React.FC<AnimationProps> = ({
  size = 48,
  color = "hsl(var(--destructive, 0 80% 60%))",
  className,
}) => (
  <motion.svg
    width={size}
    height={size}
    viewBox="0 0 48 48"
    className={className}
  >
    <motion.circle
      cx="24"
      cy="24"
      r="22"
      fill={color}
      opacity={0.18}
      animate={{ scale: [1, 1.08, 1], opacity: [0.18, 0.05, 0.18] }}
      transition={{ repeat: Infinity, duration: 1.6, ease: "easeInOut" }}
      style={{ transformOrigin: "center" }}
    />
    <motion.path
      d="M16 16 L32 32 M32 16 L16 32"
      fill="none"
      stroke={color}
      strokeWidth="3"
      strokeLinecap="round"
      initial={{ pathLength: 0 }}
      animate={{ pathLength: 1 }}
      transition={{ duration: 0.34, ease: [0.32, 0.72, 0, 1] }}
    />
  </motion.svg>
);

/* ─── 4. Empty-state telescope ───────────────────────────────────── */

export const EmptyExplore: React.FC<AnimationProps> = ({
  size = 96,
  color = "currentColor",
  className,
}) => (
  <motion.svg
    width={size}
    height={size}
    viewBox="0 0 96 96"
    className={className}
    initial={{ opacity: 0, y: 8 }}
    animate={{ opacity: 1, y: 0 }}
    transition={spring.soft}
    aria-hidden="true"
  >
    <motion.circle
      cx="48"
      cy="48"
      r="34"
      fill="none"
      stroke={color}
      strokeWidth="2"
      opacity={0.32}
    />
    <motion.circle
      cx="48"
      cy="48"
      r="22"
      fill="none"
      stroke={color}
      strokeWidth="2"
      opacity={0.5}
      animate={{ scale: [1, 1.06, 1] }}
      transition={{ repeat: Infinity, duration: 3, ease: "easeInOut" }}
      style={{ transformOrigin: "48px 48px" }}
    />
    <motion.circle
      cx="48"
      cy="48"
      r="6"
      fill={color}
      animate={{ scale: [1, 1.18, 1] }}
      transition={{ repeat: Infinity, duration: 1.6, ease: "easeInOut" }}
      style={{ transformOrigin: "48px 48px" }}
    />
    {/* Orbiting dot — represents discovering items */}
    <motion.g
      animate={{ rotate: 360 }}
      transition={{ repeat: Infinity, duration: 5, ease: "linear" }}
      style={{ transformOrigin: "48px 48px" }}
    >
      <circle cx="80" cy="48" r="3" fill={color} opacity={0.85} />
    </motion.g>
  </motion.svg>
);

/* ─── 5. Confetti burst ──────────────────────────────────────────── */

export const ConfettiBurst: React.FC<AnimationProps & { particles?: number }> = ({
  size = 120,
  color = "currentColor",
  className,
  particles = 12,
}) => {
  const center = size / 2;
  const palette = ["#60A5FA", "#A78BFA", "#34D399", "#F472B6", "#FBBF24"];
  return (
    <motion.svg
      width={size}
      height={size}
      viewBox={`0 0 ${size} ${size}`}
      className={className}
      aria-hidden="true"
    >
      {Array.from({ length: particles }).map((_, i) => {
        const angle = (i / particles) * 2 * Math.PI;
        const dx = Math.cos(angle) * (size * 0.42);
        const dy = Math.sin(angle) * (size * 0.42);
        const c = palette[i % palette.length] ?? color;
        return (
          <motion.rect
            key={i}
            x={center - 1.5}
            y={center - 4}
            width={3}
            height={8}
            rx={1.2}
            fill={c}
            initial={{ x: center - 1.5, y: center - 4, rotate: 0, opacity: 1 }}
            animate={{
              x: center - 1.5 + dx,
              y: center - 4 + dy,
              rotate: angle * (180 / Math.PI) + 90,
              opacity: 0,
            }}
            transition={{ duration: 1.1, ease: [0.2, 0.8, 0.2, 1], delay: 0.05 }}
          />
        );
      })}
    </motion.svg>
  );
};
