import React, { useMemo } from "react";
import ItineraryDay from "./ItineraryDay";
import type { TripLeg, TripReminder } from "@shared/types/lifecycle";

export interface ItineraryViewProps {
  legs: TripLeg[];
  reminders: TripReminder[];
  /** ISO date YYYY-MM-DD; defaults to today in UTC. */
  today?: string;
  className?: string;
}

interface DayBucket {
  date: string;
  legs: TripLeg[];
  reminders: TripReminder[];
}

function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
}

const ItineraryView: React.FC<ItineraryViewProps> = ({
  legs,
  reminders,
  today,
  className,
}) => {
  const todayDate = today ?? todayIso();

  const days = useMemo<DayBucket[]>(() => {
    const map = new Map<string, DayBucket>();
    const ensure = (date: string): DayBucket => {
      let b = map.get(date);
      if (!b) {
        b = { date, legs: [], reminders: [] };
        map.set(date, b);
      }
      return b;
    };
    for (const leg of legs) ensure(leg.date).legs.push(leg);
    for (const r of reminders) ensure(r.dueOn).reminders.push(r);
    return [...map.values()].sort((a, b) => a.date.localeCompare(b.date));
  }, [legs, reminders]);

  if (days.length === 0) {
    return (
      <div
        className={`rounded-2xl border border-dashed border-border bg-card/50 p-6 text-center ${
          className ?? ""
        }`}
      >
        <p className="text-sm text-muted-foreground">
          No flights or reminders on this trip yet. Save legs in the planner to
          populate the itinerary.
        </p>
      </div>
    );
  }

  return (
    <div className={`space-y-2 ${className ?? ""}`}>
      {days.map((d) => (
        <ItineraryDay
          key={d.date}
          date={d.date}
          legs={d.legs}
          reminders={d.reminders}
          isToday={d.date === todayDate}
          isPast={d.date < todayDate}
        />
      ))}
    </div>
  );
};

export default ItineraryView;
