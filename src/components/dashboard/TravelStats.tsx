import React from "react";
import { Globe, Plane, Route, Map } from "lucide-react";
import { Surface, Text } from "@/components/ui/v2";
import { cn } from "@/lib/utils";
import { useUserStore, selectVisitedCountries } from "@/store/userStore";

interface StatDef {
  icon: typeof Globe;
  label: string;
  getValue: (ctx: { tripCount: number; visitedCount: number }) => string;
  halo: string;
}

const statDefs: StatDef[] = [
  {
    icon: Globe,
    label: "Countries",
    getValue: ({ visitedCount }) => visitedCount.toString(),
    halo: "bg-brand-soft text-brand",
  },
  {
    icon: Plane,
    label: "Flights",
    getValue: ({ tripCount }) => tripCount.toString(),
    halo: "bg-state-accent-soft text-state-accent",
  },
  {
    icon: Route,
    label: "Distance",
    getValue: () => "84,200 km",
    halo: "bg-[hsl(var(--p7-warning-soft))] text-[hsl(var(--p7-warning))]",
  },
  {
    icon: Map,
    label: "Continents",
    getValue: () => "4",
    halo: "bg-state-accent-soft text-state-accent",
  },
];

const TravelStats: React.FC = () => {
  const { travelHistory } = useUserStore();
  const visitedCount = React.useMemo(
    () => selectVisitedCountries(travelHistory).length,
    [travelHistory],
  );

  return (
    <div className="grid grid-cols-4 gap-2">
      {statDefs.map((stat) => {
        const Icon = stat.icon;
        const value = stat.getValue({ tripCount: travelHistory.length, visitedCount });
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
              {value}
            </Text>
            <Text variant="caption-2" tone="tertiary" className="mt-0.5">
              {stat.label}
            </Text>
          </Surface>
        );
      })}
    </div>
  );
};

export default TravelStats;
