import React from "react";
import { motion } from "framer-motion";
import { cn } from "@/lib/utils";

/**
 * IconMotion — subtle animated icon wrapper
 * Adds pulse, glow, or gentle rotation to icons
 */
interface IconMotionProps {
  children: React.ReactNode;
  /** Animation type */
  variant?: "pulse" | "glow" | "rotate" | "breathe" | "float";
  className?: string;
}

const animations = {
  pulse: {
    animate: { scale: [1, 1.08, 1] },
    transition: { duration: 2.5, repeat: Infinity, ease: "easeInOut" },
  },
  glow: {
    animate: { opacity: [0.7, 1, 0.7] },
    transition: { duration: 3, repeat: Infinity, ease: "easeInOut" },
  },
  rotate: {
    animate: { rotate: [0, 3, -3, 0] },
    transition: { duration: 4, repeat: Infinity, ease: "easeInOut" },
  },
  breathe: {
    animate: { scale: [1, 1.04, 1], opacity: [0.85, 1, 0.85] },
    transition: { duration: 3.5, repeat: Infinity, ease: "easeInOut" },
  },
  float: {
    animate: { y: [0, -3, 0] },
    transition: { duration: 3, repeat: Infinity, ease: "easeInOut" },
  },
};

const IconMotion: React.FC<IconMotionProps> = ({
  children,
  variant = "breathe",
  className,
}) => {
  const anim = animations[variant];

  return (
    <motion.div
      className={cn("inline-flex will-change-transform", className)}
      animate={anim.animate}
      transition={anim.transition}
    >
      {children}
    </motion.div>
  );
};

export default IconMotion;
