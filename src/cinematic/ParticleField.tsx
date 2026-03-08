import React, { useMemo } from "react";
import { motion } from "framer-motion";

/**
 * ParticleField — ambient floating particles that respond subtly
 * For cinematic atmosphere behind UI
 */
interface ParticleFieldProps {
  count?: number;
  className?: string;
}

const ParticleField: React.FC<ParticleFieldProps> = ({ count = 24, className }) => {
  const particles = useMemo(
    () =>
      Array.from({ length: count }, (_, i) => ({
        id: i,
        x: Math.random() * 100,
        y: Math.random() * 100,
        size: 1.5 + Math.random() * 2.5,
        delay: Math.random() * 10,
        duration: 8 + Math.random() * 12,
        drift: (Math.random() - 0.5) * 40,
        opacity: 0.1 + Math.random() * 0.25,
        color: Math.random() > 0.5 ? "var(--primary)" : "var(--ocean-aqua)",
      })),
    [count]
  );

  return (
    <div className={className || "fixed inset-0 pointer-events-none overflow-hidden -z-5"} aria-hidden="true">
      {particles.map((p) => (
        <motion.div
          key={p.id}
          className="absolute rounded-full"
          style={{
            left: `${p.x}%`,
            top: `${p.y}%`,
            width: p.size,
            height: p.size,
            background: `hsl(${p.color} / 0.5)`,
            boxShadow: `0 0 ${p.size * 2}px hsl(${p.color} / 0.2)`,
          }}
          animate={{
            y: [0, -50 - Math.random() * 30, -100],
            x: [0, p.drift, p.drift * 0.5],
            opacity: [0, p.opacity, 0],
            scale: [0, 1, 0.3],
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

export default ParticleField;
