import React from "react";
import { motion } from "framer-motion";
import { cinematicEase, cinematicDuration, cinematicStaggerItem } from "@/cinematic/motionEngine";
import { cn } from "@/lib/utils";

interface AnimatedPageProps {
  children: React.ReactNode;
  className?: string;
  staggerIndex?: number;
}

const AnimatedPage: React.FC<AnimatedPageProps> = ({
  children,
  className,
  staggerIndex,
}) => (
  <motion.div
    className={cn("will-change-transform", className)}
    variants={cinematicStaggerItem}
    initial="initial"
    animate="animate"
    exit="exit"
    transition={{
      duration: cinematicDuration.cinematic,
      ease: cinematicEase,
      delay: staggerIndex !== undefined ? staggerIndex * 0.06 : 0,
    }}
  >
    {children}
  </motion.div>
);

export { AnimatedPage };
