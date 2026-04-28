/**
 * Slice-B Phase-1 — context engine.
 *
 * Pure, deterministic synthesis of multiple store snapshots into a single
 * "what does the user need right now?" object. Same inputs → same output,
 * always; no IO; no random numbers; no hidden time calls beyond the
 * caller-supplied `now`.
 *
 * The engine is intentionally a *pure function*. Stores wire it up; this
 * module knows nothing about Zustand. That keeps the engine testable and
 * lets us reuse it from notifications, copilot, and the home screen.
 */
import {
  classifyDelay,
  legWindow,
  msUntilTripStart,
  nextLeg,
  type DelaySeverity,
} from "./travelEngine";
import type { TripLifecycle, FlightStatus } from "@shared/types/lifecycle";
import type { WeatherForecast } from "@shared/types/weather";
import type { TravelScore } from "@shared/types/score";
import type { LoyaltySnapshot } from "@shared/types/loyalty";
import type { BudgetSnapshot } from "@shared/types/budget";
import type { FraudFinding } from "@shared/types/fraud";
import type { WalletBalance } from "@shared/types/wallet";

/** A single recommendation surface to render. */
export interface ContextRecommendation {
  /** Stable id used for dedup + analytics. */
  id: string;
  /** Higher = more urgent. Always non-negative. */
  priority: number;
  kind:
    | "trip_imminent"
    | "boarding_now"
    | "delay_alert"
    | "weather_warning"
    | "budget_alert"
    | "fraud_alert"
    | "loyalty_milestone"
    | "score_milestone"
    | "topup_currency"
    | "no_emergency_contact"
    | "esim_suggestion"
    | "visa_check";
  title: string;
  description: string;
  /** Suggested deeplink the UI can navigate to. */
  ctaPath?: string;
  /** Set of stores whose changes should re-evaluate this rec. */
  sources: ReadonlyArray<
    "wallet" | "lifecycle" | "weather" | "score" | "loyalty" | "budget" | "fraud" | "safety"
  >;
}

/** Inputs the engine consumes. Each field is optional so callers can
 *  evaluate even before all stores are hydrated. */
export interface ContextInput {
  now?: number;
  trips?: TripLifecycle[];
  flightStatuses?: Record<string, FlightStatus>;
  weatherByIata?: Record<string, { forecast: WeatherForecast } | undefined>;
  score?: TravelScore | null;
  loyalty?: LoyaltySnapshot | null;
  budget?: BudgetSnapshot | null;
  fraudFindings?: FraudFinding[];
  walletBalances?: WalletBalance[];
  emergencyContactsCount?: number;
  /** ISO-2 country the user is currently in (from wallet activeCountry). */
  activeCountryIso2?: string | null;
}

export interface ContextResult {
  recommendations: ContextRecommendation[];
  /** Sources we'd like to prefetch given the active context. */
  prefetch: Array<"weather" | "fraud" | "loyalty" | "score" | "budget">;
  /** Compact summary fit for chrome / copilot. */
  summary: {
    activeTripId: string | null;
    nextLegInMs: number | null;
    boardingNow: boolean;
    delaySeverity: DelaySeverity;
    fraudHighCount: number;
    budgetOverCount: number;
  };
}

const HOUR = 60 * 60_000;
const DAY = 24 * HOUR;

/**
 * Run the engine. Returns a sorted-by-priority list of recommendations and
 * a compact summary.
 */
