import React, { useState, useEffect, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { ScanLine, CheckCircle2, Camera, Eye } from "lucide-react";
import { cn } from "@/lib/utils";
import { cinematicEase } from "@/cinematic/motionEngine";
import { uiSound } from "@/cinematic/uiSound";
import LiveCameraScanner from "./LiveCameraScanner";

type ScanPhase = "idle" | "scanning" | "detected" | "verified";

interface PassportScannerProps {
  onComplete?: () => void;
  className?: string;
}

const PassportScanner: React.FC<PassportScannerProps> = ({ onComplete, className }) => {
  const [phase, setPhase] = useState<ScanPhase>("idle");
  const [progress, setProgress] = useState(0);
  const [liveMode, setLiveMode] = useState(false);

  const startScan = useCallback(() => {
    setPhase("scanning");
    setProgress(0);
    uiSound.click();
  }, []);

  // rAF-driven progress so the bar fills at display refresh rate (60/120Hz)
  // rather than a fixed 25fps `setInterval`. Also pauses when the document
  // is hidden, so backgrounded scans don't keep spinning.
  useEffect(() => {
    if (phase !== "scanning") return;
    let rafId = 0;
    let cancelled = false;
    const start = performance.now();
    const DURATION_MS = 2000; // 0 → 100 over ~2s, matches the previous 40ms × 50 cadence
    const step = (t: number) => {
      if (cancelled) return;
      const pct = Math.min(100, ((t - start) / DURATION_MS) * 100);
      setProgress(pct);
      if (pct >= 100) {
        setPhase("detected");
        uiSound.confirm();
        const handoff = window.setTimeout(() => {
          setPhase("verified");
          onComplete?.();
        }, 1200);
        // Park the handoff timer so we can clear it on unmount.
        cleanupTimers.add(handoff);
        return;
      }
      rafId = requestAnimationFrame(step);
    };
    const cleanupTimers = new Set<number>();
    rafId = requestAnimationFrame(step);
    return () => {
      cancelled = true;
      cancelAnimationFrame(rafId);
      cleanupTimers.forEach((id) => window.clearTimeout(id));
    };
  }, [phase, onComplete]);

  if (liveMode) {
    return (
      <div className={cn("relative", className)}>
        <LiveCameraScanner
          onCapture={() => {
            setLiveMode(false);
            setPhase("detected");
            window.setTimeout(() => {
              setPhase("verified");
              onComplete?.();
            }, 1000);
          }}
          onCancel={() => setLiveMode(false)}
        />
      </div>
    );
  }

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
      {phase === "idle" ? (
        <button
          type="button"
          onClick={() => setLiveMode(true)}
          className="mt-3 mx-auto flex items-center gap-1.5 text-[12px] font-medium text-[hsl(var(--p7-brand))] hover:underline focus:outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))] rounded-md px-2 py-1"
          aria-label="Open live camera scanner"
        >
          <Eye className="w-3.5 h-3.5" />
          Use real camera (edge detect + auto-capture)
        </button>
      ) : null}
    </div>
  );
};

export default PassportScanner;
