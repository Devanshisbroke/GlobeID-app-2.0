/**
 * Travel insights — deterministic intelligence layer (BACKLOG I 105–109).
 *
 * Pure functions over wallet transactions + travel history. No LLM,
 * no external API. Each insight is unit-testable by feeding fake
 * fixtures. The Home / Insights surfaces consume these to render
 * "Smart suggestion" pills.
 *
 * Insights produced:
 *  - I 105: Spend anomaly — flag merchants whose weekly spend is >3σ
 *           above their 8-week rolling mean.
 *  - I 106: Travel-pattern insight — top destination + top weekday.
 *  - I 108: Carbon footprint — per-flight CO₂ estimate from great-circle
 *           distance × emissions factor (kg CO₂ per passenger-km).
 *  - I 107: Itinerary tight-connection — flag flights with <60min layover.
 *  - I 109: Frequent route — count (origin→dest) over last 12 months,
 *           threshold ≥3 occurrences = candidate for "save route" CTA.
 */

import type { TravelRecord } from "@/store/userStore";

/* ──────────────────── shared types ──────────────────── */

export interface Transaction {
  id: string;
  /** Epoch ms. */
  ts: number;
  amountUSD: number;
  merchant: string;
  category?: string;
}

/* ──────────────────── I 105 spend anomaly ──────────────────── */

export interface AnomalyFlag {
  merchant: string;
  weeklySpend: number;
  rollingMean: number;
  rollingStdDev: number;
  /** sigma above rolling mean. ≥3 = anomaly. */
  zScore: number;
}

const MS_WEEK = 7 * 24 * 60 * 60 * 1000;
const ROLLING_WEEKS = 8;

/**
 * Detect merchants with a current-week spend > 3σ above their 8-week
 * rolling mean. Requires at least 4 prior weeks of data per merchant
 * to avoid noisy fixtures from triggering.
 */
export function detectSpendAnomalies(
  transactions: Transaction[],
  now: number = Date.now(),
): AnomalyFlag[] {
  const buckets = bucketByMerchantWeek(transactions, now);
  const flags: AnomalyFlag[] = [];
  for (const [merchant, weeks] of buckets) {
    const current = weeks[0] ?? 0;
    const history = weeks.slice(1, ROLLING_WEEKS).filter((v) => v > 0);
    if (history.length < 4) continue;
    const mean = history.reduce((a, b) => a + b, 0) / history.length;
    const variance =
      history.reduce((a, b) => a + (b - mean) ** 2, 0) / history.length;
    const stdDev = Math.sqrt(variance);
    if (stdDev === 0) continue;
    const zScore = (current - mean) / stdDev;
    if (zScore >= 3 && current > mean * 1.25) {
      flags.push({
        merchant,
        weeklySpend: round(current, 2),
        rollingMean: round(mean, 2),
        rollingStdDev: round(stdDev, 2),
        zScore: round(zScore, 2),
      });
    }
  }
  return flags.sort((a, b) => b.zScore - a.zScore);
}

function bucketByMerchantWeek(
  transactions: Transaction[],
  now: number,
): Map<string, number[]> {
  const buckets = new Map<string, number[]>();
  for (const t of transactions) {
    const weeksAgo = Math.floor((now - t.ts) / MS_WEEK);
    if (weeksAgo < 0 || weeksAgo >= ROLLING_WEEKS) continue;
    const list = buckets.get(t.merchant) ?? new Array(ROLLING_WEEKS).fill(0);
    list[weeksAgo] = (list[weeksAgo] ?? 0) + t.amountUSD;
    buckets.set(t.merchant, list);
  }
  return buckets;
}

/* ──────────────────── I 106 pattern insight ──────────────────── */

export interface TravelPatternInsight {
  topDestinationIata: string | null;
  /** Visit count of the top destination over last 12 months. */
  topDestinationVisits: number;
  /** ISO weekday 0..6 (0=Sun). null when sample size <3. */
  preferredWeekday: number | null;
  /** Total flights counted in window. */
  totalFlightsWindow: number;
}

const MS_YEAR = 365 * 24 * 60 * 60 * 1000;

export function computeTravelPattern(
  history: TravelRecord[],
  now: number = Date.now(),
): TravelPatternInsight {
  const window = history.filter(
    (t) => isFlight(t) && now - new Date(t.date).getTime() < MS_YEAR,
  );
  if (window.length === 0) {
    return {
      topDestinationIata: null,
      topDestinationVisits: 0,
      preferredWeekday: null,
      totalFlightsWindow: 0,
    };
  }
  const dest = new Map<string, number>();
  const weekday = new Array<number>(7).fill(0);
  for (const t of window) {
    const d = t.to ?? "";
    if (d) dest.set(d, (dest.get(d) ?? 0) + 1);
    const dt = new Date(t.date);
    if (Number.isFinite(dt.getTime())) {
      weekday[dt.getDay()] = (weekday[dt.getDay()] ?? 0) + 1;
    }
  }
  const sorted = [...dest.entries()].sort((a, b) => b[1] - a[1]);
  const topDest = sorted[0];
  const maxWeekday = Math.max(...weekday);
  const preferredWeekday =
    maxWeekday >= 3 ? weekday.indexOf(maxWeekday) : null;
  return {
    topDestinationIata: topDest?.[0] ?? null,
    topDestinationVisits: topDest?.[1] ?? 0,
    preferredWeekday,
    totalFlightsWindow: window.length,
  };
}

