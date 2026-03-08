import React from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { Globe, Plane, Route, Map } from "lucide-react";
import { cn } from "@/lib/utils";
import { visitedCountries } from "@/lib/airports";
import { useUserStore } from "@/store/userStore";

const stats = [
  {
    icon: Globe,
    label: "Countries",
    getValue: () => visitedCountries.length.toString(),
    gradient: "from-primary/12 to-primary/5",
    color: "text-primary",
  },
  {
    icon: Plane,
    label: "Flights",
    getValue: (tripCount: number) => tripCount.toString(),
    gradient: "from-accent/12 to-accent/5",
    color: "text-accent",
  },
  {
    icon: Route,
    label: "Distance",
    getValue: () => "84,200 km",
    gradient: "from-neon-amber/12 to-neon-amber/5",
    color: "text-neon-amber",
  },
  {
    icon: Map,
    label: "Continents",
    getValue: () => "4",
    gradient: "from-aurora-purple/12 to-aurora-purple/5",
    color: "text-aurora-purple",
  },
];

const TravelStats: React.FC = () => {
  const { travelHistory } = useUserStore();

  return (
    <div className="grid grid-cols-4 gap-2">
      {stats.map((stat) => {
        const Icon = stat.icon;
        const value = stat.getValue(travelHistory.length);
        return (
          <GlassCard key={stat.label} className="flex flex-col items-center py-3 px-1 text-center" depth="sm">
            <div className={cn("w-9 h-9 rounded-xl flex items-center justify-center mb-2 bg-gradient-to-br", stat.gradient)}>
              <Icon className={cn("w-4 h-4", stat.color)} strokeWidth={1.8} />
            </div>
            <p className="text-sm font-bold text-foreground tabular-nums">{value}</p>
            <p className="text-[9px] text-muted-foreground mt-0.5">{stat.label}</p>
          </GlassCard>
        );
      })}
    </div>
  );
};

export default TravelStats;
