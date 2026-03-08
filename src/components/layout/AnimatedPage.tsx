import React from "react";
import { motion } from "framer-motion";
import { cn } from "@/lib/utils";

interface AnimatedPageProps {
  children: React.ReactNode;
  className?: string;
  staggerIndex?: number;
}

/**
 * Optimized animated page section.
 * Removed blur filter animation for GPU performance.
 * Uses only opacity + translateY (composited properties).
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
      duration: 0.28,
      ease: [0.22, 1, 0.36, 1],
      delay: staggerIndex !== undefined ? staggerIndex * 0.04 : 0,
    }}
  >
    {children}
  </motion.div>
);

export { AnimatedPage };
