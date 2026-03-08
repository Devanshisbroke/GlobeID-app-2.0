import React, { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Shield, CheckCircle2, Plane } from "lucide-react";
import { cn } from "@/lib/utils";
import { cinematicEase } from "@/cinematic/motionEngine";
import { getCountryTheme } from "@/lib/countryThemes";
import { uiSound } from "@/cinematic/uiSound";

type EntryPhase = "idle" | "scanning" | "approved" | "welcome";

interface BorderEntrySimulationProps {
  countryCode?: string;
  countryName?: string;
  onComplete?: () => void;
  className?: string;
}

const BorderEntrySimulation: React.FC<BorderEntrySimulationProps> = ({
  countryCode = "SG",
  countryName = "Singapore",
  onComplete,
  className,
}) => {
  const [phase, setPhase] = useState<EntryPhase>("idle");
  const theme = getCountryTheme(countryCode);

  const startEntry = () => {
    setPhase("scanning");
    uiSound.click();
    setTimeout(() => {
      setPhase("approved");
      uiSound.confirm();
      setTimeout(() => {
        setPhase("welcome");
        setTimeout(() => onComplete?.(), 2000);
      }, 1500);
    }, 2000);
  };

  return (
    <div className={cn("relative", className)}>
      <AnimatePresence mode="wait">
        {phase === "idle" && (
          <motion.div key="idle" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="glass rounded-xl p-6 flex flex-col items-center gap-4">
            <Plane className="w-8 h-8 text-primary" />
            <p className="text-sm font-semibold text-foreground">Border Entry Simulation</p>
            <p className="text-xs text-muted-foreground text-center">Simulate arriving at {countryName} immigration</p>
            <button onClick={startEntry} className="px-5 py-2.5 rounded-xl bg-primary text-primary-foreground text-xs font-semibold active:scale-95 transition-transform">
              Begin Entry
            </button>
          </motion.div>
        )}

        {phase === "scanning" && (
          <motion.div key="scan" initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.4, ease: cinematicEase }} className="glass rounded-xl p-6 flex flex-col items-center gap-4">
            <motion.div animate={{ rotateY: [0, 360] }} transition={{ duration: 2, ease: "linear" }}>
              <Shield className="w-10 h-10 text-primary" />
            </motion.div>
            <p className="text-sm font-semibold text-foreground">Scanning Passport...</p>
            <div className="w-full h-1.5 rounded-full bg-secondary overflow-hidden">
              <motion.div
                className="h-full bg-primary rounded-full"
                initial={{ width: "0%" }}
                animate={{ width: "100%" }}
                transition={{ duration: 2, ease: cinematicEase }}
              />
            </div>
          </motion.div>
        )}

        {phase === "approved" && (
          <motion.div key="approved" initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 1.05 }} transition={{ duration: 0.5, ease: cinematicEase }} className="glass rounded-xl p-6 flex flex-col items-center gap-3">
            <motion.div initial={{ scale: 0 }} animate={{ scale: 1 }} transition={{ type: "spring", stiffness: 300, damping: 15 }}>
              <CheckCircle2 className="w-12 h-12 text-accent" />
            </motion.div>
            <p className="text-lg font-bold text-accent">Entry Approved</p>
            <p className="text-xs text-muted-foreground">{theme.flag} {countryName}</p>
          </motion.div>
        )}

        {phase === "welcome" && (
          <motion.div key="welcome" initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.6, ease: cinematicEase }} className="rounded-xl p-8 flex flex-col items-center gap-3 text-center" style={{ background: `linear-gradient(135deg, ${theme.accent}22, ${theme.accent}08)` }}>
            <motion.span className="text-5xl" initial={{ scale: 0 }} animate={{ scale: 1 }} transition={{ type: "spring", stiffness: 200, damping: 12 }}>
              {theme.flag}
            </motion.span>
            <motion.p initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }} className="text-lg font-bold text-foreground">
              Welcome to {countryName}
            </motion.p>
            <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.5 }} className="text-xs text-muted-foreground">
              {theme.greeting}
            </motion.p>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default BorderEntrySimulation;
