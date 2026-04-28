import React, { useEffect } from "react";
import { Globe2, Loader2, MapPin, Plane, Calendar } from "lucide-react";
import { GlassCard } from "@/components/ui/GlassCard";
import { useScoreStore } from "@/store/scoreStore";

const TIER_COLOR: Record<string, string> = {
  rookie: "text-slate-400",
  explorer: "text-emerald-400",
  globetrotter: "text-sky-400",
  ambassador: "text-violet-400",
  legend: "text-amber-300",
};

const ScorePanel: React.FC = () => {
  const score = useScoreStore((s) => s.score);
  const hydrated = useScoreStore((s) => s.hydrated);
  const hydrate = useScoreStore((s) => s.hydrate);
  const lastError = useScoreStore((s) => s.lastError);

  useEffect(() => {
    void hydrate();
  }, [hydrate]);

  if (!hydrated) {
    return (
      <GlassCard className="p-4 flex items-center gap-2 text-sm text-muted-foreground">
        <Loader2 className="w-4 h-4 animate-spin" /> Computing score…
      </GlassCard>
    );
  }
  if (!score) {
    return <GlassCard className="p-4 text-sm text-destructive">{lastError ?? "Score unavailable."}</GlassCard>;
  }

  const radius = 60;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference - (score.score / 1000) * circumference;
  const color = TIER_COLOR[score.tier] ?? "text-foreground";

  return (
    <div className="space-y-3">
      <GlassCard className="p-5 flex items-center gap-5">
        <svg width="160" height="160" viewBox="0 0 160 160" className="-my-2">
          <circle cx="80" cy="80" r={radius} stroke="currentColor" strokeWidth="10" fill="none" className="text-secondary" />
          <circle
            cx="80"
            cy="80"
            r={radius}
            stroke="currentColor"
            strokeWidth="10"
            fill="none"
            strokeLinecap="round"
            strokeDasharray={circumference}
            strokeDashoffset={offset}
            transform="rotate(-90 80 80)"
            className={color}
          />
          <text x="80" y="76" textAnchor="middle" className={`text-3xl font-bold fill-current ${color}`}>
            {score.score}
          </text>
          <text x="80" y="98" textAnchor="middle" className="text-[10px] uppercase tracking-widest fill-current text-muted-foreground">
            / 1000
          </text>
        </svg>
        <div className="flex-1 space-y-2">
          <p className="text-xs uppercase tracking-widest text-muted-foreground">Travel score</p>
          <p className={`text-2xl font-bold capitalize ${color}`}>{score.tier}</p>
          <p className="text-xs text-muted-foreground">
            {score.pointsToNextTier !== null ? `${score.pointsToNextTier} pts to next tier` : "Max tier reached"}
          </p>
        </div>
      </GlassCard>

      <div className="grid grid-cols-2 gap-2">
        <BreakdownTile icon={MapPin} label="Cities" value={score.breakdown.citiesVisited} />
        <BreakdownTile icon={Globe2} label="Countries" value={score.breakdown.countriesVisited} />
        <BreakdownTile icon={Plane} label="Flights" value={score.breakdown.flightsCompleted} />
        <BreakdownTile
          icon={Globe2}
          label="km flown"
          value={score.breakdown.kilometersFlown.toLocaleString()}
        />
        <BreakdownTile icon={Calendar} label="Streak (mo)" value={score.breakdown.monthlyStreak} />
        <BreakdownTile icon={Calendar} label="Upcoming" value={score.breakdown.upcomingTrips} />
      </div>
    </div>
  );
};

const BreakdownTile = React.memo(function BreakdownTile({
  icon: Icon,
  label,
  value,
}: {
  icon: React.ElementType;
  label: string;
  value: string | number;
}) {
  return (
    <GlassCard className="p-3 flex items-center gap-3">
      <div className="w-9 h-9 rounded-xl bg-secondary/50 flex items-center justify-center">
        <Icon className="w-4 h-4 text-foreground" />
      </div>
      <div>
        <p className="text-[10px] uppercase text-muted-foreground">{label}</p>
        <p className="text-base font-bold text-foreground">{value}</p>
      </div>
    </GlassCard>
  );
});

export default React.memo(ScorePanel);
