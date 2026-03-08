import { useCallback, useEffect, useMemo, useState } from "react";

export const MOTION = {
  micro: 120,
  small: 180,
  medium: 260,
  long: 380,
  cinematic: 500,
  easeOutExpo: "cubic-bezier(0.22, 1, 0.36, 1)",
  easeCinematic: "cubic-bezier(0.16, 1, 0.3, 1)",
  easeSpring: "cubic-bezier(0.34, 1.56, 0.64, 1)",
  easeSnap: "cubic-bezier(0.2, 0, 0, 1)",
} as const;

/** Framer-motion spring presets */
export const springs = {
  gentle: { type: "spring" as const, stiffness: 120, damping: 20, mass: 1 },
  snappy: { type: "spring" as const, stiffness: 300, damping: 28, mass: 0.8 },
  bounce: { type: "spring" as const, stiffness: 400, damping: 25, mass: 0.6 },
  card: { type: "spring" as const, stiffness: 260, damping: 24, mass: 0.7 },
} as const;

/** Framer-motion page transition variants */
export const pageVariants = {
  initial: { opacity: 0, y: 16, scale: 0.98 },
  animate: { opacity: 1, y: 0, scale: 1 },
  exit: { opacity: 0, y: -8, scale: 0.99 },
};

export const pageTransition = {
  type: "spring" as const,
  stiffness: 260,
  damping: 30,
  mass: 0.8,
};

/** Card press animation values */
export const cardPress = {
  whileTap: { scale: 0.97, transition: { type: "spring", stiffness: 400, damping: 25 } },
  whileHover: { y: -2, transition: { type: "spring", stiffness: 300, damping: 20 } },
};

export function useMotion() {
  const [prefersReducedMotion, setPrefersReducedMotion] = useState(false);

  useEffect(() => {
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    setPrefersReducedMotion(mq.matches);
    const handler = (e: MediaQueryListEvent) => setPrefersReducedMotion(e.matches);
    mq.addEventListener("change", handler);
    return () => mq.removeEventListener("change", handler);
  }, []);

  const duration = useCallback(
    (token: keyof typeof MOTION) => {
      if (prefersReducedMotion) return 0;
      const val = MOTION[token];
      return typeof val === "number" ? val : 0;
    },
    [prefersReducedMotion]
  );

  const transition = useCallback(
    (
      token: keyof Pick<typeof MOTION, "micro" | "small" | "medium" | "long"> = "small",
      properties = "all"
    ) => {
      if (prefersReducedMotion) return "none";
      return `${properties} ${MOTION[token]}ms ${MOTION.easeOutExpo}`;
    },
    [prefersReducedMotion]
  );

  const springTransition = useCallback(
    (
      token: keyof Pick<typeof MOTION, "micro" | "small" | "medium" | "long"> = "small",
      properties = "transform, opacity"
    ) => {
      if (prefersReducedMotion) return "none";
      return `${properties} ${MOTION[token]}ms ${MOTION.easeSpring}`;
    },
    [prefersReducedMotion]
  );

  const animationClass = useCallback(
    (className: string) => (prefersReducedMotion ? "" : className),
    [prefersReducedMotion]
  );

  return useMemo(
    () => ({
      prefersReducedMotion,
      duration,
      transition,
      springTransition,
      animationClass,
      ...MOTION,
    }),
    [prefersReducedMotion, duration, transition, springTransition, animationClass]
  );
}

/** Stagger delay for list items */
export function staggerDelay(index: number, base = 50): string {
  return `${index * base}ms`;
}
