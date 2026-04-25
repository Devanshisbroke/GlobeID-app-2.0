import React from "react";
import { motion } from "framer-motion";
import { achievements, getContinentsDiscovered } from "@/lib/explorerData";
import { Award } from "lucide-react";

interface Props {
  discoveredIds: string[];
  landmarkCount: number;
}

const DiscoveryAchievements: React.FC<Props> = ({ discoveredIds, landmarkCount }) => {
  const continents = getContinentsDiscovered(discoveredIds);

  const getProgress = (a: typeof achievements[0]) => {
    switch (a.type) {
      case "destinations": return Math.min(discoveredIds.length / a.requirement, 1);
      case "landmarks": return Math.min(landmarkCount / a.requirement, 1);
      case "continents": return Math.min(continents / a.requirement, 1);
      default: return 0;
    }
  };

  return (
    <div className="space-y-2">
      <div className="flex items-center gap-1.5 px-1">
        <Award className="w-3.5 h-3.5 text-warning" strokeWidth={1.8} />
        <p className="text-[10px] text-muted-foreground uppercase tracking-widest font-semibold">Achievements</p>
      </div>
      {achievements.map((a, i) => {
        const progress = getProgress(a);
        const unlocked = progress >= 1;
        return (
          <motion.div
            key={a.id}
            initial={{ opacity: 0, x: -8 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: i * 0.05 }}
            className={`glass border rounded-xl p-3 flex items-center gap-3 ${unlocked ? "border-accent/30" : "border-border/30"}`}
          >
            <span className="text-lg">{a.icon}</span>
            <div className="flex-1 min-w-0">
              <p className={`text-xs font-bold ${unlocked ? "text-accent" : "text-foreground"}`}>{a.name}</p>
              <p className="text-[10px] text-muted-foreground">{a.description}</p>
              <div className="mt-1.5 h-1 rounded-full bg-secondary/60 overflow-hidden">
                <motion.div
                  className="h-full rounded-full"
                  style={{ background: unlocked ? "hsl(var(--accent))" : "hsl(var(--primary))" }}
                  initial={{ width: 0 }}
                  animate={{ width: `${progress * 100}%` }}
                  transition={{ duration: 0.6, delay: i * 0.05 }}
                />
              </div>
            </div>
            {unlocked && <span className="text-[9px] px-1.5 py-0.5 rounded-full bg-accent/15 text-accent font-bold shrink-0">✓</span>}
          </motion.div>
        );
      })}
    </div>
  );
};

export default DiscoveryAchievements;
