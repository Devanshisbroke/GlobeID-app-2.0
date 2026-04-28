/**
 * Phase 9-β — Flight status (DEMO MODE).
 *
 * No real aviation API is wired. To honor "no fake features" + "no placeholder
 * UI pretending to be functional", the response always carries:
 *
 *   - isDemoData: true     — non-removable surface marker
 *   - demoNote: string     — explicit text the UI must surface
 *
 * Status is computed deterministically from a hash of (flightNumber,
 * scheduledDate, today) so the same flight returns the same value across
 * reloads within a single day. This keeps demo behavior repeatable for
 * testing/screenshots without faking "live" updates.
 *
 * When AVIATIONSTACK_API_KEY (or similar) is added in a future phase, this
 * function is the single integration point — replace the hash-based
 * computation with a real fetch and clear the demo flags.
 */
import { eq, and } from "drizzle-orm";
import { db } from "../db/client.js";
import { travelRecords } from "../db/schema.js";
import type {
  FlightStatus,
  FlightStatusKind,
} from "../../../shared/types/lifecycle.js";

function djb2(input: string): number {
  let hash = 5381;
  for (let i = 0; i < input.length; i++) {
    hash = ((hash << 5) + hash + input.charCodeAt(i)) | 0;
  }
  return hash >>> 0;
}

function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
}

function statusKindFor(scheduledDate: string, today: string, hash: number): FlightStatusKind {
  // Past flight: deterministic — landed unless flagged delayed.
  if (scheduledDate < today) {
    return hash % 17 === 0 ? "delayed" : "landed";
  }
  // Future flight (>1 day): scheduled, with rare cancellations/delays for testing.
  if (scheduledDate > today) {
    const r = hash % 100;
    if (r < 5) return "delayed";
    if (r === 99) return "cancelled";
    return "scheduled";
  }
  // Same-day: progress through the lifecycle by hash buckets so we can
  // exercise each state during demos.
  const r = hash % 5;
  if (r === 0) return "boarding";
  if (r === 1) return "departed";
  if (r === 2) return "in_air";
  if (r === 3) return "delayed";
  return "scheduled";
}

export interface FlightStatusInput {
  legId: string;
  userId: string;
}

export function getFlightStatus({ legId, userId }: FlightStatusInput): FlightStatus | null {
  const row = db
    .select({
      id: travelRecords.id,
      fromIata: travelRecords.fromIata,
      toIata: travelRecords.toIata,
      date: travelRecords.date,
      airline: travelRecords.airline,
      flightNumber: travelRecords.flightNumber,
    })
    .from(travelRecords)
    .where(and(eq(travelRecords.userId, userId), eq(travelRecords.id, legId)))
    .get();
  if (!row) return null;

  const today = todayIso();
  const seed = `${row.flightNumber ?? row.airline}|${row.date}|${today}`;
  const hash = djb2(seed);
  const statusKind = statusKindFor(row.date, today, hash);
  const delayMinutes =
    statusKind === "delayed" ? 15 + (hash % 75) : 0;

  // Mock gate/terminal — null for cancelled or far-past landed flights.
  const showGate =
    statusKind !== "cancelled" &&
    !(statusKind === "landed" && row.date < today && Math.abs(daysBetween(row.date, today)) > 7);
  const gate = showGate ? `${String.fromCharCode(65 + (hash % 6))}${(hash % 30) + 1}` : null;
  const terminal = showGate ? `T${(hash % 4) + 1}` : null;

  return {
    id: row.id,
    flightNumber: row.flightNumber,
    airline: row.airline,
    fromIata: row.fromIata,
    toIata: row.toIata,
    scheduledDate: row.date,
    statusKind,
    delayMinutes,
    gate,
    terminal,
    isDemoData: true,
    demoNote:
      "Demo status — generated deterministically from the flight number + date. Wire AVIATIONSTACK_API_KEY for live data.",
  };
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
