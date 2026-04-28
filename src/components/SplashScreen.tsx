import React, { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { easing, duration } from "@/motion/motionConfig";

interface SplashScreenProps {
  onComplete: () => void;
}

const SplashScreen: React.FC<SplashScreenProps> = ({ onComplete }) => {
  const [phase, setPhase] = useState<"logo" | "sweep" | "exit">("logo");

  useEffect(() => {
    // Slice-B target: 1.5s total splash. Phase budget tuned so the logo
    // beat reads cleanly without cropping the sweep:
    //   logo 0–500 ms · sweep 500–1100 ms · exit fade 1100–1500 ms.
    const t1 = setTimeout(() => setPhase("sweep"), 500);
    const t2 = setTimeout(() => setPhase("exit"), 1100);
    const t3 = setTimeout(() => onComplete(), 1500);
    return () => { clearTimeout(t1); clearTimeout(t2); clearTimeout(t3); };
  }, [onComplete]);

  return (
    <AnimatePresence>
      {phase !== "exit" ? null : null}
      <motion.div
        className="fixed inset-0 z-[100] flex flex-col items-center justify-center"
        initial={{ opacity: 1 }}
        animate={{ opacity: phase === "exit" ? 0 : 1 }}
        transition={{ duration: 0.6, ease: easing.cinematic }}
        style={{
          background: "linear-gradient(135deg, hsl(228 20% 5%) 0%, hsl(228 18% 9%) 50%, hsl(228 20% 5%) 100%)",
        }}
      >
        {/* Ambient orbs */}
        <div className="absolute inset-0 pointer-events-none overflow-hidden">
          {[
            { bg: "hsl(220 85% 62%)", size: 400, blur: 120, opacity: 0.25, top: "15%", left: "5%", delay: "0s" },
            { bg: "hsl(258 65% 65%)", size: 350, blur: 100, opacity: 0.18, bottom: "10%", right: "5%", delay: "2s" },
            { bg: "hsl(168 70% 48%)", size: 250, blur: 80, opacity: 0.12, top: "50%", right: "25%", delay: "4s" },
          ].map((orb, i) => (
            <div
              key={i}
              className="absolute rounded-full"
              style={{
                background: `radial-gradient(circle, ${orb.bg} 0%, transparent 70%)`,
                width: orb.size,
                height: orb.size,
                filter: `blur(${orb.blur}px)`,
                opacity: orb.opacity,
                top: orb.top,
                bottom: orb.bottom,
                left: orb.left,
                right: orb.right,
                animation: `orb-drift 8s ease-in-out infinite`,
                animationDelay: orb.delay,
              } as React.CSSProperties}
            />
          ))}
        </div>

        {/* Globe logo */}
        <motion.div
          className="relative mb-8"
          initial={{ scale: 0.7, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ duration: 0.8, ease: easing.cinematic }}
          style={{ perspective: "600px" }}
        >
          <svg
            viewBox="0 0 120 120"
            className="w-28 h-28"
            style={{ filter: "drop-shadow(0 0 30px hsl(220 85% 62% / 0.4))" }}
          >
            <circle cx="60" cy="60" r="50" fill="none" stroke="url(#globe-gradient)" strokeWidth="2"
              style={{ animation: "globe-spin 3s linear infinite", transformOrigin: "60px 60px" }} />
            <ellipse cx="60" cy="60" rx="50" ry="20" fill="none" stroke="hsl(200 90% 60% / 0.3)" strokeWidth="1" />
            <ellipse cx="60" cy="60" rx="50" ry="35" fill="none" stroke="hsl(200 90% 60% / 0.2)" strokeWidth="1" />
            <ellipse cx="60" cy="60" rx="20" ry="50" fill="none" stroke="hsl(258 65% 65% / 0.3)" strokeWidth="1" />
            {[
              { cx: 35, cy: 35 }, { cx: 85, cy: 40 }, { cx: 50, cy: 80 },
              { cx: 75, cy: 70 }, { cx: 40, cy: 55 }, { cx: 80, cy: 55 },
            ].map((dot, i) => (
              <motion.circle
                key={i}
                cx={dot.cx}
                cy={dot.cy}
                r="2.5"
                fill={`hsl(${[220, 168, 258, 25, 200, 310][i]} ${[85, 70, 65, 95, 90, 70][i]}% ${[62, 48, 65, 58, 60, 58][i]}%)`}
                initial={{ opacity: 0, scale: 0 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.4 + i * 0.1, duration: 0.3, ease: easing.elastic }}
              />
            ))}
            <line x1="35" y1="35" x2="85" y2="40" stroke="hsl(220 85% 62% / 0.2)" strokeWidth="0.5" strokeDasharray="4 4" />
            <line x1="85" y1="40" x2="75" y2="70" stroke="hsl(168 70% 48% / 0.2)" strokeWidth="0.5" strokeDasharray="4 4" />
            <line x1="40" y1="55" x2="80" y2="55" stroke="hsl(258 65% 65% / 0.2)" strokeWidth="0.5" strokeDasharray="4 4" />
            <defs>
              <linearGradient id="globe-gradient" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="hsl(220 85% 62%)" />
                <stop offset="50%" stopColor="hsl(200 90% 60%)" />
                <stop offset="100%" stopColor="hsl(168 70% 48%)" />
              </linearGradient>
            </defs>
          </svg>
        </motion.div>

        {/* Text */}
        <motion.div
          className="text-center"
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: phase !== "logo" ? 1 : 0, y: phase !== "logo" ? 0 : 16 }}
          transition={{ duration: 0.5, ease: easing.cinematic }}
        >
          <h1
            className="text-3xl font-bold tracking-tight"
            style={{
              background: "linear-gradient(135deg, hsl(220 85% 70%), hsl(200 90% 65%), hsl(168 70% 55%))",
              WebkitBackgroundClip: "text",
              WebkitTextFillColor: "transparent",
            }}
          >
            GlobeID
          </h1>
          <p className="text-sm text-muted-foreground mt-1 tracking-widest uppercase">
            Travel · Identity · Payments
          </p>
        </motion.div>

        {/* Light sweep */}
        {phase === "sweep" && (
          <motion.div
            className="absolute bottom-0 left-0 right-0 h-[2px]"
            initial={{ scaleX: 0, originX: 0 }}
            animate={{ scaleX: 1 }}
            transition={{ duration: 1.2, ease: easing.decel }}
            style={{
              background: "linear-gradient(90deg, transparent, hsl(220 85% 62%), hsl(168 70% 48%), transparent)",
            }}
          />
        )}

        {/* Particle dots */}
        {phase !== "exit" && (
          <div className="absolute inset-0 pointer-events-none overflow-hidden">
            {Array.from({ length: 12 }).map((_, i) => (
              <motion.div
                key={i}
                className="absolute w-1 h-1 rounded-full bg-primary/30"
                initial={{
                  x: `${20 + Math.random() * 60}%`,
                  y: `${20 + Math.random() * 60}%`,
                  opacity: 0,
                  scale: 0,
                }}
                animate={{
                  opacity: [0, 0.6, 0],
                  scale: [0, 1, 0],
                  y: `${10 + Math.random() * 30}%`,
                }}
                transition={{
                  duration: 2 + Math.random() * 2,
                  delay: 0.5 + i * 0.15,
                  repeat: Infinity,
                  ease: "easeInOut",
                }}
              />
            ))}
          </div>
        )}
      </motion.div>
    </AnimatePresence>
  );
};

export default SplashScreen;
