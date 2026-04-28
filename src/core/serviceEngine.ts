/**
 * Slice-B Phase-7 — service engine.
 *
 * Pure ranking layer over the Phase-11 catalogs. Given a context summary
 * (next destination, active country, budget posture, weather kind), return
 * a ranked list of service-hub tabs the UI should highlight, plus deep
 * suggestions inside each (visa policy match, top-rated hotel near centre,
 * relevant insurance tier, etc.).
 *
 * Like contextEngine, this is a pure function — no IO, deterministic.
 */
import type { TripLifecycle } from "@shared/types/lifecycle";
import type { BudgetSnapshot } from "@shared/types/budget";

export type ServiceTab =
  | "visa"
  | "insurance"
  | "esim"
  | "exchange"
  | "hotels"
  | "rides"
  | "food"
  | "local";

export interface ServiceRanking {
  tab: ServiceTab;
  score: number;
  reason: string;
}

export interface ServiceInput {
  /** ISO-2 of the user's current country (from wallet activeCountry). */
  activeCountryIso2: string | null;
  nextTrip: TripLifecycle | null;
  /** Destination ISO-2 derived from nextTrip's first leg. */
  nextDestinationIso2: string | null;
  budget: BudgetSnapshot | null;
  /** Days until next trip (Infinity if none). */
  daysToNextTrip: number;
}

const WEIGHTS: Record<ServiceTab, number> = {
  visa: 1,
  insurance: 1,
  esim: 1,
  exchange: 1,
  hotels: 1,
  rides: 1,
  food: 1,
  local: 1,
};

/**
 * Rank service tabs. Higher score = surface higher in the hub.
 *
 * The math is deliberately additive and bounded — easier to debug and
 * test than a learnt model. Rules:
 *  - Trip in <30 days + foreign destination → boost visa, insurance, esim.
 *  - Trip in <7 days → boost hotels, rides.
 *  - Trip in <2 days → boost rides, food, local.
 *  - Active foreign country → boost local + food + rides.
 *  - Budget over → de-emphasise premium services (food/hotels) very mildly.
 */
export function rankServices(input: ServiceInput): ServiceRanking[] {
  const ranks: Record<ServiceTab, { score: number; reasons: string[] }> = {
    visa: { score: WEIGHTS.visa, reasons: [] },
    insurance: { score: WEIGHTS.insurance, reasons: [] },
    esim: { score: WEIGHTS.esim, reasons: [] },
    exchange: { score: WEIGHTS.exchange, reasons: [] },
    hotels: { score: WEIGHTS.hotels, reasons: [] },
    rides: { score: WEIGHTS.rides, reasons: [] },
    food: { score: WEIGHTS.food, reasons: [] },
    local: { score: WEIGHTS.local, reasons: [] },
  };

  const isForeignTrip =
    !!input.nextDestinationIso2 &&
    !!input.activeCountryIso2 &&
    input.nextDestinationIso2 !== input.activeCountryIso2;

  if (isForeignTrip && input.daysToNextTrip <= 30) {
    ranks.visa.score += 4;
    ranks.visa.reasons.push("Upcoming foreign trip — verify visa.");
    ranks.insurance.score += 4;
    ranks.insurance.reasons.push("Upcoming foreign trip — quote insurance.");
    ranks.esim.score += 3;
    ranks.esim.reasons.push("Pre-trip — set up data plan.");
    ranks.exchange.score += 3;
    ranks.exchange.reasons.push("Pre-trip — convert currency.");
  }

  if (input.daysToNextTrip <= 7) {
    ranks.hotels.score += 3;
    ranks.hotels.reasons.push("Trip this week — finalise stay.");
    ranks.rides.score += 2;
    ranks.rides.reasons.push("Trip this week — plan airport transfer.");
  }

  if (input.daysToNextTrip <= 2) {
    ranks.rides.score += 4;
    ranks.rides.reasons.push("Trip imminent — book the ride.");
    ranks.food.score += 2;
    ranks.food.reasons.push("Plan first meal at the destination.");
    ranks.local.score += 2;
    ranks.local.reasons.push("Quick reference for embassies / SIM stores.");
  }

  if (input.activeCountryIso2 && input.daysToNextTrip > 30) {
    // user not actively travelling — but currently in a country: surface local
    ranks.local.score += 3;
    ranks.local.reasons.push(`Discover ${input.activeCountryIso2} services nearby.`);
    ranks.food.score += 2;
    ranks.food.reasons.push("Local restaurants and cuisines.");
  }

  if (input.budget) {
    const overCount = input.budget.usage.filter((u) => u.status === "over").length;
    if (overCount > 0) {
      // small de-emphasis — we still want food/hotels reachable, just not top
      ranks.food.score -= 1;
      ranks.hotels.score -= 1;
      ranks.exchange.score += 1;
      ranks.exchange.reasons.push("Over budget — review FX before spending.");
    }
  }

  const ordered: ServiceRanking[] = (Object.keys(ranks) as ServiceTab[])
    .map((t) => ({
      tab: t,
      score: ranks[t].score,
      reason: ranks[t].reasons[0] ?? "Browse and compare.",
    }))
    .sort((a, b) => b.score - a.score);
  return ordered;
}
