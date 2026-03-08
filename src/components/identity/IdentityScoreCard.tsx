import React from "react";
import { motion } from "framer-motion";
import { IdentityScore } from "@/components/ui/IdentityScore";
import { useUserStore } from "@/store/userStore";
import { cn } from "@/lib/utils";
import { cinematicEase } from "@/cinematic/motionEngine";

const factors = [
  { label: "Documents Verified", value: 5, max: 5 },
  { label: "Countries Visited", value: 12, max: 20 },
  { label: "Travel Activity", value: 8, max: 10 },
  { label: "Biometric Match", value: 1, max: 1 },
];

const IdentityScoreCard: React.FC<{ className?: string }> = ({ className }) => {
  const { profile } = useUserStore();

  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, ease: cinematicEase }}
      className={cn("glass rounded-xl p-4", className)}
    >
      <div className="flex items-center gap-4">
        <IdentityScore score={profile.identityScore} size={72} strokeWidth={5} />
        <div className="flex-1 space-y-1.5">
          <p className="text-sm font-bold text-foreground">Identity Score</p>
          {factors.map((f) => (
            <div key={f.label} className="flex items-center gap-2">
              <span className="text-[10px] text-muted-foreground flex-1">{f.label}</span>
              <div className="w-16 h-1 rounded-full bg-secondary overflow-hidden">
                <div className="h-full bg-accent rounded-full" style={{ width: `${(f.value / f.max) * 100}%` }} />
              </div>
              <span className="text-[10px] font-mono text-foreground w-6 text-right">{f.value}/{f.max}</span>
            </div>
          ))}
        </div>
      </div>
    </motion.div>
  );
};

export default IdentityScoreCard;
