import React from "react";
import { useNavigate } from "react-router-dom";
import { GlassCard } from "@/components/ui/GlassCard";
import { useUserStore, formatTripDate } from "@/store/userStore";
import { getAirport } from "@/lib/airports";
import { Plane, Clock, Calendar, ChevronRight } from "lucide-react";
import { cn } from "@/lib/utils";

const UpcomingTrips: React.FC = () => {
  const navigate = useNavigate();
  const { travelHistory } = useUserStore();
  const upcoming = travelHistory.filter((t) => t.type === "upcoming" || t.type === "current");

  if (upcoming.length === 0) return null;

  return (
    <div className="space-y-2.5">
      {upcoming.slice(0, 3).map((trip) => {
        const from = getAirport(trip.from);
        const to = getAirport(trip.to);

        return (
          <GlassCard
            key={trip.id}
            className="cursor-pointer touch-bounce"
            depth="md"
            onClick={() => navigate("/map")}
          >
            <div className="flex items-center gap-3">
              <div className="w-11 h-11 rounded-xl bg-gradient-ocean flex items-center justify-center shrink-0 shadow-glow-sm">
                <Plane className="w-5 h-5 text-primary-foreground" strokeWidth={1.8} />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-1.5">
                  <p className="text-sm font-bold text-foreground">{trip.from}</p>
                  <div className="w-8 h-px bg-gradient-to-r from-primary to-accent" />
                  <p className="text-sm font-bold text-foreground">{trip.to}</p>
                </div>
                <p className="text-xs text-muted-foreground">
                  {from?.city ?? trip.from} → {to?.city ?? trip.to}
                </p>
              </div>
              <ChevronRight className="w-4 h-4 text-muted-foreground/50 shrink-0" />
            </div>
            <div className="mt-2.5 pt-2.5 border-t border-border/20 flex items-center gap-4 text-[10px] text-muted-foreground">
              <span className="flex items-center gap-1"><Calendar className="w-3 h-3" />{formatTripDate(trip.date)}</span>
              <span className="flex items-center gap-1"><Clock className="w-3 h-3" />{trip.duration}</span>
              <span className="flex items-center gap-1"><Plane className="w-3 h-3" />{trip.airline}</span>
            </div>
          </GlassCard>
        );
      })}
    </div>
  );
};

export default UpcomingTrips;
