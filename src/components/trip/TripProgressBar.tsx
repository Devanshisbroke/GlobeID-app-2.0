import React from "react";
import { motion } from "framer-motion";
import { getAirport } from "@/lib/airports";
import { useTripPlannerStore } from "@/store/tripPlannerStore";
import { cn } from "@/lib/utils";

const TripProgressBar: React.FC = () => {
  const { currentDestinations } = useTripPlannerStore();
  if (currentDestinations.length < 2) return null;

  return (
    <div className="flex items-center gap-0 overflow-x-auto hide-scrollbar py-2">
      {currentDestinations.map((iata, idx) => {
        const apt = getAirport(iata);
        return (
          <React.Fragment key={iata}>
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ type: "spring", stiffness: 400, damping: 20, delay: idx * 0.06 }}
              className={cn(
                "flex-shrink-0 flex flex-col items-center",
                idx === 0 && "text-accent",
                idx === currentDestinations.length - 1 && "text-primary"
              )}
            >
              <div className={cn(
                "w-3 h-3 rounded-full border-2",
                idx === 0 ? "bg-accent border-accent" :
                idx === currentDestinations.length - 1 ? "bg-primary border-primary" :
                "bg-primary/20 border-primary/40"
              )} />
              <span className="text-[9px] font-mono font-bold mt-1 text-foreground">{iata}</span>
              {apt && <span className="text-[8px] text-muted-foreground">{apt.city}</span>}
            </motion.div>
            {idx < currentDestinations.length - 1 && (
              <div className="flex-1 min-w-[20px] h-px bg-gradient-to-r from-primary/40 to-primary/20 mx-1 mt-[-12px]" />
            )}
          </React.Fragment>
        );
      })}
    </div>
  );
};

export default TripProgressBar;
