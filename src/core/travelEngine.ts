/**
 * Slice-B Phase-2 — travel engine.
 *
 * Pure functions over `TripLifecycle` + `FlightStatus`. No store reads, no
 * IO — call sites pass in everything they need so this module is trivial
 * to unit-test and reuse from the contextEngine, the notifications engine,
 * and any future scheduler.
 *
 * Concerns:
 *  - boarding / check-in windows (real airline conventions)
 *  - delay severity classification (deterministic thresholds)
 *  - "next leg" selection across a multi-leg trip
 *  - upcoming-leg ETA math (ms-to-departure)
 *
 * NOTE: time math is in milliseconds and uses a caller-supplied `now`
 * (defaults to `Date.now()`) so tests can pin a clock.
 */
import type { TripLeg, TripLifecycle, FlightStatus } from "@shared/types/lifecycle";

/** Milliseconds in one minute. */
const MIN = 60_000;
/** Milliseconds in one hour. */
const HOUR = 60 * MIN;

/** Real-world airline windows. Domestic and international vary slightly;
 *  we use international as the default since GlobeID is identity-aware. */
export const CHECK_IN_OPEN_HOURS = 48; // online check-in opens 48h before
export const CHECK_IN_CLOSE_MIN = 60;  // closes 60min before departure
export const BOARDING_OPEN_MIN = 45;   // boarding starts 45min before
export const BOARDING_FINAL_MIN = 15;  // final-call window starts 15min before
export const AT_GATE_MIN = 10;         // be physically at the gate

/** Severity bucket for a delay. */
export type DelaySeverity = "none" | "minor" | "moderate" | "major" | "critical";

/**
 * Classify a delay deterministically. Same minutes → same severity, always.
 * Thresholds match what most carriers actually treat as "minor / mod / major"
 * for re-booking decisions. Cancelled is always critical.
 */
export function classifyDelay(status: FlightStatus): DelaySeverity {
  if (status.statusKind === "cancelled") return "critical";
  if (status.statusKind !== "delayed") return "none";
  const m = status.delayMinutes;
  if (m <= 0) return "none";
  if (m < 30) return "minor";
  if (m < 90) return "moderate";
  if (m < 240) return "major";
  return "critical";
}

/** Boarding/check-in window state for one leg. */
export interface LegWindow {
  legId: string;
  /** ISO scheduled departure (we store date-only; assume 00:00Z for math). */
  scheduledDeparture: string;
  /** True iff [now, departure - check-in-close] is open right now. */
  checkInOpen: boolean;
  /** True iff within boarding window. */
  boardingOpen: boolean;
  /** True iff inside the final-call window. */
  finalCall: boolean;
  /** True iff caller should already be at the gate. */
  atGate: boolean;
  /** ms until scheduled departure (negative once departed). */
  msToDeparture: number;
}

/**
 * Compute the windows for a single leg given a scheduled-departure ISO date
 * (YYYY-MM-DD). For the demo dataset we don't have a wall-clock time, so we
 * treat the date as 00:00 UTC. Real flight integrations would supply ms
 * timestamps and we'd swap the parser.
 */
export function legWindow(leg: TripLeg, now = Date.now()): LegWindow {
  const t = parseDateUTC(leg.date);
  const ms = t - now;
  return {
    legId: leg.id,
    scheduledDeparture: leg.date,
    checkInOpen: ms <= CHECK_IN_OPEN_HOURS * HOUR && ms >= CHECK_IN_CLOSE_MIN * MIN,
    boardingOpen: ms <= BOARDING_OPEN_MIN * MIN && ms >= 0,
    finalCall: ms <= BOARDING_FINAL_MIN * MIN && ms >= 0,
    atGate: ms <= AT_GATE_MIN * MIN && ms >= -2 * HOUR,
    msToDeparture: ms,
  };
}

/** Pick the next leg to act on (current → upcoming → null). */
export function nextLeg(trip: TripLifecycle): TripLeg | null {
  return (
    trip.legs.find((l) => l.type === "current") ??
    trip.legs.find((l) => l.type === "upcoming") ??
    null
  );
}

/** ms until the trip starts (negative if started or no legs). */
export function msUntilTripStart(trip: TripLifecycle, now = Date.now()): number {
  if (!trip.startsAt) return Number.POSITIVE_INFINITY;
  return parseDateUTC(trip.startsAt) - now;
}

/**
 * Severity ranking helper used by the notifications engine to prioritise
 * across multiple trips. Higher = more urgent.
 */
export const DELAY_SEVERITY_RANK: Record<DelaySeverity, number> = {
  none: 0,
  minor: 1,
  moderate: 2,
  major: 3,
  critical: 4,
};

function parseDateUTC(iso: string): number {
  // YYYY-MM-DD or full ISO. `Date.parse` interprets a date-only string as UTC.
  const t = Date.parse(iso);
  if (Number.isFinite(t)) return t;
  return Number.POSITIVE_INFINITY;
}
