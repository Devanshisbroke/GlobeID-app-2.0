import React from "react";
import { motion, useScroll, useTransform } from "framer-motion";

/**
 * DepthParallax — creates cinematic scroll-based parallax layers
 * Wraps children that shift at different speeds on scroll
 */
interface DepthParallaxProps {
  children: React.ReactNode;
  /** Speed multiplier — 0 = stationary, 1 = normal scroll, <1 = slower, >1 = faster */
  speed?: number;
  /** Additional className */
  className?: string;
  /** Direction of parallax offset */
  direction?: "vertical" | "horizontal";
}

const DepthParallax: React.FC<DepthParallaxProps> = ({
  children,
  speed = 0.5,
  className,
  direction = "vertical",
}) => {
  const { scrollY } = useScroll();
  const offset = useTransform(scrollY, [0, 1000], [0, -100 * speed]);
  const horizontalOffset = useTransform(scrollY, [0, 1000], [0, -50 * speed]);

  return (
    <motion.div
      className={className}
      style={
        direction === "vertical"
          ? { y: offset }
          : { x: horizontalOffset }
      }
    >
      {children}
    </motion.div>
  );
};

export default DepthParallax;
