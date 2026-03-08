import React from "react";
import { motion } from "framer-motion";
import { cn } from "@/lib/utils";

/**
 * UILighting — subtle dynamic light reflections on UI cards
 * Wrap any card component to add an animated light sweep effect
 */
interface UILightingProps {
  children: React.ReactNode;
  className?: string;
  /** Intensity 0-1, default 0.5 */
  intensity?: number;
  /** Enable edge glow */
  edgeGlow?: boolean;
}

const UILighting: React.FC<UILightingProps> = ({
  children,
  className,
  intensity = 0.5,
  edgeGlow = false,
}) => {
  const sweepOpacity = 0.03 + intensity * 0.05;

  return (
    <div className={cn("relative overflow-hidden", className)}>
      {children}

      {/* Light reflection sweep */}
      <motion.div
        className="absolute inset-0 pointer-events-none rounded-[inherit]"
        style={{
          background: `linear-gradient(115deg, transparent 30%, hsl(0 0% 100% / ${sweepOpacity}) 45%, hsl(0 0% 100% / ${sweepOpacity * 1.8}) 50%, hsl(0 0% 100% / ${sweepOpacity}) 55%, transparent 70%)`,
          backgroundSize: "250% 100%",
        }}
        animate={{
          backgroundPosition: ["-100% 0%", "200% 0%"],
        }}
        transition={{
          duration: 5 + Math.random() * 3,
          repeat: Infinity,
          ease: "linear",
          repeatDelay: 2,
        }}
      />

      {/* Edge glow */}
      {edgeGlow && (
        <motion.div
          className="absolute inset-0 pointer-events-none rounded-[inherit]"
          style={{
            boxShadow: `inset 0 1px 0 hsl(0 0% 100% / ${0.04 + intensity * 0.04}), inset 0 -1px 0 hsl(0 0% 0% / 0.04)`,
          }}
          animate={{
            opacity: [0.5, 1, 0.5],
          }}
          transition={{
            duration: 4,
            repeat: Infinity,
            ease: "easeInOut",
          }}
        />
      )}
    </div>
  );
};

export default UILighting;
