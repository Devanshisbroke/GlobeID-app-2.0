/**
 * Phase 9-β — Trip lifecycle + flight status types.
 *
 * Lifecycle is *derived* from `planned_trips` + linked `travel_records`.
 * No new columns, no migration — the server computes state on every request.
 *
 * Flight status is *demo-mode* by default: deterministic mock generated from
 * the flight number + scheduled date so the UI is repeatable across reloads.
 * The `isDemoData: true` flag and the `demoNote` text are non-removable
 * surface markers required by Phase 9-β's "no fake features" rule.
 */
import { z } from "zod";

/* ── Trip lifecycle ── */

export const tripLifecycleStateEnum = z.enum([
  "planning",
  "booked",
  "active",
  "complete",
]);
export type TripLifecycleState = z.infer<typeof tripLifecycleStateEnum>;

export const tripReminderKindEnum = z.enum([
  "check_in_window",
  "departure_imminent",
  "currency_topup",
  "passport_check",
  "post_trip_review",
]);
export type TripReminderKind = z.infer<typeof tripReminderKindEnum>;

export const tripReminderSchema = z.object({
  id: z.string(),
  kind: tripReminderKindEnum,
  /** ISO YYYY-MM-DD when the reminder becomes relevant. */
  dueOn: z.string(),
  severity: z.enum(["info", "warning", "critical"]),
  title: z.string(),
  description: z.string(),
});
export type TripReminder = z.infer<typeof tripReminderSchema>;

export const tripLegSchema = z.object({
  id: z.string(),
  fromIata: z.string().length(3),
  toIata: z.string().length(3),
  date: z.string(),
  airline: z.string(),
  flightNumber: z.string().nullable(),
  /** Leg-level lifecycle: `past` legs are complete, `current`/`upcoming` legs
   *  inform the parent trip's state. */
  type: z.enum(["upcoming", "past", "current"]),
  source: z.enum(["history", "planner"]),
});
export type TripLeg = z.infer<typeof tripLegSchema>;

export const tripLifecycleSchema = z.object({
  /** Planned-trip ID (null for "ad-hoc" lifecycles built from un-linked travel records). */
  tripId: z.string().nullable(),
  name: z.string(),
  theme: z.enum(["vacation", "business", "backpacking", "world_tour"]).nullable(),
  state: tripLifecycleStateEnum,
  destinations: z.array(z.string().length(3)),
  legs: z.array(tripLegSchema),
  reminders: z.array(tripReminderSchema),
  /** Earliest leg date (ISO YYYY-MM-DD). null when no legs. */
  startsAt: z.string().nullable(),
  /** Latest leg date (ISO YYYY-MM-DD). null when no legs. */
  endsAt: z.string().nullable(),
});
export type TripLifecycle = z.infer<typeof tripLifecycleSchema>;

/* ── Flight status (demo mode) ── */

export const flightStatusKindEnum = z.enum([
  "scheduled",
  "boarding",
  "departed",
  "in_air",
  "landed",
  "delayed",
  "cancelled",
]);
export type FlightStatusKind = z.infer<typeof flightStatusKindEnum>;

export const flightStatusSchema = z.object({
  id: z.string(),
  flightNumber: z.string().nullable(),
  airline: z.string(),
  fromIata: z.string().length(3),
  toIata: z.string().length(3),
  /** ISO YYYY-MM-DD scheduled date. */
  scheduledDate: z.string(),
  statusKind: flightStatusKindEnum,
  /** Minutes delayed from schedule. 0 unless statusKind === 'delayed'. */
  delayMinutes: z.number().int().min(0),
  /** Mock gate (e.g. "B14"). null for cancelled/landed-far-past. */
  gate: z.string().nullable(),
  /** Mock terminal letter. null for cancelled/landed-far-past. */
  terminal: z.string().nullable(),
  /** Required surface marker — the UI MUST display this somewhere. */
  isDemoData: z.literal(true),
  demoNote: z.string(),
});
export type FlightStatus = z.infer<typeof flightStatusSchema>;
