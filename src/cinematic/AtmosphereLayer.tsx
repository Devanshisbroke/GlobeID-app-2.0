import React, { useMemo } from "react";
import { motion } from "framer-motion";
import { useReducedEffects } from "@/hooks/useReducedEffects";

/**
 * AtmosphereLayer — subtle ambient particles + glow orbs behind UI
 * Renders as a fixed full-screen layer. Use inside AppShell.
 *
 * On mobile / Capacitor / reduced-motion devices the layer falls back to
 * a small set of static-looking blurred orbs and skips the per-particle
 * framer-motion timeline, which is the dominant paint cost in Android
 * WebView (large filter: blur fills + many composited layers).
 */
const AtmosphereLayer: React.FC = () => {
  const reduced = useReducedEffects();

  const particles = useMemo(
    () =>
      reduced
        ? []
        : Array.from({ length: 18 }, (_, i) => ({
            id: i,
            x: Math.random() * 100,
            y: Math.random() * 100,
            size: 2 + Math.random() * 3,
            delay: Math.random() * 8,
            duration: 6 + Math.random() * 8,
            opacity: 0.15 + Math.random() * 0.2,
          })),
    [reduced]
  );

  // Mobile fallback: two static blurred orbs, no transforms.
  if (reduced) {
    return (
      <div
        className="fixed inset-0 pointer-events-none overflow-hidden -z-5"
        aria-hidden="true"
      >
        <div
          className="absolute w-[260px] h-[260px] rounded-full"
          style={{
            top: "-6%",
            left: "-8%",
            background:
              "radial-gradient(circle, hsl(var(--ocean-aqua) / 0.06) 0%, transparent 70%)",
            filter: "blur(40px)",
          }}
        />
        <div
          className="absolute w-[240px] h-[240px] rounded-full"
          style={{
            bottom: "8%",
            right: "-10%",
            background:
              "radial-gradient(circle, hsl(var(--aurora-purple) / 0.05) 0%, transparent 70%)",
            filter: "blur(40px)",
          }}
        />
      </div>
    );
  }

  return (
    <div
      className="fixed inset-0 pointer-events-none overflow-hidden -z-5"
      aria-hidden="true"
    >
      {/* Gradient glow orbs */}
      <motion.div
        className="absolute w-[400px] h-[400px] rounded-full"
        style={{
          top: "-8%",
          left: "-5%",
          background:
            "radial-gradient(circle, hsl(var(--ocean-aqua) / 0.08) 0%, transparent 70%)",
          filter: "blur(60px)",
        }}
        animate={{
          x: [0, 30, -20, 0],
          y: [0, -20, 15, 0],
          scale: [1, 1.08, 0.95, 1],
        }}
        transition={{ duration: 25, repeat: Infinity, ease: "linear" }}
      />

      <motion.div
        className="absolute w-[350px] h-[350px] rounded-full"
        style={{
          bottom: "10%",
          right: "-10%",
          background:
            "radial-gradient(circle, hsl(var(--aurora-purple) / 0.06) 0%, transparent 70%)",
          filter: "blur(60px)",
        }}
        animate={{
          x: [0, -25, 15, 0],
          y: [0, 20, -10, 0],
          scale: [1, 0.95, 1.06, 1],
        }}
        transition={{ duration: 30, repeat: Infinity, ease: "linear" }}
      />

      <motion.div
        className="absolute w-[280px] h-[280px] rounded-full"
        style={{
          top: "40%",
          left: "30%",
          background:
            "radial-gradient(circle, hsl(var(--forest-jade) / 0.04) 0%, transparent 70%)",
          filter: "blur(50px)",
        }}
        animate={{
          x: [0, 20, -30, 10, 0],
          y: [0, -15, 10, -5, 0],
        }}
        transition={{ duration: 35, repeat: Infinity, ease: "linear" }}
      />

      {/* Ambient light ray */}
      <motion.div
        className="absolute w-[200%] h-[1px] left-[-50%]"
        style={{
          top: "25%",
          background:
            "linear-gradient(90deg, transparent 0%, hsl(var(--ocean-aqua) / 0.04) 30%, hsl(var(--primary) / 0.06) 50%, hsl(var(--aurora-purple) / 0.04) 70%, transparent 100%)",
          transform: "rotate(-5deg)",
          filter: "blur(1px)",
        }}
        animate={{ opacity: [0.3, 0.6, 0.3] }}
        transition={{ duration: 8, repeat: Infinity, ease: "easeInOut" }}
      />

      {/* Floating particles */}
      {particles.map((p) => (
        <motion.div
          key={p.id}
          className="absolute rounded-full"
          style={{
            left: `${p.x}%`,
            top: `${p.y}%`,
            width: p.size,
            height: p.size,
            background: "hsl(var(--primary) / 0.4)",
          }}
          animate={{
            y: [0, -30, -60],
            opacity: [0, p.opacity, 0],
            scale: [0, 1, 0.5],
          }}
          transition={{
            duration: p.duration,
            delay: p.delay,
            repeat: Infinity,
            ease: "easeOut",
          }}
        />
      ))}
    </div>
  );
};

export default AtmosphereLayer;
