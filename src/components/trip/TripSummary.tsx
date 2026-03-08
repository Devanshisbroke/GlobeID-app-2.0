import React from "react";
import { motion } from "framer-motion";
import { Plane, Globe, MapPin, Ruler } from "lucide-react";
import { useTripPlannerStore } from "@/store/tripPlannerStore";
import { totalJourneyDistance, uniqueCountries, uniqueContinents, distanceBetween, estimateDuration } from "@/lib/distanceEngine";
import { getAirport } from "@/lib/airports";

const StatCard: React.FC<{ icon: React.ElementType; label: string; value: string | number }> = ({ icon: Icon, label, value }) => (
  <motion.div
    initial={{ opacity: 0, scale: 0.9 }}
    animate={{ opacity: 1, scale: 1 }}
    className="glass rounded-xl border border-border/30 p-3 flex flex-col items-center gap-1"
  >
    <Icon className="w-4 h-4 text-primary" />
    <span className="text-lg font-bold text-foreground">{value}</span>
    <span className="text-[10px] text-muted-foreground uppercase tracking-wider">{label}</span>
  </motion.div>
);

const TripSummary: React.FC = () => {
  const { currentDestinations } = useTripPlannerStore();

  if (currentDestinations.length < 2) {
    return (
      <div className="text-center py-8 text-muted-foreground text-sm">
        Add at least 2 destinations to see trip summary
      </div>
    );
  }

  const distance = totalJourneyDistance(currentDestinations);
  const countries = uniqueCountries(currentDestinations);
  const continents = uniqueContinents(currentDestinations);
  const flights = currentDestinations.length - 1;

  return (
    <div className="space-y-4">
      {/* Stats grid */}
      <div className="grid grid-cols-2 gap-2">
        <StatCard icon={Plane} label="Flights" value={flights} />
        <StatCard icon={Ruler} label="Distance" value={`${(distance / 1000).toFixed(1)}k km`} />
        <StatCard icon={MapPin} label="Countries" value={countries.length} />
        <StatCard icon={Globe} label="Continents" value={continents.length} />
      </div>

      {/* Leg breakdown */}
      <div className="space-y-1.5">
        <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider px-1">Legs</p>
        {currentDestinations.slice(0, -1).map((iata, idx) => {
          const next = currentDestinations[idx + 1];
          const from = getAirport(iata);
          const to = getAirport(next);
          const dist = distanceBetween(iata, next);
          return (
            <motion.div
              key={`${iata}-${next}`}
              initial={{ opacity: 0, x: 8 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: idx * 0.05 }}
              className="flex items-center gap-2 px-3 py-2 rounded-lg glass border border-border/20 text-xs"
            >
              <span className="font-mono font-bold text-foreground">{iata}</span>
              <span className="text-muted-foreground">→</span>
              <span className="font-mono font-bold text-foreground">{next}</span>
              <span className="flex-1" />
              <span className="text-muted-foreground">{dist.toLocaleString()} km</span>
              <span className="text-muted-foreground/60">·</span>
              <span className="text-muted-foreground">{estimateDuration(dist)}</span>
            </motion.div>
          );
        })}
      </div>

      {/* Countries */}
      <div className="flex flex-wrap gap-1.5">
        {countries.map((c) => (
          <span key={c} className="px-2 py-0.5 rounded-full text-[10px] font-medium bg-primary/10 text-primary border border-primary/20">
            {c}
          </span>
        ))}
      </div>
    </div>
  );
};

export default TripSummary;
