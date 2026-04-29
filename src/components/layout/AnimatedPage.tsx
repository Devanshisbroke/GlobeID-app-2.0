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
 * Slice-G: section-level reveal. Each `<AnimatedPage>` fades + lifts + un-blurs
 * from 4 px to 0. When used multiple times on a screen, pass sequential
 * `staggerIndex` values (0, 1, 2, …) to get the 60 ms cascade the product spec
 * requires. The blur is intentionally tiny so it reads as "settle-in focus"
 * not "background noise".
 */
const STAGGER_STEP = 0.06;

const AnimatedPage: React.FC<AnimatedPageProps> = ({
  children,
  className,
  staggerIndex,
}) => (
  <motion.div
    className={cn("will-change-[transform,opacity,filter]", className)}
    initial={{ opacity: 0, y: 14, filter: "blur(4px)" }}
    animate={{ opacity: 1, y: 0, filter: "blur(0px)" }}
    transition={{
      duration: duration.medium,
      ease: easing.cinematic,
      delay: staggerIndex !== undefined ? staggerIndex * STAGGER_STEP : 0,
    }}
  >
    {children}
  </motion.div>
);

export { AnimatedPage };
