import { z } from "zod";

/**
 * Slice-B — travel scoring.
 *
 * The score is *fully derived* from existing `travelRecords` + `plannedTrips`
 * — no new mutable state. Computed server-side so the same number is
 * shown across web/native clients.
 */

export const travelScoreBreakdownSchema = z.object({
  /** Distinct destination IATAs visited (past type). */
  citiesVisited: z.number().int().min(0),
  /** Distinct ISO country codes inferred from destination IATAs. */
  countriesVisited: z.number().int().min(0),
  /** Distinct continents covered (one of: AF, AN, AS, EU, NA, OC, SA). */
  continentsCovered: z.number().int().min(0),
  /** Total km flown (great-circle, sum of all past legs). */
  kilometersFlown: z.number().min(0),
  /** Number of legs flagged source='history'. */
  flightsCompleted: z.number().int().min(0),
  /** Longest single trip in days (from earliest leg to latest leg of same tripId). */
  longestTripDays: z.number().int().min(0),
  /** Consecutive months with at least one trip, ending at the most recent. */
  monthlyStreak: z.number().int().min(0),
  /** Upcoming trips (source='planner' or type='upcoming'). */
  upcomingTrips: z.number().int().min(0),
});
export type TravelScoreBreakdown = z.infer<typeof travelScoreBreakdownSchema>;

export const travelScoreTierEnum = z.enum([
  "rookie",
  "explorer",
  "globetrotter",
  "ambassador",
  "legend",
]);
export type TravelScoreTier = z.infer<typeof travelScoreTierEnum>;

export const travelScoreSchema = z.object({
  /** 0..1000 composite score. Deterministic from breakdown. */
  score: z.number().int().min(0).max(1000),
  tier: travelScoreTierEnum,
  pointsToNextTier: z.number().int().nullable(),
  breakdown: travelScoreBreakdownSchema,
  computedAt: z.string(),
});
export type TravelScore = z.infer<typeof travelScoreSchema>;
