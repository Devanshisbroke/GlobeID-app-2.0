import React from "react";
import { motion } from "framer-motion";
import { Plane, Calendar, AlertCircle, Bell } from "lucide-react";
import { cn } from "@/lib/utils";
import TripLifecycleBadge from "./TripLifecycleBadge";
import type { TripLifecycle, TripReminder } from "@shared/types/lifecycle";

const reminderPalette: Record<
  TripReminder["severity"],
  { tone: string; bg: string }
> = {
  critical: { tone: "text-destructive", bg: "bg-destructive/10" },
  warning: { tone: "text-amber-500", bg: "bg-amber-500/10" },
  info: { tone: "text-primary", bg: "bg-primary/10" },
};

interface TripLifecycleCardProps {
  trip: TripLifecycle;
  index?: number;
  className?: string;
  onSelect?: (trip: TripLifecycle) => void;
}

const TripLifecycleCard: React.FC<TripLifecycleCardProps> = ({
  trip,
  index = 0,
  className,
  onSelect,
}) => {
  const next = trip.legs.find((l) => l.type === "upcoming" || l.type === "current");
  const last = trip.legs[trip.legs.length - 1];

  return (
    <motion.button
      type="button"
      onClick={onSelect ? () => onSelect(trip) : undefined}
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.04, duration: 0.25 }}
      className={cn(
        "w-full text-left rounded-2xl border border-border bg-card p-4 space-y-3",
        onSelect && "active:scale-[0.99] transition-transform",
        className,
      )}
      data-trip-id={trip.tripId ?? "adhoc"}
      data-trip-state={trip.state}
    >
      <div className="flex items-start gap-2">
        <Plane className="w-4 h-4 mt-1 text-primary shrink-0" />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 flex-wrap">
            <p className="text-sm font-semibold text-foreground truncate">{trip.name}</p>
            <TripLifecycleBadge state={trip.state} />
          </div>
          {trip.theme ? (
            <p className="text-[11px] text-muted-foreground capitalize mt-0.5">
              {trip.theme.replace("_", " ")}
            </p>
          ) : null}
        </div>
      </div>

      {trip.destinations.length > 0 ? (
        <div className="flex flex-wrap items-center gap-1.5">
          {trip.destinations.map((iata) => (
            <span
              key={iata}
              className="text-[10.5px] font-mono font-semibold text-foreground bg-secondary/60 px-1.5 py-0.5 rounded"
            >
              {iata}
            </span>
          ))}
        </div>
      ) : null}

      {next || last ? (
        <div className="flex items-center gap-2 text-[11px] text-muted-foreground">
          <Calendar className="w-3 h-3" />
          {next ? (
            <span>
              Next: {next.fromIata} → {next.toIata} · {next.date}
            </span>
          ) : last ? (
            <span>
              Last: {last.fromIata} → {last.toIata} · {last.date}
            </span>
          ) : null}
        </div>
      ) : null}

      {trip.reminders.length > 0 ? (
        <div className="space-y-1.5 pt-1 border-t border-border">
          {trip.reminders.slice(0, 2).map((r) => {
            const p = reminderPalette[r.severity];
            return (
              <div
                key={r.id}
                className={cn(
                  "flex items-start gap-1.5 rounded-lg px-2 py-1.5",
                  p.bg,
                )}
              >
                {r.severity === "critical" ? (
                  <AlertCircle className={cn("w-3 h-3 mt-0.5 shrink-0", p.tone)} />
                ) : (
                  <Bell className={cn("w-3 h-3 mt-0.5 shrink-0", p.tone)} />
                )}
                <div className="flex-1 min-w-0">
                  <p className={cn("text-[11px] font-semibold", p.tone)}>{r.title}</p>
                  <p className="text-[10.5px] text-muted-foreground leading-snug">
                    {r.description}
                  </p>
                </div>
              </div>
            );
          })}
        </div>
      ) : null}

      <div className="flex items-center justify-between text-[10px] text-muted-foreground/70 pt-1">
        <span>
          {trip.legs.length} leg{trip.legs.length === 1 ? "" : "s"}
        </span>
        {trip.startsAt && trip.endsAt ? (
          <span>
            {trip.startsAt}
            {trip.startsAt !== trip.endsAt ? ` → ${trip.endsAt}` : ""}
          </span>
        ) : null}
      </div>
    </motion.button>
  );
};

export default TripLifecycleCard;
