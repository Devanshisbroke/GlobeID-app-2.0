import React from "react";
import { motion } from "motion/react";
import { IdentityScore } from "@/components/ui/IdentityScore";
import { Surface, Text, ease, duration } from "@/components/ui/v2";
import { useUserStore } from "@/store/userStore";
import { cn } from "@/lib/utils";

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
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: duration.hero, ease: ease.standard }}
    >
      <Surface
        variant="elevated"
        radius="surface"
        className={cn("p-4", className)}
      >
        <div className="flex items-center gap-4">
          <IdentityScore score={profile.identityScore} size={72} strokeWidth={5} />
          <div className="flex-1 space-y-1.5">
            <Text variant="caption-1" tone="tertiary" className="uppercase tracking-wider">
              Identity Score
            </Text>
            {factors.map((f) => (
              <div key={f.label} className="flex items-center gap-2">
                <Text variant="caption-2" tone="secondary" className="flex-1">
                  {f.label}
                </Text>
                <div className="w-16 h-1 rounded-full bg-surface-overlay overflow-hidden">
                  <div
                    className="h-full bg-state-accent rounded-full"
                    style={{ width: `${(f.value / f.max) * 100}%` }}
                  />
                </div>
                <Text
                  variant="caption-2"
                  tone="primary"
                  className="font-mono w-7 text-right tabular-nums"
                >
                  {f.value}/{f.max}
                </Text>
              </div>
            ))}
          </div>
        </div>
      </Surface>
    </motion.div>
  );
};

export default IdentityScoreCard;
