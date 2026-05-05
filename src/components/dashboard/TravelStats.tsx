import React from "react";
import { Globe, Plane, Route, Map, Leaf } from "lucide-react";
import { Surface, Text } from "@/components/ui/v2";
import { cn } from "@/lib/utils";
import { useUserStore, selectVisitedCountries } from "@/store/userStore";
import AnimatedNumber from "@/components/ui/AnimatedNumber";
import {
  distanceBetween,
  uniqueContinents,
} from "@/lib/distanceEngine";
import { estimateFlightCarbon } from "@/lib/travelInsights";

interface StatDef {
  icon: typeof Globe;
  label: string;
  /** Tuple shape: [numeric value, suffix]. Suffix is rendered after the
   *  ticker so units (km / continents) animate cleanly. */
  getValue: (ctx: TravelStatsCtx) => readonly [number, string];
  halo: string;
}

interface TravelStatsCtx {
  tripCount: number;
  visitedCount: number;
  totalDistanceKm: number;
  continentCount: number;
  totalCo2Kg: number;
}

const statDefs: StatDef[] = [
  {
    icon: Globe,
    label: "Countries",
    getValue: ({ visitedCount }) => [visitedCount, ""] as const,
    halo: "bg-brand-soft text-brand",
  },
  {
    icon: Plane,
    label: "Flights",
    getValue: ({ tripCount }) => [tripCount, ""] as const,
    halo: "bg-state-accent-soft text-state-accent",
  },
  {
    icon: Route,
    label: "Distance",
    getValue: ({ totalDistanceKm }) =>
      [Math.round(totalDistanceKm), " km"] as const,
    halo: "bg-[hsl(var(--p7-warning-soft))] text-[hsl(var(--p7-warning))]",
  },
  {
    icon: Map,
    label: "Continents",
    getValue: ({ continentCount }) => [continentCount, ""] as const,
    halo: "bg-state-accent-soft text-state-accent",
  },
  {
    icon: Leaf,
    label: "CO₂",
    getValue: ({ totalCo2Kg }) => [Math.round(totalCo2Kg), " kg"] as const,
    halo: "bg-emerald-500/15 text-emerald-300",
  },
];

const TravelStats: React.FC = () => {
  const { travelHistory } = useUserStore();
  const visitedCount = React.useMemo(
    () => selectVisitedCountries(travelHistory).length,
    [travelHistory],
  );

  // Real distance summed across all flight legs in history. Memoised
  // because `distanceBetween` does an airport lookup + haversine per
  // call, and travelHistory can be ~100 entries. Replaces the
  // hardcoded 84 200 km placeholder.
  const totalDistanceKm = React.useMemo(() => {
    let total = 0;
    for (const t of travelHistory) {
      total += distanceBetween(t.from, t.to);
    }
    return total;
  }, [travelHistory]);

  // Continents touched across all flight legs (origin + destination).
  const continentCount = React.useMemo(() => {
    const iatas = travelHistory.flatMap((t) => [t.from, t.to]);
    return uniqueContinents(iatas).length;
  }, [travelHistory]);

  // Per-flight CO₂ summed across history. Economy cabin assumed
  // (worst case for the user is overestimating their footprint, so
  // economy under-estimates — fine for the headline tile).
  const totalCo2Kg = React.useMemo(() => {
    let total = 0;
    for (const t of travelHistory) {
      const km = distanceBetween(t.from, t.to);
      total += estimateFlightCarbon(km, "economy").kgCo2e;
    }
    return total;
  }, [travelHistory]);

  return (
    <div className="grid grid-cols-5 gap-2">
      {statDefs.map((stat) => {
        const Icon = stat.icon;
        const [num, suffix] = stat.getValue({
          tripCount: travelHistory.length,
          visitedCount,
          totalDistanceKm,
          continentCount,
          totalCo2Kg,
        });
        return (
          <Surface
            key={stat.label}
            variant="elevated"
            radius="surface"
            className="flex flex-col items-center py-3 px-1 text-center"
          >
            <div
              className={cn(
                "w-9 h-9 rounded-p7-input flex items-center justify-center mb-2",
                stat.halo,
              )}
            >
              <Icon className="w-4 h-4" strokeWidth={1.8} />
            </div>
            <Text variant="body-em" tone="primary" className="tabular-nums">
              <AnimatedNumber
                value={num}
                suffix={suffix}
                duration={650}
                ariaLabel={`${stat.label} ${num}${suffix}`}
              />
            </Text>
            <Text variant="caption-1" tone="tertiary" className="mt-0.5 text-[10px] uppercase tracking-wider">
              {stat.label}
            </Text>
          </Surface>
        );
      })}
    </div>
  );
};

export default TravelStats;
