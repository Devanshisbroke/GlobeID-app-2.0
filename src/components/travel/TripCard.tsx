import React from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { Plane, Clock, Calendar } from "lucide-react";
import { getAirport } from "@/lib/airports";
import { cn } from "@/lib/utils";
import { formatTripDate, type TravelRecord } from "@/store/userStore";

interface TripCardProps {
  trip: TravelRecord;
  className?: string;
}

const TripCard: React.FC<TripCardProps> = ({ trip, className }) => {
  const fromAirport = getAirport(trip.from);
  const toAirport = getAirport(trip.to);

  const isUpcoming = trip.type === "upcoming" || trip.type === "current";

  return (
    <GlassCard className={cn("cursor-pointer touch-bounce", className)} depth="md">
      <div className="flex items-center gap-3">
        <div className={cn(
          "w-11 h-11 rounded-xl flex items-center justify-center shrink-0 shadow-depth-sm",
          isUpcoming ? "bg-gradient-ocean" : "bg-secondary/60"
        )}>
          <Plane className={cn("w-5 h-5", isUpcoming ? "text-primary-foreground" : "text-muted-foreground")} strokeWidth={1.8} />
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-sm font-bold text-foreground">{trip.from} → {trip.to}</p>
          <p className="text-xs text-muted-foreground">
            {fromAirport?.city ?? trip.from} to {toAirport?.city ?? trip.to}
          </p>
        </div>
        <span className={cn(
          "text-[10px] px-2 py-0.5 rounded-full font-semibold",
          isUpcoming ? "bg-primary/15 text-primary" : "bg-muted text-muted-foreground"
        )}>
          {trip.type}
        </span>
      </div>
      <div className="mt-3 pt-3 border-t border-border/30 flex items-center gap-4 text-xs text-muted-foreground">
        <span className="flex items-center gap-1"><Calendar className="w-3 h-3" />{formatTripDate(trip.date)}</span>
        <span className="flex items-center gap-1"><Clock className="w-3 h-3" />{trip.duration}</span>
        <span className="flex items-center gap-1"><Plane className="w-3 h-3" />{trip.airline}</span>
      </div>
    </GlassCard>
  );
};

export default TripCard;
