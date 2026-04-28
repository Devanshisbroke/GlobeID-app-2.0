/**
 * Phase 9-β — Trip lifecycle derivation.
 *
 * Lifecycle states are *derived*, not stored:
 *   - planning  : planned_trip exists but has no linked travel_records.
 *   - booked    : has linked legs, all legs' dates are in the future.
 *   - active    : at least one leg's date is today, or some past + some future.
 *   - complete  : has linked legs, all legs' dates are in the past.
 *
 * Reminders are computed per-trip from the leg dates + lifecycle state.
 *
 * The result also includes "ad-hoc" lifecycles for legs that are not linked
 * to any planned_trip (legacy seed history, planner saves before Phase 8).
 */
import { eq } from "drizzle-orm";
import { db } from "../db/client.js";
import { plannedTrips, travelRecords } from "../db/schema.js";
import type {
  TripLeg,
  TripLifecycle,
  TripLifecycleState,
  TripReminder,
} from "../../../shared/types/lifecycle.js";

interface PlannedTripRow {
  id: string;
  name: string;
  theme: "vacation" | "business" | "backpacking" | "world_tour";
  destinations: string;
  createdAt: number;
}

interface TravelRow {
  id: string;
  fromIata: string;
  toIata: string;
  date: string;
  airline: string;
  flightNumber: string | null;
  type: "upcoming" | "past" | "current";
  source: "history" | "planner";
  tripId: string | null;
}

function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
}

function daysBetween(fromIso: string, toIso: string): number {
  const a = Date.UTC(
    Number(fromIso.slice(0, 4)),
    Number(fromIso.slice(5, 7)) - 1,
    Number(fromIso.slice(8, 10)),
  );
  const b = Date.UTC(
    Number(toIso.slice(0, 4)),
    Number(toIso.slice(5, 7)) - 1,
    Number(toIso.slice(8, 10)),
  );
  return Math.round((b - a) / 86_400_000);
}

function rowToLeg(r: TravelRow): TripLeg {
  return {
    id: r.id,
    fromIata: r.fromIata,
    toIata: r.toIata,
    date: r.date,
    airline: r.airline,
    flightNumber: r.flightNumber,
    type: r.type,
    source: r.source,
  };
}

/* ── Lifecycle derivation ── */

export function deriveLifecycleState(legs: TripLeg[], today: string): TripLifecycleState {
  if (legs.length === 0) return "planning";
  let hasFuture = false;
  let hasPast = false;
  let hasToday = false;
  for (const l of legs) {
    if (l.date > today) hasFuture = true;
    else if (l.date < today) hasPast = true;
    else hasToday = true;
  }
  if (hasToday) return "active";
  if (hasFuture && hasPast) return "active";
  if (hasFuture) return "booked";
  return "complete";
}

/* ── Reminder generation ── */

function computeReminders(
  tripId: string | null,
  state: TripLifecycleState,
  legs: TripLeg[],
  today: string,
): TripReminder[] {
  const reminders: TripReminder[] = [];
  if (legs.length === 0) return reminders;

  // Earliest future or today leg (the "next departure").
  const upcoming = legs
    .filter((l) => l.date >= today)
    .sort((a, b) => a.date.localeCompare(b.date))[0];

  if (upcoming) {
    const days = daysBetween(today, upcoming.date);
    const tripKey = tripId ?? upcoming.id;

    if (days <= 1) {
      reminders.push({
        id: `rem-imminent-${tripKey}`,
        kind: "departure_imminent",
        dueOn: upcoming.date,
        severity: "critical",
        title: days === 0 ? "Departure today" : "Departure tomorrow",
        description: `${upcoming.fromIata} → ${upcoming.toIata} on ${
          upcoming.flightNumber ?? upcoming.airline
        }. Confirm boarding pass.`,
      });
    } else if (days <= 3) {
      reminders.push({
        id: `rem-checkin-${tripKey}`,
        kind: "check_in_window",
        dueOn: upcoming.date,
        severity: "warning",
        title: "Online check-in opens soon",
        description: `${days}d to ${upcoming.toIata}. Most carriers open check-in 24–48h before departure.`,
      });
    } else if (days <= 14) {
      reminders.push({
        id: `rem-currency-${tripKey}`,
        kind: "currency_topup",
        dueOn: upcoming.date,
        severity: "info",
        title: "Top up destination currency",
        description: `${days}d to ${upcoming.toIata}. Convert before exchange-counter rates apply.`,
      });
    } else if (days <= 30) {
      reminders.push({
        id: `rem-passport-${tripKey}`,
        kind: "passport_check",
        dueOn: upcoming.date,
        severity: "info",
        title: "Check passport validity",
        description: `${days}d to ${upcoming.toIata}. Many destinations require ≥6 months validity.`,
      });
    }
  }

  if (state === "complete") {
    const last = [...legs].sort((a, b) => b.date.localeCompare(a.date))[0]!;
    const daysSince = daysBetween(last.date, today);
    if (daysSince <= 14) {
      reminders.push({
        id: `rem-review-${tripId ?? last.id}`,
        kind: "post_trip_review",
        dueOn: last.date,
        severity: "info",
        title: "Share a recap",
        description: `Trip ended ${daysSince}d ago. Add notes or a photo to your travel log.`,
      });
    }
  }

  return reminders;
}

