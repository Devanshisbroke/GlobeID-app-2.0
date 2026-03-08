import React from "react";
import { motion } from "framer-motion";
import { TrendingUp, TrendingDown, Plane } from "lucide-react";
import { cn } from "@/lib/utils";
import { type DestinationData } from "@/lib/destinationAnalytics";
import { cinematicEase } from "@/cinematic/motionEngine";

interface DestinationCardProps {
  dest: DestinationData;
  rank?: number;
  index?: number;
  className?: string;
}

const DestinationCard: React.FC<DestinationCardProps> = ({ dest, rank, index = 0, className }) => {
  const isGrowing = dest.growth > 0;

  return (
    <motion.div
      initial={{ opacity: 0, y: 14, filter: "blur(4px)" }}
      animate={{ opacity: 1, y: 0, filter: "blur(0px)" }}
      transition={{ delay: index * 0.05, duration: 0.4, ease: cinematicEase }}
      className={cn("glass rounded-xl p-3.5 active:scale-[0.98] transition-transform", className)}
    >
      <div className="flex items-center gap-3">
        {rank !== undefined && (
          <div className="w-7 h-7 rounded-lg bg-primary/10 flex items-center justify-center shrink-0">
            <span className="text-xs font-bold text-primary">#{rank}</span>
          </div>
        )}
        <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-[hsl(var(--primary))] to-[hsl(var(--ocean-aqua))] flex items-center justify-center shrink-0">
          <Plane className="w-4 h-4 text-primary-foreground" />
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-sm font-semibold text-foreground truncate">{dest.city}</p>
          <p className="text-[10px] text-muted-foreground">{dest.country} · {dest.continent}</p>
        </div>
        <div className="text-right shrink-0">
          <p className="text-sm font-bold text-foreground">{dest.popularity}</p>
          <div className={cn("flex items-center gap-0.5 text-[10px] font-medium", isGrowing ? "text-accent" : "text-destructive")}>
            {isGrowing ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />}
            {isGrowing ? "+" : ""}{dest.growth}%
          </div>
        </div>
      </div>
      {/* Mini traffic chart */}
      <div className="mt-2.5 flex items-end gap-px h-6">
        {dest.monthlyTraffic.map((v, i) => (
          <motion.div
            key={i}
            className="flex-1 rounded-t-sm bg-primary/20"
            initial={{ height: 0 }}
            animate={{ height: `${(v / 100) * 100}%` }}
            transition={{ delay: index * 0.05 + i * 0.03, duration: 0.4, ease: cinematicEase }}
          />
        ))}
      </div>
    </motion.div>
  );
};

export default DestinationCard;
