import React from "react";
import { motion } from "framer-motion";
import { pageVariants, pageTransition } from "@/hooks/useMotion";
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
    className={cn(className)}
    variants={pageVariants}
    initial="initial"
    animate="animate"
    exit="exit"
    transition={{
      ...pageTransition,
      delay: staggerIndex !== undefined ? staggerIndex * 0.06 : 0,
    }}
  >
    {children}
  </motion.div>
);

export { AnimatedPage };
