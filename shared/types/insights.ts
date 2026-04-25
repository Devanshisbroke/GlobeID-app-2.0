import { z } from "zod";

/** Travel insights derived from a user's travel_records. */
export const continentBreakdownSchema = z.object({
  name: z.string(),
  countries: z.array(z.string()),
  count: z.number().int().nonnegative(),
});

export const travelInsightSchema = z.object({
  totalCountries: z.number().int().nonnegative(),
  totalFlights: z.number().int().nonnegative(),
  totalDistanceKm: z.number().nonnegative(),
  longestFlightKm: z.number().nonnegative(),
  longestRoute: z.string().nullable(), // e.g. "BOM → SFO" or null
  byContinent: z.array(continentBreakdownSchema),
  visitedCountries: z.array(z.string()),
  upcomingCountries: z.array(z.string()),
  nextTrip: z
    .object({
      id: z.string(),
      from: z.string().length(3),
      to: z.string().length(3),
      destinationCountry: z.string(),
      date: z.string(),
      airline: z.string(),
      flightNumber: z.string().optional(),
    })
    .nullable(),
  daysUntilNextTrip: z.number().int().nullable(),
  tripsThisYear: z.number().int().nonnegative(),
  mostVisitedRegion: z.string().nullable(),
});
export type TravelInsight = z.infer<typeof travelInsightSchema>;

/** Wallet insights derived from balances + recent travel context. */
export const walletCurrencyInsightSchema = z.object({
  currency: z.string(),
  amount: z.number(),
  amountUSD: z.number(),
  flag: z.string(),
  isInactive: z.boolean(),
  isActive: z.boolean(),
  reason: z.string().optional(), // e.g. "Active for upcoming Japan trip"
});

export const walletInsightSchema = z.object({
  totalUSD: z.number().nonnegative(),
  balanceCount: z.number().int().nonnegative(),
  byCurrency: z.array(walletCurrencyInsightSchema),
  dominantCurrency: z.string().nullable(),
  inactiveCurrencies: z.array(z.string()),
  activeCurrency: z.string().nullable(),
});
export type WalletInsight = z.infer<typeof walletInsightSchema>;

/** Cross-cutting activity insight for the home dashboard. */
export const activityInsightSchema = z.object({
  tripsThisMonth: z.number().int().nonnegative(),
  tripsLast30Days: z.number().int().nonnegative(),
  upcomingNext7Days: z.number().int().nonnegative(),
  upcomingNext30Days: z.number().int().nonnegative(),
  alertsUnread: z.number().int().nonnegative(),
  travelReadinessScore: z.number().int().min(0).max(100),
});
export type ActivityInsight = z.infer<typeof activityInsightSchema>;

/** Recommendation envelope. Grounded in real stored data. */
export const recommendationSchema = z.object({
  id: z.string(),
  kind: z.enum([
    "next_destination",
    "currency_action",
    "trip_continuation",
    "readiness",
  ]),
  title: z.string(),
  description: z.string(),
  /** Optional concrete payload: IATA codes, currency pair, etc. */
  payload: z.record(z.unknown()).optional(),
  /** Source data points cited so the UI can show provenance. */
  citations: z.array(z.string()).optional(),
  priority: z.number().int().min(0).max(100).default(50),
});
export type Recommendation = z.infer<typeof recommendationSchema>;

export const recommendationsResponseSchema = z.object({
  generatedAt: z.number().int(),
  items: z.array(recommendationSchema),
});
export type RecommendationsResponse = z.infer<typeof recommendationsResponseSchema>;
