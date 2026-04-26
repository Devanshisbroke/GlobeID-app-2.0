import React from "react";
import { Plane, Clock, Calendar } from "lucide-react";
import { Surface, Pill, Text } from "@/components/ui/v2";
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
    <Surface
      variant={isUpcoming ? "elevated" : "plain"}
      radius="surface"
      className={cn("p-3.5 cursor-pointer transition-transform active:scale-[0.99]", className)}
    >
      <div className="flex items-center gap-3">
        <div
          className={cn(
            "w-11 h-11 rounded-p7-input flex items-center justify-center shrink-0",
            isUpcoming ? "bg-brand-soft" : "bg-surface-overlay",
          )}
        >
          <Plane
            className={cn("w-5 h-5", isUpcoming ? "text-brand" : "text-ink-tertiary")}
            strokeWidth={1.8}
          />
        </div>
        <div className="flex-1 min-w-0">
          <Text variant="body-em" tone="primary" truncate>
            {trip.from} → {trip.to}
          </Text>
          <Text variant="caption-1" tone="tertiary" truncate>
            {fromAirport?.city ?? trip.from} to {toAirport?.city ?? trip.to}
          </Text>
        </div>
        <Pill tone={isUpcoming ? "brand" : "neutral"} weight="tinted">
          {trip.type}
        </Pill>
      </div>
      <div className="mt-3 pt-3 border-t border-surface-hairline flex items-center gap-4">
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
};

export default TripCard;
