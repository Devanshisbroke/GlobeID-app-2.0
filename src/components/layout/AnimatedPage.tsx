import React from "react";
import { motion } from "framer-motion";
import { cn } from "@/lib/utils";
import { duration, easing } from "@/motion/motionConfig";

interface AnimatedPageProps {
  children: React.ReactNode;
  className?: string;
  staggerIndex?: number;
}

/**
 * Optimized animated page section.
 * Phase 5 PR-α: ad-hoc duration/ease literals replaced with canonical motion tokens.
 */
const AnimatedPage: React.FC<AnimatedPageProps> = ({
  children,
  className,
  staggerIndex,
}) => (
  <motion.div
    className={cn("will-change-[transform,opacity]", className)}
    initial={{ opacity: 0, y: 14 }}
    animate={{ opacity: 1, y: 0 }}
    transition={{
      duration: duration.smooth,
      ease: easing.cinematic,
      delay: staggerIndex !== undefined ? staggerIndex * 0.04 : 0,
    }}
  >
    {children}
  </motion.div>
);

export { AnimatedPage };
