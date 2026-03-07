import { useCallback, useEffect, useMemo, useState } from "react";

export const MOTION = {
  micro: 160,
  small: 240,
  medium: 400,
  long: 800,
  easeOutExpo: "cubic-bezier(0.22, 1, 0.36, 1)",
  easeSpring: "cubic-bezier(0.34, 1.56, 0.64, 1)",
} as const;

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
export function staggerDelay(index: number, base = 60): string {
  return `${index * base}ms`;
}
