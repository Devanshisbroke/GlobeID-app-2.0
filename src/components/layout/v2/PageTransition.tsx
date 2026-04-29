import * as React from "react";
import { motion, AnimatePresence } from "motion/react";
import { useLocation } from "react-router-dom";
import { ease, duration } from "@/lib/motion-tokens";

/**
 * PageTransition v2 — Phase 7 PR-γ.
 *
 * Differences from the legacy framer-motion transition:
 *  - Built on `motion@12` not `framer-motion@11`.
 *  - Uses `mode="popLayout"` so the outgoing page is taken out of layout
 *    flow as soon as the incoming page mounts. This lets the new page lay
 *    out at its final position immediately and the old page float on top
 *    during fade-out — no layout shimmer.
 *  - Distance / duration tuned to feel like "lift up, settle in" (z-axis)
 *    rather than left/right slide. Phase 7 navigation paradigm is layered,
 *    not lateral.
 *  - Honors `prefers-reduced-motion`: instant cross-fade with no transform.
 *
 * Per-route shared-element morphing (Tab → Detail) is handled by the
 * receiving component using `motion`'s `layoutId` directly — this transition
 * deliberately does **not** wrap any layoutId machinery so child shared
 * elements aren't double-tracked.
 */

interface Props {
  children: React.ReactNode;
}

const PageTransitionV2: React.FC<Props> = ({ children }) => {
  const location = useLocation();
  const prefersReducedMotion = usePrefersReducedMotion();

  // We use a single transition for both directions — split timing in
  // motion v12 requires variants, but the in / out durations are close
  // enough that one tuned curve reads well in both directions. Cinematic
  // tuning lives in the easing token, not in the duration delta.
  const transition = prefersReducedMotion
    ? { duration: duration.tap, ease: ease.standard }
    : { duration: duration.page, ease: ease.decelerated };

  // Slice-G: widened Y + scale deltas and added subtle backdrop blur on the
  // entering page (2–6px) so the transition reads as "layered settle-in"
  // rather than a fade. Blur is GPU-cheap here because the filter is applied
  // to the single transitioning page node, not to descendants individually.
  const initial = prefersReducedMotion
    ? { opacity: 0 }
    : { opacity: 0, y: 12, scale: 0.98, filter: "blur(6px)" };

  const animate = prefersReducedMotion
    ? { opacity: 1 }
    : { opacity: 1, y: 0, scale: 1, filter: "blur(0px)" };

  const exit = prefersReducedMotion
    ? { opacity: 0 }
    : { opacity: 0, y: -8, scale: 1.006, filter: "blur(4px)" };

  return (
    <AnimatePresence mode="popLayout" initial={false}>
      <motion.div
        key={location.pathname}
        initial={initial}
        animate={animate}
        exit={exit}
        transition={transition}
        style={{ willChange: "transform, opacity" }}
        className="will-change-[transform,opacity]"
      >
        {children}
      </motion.div>
    </AnimatePresence>
  );
};

/**
 * Tracks the user's `prefers-reduced-motion` setting reactively. We don't
 * just sample it once because a user can toggle it from the OS panel mid-
 * session and we'd rather honor the change immediately.
 */
function usePrefersReducedMotion(): boolean {
  const [reduced, setReduced] = React.useState<boolean>(() => {
    if (typeof window === "undefined") return false;
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  });

  React.useEffect(() => {
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    const handler = (e: MediaQueryListEvent) => setReduced(e.matches);
    mq.addEventListener("change", handler);
    return () => mq.removeEventListener("change", handler);
  }, []);

  return reduced;
}

export default PageTransitionV2;
