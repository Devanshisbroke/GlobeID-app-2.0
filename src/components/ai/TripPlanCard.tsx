import React from "react";
import { motion } from "framer-motion";
import { MapPin, Clock, ChevronRight } from "lucide-react";
import type { GeneratedStop } from "@/lib/tripGenerator";
import { cn } from "@/lib/utils";

interface TripPlanCardProps {
  stop: GeneratedStop;
  index: number;
  total: number;
  isActive?: boolean;
  onClick?: () => void;
}

const TripPlanCard: React.FC<TripPlanCardProps> = ({ stop, index, total, isActive, onClick }) => (
  <motion.div
    initial={{ opacity: 0, x: -20 }}
    animate={{ opacity: 1, x: 0 }}
    transition={{ type: "spring", stiffness: 300, damping: 25, delay: index * 0.08 }}
    onClick={onClick}
    className={cn(
      "relative flex items-center gap-3 px-4 py-3 rounded-xl cursor-pointer transition-all",
      "glass border",
      isActive
        ? "border-primary/40 shadow-glow-sm bg-primary/5"
        : "border-border/30 hover:border-primary/20"
    )}
  >
    {/* Timeline connector */}
    <div className="flex flex-col items-center gap-0.5">
      <div className={cn(
        "w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold",
        index === 0 ? "bg-accent text-accent-foreground" :
        index === total - 1 ? "bg-primary text-primary-foreground" :
        "bg-primary/15 text-primary"
      )}>
        {index + 1}
      </div>
      {index < total - 1 && (
        <div className="w-px h-4 bg-gradient-to-b from-primary/30 to-transparent" />
      )}
    </div>

    <div className="flex-1 min-w-0">
      <div className="flex items-center gap-1.5">
        <MapPin className="w-3.5 h-3.5 text-primary" />
        <span className="text-sm font-semibold text-foreground">{stop.city}</span>
        <span className="text-[10px] font-mono text-muted-foreground">{stop.iata}</span>
      </div>
      <p className="text-xs text-muted-foreground mt-0.5">{stop.country}</p>
    </div>

    <div className="flex items-center gap-1 px-2 py-1 rounded-lg bg-secondary/50">
      <Clock className="w-3 h-3 text-muted-foreground" />
      <span className="text-xs font-medium text-foreground">{stop.days}d</span>
    </div>

    {index < total - 1 && (
      <ChevronRight className="w-3.5 h-3.5 text-muted-foreground/40" />
    )}
  </motion.div>
);

export default TripPlanCard;
