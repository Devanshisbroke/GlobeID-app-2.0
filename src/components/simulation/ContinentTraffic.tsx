import React from "react";
import { motion } from "framer-motion";
import { getContinentTraffic } from "@/simulation/PlanetSimulation";
import { MapPin } from "lucide-react";

const data = getContinentTraffic();

const ContinentTraffic: React.FC = () => {
  return (
    <div className="space-y-2">
      <div className="flex items-center gap-1.5 mb-1">
        <MapPin className="w-3 h-3 text-muted-foreground" />
        <span className="text-[10px] text-muted-foreground uppercase tracking-widest font-semibold">Continent Traffic</span>
      </div>
      {data.map((c, i) => (
        <div key={c.name} className="flex items-center gap-2">
          <span className="text-[10px] text-muted-foreground w-24 truncate">{c.name}</span>
          <div className="flex-1 h-2 rounded-full bg-secondary/60 overflow-hidden">
            <motion.div
              className="h-full rounded-full"
              initial={{ width: 0 }}
              animate={{ width: `${c.share}%` }}
              transition={{ duration: 0.8, delay: i * 0.08, ease: [0.22, 1, 0.36, 1] }}
              style={{ background: c.color }}
            />
          </div>
          <span className="text-[10px] font-bold text-foreground tabular-nums w-8 text-right">{c.share}%</span>
        </div>
      ))}
    </div>
  );
};

export default ContinentTraffic;
