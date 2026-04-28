import React from "react";
import { Plane, Bell, AlertCircle, Calendar } from "lucide-react";
import { cn } from "@/lib/utils";
import { getAirport } from "@/lib/airports";
import type { TripLeg, TripReminder } from "@shared/types/lifecycle";

const reminderPalette: Record<
  TripReminder["severity"],
  { tone: string; bg: string }
> = {
  critical: { tone: "text-destructive", bg: "bg-destructive/10" },
  warning: { tone: "text-amber-500", bg: "bg-amber-500/10" },
  info: { tone: "text-primary", bg: "bg-primary/10" },
};

export interface ItineraryDayProps {
  date: string;
  legs: TripLeg[];
  reminders: TripReminder[];
  isToday?: boolean;
  isPast?: boolean;
  className?: string;
}

const ItineraryDay: React.FC<ItineraryDayProps> = ({
  date,
  legs,
  reminders,
  isToday = false,
  isPast = false,
  className,
}) => {
  const dayLabel = (() => {
    const d = new Date(date + "T00:00:00Z");
    if (Number.isNaN(d.valueOf())) return date;
    return d.toLocaleDateString(undefined, {
      weekday: "short",
      month: "short",
      day: "numeric",
    });
  })();

  return (
    <div
      className={cn(
        "rounded-2xl border bg-card p-4 space-y-3",
        isToday
          ? "border-primary/40 shadow-sm shadow-primary/10"
          : isPast
          ? "border-border opacity-70"
          : "border-border",
        className,
      )}
    >
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Calendar
            className={cn(
              "w-3.5 h-3.5",
              isToday ? "text-primary" : "text-muted-foreground",
            )}
          />
          <p
            className={cn(
              "text-xs font-semibold uppercase tracking-wider",
              isToday ? "text-primary" : "text-foreground",
            )}
          >
            {dayLabel}
          </p>
        </div>
        {isToday ? (
          <span className="inline-flex items-center gap-1 text-[10px] font-semibold uppercase tracking-wider text-primary">
            <span className="w-1.5 h-1.5 rounded-full bg-primary animate-pulse" />
            Today
          </span>
        ) : null}
      </div>

      {legs.length === 0 ? (
        <p className="text-[11px] text-muted-foreground italic">No flights this day.</p>
      ) : (
        <div className="space-y-2">
          {legs.map((leg) => {
            const fromCity = getAirport(leg.fromIata)?.city ?? leg.fromIata;
            const toCity = getAirport(leg.toIata)?.city ?? leg.toIata;
            return (
              <div
                key={leg.id}
                className="flex items-center gap-3 rounded-xl border border-border bg-background/50 px-3 py-2"
                data-leg-id={leg.id}
              >
                <Plane className="w-4 h-4 text-primary shrink-0" />
                <div className="flex-1 min-w-0">
                  <p className="text-[12.5px] font-semibold text-foreground truncate">
                    {fromCity} → {toCity}
                  </p>
                  <p className="text-[10.5px] text-muted-foreground font-mono">
                    {leg.flightNumber} · {leg.airline}
                  </p>
                </div>
                <span className="text-[10px] font-mono font-semibold text-muted-foreground bg-secondary/60 px-1.5 py-0.5 rounded">
                  {leg.fromIata}–{leg.toIata}
                </span>
              </div>
            );
          })}
        </div>
      )}

      {reminders.length > 0 ? (
        <div className="space-y-1.5 pt-1 border-t border-border">
          {reminders.map((r) => {
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
    </div>
  );
};

export default ItineraryDay;
