import React, { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { ScanLine, ShieldCheck, FileCheck, CheckCircle2 } from "lucide-react";
import { cn } from "@/lib/utils";
import { cinematicEase } from "@/cinematic/motionEngine";

const steps = [
  { id: "scan", label: "Scan Passport", icon: ScanLine, description: "Position passport in frame" },
  { id: "verify", label: "Verify Identity", icon: ShieldCheck, description: "Biometric verification" },
  { id: "confirm", label: "Credentials Ready", icon: FileCheck, description: "Travel credentials confirmed" },
];

interface VerificationFlowProps {
  onComplete?: () => void;
  autoPlay?: boolean;
  className?: string;
}

const VerificationFlow: React.FC<VerificationFlowProps> = ({ onComplete, autoPlay = false, className }) => {
  const [currentStep, setCurrentStep] = useState(0);
  const [completed, setCompleted] = useState<number[]>([]);

  useEffect(() => {
    if (!autoPlay) return;
    if (currentStep >= steps.length) {
      onComplete?.();
      return;
    }
    const timer = setTimeout(() => {
      setCompleted((prev) => [...prev, currentStep]);
      setCurrentStep((s) => s + 1);
    }, 1800);
    return () => clearTimeout(timer);
  }, [currentStep, autoPlay, onComplete]);

  const advanceStep = () => {
    if (currentStep >= steps.length) return;
    setCompleted((prev) => [...prev, currentStep]);
    setCurrentStep((s) => s + 1);
    if (currentStep + 1 >= steps.length) onComplete?.();
  };

  return (
    <div className={cn("space-y-4", className)}>
      {/* Progress line */}
      <div className="flex items-center gap-1 px-2">
        {steps.map((step, i) => {
          const done = completed.includes(i);
          const active = i === currentStep;
          return (
            <React.Fragment key={step.id}>
              <motion.div
                className={cn(
                  "w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold shrink-0 border transition-colors",
                  done ? "bg-accent text-accent-foreground border-accent" :
                  active ? "border-primary text-primary bg-primary/10" :
                  "border-border text-muted-foreground"
                )}
                animate={active ? { scale: [1, 1.1, 1] } : {}}
                transition={{ duration: 1.2, repeat: active ? Infinity : 0 }}
              >
                {done ? <CheckCircle2 className="w-4 h-4" /> : i + 1}
              </motion.div>
              {i < steps.length - 1 && (
                <div className="flex-1 h-0.5 rounded-full bg-border overflow-hidden">
                  <motion.div
                    className="h-full bg-accent"
                    initial={{ width: "0%" }}
                    animate={{ width: done ? "100%" : "0%" }}
                    transition={{ duration: 0.5, ease: cinematicEase }}
                  />
                </div>
              )}
            </React.Fragment>
          );
        })}
      </div>

      {/* Active step card */}
      <AnimatePresence mode="wait">
        {currentStep < steps.length && (
          <motion.div
            key={steps[currentStep].id}
            initial={{ opacity: 0, y: 12, filter: "blur(6px)" }}
            animate={{ opacity: 1, y: 0, filter: "blur(0px)" }}
            exit={{ opacity: 0, y: -12, filter: "blur(6px)" }}
            transition={{ duration: 0.4, ease: cinematicEase }}
            className="glass rounded-xl p-4 flex items-center gap-3 cursor-pointer active:scale-[0.98] transition-transform"
            onClick={!autoPlay ? advanceStep : undefined}
          >
            <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center">
              {React.createElement(steps[currentStep].icon, { className: "w-5 h-5 text-primary" })}
            </div>
            <div className="flex-1">
              <p className="text-sm font-semibold text-foreground">{steps[currentStep].label}</p>
              <p className="text-xs text-muted-foreground">{steps[currentStep].description}</p>
            </div>
            {!autoPlay && (
              <span className="text-[10px] text-muted-foreground">Tap to proceed</span>
            )}
          </motion.div>
        )}
        {currentStep >= steps.length && (
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            className="glass rounded-xl p-4 flex items-center gap-3"
          >
            <div className="w-10 h-10 rounded-xl bg-accent/15 flex items-center justify-center">
              <CheckCircle2 className="w-5 h-5 text-accent" />
            </div>
            <div>
              <p className="text-sm font-semibold text-foreground">Verification Complete</p>
              <p className="text-xs text-muted-foreground">All credentials verified successfully</p>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default VerificationFlow;