/* ──────────────────── I 108 carbon footprint ──────────────────── */

export interface CarbonEstimate {
  /** kg CO₂e per passenger. Caller renders. */
  kgCo2e: number;
  distanceKm: number;
  /** Cabin class assumed. Economy default. */
  cabinClass: "economy" | "premium" | "business" | "first";
}

/**
 * Per-passenger CO₂e estimate using ICAO 2018 baseline factors:
 *  - short-haul (<1500km): 0.255 kg/pax-km
 *  - medium (<3000km):     0.156 kg/pax-km
 *  - long  (≥3000km):      0.134 kg/pax-km
 * Cabin multipliers (ICAO): economy 1.0, premium 1.6, business 2.9,
 * first 4.0. Output rounded to whole kg.
 */
export function estimateFlightCarbon(
  distanceKm: number,
  cabinClass: CarbonEstimate["cabinClass"] = "economy",
): CarbonEstimate {
  const factor =
    distanceKm < 1500 ? 0.255 : distanceKm < 3000 ? 0.156 : 0.134;
  const cabinMul = { economy: 1, premium: 1.6, business: 2.9, first: 4 }[
    cabinClass
  ];
  const kg = Math.round(distanceKm * factor * cabinMul);
  return { kgCo2e: kg, distanceKm: Math.round(distanceKm), cabinClass };
}

/* ──────────────────── I 107 tight connection ──────────────────── */

export interface TightConnectionFlag {
  fromLegId: string;
  toLegId: string;
  airportIata: string;
  layoverMinutes: number;
  severity: "warning" | "critical";
}

const TIGHT_LAYOVER_WARNING_MIN = 90;
const TIGHT_LAYOVER_CRITICAL_MIN = 60;

export interface ConnectionLeg {
  id: string;
  fromIata: string;
  toIata: string;
  /** Epoch ms departure. */
  departureTs: number;
  /** Epoch ms arrival. */
  arrivalTs: number;
}

export function detectTightConnections(
  legs: ConnectionLeg[],
): TightConnectionFlag[] {
  if (legs.length < 2) return [];
  const sorted = [...legs].sort((a, b) => a.departureTs - b.departureTs);
  const out: TightConnectionFlag[] = [];
  for (let i = 0; i < sorted.length - 1; i++) {
    const a = sorted[i]!;
    const b = sorted[i + 1]!;
    if (a.toIata !== b.fromIata) continue;
    const diffMin = (b.departureTs - a.arrivalTs) / 60000;
    if (diffMin < TIGHT_LAYOVER_WARNING_MIN) {
      out.push({
        fromLegId: a.id,
        toLegId: b.id,
        airportIata: a.toIata,
        layoverMinutes: Math.round(diffMin),
        severity:
          diffMin < TIGHT_LAYOVER_CRITICAL_MIN ? "critical" : "warning",
      });
    }
  }
  return out;
}

/* ──────────────────── I 109 frequent route ──────────────────── */

export interface FrequentRoute {
  fromIata: string;
  toIata: string;
  count: number;
}

export function detectFrequentRoutes(
  history: TravelRecord[],
  now: number = Date.now(),
  threshold: number = 3,
): FrequentRoute[] {
  const window = history.filter(
    (t) => isFlight(t) && now - new Date(t.date).getTime() < MS_YEAR,
  );
  const counts = new Map<string, number>();
  for (const t of window) {
    const from = t.from ?? "";
    const to = t.to ?? "";
    if (!from || !to) continue;
    const key = `${from}->${to}`;
    counts.set(key, (counts.get(key) ?? 0) + 1);
  }
  const out: FrequentRoute[] = [];
  for (const [key, count] of counts) {
    if (count < threshold) continue;
    const [from, to] = key.split("->");
    if (from && to) out.push({ fromIata: from, toIata: to, count });
  }
  return out.sort((a, b) => b.count - a.count);
}

/* ──────────────────── shared helpers ──────────────────── */

function isFlight(t: TravelRecord): boolean {
  // Every TravelRecord is a flight in this app — the discriminant is the
  // tense (past/current/upcoming), not the modality. Helper kept around
  // so future work that introduces non-flight TravelRecords doesn't
  // accidentally polute the insight buckets.
  return t.type === "past" || t.type === "current" || t.type === "upcoming";
}

function round(n: number, decimals: number): number {
  const m = 10 ** decimals;
  return Math.round(n * m) / m;
}
