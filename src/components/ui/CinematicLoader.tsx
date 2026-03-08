import React from "react";
import { motion } from "framer-motion";
import { cinematicEase } from "@/cinematic/motionEngine";

/**
 * CinematicLoader — premium loading experience
 * Rotating rings with glow particles
 */
interface CinematicLoaderProps {
  size?: "sm" | "md" | "lg";
  label?: string;
}

const sizes = { sm: 32, md: 48, lg: 72 };

const CinematicLoader: React.FC<CinematicLoaderProps> = ({ size = "md", label }) => {
  const s = sizes[size];
  const stroke = size === "sm" ? 2 : size === "md" ? 2.5 : 3;

  return (
    <div className="flex flex-col items-center justify-center gap-3">
      <div className="relative" style={{ width: s, height: s }}>
        {/* Outer ring */}
        <motion.svg
          width={s}
          height={s}
          viewBox={`0 0 ${s} ${s}`}
          className="absolute inset-0"
          animate={{ rotate: 360 }}
          transition={{ duration: 2.5, repeat: Infinity, ease: "linear" }}
        >
          <circle
            cx={s / 2}
            cy={s / 2}
            r={s / 2 - stroke * 2}
            fill="none"
            stroke="hsl(var(--primary) / 0.15)"
            strokeWidth={stroke}
          />
          <motion.circle
            cx={s / 2}
            cy={s / 2}
            r={s / 2 - stroke * 2}
            fill="none"
            stroke="url(#loaderGrad)"
            strokeWidth={stroke}
            strokeLinecap="round"
            strokeDasharray={`${(s - stroke * 4) * Math.PI}`}
            strokeDashoffset={`${(s - stroke * 4) * Math.PI * 0.7}`}
          />
          <defs>
            <linearGradient id="loaderGrad" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="hsl(var(--primary))" />
              <stop offset="100%" stopColor="hsl(var(--ocean-aqua))" />
            </linearGradient>
          </defs>
        </motion.svg>

        {/* Inner ring */}
        <motion.svg
          width={s}
          height={s}
          viewBox={`0 0 ${s} ${s}`}
          className="absolute inset-0"
          animate={{ rotate: -360 }}
          transition={{ duration: 3.5, repeat: Infinity, ease: "linear" }}
        >
          <motion.circle
            cx={s / 2}
            cy={s / 2}
            r={s / 2 - stroke * 5}
            fill="none"
            stroke="hsl(var(--accent) / 0.3)"
            strokeWidth={stroke * 0.8}
            strokeLinecap="round"
            strokeDasharray={`${(s - stroke * 10) * Math.PI}`}
            strokeDashoffset={`${(s - stroke * 10) * Math.PI * 0.8}`}
          />
        </motion.svg>

        {/* Center glow dot */}
        <motion.div
          className="absolute rounded-full"
          style={{
            width: stroke * 3,
            height: stroke * 3,
            left: "50%",
            top: "50%",
            transform: "translate(-50%, -50%)",
            background: "hsl(var(--primary))",
            boxShadow: "0 0 12px hsl(var(--primary) / 0.4)",
          }}
          animate={{
            scale: [1, 1.3, 1],
            opacity: [0.6, 1, 0.6],
          }}
          transition={{ duration: 1.5, repeat: Infinity, ease: "easeInOut" }}
        />
      </div>

      {label && (
        <motion.p
          className="text-xs text-muted-foreground font-medium"
          animate={{ opacity: [0.5, 1, 0.5] }}
          transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
        >
          {label}
        </motion.p>
      )}
    </div>
  );
};

export default CinematicLoader;
