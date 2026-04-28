import React, { useEffect, useState, useCallback } from "react";
import { Award, Loader2 } from "lucide-react";
import { GlassCard } from "@/components/ui/GlassCard";
import { useLoyaltyStore } from "@/store/loyaltyStore";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

const TIER_COLORS: Record<string, string> = {
  bronze: "from-amber-700 to-amber-500",
  silver: "from-slate-400 to-slate-200",
  gold: "from-yellow-400 to-yellow-200",
  platinum: "from-violet-300 to-pink-200",
};

const LoyaltyPanel: React.FC = () => {
  const snapshot = useLoyaltyStore((s) => s.snapshot);
  const hydrated = useLoyaltyStore((s) => s.hydrated);
  const lastError = useLoyaltyStore((s) => s.lastError);
  const hydrate = useLoyaltyStore((s) => s.hydrate);
  const redeem = useLoyaltyStore((s) => s.redeem);
  const [redeeming, setRedeeming] = useState(false);

  useEffect(() => {
    void hydrate();
  }, [hydrate]);

  const onRedeem = useCallback(
    async (points: number, description: string) => {
      setRedeeming(true);
      try {
        await redeem({ points, description });
      } finally {
        setRedeeming(false);
      }
    },
    [redeem],
  );

  if (!hydrated) {
    return (
      <GlassCard className="p-4 flex items-center gap-2 text-sm text-muted-foreground">
        <Loader2 className="w-4 h-4 animate-spin" /> Loading loyalty…
      </GlassCard>
    );
  }
  if (!snapshot) {
    return (
      <GlassCard className="p-4 text-sm text-destructive">
        {lastError ?? "Loyalty unavailable."}
      </GlassCard>
    );
  }

  const tier = snapshot.tier;
  const grad = TIER_COLORS[tier] ?? TIER_COLORS.bronze;
  return (
    <div className="space-y-3">
      <GlassCard className="p-5">
        <div className="flex items-center gap-3 mb-4">
          <div
            className={cn(
              "w-12 h-12 rounded-2xl flex items-center justify-center bg-gradient-to-br shadow-depth-sm",
              grad,
            )}
          >
            <Award className="w-6 h-6 text-white drop-shadow" />
          </div>
          <div>
            <p className="text-xs uppercase tracking-widest text-muted-foreground">Tier</p>
            <p className="text-xl font-bold text-foreground capitalize">{tier}</p>
          </div>
          <div className="ml-auto text-right">
            <p className="text-xs uppercase tracking-widest text-muted-foreground">Balance</p>
            <p className="text-2xl font-bold text-foreground">{snapshot.totalPoints.toLocaleString()}</p>
          </div>
        </div>
        <div className="grid grid-cols-3 gap-3 text-center">
          <div>
            <p className="text-[10px] uppercase text-muted-foreground">Earned</p>
            <p className="text-sm font-semibold text-foreground">{snapshot.earnedLifetime.toLocaleString()}</p>
          </div>
          <div>
            <p className="text-[10px] uppercase text-muted-foreground">Redeemed</p>
            <p className="text-sm font-semibold text-foreground">{snapshot.redeemedLifetime.toLocaleString()}</p>
          </div>
          <div>
            <p className="text-[10px] uppercase text-muted-foreground">To next tier</p>
            <p className="text-sm font-semibold text-foreground">
              {snapshot.pointsToNextTier !== null ? snapshot.pointsToNextTier.toLocaleString() : "max"}
            </p>
          </div>
        </div>
      </GlassCard>

      <div className="grid grid-cols-3 gap-2">
        {[
          { pts: 500, label: "$5 wallet credit" },
          { pts: 2000, label: "Lounge access" },
          { pts: 5000, label: "Free eSIM 1GB" },
        ].map((r) => (
          <Button
            key={r.pts}
            variant="outline"
            size="sm"
            disabled={redeeming || snapshot.totalPoints < r.pts}
            onClick={() => onRedeem(r.pts, r.label)}
            className="text-[11px] flex-col h-auto py-2"
          >
            <span className="font-bold">{r.pts}</span>
            <span className="text-muted-foreground">{r.label}</span>
          </Button>
        ))}
      </div>

      <GlassCard className="p-4">
        <p className="text-xs uppercase tracking-widest text-muted-foreground mb-2">Recent ledger</p>
        {snapshot.recent.length === 0 ? (
          <p className="text-xs text-muted-foreground">No activity yet.</p>
        ) : (
          <div className="space-y-1.5 max-h-56 overflow-y-auto">
            {snapshot.recent.map((tx) => (
              <div key={tx.id} className="flex items-center justify-between text-xs">
                <div className="flex-1 truncate">
                  <span className="text-foreground font-medium">{tx.description}</span>
                  <span className="text-muted-foreground ml-2 capitalize">{tx.kind.replace("_", " ")}</span>
                </div>
                <span className={cn("font-bold ml-2", tx.points >= 0 ? "text-emerald-500" : "text-rose-500")}>
                  {tx.points >= 0 ? "+" : ""}
                  {tx.points}
                </span>
              </div>
            ))}
          </div>
        )}
      </GlassCard>
    </div>
  );
};

export default React.memo(LoyaltyPanel);
