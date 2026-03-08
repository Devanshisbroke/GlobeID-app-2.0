import React, { useState } from "react";
import { motion } from "framer-motion";
import { TrendingUp, Sparkles } from "lucide-react";
import { cn } from "@/lib/utils";
import { getTopDestinations, getFastestGrowing, getByContinent } from "@/lib/destinationAnalytics";
import { getTopPredictions, getCategoryColor } from "@/lib/travelPrediction";
import { cinematicEase } from "@/cinematic/motionEngine";

const continents = ["All", "Asia", "Europe", "North America", "Middle East", "Oceania", "Africa"];

const TravelTrends: React.FC<{ className?: string }> = ({ className }) => {
  const [selectedContinent, setSelectedContinent] = useState("All");
  const top = selectedContinent === "All" ? getTopDestinations(6) : getByContinent(selectedContinent).slice(0, 6);
  const growing = getFastestGrowing(4);
  const predicted = getTopPredictions(4);

  return (
    <div className={cn("space-y-5", className)}>
      {/* Continent filter */}
      <div className="flex gap-1.5 overflow-x-auto pb-1 scrollbar-hide">
        {continents.map((c) => (
          <button
            key={c}
            onClick={() => setSelectedContinent(c)}
            className={cn(
              "px-3 py-1.5 rounded-lg text-[10px] font-medium whitespace-nowrap transition-colors shrink-0",
              selectedContinent === c ? "bg-primary text-primary-foreground" : "glass text-muted-foreground"
            )}
          >
            {c}
          </button>
        ))}
      </div>

      {/* Top destinations bar chart */}
      <div>
        <p className="text-xs font-semibold text-muted-foreground uppercase tracking-widest mb-3">Popularity Index</p>
        <div className="space-y-2">
          {top.map((d, i) => (
            <motion.div
              key={d.iata}
              initial={{ opacity: 0, x: -12 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: i * 0.04, duration: 0.35, ease: cinematicEase }}
              className="flex items-center gap-2"
            >
              <span className="text-[10px] font-mono text-muted-foreground w-8">{d.iata}</span>
              <div className="flex-1 h-4 rounded-full bg-secondary/50 overflow-hidden">
                <motion.div
                  className="h-full rounded-full bg-gradient-to-r from-[hsl(var(--primary))] to-[hsl(var(--ocean-aqua))]"
                  initial={{ width: 0 }}
                  animate={{ width: `${d.popularity}%` }}
                  transition={{ delay: i * 0.06, duration: 0.6, ease: cinematicEase }}
                />
              </div>
              <span className="text-[10px] font-bold text-foreground w-6 text-right">{d.popularity}</span>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Fastest growing */}
      <div>
        <p className="text-xs font-semibold text-muted-foreground uppercase tracking-widest mb-3 flex items-center gap-1.5">
          <TrendingUp className="w-3.5 h-3.5" /> Fastest Growing
        </p>
        <div className="grid grid-cols-2 gap-2">
          {growing.map((d, i) => (
            <motion.div
              key={d.iata}
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: i * 0.06, duration: 0.35, ease: cinematicEase }}
              className="glass rounded-lg p-3 text-center"
            >
              <p className="text-sm font-bold text-foreground">{d.city}</p>
              <p className="text-accent text-xs font-semibold">+{d.growth}%</p>
              <p className="text-[9px] text-muted-foreground">{d.continent}</p>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Predictions */}
      <div>
        <p className="text-xs font-semibold text-muted-foreground uppercase tracking-widest mb-3 flex items-center gap-1.5">
          <Sparkles className="w-3.5 h-3.5" /> AI Predictions
        </p>
        <div className="space-y-2">
          {predicted.map((p, i) => (
            <motion.div
              key={p.city}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.06, duration: 0.35, ease: cinematicEase }}
              className="glass rounded-lg p-3 flex items-center gap-3"
            >
              <span className="text-lg">{p.flag}</span>
              <div className="flex-1 min-w-0">
                <p className="text-xs font-semibold text-foreground">{p.city}, {p.country}</p>
                <p className="text-[10px] text-muted-foreground truncate">{p.reason}</p>
              </div>
              <span className={cn("text-[10px] font-bold uppercase", getCategoryColor(p.trendCategory))}>
                {p.trendCategory}
              </span>
            </motion.div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default TravelTrends;
