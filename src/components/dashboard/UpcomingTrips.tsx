import React from "react";
import { useNavigate } from "react-router-dom";
import { Plane, Clock, Calendar, ChevronRight } from "lucide-react";
import { Surface, Text } from "@/components/ui/v2";
import { useUserStore, formatTripDate } from "@/store/userStore";
import { getAirport } from "@/lib/airports";

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
          <Surface
            key={trip.id}
            variant="elevated"
            radius="surface"
            className="p-3.5 cursor-pointer transition-transform active:scale-[0.99]"
            onClick={() => navigate("/map")}
          >
            <div className="flex items-center gap-3">
              <div className="w-11 h-11 rounded-p7-input bg-brand-soft flex items-center justify-center shrink-0">
                <Plane className="w-5 h-5 text-brand" strokeWidth={1.8} />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-1.5">
                  <Text variant="body-em" tone="primary" className="font-mono tabular-nums">
                    {trip.from}
                  </Text>
                  <div className="w-8 h-px bg-brand/60" />
                  <Text variant="body-em" tone="primary" className="font-mono tabular-nums">
                    {trip.to}
                  </Text>
                </div>
                <Text variant="caption-1" tone="tertiary" truncate>
                  {from?.city ?? trip.from} → {to?.city ?? trip.to}
                </Text>
              </div>
              <ChevronRight className="w-4 h-4 text-ink-tertiary shrink-0" />
            </div>
            <div className="mt-2.5 pt-2.5 border-t border-surface-hairline flex items-center gap-4">
              <Text variant="caption-2" tone="tertiary" className="flex items-center gap-1">
                <Calendar className="w-3 h-3" />
                {formatTripDate(trip.date)}
              </Text>
              <Text variant="caption-2" tone="tertiary" className="flex items-center gap-1">
                <Clock className="w-3 h-3" />
                {trip.duration}
              </Text>
              <Text variant="caption-2" tone="tertiary" className="flex items-center gap-1">
                <Plane className="w-3 h-3" />
                {trip.airline}
              </Text>
            </div>
          </Surface>
        );
      })}
    </div>
  );
};

export default UpcomingTrips;
