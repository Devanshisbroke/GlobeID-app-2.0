import { getAirport } from "@/lib/airports";
import type { TripLifecycle, TripLeg } from "@shared/types/lifecycle";
import type { TravelRecord } from "@/store/userStore";

function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
}

/**
 * Convert a `TravelRecord` (the seed shape used by `userStore.travelHistory`)
 * into a synthetic `TripLifecycle` so we can render it through the same
 * detail view as planner-issued trips. This keeps the boarding pass + globe
 * preview sub-components on a single contract instead of duplicating UI.
 *
 * The synthesised lifecycle has no reminders and a single leg whose IDs are
 * derived from the source record so QRBoardingPass + the wallet pass stay
 * stable across re-renders.
 */
export function travelRecordToLifecycle(record: TravelRecord): TripLifecycle {
  const fromAirport = getAirport(record.from);
  const toAirport = getAirport(record.to);
  const state: TripLifecycle["state"] =
    record.type === "current"
      ? "active"
      : record.type === "upcoming"
        ? record.date <= todayIso()
          ? "active"
          : "booked"
        : "complete";

  const leg: TripLeg = {
    id: `leg-${record.id}`,
    date: record.date,
    fromIata: record.from,
    toIata: record.to,
    flightNumber: record.flightNumber ?? null,
    airline: record.airline,
    type: record.type,
    source: record.source,
  };

  return {
    tripId: record.id,
    name: `${fromAirport?.city ?? record.from} → ${toAirport?.city ?? record.to}`,
    theme: null,
    state,
    startsAt: record.date,
    endsAt: record.date,
    destinations: [record.to],
    legs: [leg],
    reminders: [],
  };
}