/* ── Public API ── */

function loadPlanned(userId: string): PlannedTripRow[] {
  return db
    .select({
      id: plannedTrips.id,
      name: plannedTrips.name,
      theme: plannedTrips.theme,
      destinations: plannedTrips.destinations,
      createdAt: plannedTrips.createdAt,
    })
    .from(plannedTrips)
    .where(eq(plannedTrips.userId, userId))
    .all();
}

function loadTravel(userId: string): TravelRow[] {
  return db
    .select({
      id: travelRecords.id,
      fromIata: travelRecords.fromIata,
      toIata: travelRecords.toIata,
      date: travelRecords.date,
      airline: travelRecords.airline,
      flightNumber: travelRecords.flightNumber,
      type: travelRecords.type,
      source: travelRecords.source,
      tripId: travelRecords.tripId,
    })
    .from(travelRecords)
    .where(eq(travelRecords.userId, userId))
    .all();
}

export function computeTripLifecycles(userId: string): TripLifecycle[] {
  const today = todayIso();
  const planned = loadPlanned(userId);
  const records = loadTravel(userId);

  // Group records by tripId.
  const byTrip = new Map<string, TravelRow[]>();
  const adhoc: TravelRow[] = [];
  for (const r of records) {
    if (r.tripId) {
      if (!byTrip.has(r.tripId)) byTrip.set(r.tripId, []);
      byTrip.get(r.tripId)!.push(r);
    } else {
      adhoc.push(r);
    }
  }

  const out: TripLifecycle[] = [];

  // 1) Planned trips (canonical).
  for (const p of planned) {
    let dests: string[] = [];
    try {
      const raw = JSON.parse(p.destinations) as unknown;
      if (Array.isArray(raw)) dests = raw.filter((s): s is string => typeof s === "string");
    } catch {
      /* malformed — leave empty */
    }
    const rowsForTrip = byTrip.get(p.id) ?? [];
    const legs = rowsForTrip
      .map(rowToLeg)
      .sort((a, b) => a.date.localeCompare(b.date));
    const state = deriveLifecycleState(legs, today);
    out.push({
      tripId: p.id,
      name: p.name,
      theme: p.theme,
      state,
      destinations: dests,
      legs,
      reminders: computeReminders(p.id, state, legs, today),
      startsAt: legs[0]?.date ?? null,
      endsAt: legs[legs.length - 1]?.date ?? null,
    });
  }

  // 2) Ad-hoc lifecycle for un-linked legs (seed history, legacy planner saves).
  if (adhoc.length > 0) {
    const legs = adhoc
      .map(rowToLeg)
      .sort((a, b) => a.date.localeCompare(b.date));
    const state = deriveLifecycleState(legs, today);
    // Ad-hoc legs may span multiple "trips" but we can't reconstruct them
    // without the planned_trip metadata, so we surface them as a single
    // catch-all entry. Useful enough for the UI to show "8 unfiled flights".
    out.push({
      tripId: null,
      name: "Unfiled flights",
      theme: null,
      state,
      destinations: [...new Set(legs.flatMap((l) => [l.fromIata, l.toIata]))],
      legs,
      reminders: computeReminders(null, state, legs, today),
      startsAt: legs[0]?.date ?? null,
      endsAt: legs[legs.length - 1]?.date ?? null,
    });
  }

  // Sort: active first, then booked, then planning, then complete.
  const order: Record<TripLifecycleState, number> = {
    active: 0,
    booked: 1,
    planning: 2,
    complete: 3,
  };
  out.sort((a, b) => {
    const sa = order[a.state] - order[b.state];
    if (sa !== 0) return sa;
    return (a.startsAt ?? "9999-12-31").localeCompare(b.startsAt ?? "9999-12-31");
  });

  return out;
}
