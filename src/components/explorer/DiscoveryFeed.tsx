import React from "react";
import { motion } from "framer-motion";
import { MapPin, Star, ChevronRight } from "lucide-react";
import { destinations, type Destination } from "@/lib/explorerData";
import PopularityIndicator from "./PopularityIndicator";

interface Props {
  onSelect: (d: Destination) => void;
  discoveredIds: string[];
}

const DiscoveryFeed: React.FC<Props> = ({ onSelect, discoveredIds }) => {
  const sorted = [...destinations].sort((a, b) => b.popularity - a.popularity);

  return (
    <div className="space-y-2">
      <p className="text-[10px] text-muted-foreground uppercase tracking-widest font-semibold px-1">Trending Destinations</p>
      {sorted.map((d, i) => {
        const discovered = discoveredIds.includes(d.id);
        return (
          <motion.button
            key={d.id}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.04, duration: 0.3 }}
            onClick={() => onSelect(d)}
            className="w-full glass border border-border/30 rounded-xl p-3 flex items-center gap-3 text-left hover:border-primary/20 transition-colors"
          >
            <PopularityIndicator score={d.popularity} />
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-1.5">
                <span className="text-sm">{d.emoji}</span>
                <span className="text-sm font-bold text-foreground">{d.city}</span>
                {discovered && (
                  <span className="text-[8px] px-1.5 py-0.5 rounded-full bg-accent/15 text-accent font-bold">Discovered</span>
                )}
              </div>
              <div className="flex items-center gap-1 mt-0.5">
                <MapPin className="w-2.5 h-2.5 text-muted-foreground" />
                <span className="text-[10px] text-muted-foreground">{d.country} · {d.continent}</span>
              </div>
            </div>
            <ChevronRight className="w-4 h-4 text-muted-foreground/50 shrink-0" />
          </motion.button>
        );
      })}
    </div>
  );
};

export default DiscoveryFeed;
