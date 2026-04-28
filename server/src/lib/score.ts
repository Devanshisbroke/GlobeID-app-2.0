import type { TravelRecord } from "../../../shared/types/travel.js";
import type { TravelScore, TravelScoreBreakdown, TravelScoreTier } from "../../../shared/types/score.js";
import { findAirport, greatCircleKm, continentFor } from "./geo.js";

/**
 * Slice-B Phase-15 — travel scoring.
 *
 * Score is a deterministic function of breakdown:
 *   score =  20 * citiesVisited
 *         +  35 * countriesVisited
 *         +  60 * continentsCovered
 *         + 0.05 * kilometersFlown   (km of long-haul matter)
 *         +  10 * flightsCompleted
 *         +   3 * longestTripDays
 *         +  25 * monthlyStreak
 *         +  15 * upcomingTrips
 * Capped at 1000 so tiers stay meaningful.
 */

const TIERS: Array<{ tier: TravelScoreTier; min: number }> = [
  { tier: "rookie", min: 0 },
  { tier: "explorer", min: 150 },
  { tier: "globetrotter", min: 400 },
  { tier: "ambassador", min: 700 },
  { tier: "legend", min: 950 },
];

export function tierForScore(score: number): {
  tier: TravelScoreTier;
  pointsToNextTier: number | null;
} {
  let current: TravelScoreTier = "rookie";
  let next: { tier: TravelScoreTier; min: number } | null = null;
  for (const t of TIERS) {
    if (score >= t.min) current = t.tier;
    else {
      next = t;
      break;
    }
  }
  return {
    tier: current,
    pointsToNextTier: next ? next.min - score : null,
  };
}

export function computeBreakdown(records: TravelRecord[]): TravelScoreBreakdown {
  const past = records.filter((r) => r.type === "past");
  const upcoming = records.filter((r) => r.type !== "past");

  const cities = new Set<string>();
  const countries = new Set<string>();
  const continents = new Set<string>();
  let km = 0;
  let flightsCompleted = 0;

  for (const r of past) {
    flightsCompleted += 1;
    cities.add(r.to);
    cities.add(r.from);
    const fromAir = findAirport(r.from);
    const toAir = findAirport(r.to);
    if (fromAir) {
      countries.add(fromAir.country);
      continents.add(continentFor(fromAir.lat, fromAir.lng));
    }
    if (toAir) {
      countries.add(toAir.country);
      continents.add(continentFor(toAir.lat, toAir.lng));
    }
    if (fromAir && toAir) {
      km += greatCircleKm(fromAir, toAir);
    }
  }

  // Longest trip = max span (in days) for legs sharing the same calendar window.
  // Without an explicit tripId, we approximate by clustering consecutive past
  // legs that share neither origin nor destination by more than 14 days.
  const sortedDates = past.map((r) => r.date).sort();
  let longestTripDays = 0;
  if (sortedDates.length > 0) {
    const first = sortedDates[0]!;
    let clusterStart = first;
    let clusterEnd = first;
    for (let i = 1; i < sortedDates.length; i++) {
      const cur = sortedDates[i]!;
      const prev = new Date(clusterEnd);
      const curDate = new Date(cur);
      const dayGap = Math.round((curDate.getTime() - prev.getTime()) / 86_400_000);
      if (dayGap > 14) {
        const span = Math.round((new Date(clusterEnd).getTime() - new Date(clusterStart).getTime()) / 86_400_000);
        if (span > longestTripDays) longestTripDays = span;
        clusterStart = cur;
      }
      clusterEnd = cur;
    }
    const span = Math.round((new Date(clusterEnd).getTime() - new Date(clusterStart).getTime()) / 86_400_000);
    if (span > longestTripDays) longestTripDays = span;
  }

  // Monthly streak — count distinct YYYY-MM keys, ending with the most recent.
  const months = new Set(past.map((r) => r.date.slice(0, 7)));
  const sortedMonths = [...months].sort().reverse();
  let streak = 0;
  if (sortedMonths.length > 0) {
    streak = 1;
    for (let i = 0; i < sortedMonths.length - 1; i++) {
      const a = sortedMonths[i]!;
      const b = sortedMonths[i + 1]!;
      const aDate = new Date(`${a}-01`);
      const bDate = new Date(`${b}-01`);
      const monthDiff =
        (aDate.getFullYear() - bDate.getFullYear()) * 12 + (aDate.getMonth() - bDate.getMonth());
      if (monthDiff === 1) streak += 1;
      else break;
    }
  }

  return {
    citiesVisited: cities.size,
    countriesVisited: countries.size,
    continentsCovered: continents.size,
    kilometersFlown: Math.round(km),
    flightsCompleted,
    longestTripDays,
    monthlyStreak: streak,
    upcomingTrips: upcoming.length,
  };
}

export function scoreFromBreakdown(b: TravelScoreBreakdown): number {
  const raw =
    20 * b.citiesVisited +
    35 * b.countriesVisited +
    60 * b.continentsCovered +
    0.05 * b.kilometersFlown +
    10 * b.flightsCompleted +
    3 * b.longestTripDays +
    25 * b.monthlyStreak +
    15 * b.upcomingTrips;
  return Math.min(1000, Math.max(0, Math.round(raw)));
}

export function buildTravelScore(records: TravelRecord[]): TravelScore {
  const breakdown = computeBreakdown(records);
  const score = scoreFromBreakdown(breakdown);
  const tierInfo = tierForScore(score);
  return {
    score,
    tier: tierInfo.tier,
    pointsToNextTier: tierInfo.pointsToNextTier,
    breakdown,
    computedAt: new Date().toISOString(),
  };
}
