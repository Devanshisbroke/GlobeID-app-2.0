import React from "react";
import { motion } from "framer-motion";
import { Compass, Globe, Map, Trophy } from "lucide-react";
import { getExplorationProgress, getContinentsDiscovered, destinations } from "@/lib/explorerData";

interface Props {
  discoveredIds: string[];
  currentDestination?: string;
}

const ExplorerHUD: React.FC<Props> = ({ discoveredIds, currentDestination }) => {
  const progress = getExplorationProgress(discoveredIds);
  const continents = getContinentsDiscovered(discoveredIds);
  const current = destinations.find((d) => d.id === currentDestination);

  const stats = [
    { icon: Globe, label: "Discovered", value: `${discoveredIds.length}/${destinations.length}`, color: "text-accent" },
    { icon: Map, label: "Continents", value: `${continents}/6`, color: "text-primary" },
    { icon: Trophy, label: "Progress", value: `${progress}%`, color: "text-sunset-gold" },
  ];

  return (
    <motion.div
      initial={{ opacity: 0, y: -16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
      className="space-y-2"
    >
      {/* Current location */}
      {current && (
        <div className="glass border border-border/30 rounded-xl px-3 py-2 flex items-center gap-2">
          <Compass className="w-3.5 h-3.5 text-accent animate-pulse" />
          <span className="text-[10px] text-muted-foreground">Exploring</span>
          <span className="text-xs font-bold text-foreground">{current.emoji} {current.city}</span>
          <span className="text-[10px] text-muted-foreground ml-auto">{current.country}</span>
        </div>
      )}

      {/* Stats row */}
      <div className="flex gap-2">
        {stats.map((s) => {
          const Icon = s.icon;
          return (
            <div key={s.label} className="flex-1 glass border border-border/30 rounded-xl py-2 px-2.5 text-center">
              <Icon className={`w-3.5 h-3.5 mx-auto mb-0.5 ${s.color}`} strokeWidth={1.8} />
              <p className="text-xs font-bold text-foreground tabular-nums">{s.value}</p>
              <p className="text-[9px] text-muted-foreground">{s.label}</p>
            </div>
          );
        })}
      </div>
    </motion.div>
  );
};

export default ExplorerHUD;
