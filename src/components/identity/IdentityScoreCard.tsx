import React, { useState } from "react";
import { motion } from "motion/react";
import { IdentityScore } from "@/components/ui/IdentityScore";
import { Surface, Text, ease, duration } from "@/components/ui/v2";
import { useUserStore } from "@/store/userStore";
import { cn } from "@/lib/utils";
import { haptics } from "@/utils/haptics";
import ScoreFactorDrawer from "./ScoreFactorDrawer";
import {
  SCORE_FACTOR_META,
  type ScoreFactorMeta,
} from "./scoreFactorMeta";
import { progressToNextTier } from "@/lib/identityTier";
import IdentityScoreSparkline from "./IdentityScoreSparkline";

const TIER_TONE_CLASS: Record<string, string> = {
  muted: "bg-slate-500/15 text-slate-200 ring-slate-400/20",
  info: "bg-sky-500/15 text-sky-200 ring-sky-400/20",
  success: "bg-emerald-500/15 text-emerald-200 ring-emerald-400/20",
  premium: "bg-amber-500/15 text-amber-200 ring-amber-400/20",
};

interface FactorRow {
  id: string;
  label: string;
  value: number;
  max: number;
}

const factors: readonly FactorRow[] = [
  { id: "documents-verified", label: "Documents Verified", value: 5, max: 5 },
  { id: "countries-visited", label: "Countries Visited", value: 12, max: 20 },
  { id: "travel-activity", label: "Travel Activity", value: 8, max: 10 },
  { id: "biometric-match", label: "Biometric Match", value: 1, max: 1 },
];

const IdentityScoreCard: React.FC<{ className?: string }> = ({ className }) => {
  const { profile } = useUserStore();
  const [activeFactor, setActiveFactor] = useState<ScoreFactorMeta | null>(null);
  const tier = progressToNextTier(profile.identityScore);

  const handleFactorTap = (id: string) => {
    haptics.selection();
    const meta = SCORE_FACTOR_META.find((m) => m.id === id);
    if (meta) setActiveFactor(meta);
  };

  return (
    <>
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
              <div className="flex items-center justify-between gap-2">
                <Text variant="caption-1" tone="tertiary" className="uppercase tracking-wider">
                  Identity Score
                </Text>
                {/* E 58 — weekly trend sparkline */}
                <IdentityScoreSparkline />
              </div>
              <div className="flex items-center justify-between gap-2 -mt-1">
                <span className="text-[10px] text-muted-foreground">Tier</span>
                {/* E 68 — tier badge */}
                <span
                  className={cn(
                    "inline-flex items-center rounded-full px-2 py-[2px] text-[9px] font-semibold uppercase tracking-wider ring-1",
                    TIER_TONE_CLASS[tier.current.tone] ?? TIER_TONE_CLASS.muted,
                  )}
                  aria-label={tier.current.label}
                >
                  {tier.current.label.split("·")[1]?.trim() ?? "Tier"}
                </span>
              </div>
              {tier.next ? (
                <p className="text-[10px] text-muted-foreground">
                  {tier.remaining} pts to {tier.next.label.split("·")[1]?.trim()} · {tier.current.unlocks}
                </p>
              ) : (
                <p className="text-[10px] text-muted-foreground">
                  {tier.current.unlocks}
                </p>
              )}
              {factors.map((f) => (
                <button
                  key={f.id}
                  type="button"
                  onClick={() => handleFactorTap(f.id)}
                  className="group w-full flex items-center gap-2 -mx-1 px-1 py-0.5 rounded-md text-left min-h-[28px] hover:bg-surface-overlay/40 active:bg-surface-overlay/60 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--p7-ring))]"
                  aria-label={`Learn more about ${f.label}`}
                >
                  <Text variant="caption-2" tone="secondary" className="flex-1 group-hover:text-foreground transition-colors">
                    {f.label}
                  </Text>
                  <div className="w-16 h-1 rounded-full bg-surface-overlay overflow-hidden">
                    <motion.div
                      className="h-full bg-state-accent rounded-full"
                      initial={{ width: 0 }}
                      animate={{ width: `${(f.value / f.max) * 100}%` }}
                      transition={{ duration: 0.6, ease: ease.standard, delay: 0.1 }}
                    />
                  </div>
                  <Text
                    variant="caption-2"
                    tone="primary"
                    className="font-mono w-7 text-right tabular-nums"
                  >
                    {f.value}/{f.max}
                  </Text>
                </button>
              ))}
            </div>
          </div>
        </Surface>
      </motion.div>
      <ScoreFactorDrawer
        factor={activeFactor}
        onClose={() => setActiveFactor(null)}
      />
    </>
  );
};

export default IdentityScoreCard;