export function evaluateContext(input: ContextInput): ContextResult {
  const now = input.now ?? Date.now();
  const recs: ContextRecommendation[] = [];
  const prefetch: Set<ContextResult["prefetch"][number]> = new Set();

  const trips = input.trips ?? [];
  const activeTrip = trips.find((t) => t.state === "active") ?? null;
  const upcoming = trips
    .filter((t) => t.state === "booked" || t.state === "planning")
    .sort((a, b) => msUntilTripStart(a, now) - msUntilTripStart(b, now));
  const next = activeTrip ?? upcoming[0] ?? null;
  const nextLegRow = next ? nextLeg(next) : null;

  // --- Trip imminent / boarding now / delays -------------------------------
  let delaySeverity: DelaySeverity = "none";
  let boardingNow = false;
  let nextLegInMs: number | null = null;

  if (nextLegRow) {
    const win = legWindow(nextLegRow, now);
    nextLegInMs = win.msToDeparture;
    if (win.boardingOpen) {
      boardingNow = true;
      recs.push({
        id: `boarding:${nextLegRow.id}`,
        priority: 100,
        kind: "boarding_now",
        title: "Boarding now",
        description: `${nextLegRow.airline} ${nextLegRow.flightNumber ?? ""} from ${nextLegRow.fromIata} → ${nextLegRow.toIata} is boarding.`,
        ctaPath: next ? (next.tripId ? `/trip/${next.tripId}` : "/timeline") : undefined,
        sources: ["lifecycle"],
      });
    } else if (win.msToDeparture > 0 && win.msToDeparture <= 6 * HOUR) {
      recs.push({
        id: `imminent:${nextLegRow.id}`,
        priority: 80,
        kind: "trip_imminent",
        title: "Trip departing soon",
        description: `${nextLegRow.fromIata} → ${nextLegRow.toIata} in ${formatDuration(win.msToDeparture)}.`,
        ctaPath: next?.tripId ? `/trip/${next.tripId}` : "/timeline",
        sources: ["lifecycle"],
      });
      prefetch.add("weather");
    } else if (win.msToDeparture > 0 && win.msToDeparture <= 3 * DAY) {
      recs.push({
        id: `imminent:${nextLegRow.id}`,
        priority: 50,
        kind: "trip_imminent",
        title: "Trip in your week",
        description: `${nextLegRow.fromIata} → ${nextLegRow.toIata} in ${Math.ceil(win.msToDeparture / DAY)} day(s).`,
        ctaPath: next?.tripId ? `/trip/${next.tripId}` : "/timeline",
        sources: ["lifecycle"],
      });
    }

    const status = input.flightStatuses?.[nextLegRow.id];
    if (status) {
      const s = classifyDelay(status);
      if (s !== "none") {
        delaySeverity = s;
        recs.push({
          id: `delay:${nextLegRow.id}`,
          priority: priorityForDelay(s),
          kind: "delay_alert",
          title: severityLabel(s) + " delay",
          description: `${status.airline} ${status.flightNumber ?? ""} delayed ${status.delayMinutes} min.`,
          ctaPath: "/timeline",
          sources: ["lifecycle"],
        });
      }
    }

    // Weather warnings for the destination 7-day forecast
    const wx = input.weatherByIata?.[nextLegRow.toIata]?.forecast;
    if (wx) {
      const bad = wx.days
        .slice(0, 3)
        .find((d) => d.kind === "thunderstorm" || d.kind === "snow" || d.precipitationMm > 25);
      if (bad) {
        recs.push({
          id: `weather:${nextLegRow.id}`,
          priority: 40,
          kind: "weather_warning",
          title: `Severe weather at ${nextLegRow.toIata}`,
          description: `${labelKind(bad.kind)} expected on ${bad.date} (${bad.precipitationMm.toFixed(0)} mm).`,
          ctaPath: "/services/super",
          sources: ["weather", "lifecycle"],
        });
      }
    }
  }

  // --- Currency top-up suggestion -----------------------------------------
  if (next && input.walletBalances) {
    const destCountry = nextLegRow ? destCountryGuess(nextLegRow.toIata) : null;
    if (destCountry && next.state !== "complete") {
      const has = input.walletBalances.some(
        (b) => b.currency === destCountry.currency && b.amount > 0,
      );
      if (!has) {
        recs.push({
          id: `topup:${destCountry.currency}`,
          priority: 30,
          kind: "topup_currency",
          title: `Top up ${destCountry.currency}`,
          description: `You'll need ${destCountry.currency} for ${destCountry.name}. Convert from your wallet.`,
          ctaPath: "/wallet",
          sources: ["wallet", "lifecycle"],
        });
      }
    }
  }

  // --- Budget alerts -------------------------------------------------------
  let budgetOverCount = 0;
  if (input.budget) {
    for (const u of input.budget.usage) {
      if (u.status === "over") {
        budgetOverCount += 1;
        recs.push({
          id: `budget-over:${u.scope}`,
          priority: 60,
          kind: "budget_alert",
          title: `Over budget: ${u.scope}`,
          description: `Spent ${u.spent.toFixed(2)} / ${u.cap.capAmount.toFixed(2)} ${u.cap.currency}.`,
          ctaPath: "/services/super",
          sources: ["budget", "wallet"],
        });
      } else if (u.status === "near") {
        recs.push({
          id: `budget-near:${u.scope}`,
          priority: 25,
          kind: "budget_alert",
          title: `Approaching cap: ${u.scope}`,
          description: `${(u.fractionUsed * 100).toFixed(0)}% used.`,
          ctaPath: "/services/super",
          sources: ["budget", "wallet"],
        });
      }
    }
  } else {
    prefetch.add("budget");
  }

  // --- Fraud ---------------------------------------------------------------
  let fraudHighCount = 0;
  if (input.fraudFindings) {
    for (const f of input.fraudFindings) {
      if (f.severity === "high") fraudHighCount += 1;
    }
    if (fraudHighCount > 0) {
      recs.push({
        id: `fraud:${fraudHighCount}`,
        priority: 90,
        kind: "fraud_alert",
        title: `${fraudHighCount} high-severity fraud finding(s)`,
        description: "Review your wallet activity and confirm or dispute these debits.",
        ctaPath: "/services/super",
        sources: ["fraud", "wallet"],
      });
    }
  } else {
    prefetch.add("fraud");
  }

  // --- Loyalty milestones --------------------------------------------------
  if (input.loyalty) {
    if (
      input.loyalty.pointsToNextTier !== null &&
      input.loyalty.pointsToNextTier <= 200
    ) {
      recs.push({
        id: `loyalty:next-tier`,
        priority: 20,
        kind: "loyalty_milestone",
        title: `${input.loyalty.pointsToNextTier} pts to next tier`,
        description: `Currently ${input.loyalty.tier} — close to a tier upgrade.`,
        ctaPath: "/services/super",
        sources: ["loyalty"],
      });
    }
  } else {
    prefetch.add("loyalty");
  }

  // --- Score milestones ----------------------------------------------------
  if (input.score) {
    if (input.score.pointsToNextTier !== null && input.score.pointsToNextTier <= 50) {
      recs.push({
        id: "score:near-tier",
        priority: 15,
        kind: "score_milestone",
        title: `${input.score.pointsToNextTier} pts to ${input.score.tier === "legend" ? "legend" : "next tier"}`,
        description: `Travel score ${input.score.score} / 1000.`,
        ctaPath: "/services/super",
        sources: ["score"],
      });
    }
  } else {
    prefetch.add("score");
  }

  // --- Safety: missing emergency contacts ---------------------------------
  if (input.emergencyContactsCount === 0) {
    recs.push({
      id: "safety:no-contact",
      priority: 35,
      kind: "no_emergency_contact",
      title: "Add an emergency contact",
      description: "Travelling abroad without one is a real safety risk.",
      ctaPath: "/services/super",
      sources: ["safety"],
    });
  }

  // --- eSIM suggestion (next trip in foreign country) ---------------------
  if (next && nextLegRow) {
    const dest = destCountryGuess(nextLegRow.toIata);
    if (dest && dest.iso2 !== input.activeCountryIso2) {
      recs.push({
        id: `esim:${dest.iso2}`,
        priority: 18,
        kind: "esim_suggestion",
        title: `Get an eSIM for ${dest.name}`,
        description: "Avoid roaming surprises — activate before you fly.",
        ctaPath: "/services/super",
        sources: ["lifecycle"],
      });
      recs.push({
        id: `visa:${dest.iso2}`,
        priority: 22,
        kind: "visa_check",
        title: `Check visa for ${dest.name}`,
        description: "Confirm requirements and processing days.",
        ctaPath: "/services/super",
        sources: ["lifecycle"],
      });
    }
  }

  recs.sort((a, b) => b.priority - a.priority);
  return {
    recommendations: recs,
    prefetch: Array.from(prefetch),
    summary: {
      activeTripId: activeTrip?.tripId ?? null,
      nextLegInMs,
      boardingNow,
      delaySeverity,
      fraudHighCount,
      budgetOverCount,
    },
  };
}

