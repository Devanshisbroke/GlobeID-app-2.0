import React, { useState, useEffect, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { ScanLine, CheckCircle2, Camera } from "lucide-react";
import { cn } from "@/lib/utils";
import { cinematicEase } from "@/cinematic/motionEngine";
import { uiSound } from "@/cinematic/uiSound";

type ScanPhase = "idle" | "scanning" | "detected" | "verified";

interface PassportScannerProps {
  onComplete?: () => void;
  className?: string;
}

const PassportScanner: React.FC<PassportScannerProps> = ({ onComplete, className }) => {
  const [phase, setPhase] = useState<ScanPhase>("idle");
  const [progress, setProgress] = useState(0);

  const startScan = useCallback(() => {
    setPhase("scanning");
    setProgress(0);
    uiSound.click();
  }, []);

  useEffect(() => {
    if (phase !== "scanning") return;
    const interval = setInterval(() => {
      setProgress((p) => {
        if (p >= 100) {
          clearInterval(interval);
          setPhase("detected");
          uiSound.confirm();
          setTimeout(() => {
            setPhase("verified");
            onComplete?.();
          }, 1200);
          return 100;
        }
        return p + 2;
      });
    }, 40);
    return () => clearInterval(interval);
  }, [phase, onComplete]);

  return (
    <div className={cn("relative", className)}>
      <div className="relative aspect-[4/3] rounded-2xl overflow-hidden bg-secondary/40 border border-border/30">
        {/* Camera bg */}
        <div className="absolute inset-0 bg-gradient-to-b from-secondary/20 to-secondary/60" />

        {/* Corner brackets */}
        {["top-3 left-3", "top-3 right-3 rotate-90", "bottom-3 right-3 rotate-180", "bottom-3 left-3 -rotate-90"].map((pos, i) => (
          <div key={i} className={cn("absolute w-8 h-8 border-t-2 border-l-2 border-primary/60", pos)} />
        ))}

        {/* Scan line */}
        {phase === "scanning" && (
          <motion.div
            className="absolute left-4 right-4 h-0.5 bg-gradient-to-r from-transparent via-primary to-transparent"
            style={{ boxShadow: "0 0 12px hsl(var(--primary) / 0.5)" }}
            animate={{ top: ["10%", "90%", "10%"] }}
            transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
          />
        )}

        {/* Center content */}
        <div className="absolute inset-0 flex flex-col items-center justify-center gap-2">
          <AnimatePresence mode="wait">
            {phase === "idle" && (
              <motion.div key="idle" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="flex flex-col items-center gap-2">
                <Camera className="w-8 h-8 text-muted-foreground" />
                <p className="text-xs text-muted-foreground">Position passport in frame</p>
                <button onClick={startScan} className="mt-2 px-4 py-2 rounded-xl bg-primary text-primary-foreground text-xs font-medium active:scale-95 transition-transform">
                  Start Scan
                </button>
              </motion.div>
            )}
            {phase === "scanning" && (
              <motion.div key="scanning" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="flex flex-col items-center gap-2">
                <ScanLine className="w-8 h-8 text-primary animate-pulse" />
                <p className="text-xs text-primary font-medium">Scanning passport...</p>
              </motion.div>
            )}
            {(phase === "detected" || phase === "verified") && (
              <motion.div key="done" initial={{ opacity: 0, scale: 0.8 }} animate={{ opacity: 1, scale: 1 }} transition={{ duration: 0.4, ease: cinematicEase }} className="flex flex-col items-center gap-2">
                <motion.div animate={{ scale: [1, 1.15, 1] }} transition={{ duration: 0.5 }}>
                  <CheckCircle2 className="w-10 h-10 text-accent" />
                </motion.div>
                <p className="text-xs text-accent font-semibold">
                  {phase === "detected" ? "Passport Detected" : "Verification Complete"}
                </p>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* Progress bar */}
        {phase === "scanning" && (
          <div className="absolute bottom-0 left-0 right-0 h-1 bg-secondary">
            <motion.div className="h-full bg-primary" style={{ width: `${progress}%` }} transition={{ duration: 0.1 }} />
          </div>
        )}
      </div>
    </div>
  );
};

export default PassportScanner;
