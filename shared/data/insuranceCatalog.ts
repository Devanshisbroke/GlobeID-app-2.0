/**
 * Slice-B Phase-11 — travel insurance plans.
 *
 * Catalogs are the *real* part. Premiums are computed deterministically
 * from trip duration, traveller age, and tier — no random "from $X" pricing.
 */

export type CoverageTier = "basic" | "standard" | "premium" | "world_explorer";

export interface InsurancePlan {
  id: string;
  carrier: string;
  tier: CoverageTier;
  /** Underwritten daily base premium in USD. */
  baseDailyUsd: number;
  /** Deductible in USD. */
  deductibleUsd: number;
  medicalCoverageUsd: number;
  evacuationCoverageUsd: number;
  baggageCoverageUsd: number;
  tripCancellationCoverageUsd: number;
  inclusions: string[];
  exclusions: string[];
  ageBands: Array<{ minAge: number; maxAge: number; multiplier: number }>;
  /** Region multiplier vs. baseline (Schengen = 1.0). */
  regionMultipliers: Record<string, number>;
}

export const insuranceCatalog: InsurancePlan[] = [
  {
    id: "ins_basic_world",
    carrier: "GlobeShield",
    tier: "basic",
    baseDailyUsd: 1.5,
    deductibleUsd: 250,
    medicalCoverageUsd: 50_000,
    evacuationCoverageUsd: 100_000,
    baggageCoverageUsd: 500,
    tripCancellationCoverageUsd: 1_000,
    inclusions: ["Emergency medical", "Lost baggage (capped)", "Trip delay > 6h"],
    exclusions: ["Pre-existing conditions", "Adventure sports", "Pregnancy"],
    ageBands: [
      { minAge: 0, maxAge: 17, multiplier: 0.6 },
      { minAge: 18, maxAge: 39, multiplier: 1.0 },
      { minAge: 40, maxAge: 59, multiplier: 1.2 },
      { minAge: 60, maxAge: 75, multiplier: 1.8 },
      { minAge: 76, maxAge: 99, multiplier: 2.5 },
    ],
    regionMultipliers: { schengen: 1.0, us_canada: 1.4, asean: 0.9, default: 1.0 },
  },
  {
    id: "ins_standard_world",
    carrier: "GlobeShield",
    tier: "standard",
    baseDailyUsd: 2.5,
    deductibleUsd: 100,
    medicalCoverageUsd: 250_000,
    evacuationCoverageUsd: 500_000,
    baggageCoverageUsd: 1_500,
    tripCancellationCoverageUsd: 5_000,
    inclusions: ["Everything in Basic", "Pre-existing stable conditions", "Trip cancellation", "Personal liability up to $50k"],
    exclusions: ["Adventure sports without rider", "Pregnancy after 24 weeks"],
    ageBands: [
      { minAge: 0, maxAge: 17, multiplier: 0.6 },
      { minAge: 18, maxAge: 39, multiplier: 1.0 },
      { minAge: 40, maxAge: 59, multiplier: 1.3 },
      { minAge: 60, maxAge: 75, multiplier: 2.0 },
      { minAge: 76, maxAge: 99, multiplier: 3.0 },
    ],
    regionMultipliers: { schengen: 1.0, us_canada: 1.4, asean: 0.9, default: 1.0 },
  },
  {
    id: "ins_premium_world",
    carrier: "TravelGuard Plus",
    tier: "premium",
    baseDailyUsd: 4.5,
    deductibleUsd: 0,
    medicalCoverageUsd: 1_000_000,
    evacuationCoverageUsd: 1_000_000,
    baggageCoverageUsd: 5_000,
    tripCancellationCoverageUsd: 15_000,
    inclusions: ["Everything in Standard", "Cancel-for-any-reason (75%)", "Adventure sports", "Rental car damage"],
    exclusions: ["Self-inflicted injuries", "War zones (per advisory)"],
    ageBands: [
      { minAge: 0, maxAge: 17, multiplier: 0.7 },
      { minAge: 18, maxAge: 39, multiplier: 1.0 },
      { minAge: 40, maxAge: 59, multiplier: 1.3 },
      { minAge: 60, maxAge: 75, multiplier: 2.1 },
      { minAge: 76, maxAge: 99, multiplier: 3.2 },
    ],
    regionMultipliers: { schengen: 1.0, us_canada: 1.5, asean: 0.9, default: 1.0 },
  },
  {
    id: "ins_world_explorer",
    carrier: "TravelGuard Plus",
    tier: "world_explorer",
    baseDailyUsd: 7.5,
    deductibleUsd: 0,
    medicalCoverageUsd: 2_000_000,
    evacuationCoverageUsd: 2_000_000,
    baggageCoverageUsd: 10_000,
    tripCancellationCoverageUsd: 30_000,
    inclusions: ["Everything in Premium", "Annual multi-trip (60 days/trip)", "Concierge", "High-altitude trekking", "Scuba up to 40m"],
    exclusions: ["Hazardous occupations", "Professional sports"],
    ageBands: [
      { minAge: 18, maxAge: 39, multiplier: 1.0 },
      { minAge: 40, maxAge: 59, multiplier: 1.4 },
      { minAge: 60, maxAge: 75, multiplier: 2.4 },
      { minAge: 76, maxAge: 99, multiplier: 3.8 },
    ],
    regionMultipliers: { schengen: 1.0, us_canada: 1.5, asean: 1.0, default: 1.1 },
  },
];

export function classifyRegion(destinationIso2: string): keyof InsurancePlan["regionMultipliers"] {
  const schengen = ["AT","BE","CH","CZ","DE","DK","EE","ES","FI","FR","GR","HR","HU","IS","IT","LI","LT","LU","LV","MT","NL","NO","PL","PT","SE","SI","SK"];
  if (schengen.includes(destinationIso2.toUpperCase())) return "schengen";
  if (["US", "CA"].includes(destinationIso2.toUpperCase())) return "us_canada";
  if (["SG", "MY", "TH", "VN", "ID", "PH", "BN", "MM", "KH", "LA"].includes(destinationIso2.toUpperCase())) return "asean";
  return "default";
}

export function quotePremium(
  plan: InsurancePlan,
  tripDays: number,
  travellerAge: number,
  destinationIso2: string,
): { premiumUsd: number; ageMultiplier: number; regionMultiplier: number } {
  const ageBand = plan.ageBands.find((b) => travellerAge >= b.minAge && travellerAge <= b.maxAge);
  const ageMultiplier = ageBand?.multiplier ?? 1.0;
  const region = classifyRegion(destinationIso2);
  const regionMultiplier = plan.regionMultipliers[region] ?? plan.regionMultipliers.default ?? 1.0;
  const days = Math.max(1, Math.floor(tripDays));
  const premium = plan.baseDailyUsd * days * ageMultiplier * regionMultiplier;
  return {
    premiumUsd: Math.round(premium * 100) / 100,
    ageMultiplier,
    regionMultiplier,
  };
}