/* ── helpers ─────────────────────────────────────────────────────────── */

function priorityForDelay(s: DelaySeverity): number {
  return { none: 0, minor: 30, moderate: 55, major: 75, critical: 95 }[s];
}

function severityLabel(s: DelaySeverity): string {
  return s === "minor" ? "Minor" : s === "moderate" ? "Moderate" : s === "major" ? "Major" : "Critical";
}

function labelKind(k: string): string {
  return k.replace("_", " ");
}

function formatDuration(ms: number): string {
  if (ms < 60_000) return "<1 min";
  const min = Math.floor(ms / 60_000);
  if (min < 60) return `${min} min`;
  const h = Math.floor(min / 60);
  const m = min % 60;
  return m === 0 ? `${h}h` : `${h}h ${m}m`;
}

/**
 * Tiny IATA → country/currency map for the most-frequent destinations in
 * the catalog. Keeps the engine self-contained for the rec heuristics; the
 * full mapping lives in `shared/data/airportsCatalog.ts` for the real
 * lookups (services / boarding pass).
 */
const IATA_HINT: Record<string, { iso2: string; name: string; currency: string }> = {
  SIN: { iso2: "SG", name: "Singapore", currency: "SGD" },
  HND: { iso2: "JP", name: "Japan", currency: "JPY" },
  NRT: { iso2: "JP", name: "Japan", currency: "JPY" },
  LHR: { iso2: "GB", name: "United Kingdom", currency: "GBP" },
  LGW: { iso2: "GB", name: "United Kingdom", currency: "GBP" },
  CDG: { iso2: "FR", name: "France", currency: "EUR" },
  FRA: { iso2: "DE", name: "Germany", currency: "EUR" },
  DXB: { iso2: "AE", name: "United Arab Emirates", currency: "AED" },
  JFK: { iso2: "US", name: "United States", currency: "USD" },
  EWR: { iso2: "US", name: "United States", currency: "USD" },
  LAX: { iso2: "US", name: "United States", currency: "USD" },
  SFO: { iso2: "US", name: "United States", currency: "USD" },
  BKK: { iso2: "TH", name: "Thailand", currency: "THB" },
  BOM: { iso2: "IN", name: "India", currency: "INR" },
  DEL: { iso2: "IN", name: "India", currency: "INR" },
  HKG: { iso2: "HK", name: "Hong Kong", currency: "HKD" },
  ICN: { iso2: "KR", name: "South Korea", currency: "KRW" },
  SYD: { iso2: "AU", name: "Australia", currency: "AUD" },
  AMS: { iso2: "NL", name: "Netherlands", currency: "EUR" },
  IST: { iso2: "TR", name: "Turkey", currency: "TRY" },
};

function destCountryGuess(iata: string): { iso2: string; name: string; currency: string } | null {
  return IATA_HINT[iata.toUpperCase()] ?? null;
}
