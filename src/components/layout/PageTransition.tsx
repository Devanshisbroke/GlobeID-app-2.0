import React from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useLocation } from "react-router-dom";

/**
 * Optimized page transition — no blur (GPU-expensive), fast opacity+transform only.
 * Uses mode="popLayout" instead of "wait" to avoid blocking on exit animation.
 */
// Slice-G: widened Y + scale deltas, added subtle blur, bumped duration
// into the 300–450ms band so transitions no longer feel like jump cuts.
const variants = {
  initial: {
    opacity: 0,
    y: 12,
    scale: 0.98,
    filter: "blur(6px)",
  },
  animate: {
    opacity: 1,
    y: 0,
    scale: 1,
    filter: "blur(0px)",
  },
  exit: {
    opacity: 0,
    y: -8,
    scale: 1.006,
    filter: "blur(4px)",
  },
};

const transitionIn = {
  duration: 0.38,
  ease: [0.22, 1, 0.36, 1] as [number, number, number, number],
};

interface PageTransitionProps {
  children: React.ReactNode;
}

const PageTransition: React.FC<PageTransitionProps> = ({ children }) => {
  const location = useLocation();

  return (
    <AnimatePresence mode="popLayout" initial={false}>
      <motion.div
        key={location.pathname}
        variants={variants}
        initial="initial"
        animate="animate"
        exit="exit"
        transition={transitionIn}
        className="will-change-[transform,opacity]"
        style={{ willChange: "transform, opacity" }}
      >
        {children}
      </motion.div>
    </AnimatePresence>
  );
};

export { PageTransition };
