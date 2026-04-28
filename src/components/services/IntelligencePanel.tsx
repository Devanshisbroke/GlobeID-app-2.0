import React, { useEffect } from "react";
import { Brain, Bell, ArrowRight } from "lucide-react";
import { Link } from "react-router-dom";
import { GlassCard } from "@/components/ui/GlassCard";
import { useIntelligence } from "@/core/useIntelligence";
import { useLifecycleStore } from "@/store/lifecycleStore";
import { useWeatherStore } from "@/store/weatherStore";
import { useScoreStore } from "@/store/scoreStore";
import { useLoyaltyStore } from "@/store/loyaltyStore";
import { useBudgetStore } from "@/store/budgetStore";
import { useFraudStore } from "@/store/fraudStore";
import { useSafetyStore } from "@/store/safetyStore";
import { useWalletStore } from "@/store/walletStore";
import { cn } from "@/lib/utils";
import { nextLeg } from "@/core/travelEngine";

const PRIORITY_DOT = (p: number) =>
  p >= 90
    ? "bg-rose-500"
    : p >= 70
      ? "bg-amber-500"
      : p >= 40
        ? "bg-sky-500"
        : "bg-slate-400";

const IntelligencePanel: React.FC = () => {
  // Hydrate every backing store on mount. Each is idempotent + cheap; the
  // Intelligence panel is the natural "everything-in-one" entry point so
  // hydrating here means the engine has real inputs even if the user
  // skipped the per-domain panels first.
  const hydrateLifecycle = useLifecycleStore((s) => s.hydrate);
  const hydrateScore = useScoreStore((s) => s.hydrate);
  const hydrateLoyalty = useLoyaltyStore((s) => s.hydrate);
  const hydrateBudget = useBudgetStore((s) => s.hydrate);
  const refreshFraud = useFraudStore((s) => s.refresh);
  const hydrateSafety = useSafetyStore((s) => s.hydrate);
  const hydrateWallet = useWalletStore((s) => s.hydrate);
  const trips = useLifecycleStore((s) => s.trips);
  const fetchWeather = useWeatherStore((s) => s.fetchFor);

  useEffect(() => {
    void hydrateLifecycle();
    void hydrateScore();
    void hydrateLoyalty();
    void hydrateBudget();
    void refreshFraud();
    void hydrateSafety();
    void hydrateWallet();
  }, [hydrateLifecycle, hydrateScore, hydrateLoyalty, hydrateBudget, refreshFraud, hydrateSafety, hydrateWallet]);

  // Once trips are hydrated, prefetch weather for the next leg destination.
  useEffect(() => {
    const upcoming = trips.find((t) => t.state !== "complete");
    if (!upcoming) return;
    const leg = nextLeg(upcoming);
    if (leg) void fetchWeather(leg.toIata);
  }, [trips, fetchWeather]);

  const { context, services } = useIntelligence();

  return (
    <div className="space-y-3">
      <GlassCard className="p-4">
        <div className="flex items-center gap-2 mb-2">
          <Brain className="w-5 h-5 text-primary" />
          <p className="text-sm font-bold text-foreground">Live recommendations</p>
          <span className="ml-auto text-[10px] uppercase tracking-widest text-muted-foreground">
            {context.recommendations.length} signals
          </span>
        </div>
        {context.recommendations.length === 0 ? (
          <p className="text-xs text-muted-foreground">
            All systems quiet. Recommendations will surface here as your wallet, trips, weather and fraud signals
            change.
          </p>
        ) : (
          <ul className="space-y-2">
            {context.recommendations.slice(0, 8).map((r) => (
              <li key={r.id} className="flex items-start gap-2">
                <span
                  className={cn(
                    "w-1.5 h-1.5 rounded-full mt-1.5 shrink-0",
                    PRIORITY_DOT(r.priority),
                  )}
                />
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between gap-2">
                    <p className="text-xs font-semibold text-foreground truncate">{r.title}</p>
                    <span className="text-[10px] uppercase tracking-widest text-muted-foreground shrink-0">
                      p{r.priority}
                    </span>
                  </div>
                  <p className="text-[11px] text-muted-foreground">{r.description}</p>
                </div>
                {r.ctaPath && (
                  <Link
                    to={r.ctaPath}
                    className="text-muted-foreground hover:text-foreground transition-colors"
                    aria-label="Open recommendation"
                  >
                    <ArrowRight className="w-3.5 h-3.5" />
                  </Link>
                )}
              </li>
            ))}
          </ul>
        )}
      </GlassCard>

      <GlassCard className="p-4">
        <div className="flex items-center gap-2 mb-2">
          <Bell className="w-5 h-5 text-primary" />
          <p className="text-sm font-bold text-foreground">Service ranking</p>
        </div>
        <div className="grid grid-cols-2 gap-2">
          {services.map((s) => (
            <div key={s.tab} className="rounded-lg bg-secondary/40 p-2">
              <div className="flex items-center justify-between text-xs">
                <span className="font-semibold text-foreground capitalize">{s.tab}</span>
                <span className="text-[10px] text-muted-foreground">{s.score.toFixed(1)}</span>
              </div>
              <p className="text-[10px] text-muted-foreground truncate">{s.reason}</p>
            </div>
          ))}
        </div>
      </GlassCard>

      <GlassCard className="p-4">
        <p className="text-xs uppercase tracking-widest text-muted-foreground mb-2">Engine summary</p>
        <div className="grid grid-cols-2 gap-2 text-[11px]">
          <Stat label="Active trip" value={context.summary.activeTripId ?? "—"} mono />
          <Stat
            label="Next leg in"
            value={
              context.summary.nextLegInMs === null
                ? "—"
                : context.summary.nextLegInMs <= 0
                  ? "now"
                  : formatDur(context.summary.nextLegInMs)
            }
          />
          <Stat label="Boarding now" value={context.summary.boardingNow ? "yes" : "no"} />
          <Stat label="Delay severity" value={context.summary.delaySeverity} />
          <Stat label="Fraud (high)" value={String(context.summary.fraudHighCount)} />
          <Stat label="Budgets over" value={String(context.summary.budgetOverCount)} />
        </div>
      </GlassCard>
    </div>
  );
};

const Stat = React.memo(function Stat({
  label,
  value,
  mono,
}: {
  label: string;
  value: string;
  mono?: boolean;
}) {
  return (
    <div className="rounded-lg bg-secondary/40 p-2">
      <p className="text-[10px] uppercase text-muted-foreground">{label}</p>
      <p className={cn("text-foreground font-semibold capitalize", mono && "font-mono normal-case")}>{value}</p>
    </div>
  );
});

function formatDur(ms: number): string {
  if (ms < 60_000) return "<1m";
  const min = Math.floor(ms / 60_000);
  if (min < 60) return `${min}m`;
  const h = Math.floor(min / 60);
  const m = min % 60;
  return m === 0 ? `${h}h` : `${h}h ${m}m`;
}

export default React.memo(IntelligencePanel);
