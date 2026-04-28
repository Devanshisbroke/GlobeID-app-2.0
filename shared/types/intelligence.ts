/**
 * Phase 9-β — Intelligence types.
 *
 * Everything here is *derived* from canonical state already on the server
 * (`travel_records`, `wallet_*`, `planned_trips`, `users`). No placeholder
 * fields, no fake confidence scores — every value is grounded in real data
 * and carries a `citations[]` array so the UI can surface provenance.
 */
import { z } from "zod";

/* ── Location context ── */

export const locationSourceEnum = z.enum(["wallet", "travel", "home"]);
export type LocationSource = z.infer<typeof locationSourceEnum>;

export const locationContextSchema = z.object({
  /** ISO country name (e.g. "Singapore"). null when nothing in state implies a location. */
  country: z.string().nullable(),
  /** ISO 4217 currency code matching the country, or null. */
  currency: z.string().nullable(),
  /** Where this location came from. `wallet` = `wallet_state.active_country`,
   *  `travel` = currently-active or most-recent past travel record's destination,
   *  `home` = user.nationality fallback. */
  source: locationSourceEnum,
  /** Confidence is structural — we either know or we don't. 1.0 when source
   *  is wallet/travel, 0.5 when falling back to home. */
  confidence: z.number().min(0).max(1),
});
export type LocationContext = z.infer<typeof locationContextSchema>;

/* ── Automation flags ── */

export const automationFlagKindEnum = z.enum([
  "passport_expiring",
  "currency_mismatch",
  "currency_idle",
  "trip_imminent",
  "missing_documents",
]);
export type AutomationFlagKind = z.infer<typeof automationFlagKindEnum>;

export const automationFlagSeverityEnum = z.enum(["info", "warning", "critical"]);
export type AutomationFlagSeverity = z.infer<typeof automationFlagSeverityEnum>;

export const automationFlagSchema = z.object({
  id: z.string(),
  kind: automationFlagKindEnum,
  severity: automationFlagSeverityEnum,
  title: z.string(),
  description: z.string(),
  /** Optional CTA — `route` is a frontend path; `payload` is opaque to the
   *  server, interpreted by the screen at `route`. */
  cta: z
    .object({
      label: z.string(),
      route: z.string(),
      payload: z.record(z.unknown()).optional(),
    })
    .optional(),
  citations: z.array(z.string()),
});
export type AutomationFlag = z.infer<typeof automationFlagSchema>;

/* ── Predictive next trip ── */

export const predictiveNextTripSchema = z.object({
  /** True when we have enough past trips to compute a cadence. */
  hasEnoughHistory: z.boolean(),
  /** Mean days between past trips. null when hasEnoughHistory is false. */
  cadenceDays: z.number().nullable(),
  /** Days since the most recent past trip. null when no past trips. */
  daysSinceLastTrip: z.number().nullable(),
  /** True when daysSinceLastTrip > cadenceDays AND no upcoming trips. */
  isDue: z.boolean(),
  /** Hub IATA codes the user has flown from before, ordered by frequency. */
  preferredOrigins: z.array(z.string()),
  /** Continent-level suggestions: pick continents the user has dwelled in
   *  but hasn't visited recently. */
  suggestedContinents: z.array(z.string()),
  reasoning: z.string(),
});
export type PredictiveNextTrip = z.infer<typeof predictiveNextTripSchema>;

/* ── Context snapshot ── */

export const contextSnapshotSchema = z.object({
  generatedAt: z.number().int(),
  location: locationContextSchema,
  /** Currently-active trip (date is today or has a leg in `current` state). */
  activeTrip: z
    .object({
      tripId: z.string().nullable(),
      legId: z.string(),
      from: z.string().length(3),
      to: z.string().length(3),
      destinationCountry: z.string(),
      date: z.string(),
      airline: z.string(),
      flightNumber: z.string().nullable(),
    })
    .nullable(),
  /** Next upcoming trip (earliest future leg). Same shape as activeTrip but
   *  semantically distinct: present even when activeTrip is null. */
  nextTrip: z
    .object({
      tripId: z.string().nullable(),
      legId: z.string(),
      from: z.string().length(3),
      to: z.string().length(3),
      destinationCountry: z.string(),
      date: z.string(),
      airline: z.string(),
      flightNumber: z.string().nullable(),
      daysAway: z.number().int(),
    })
    .nullable(),
  walletSummary: z.object({
    totalUSD: z.number(),
    activeCurrency: z.string().nullable(),
    activeCurrencyAmount: z.number().nullable(),
    activeCurrencyAmountUSD: z.number().nullable(),
  }),
  automationFlags: z.array(automationFlagSchema),
  predictiveNextTrip: predictiveNextTripSchema,
  /** Suggested actions = top 3 recommendation IDs the home/copilot UI should surface. */
  suggestedActionIds: z.array(z.string()),
});
export type ContextSnapshot = z.infer<typeof contextSnapshotSchema>;
