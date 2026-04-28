import React from "react";
import { motion } from "framer-motion";
import { Compass, Calendar, TrendingUp } from "lucide-react";
import { usePredictiveNextTrip } from "@/hooks/useTravelContext";
import { cn } from "@/lib/utils";

/**
 * Surfaces the predictive-next-trip block from `/context/current`. Shows real
 * cadence numbers — never fakes them. Hides itself when history is too thin.
 */
const PredictiveNextTripCard: React.FC<{ className?: string }> = ({ className }) => {
  const pred = usePredictiveNextTrip();
  if (!pred || !pred.hasEnoughHistory) return null;

  const dueColor = pred.isDue ? "text-amber-500" : "text-muted-foreground";

  return (
    <motion.div
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
      className={cn(
        "rounded-2xl border border-border bg-card p-4 space-y-3",
        className,
      )}
      data-due={pred.isDue}
    >
      <div className="flex items-center gap-2">
        <Compass className={cn("w-4 h-4", pred.isDue ? "text-amber-500" : "text-primary")} />
        <p className="text-sm font-semibold text-foreground">Trip cadence</p>
        {pred.isDue ? (
          <span className="ml-auto text-[10px] font-bold uppercase tracking-wider text-amber-500 bg-amber-500/10 px-1.5 py-0.5 rounded">
            Due
          </span>
        ) : null}
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div className="space-y-0.5">
          <div className="flex items-center gap-1 text-[10px] uppercase tracking-wider text-muted-foreground">
            <TrendingUp className="w-3 h-3" /> Avg gap
          </div>
          <p className="text-base font-bold text-foreground">
            {pred.cadenceDays !== null ? `${pred.cadenceDays}d` : "—"}
          </p>
        </div>
        <div className="space-y-0.5">
          <div className="flex items-center gap-1 text-[10px] uppercase tracking-wider text-muted-foreground">
            <Calendar className="w-3 h-3" /> Since last
          </div>
          <p className={cn("text-base font-bold", dueColor)}>
            {pred.daysSinceLastTrip !== null ? `${pred.daysSinceLastTrip}d` : "—"}
          </p>
        </div>
      </div>

      <p className="text-[11.5px] text-muted-foreground leading-snug">{pred.reasoning}</p>

      {pred.preferredOrigins.length > 0 ? (
        <div className="flex flex-wrap items-center gap-1.5 pt-1 border-t border-border">
          <span className="text-[10px] uppercase tracking-wider text-muted-foreground">
            Hubs
          </span>
          {pred.preferredOrigins.map((iata) => (
            <span
              key={iata}
              className="text-[10.5px] font-mono font-semibold text-foreground bg-secondary/60 px-1.5 py-0.5 rounded"
            >
              {iata}
            </span>
          ))}
        </div>
      ) : null}
    </motion.div>
  );
};

export default PredictiveNextTripCard;
