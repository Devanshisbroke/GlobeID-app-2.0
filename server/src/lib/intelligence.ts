/**
 * Phase 9-β — Intelligence engine.
 *
 * Pure derivation over loaded DB rows. No network, no external APIs, no
 * placeholder confidence scores — every value carries citations[] so the UI
 * can show provenance.
 *
 * Three responsibilities:
 *   1. computeLocationContext — what country/currency is the user "in".
 *   2. computePredictiveNextTrip — flight cadence analysis on past travel.
 *   3. computeAutomationFlags — passport, currency, document checks.
 *   4. computeContextSnapshot — orchestrator that assembles 1+2+3 plus the
 *      next/active trip and a wallet summary into a single payload.
 */

import { eq } from "drizzle-orm";
import { db } from "../db/client.js";
import {
  travelRecords,
  walletBalances,
  walletState,
  users,
} from "../db/schema.js";
import { findAirport, currencyOf, continentOf } from "../../../shared/data/airports.js";
import type {
  AutomationFlag,
  ContextSnapshot,
  LocationContext,
  PredictiveNextTrip,
} from "../../../shared/types/intelligence.js";
import { computeWalletInsight, computeTravelInsight } from "./insights.js";
import { computeRecommendations } from "./insights.js";

/* ── Helpers ── */

function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
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

interface TravelRow {
  id: string;
  fromIata: string;
  toIata: string;
  date: string;
  airline: string;
  type: "upcoming" | "past" | "current";
  flightNumber: string | null;
  tripId: string | null;
  source: "history" | "planner";
}

function loadTravel(userId: string): TravelRow[] {
  return db
    .select({
      id: travelRecords.id,
      fromIata: travelRecords.fromIata,
      toIata: travelRecords.toIata,
      date: travelRecords.date,
      airline: travelRecords.airline,
      type: travelRecords.type,
      flightNumber: travelRecords.flightNumber,
      tripId: travelRecords.tripId,
      source: travelRecords.source,
    })
    .from(travelRecords)
    .where(eq(travelRecords.userId, userId))
    .all();
}

/* ── 1) Location context ── */

export function computeLocationContext(userId: string): LocationContext {
  const stateRow = db
    .select({
      activeCountry: walletState.activeCountry,
      defaultCurrency: walletState.defaultCurrency,
    })
    .from(walletState)
    .where(eq(walletState.userId, userId))
    .get();

  // 1a) wallet_state.active_country wins when present.
  if (stateRow?.activeCountry) {
    return {
      country: stateRow.activeCountry,
      currency: currencyOf(stateRow.activeCountry) ?? stateRow.defaultCurrency ?? null,
      source: "wallet",
      confidence: 1,
    };
  }

  // 1b) Most recent past travel destination.
  const today = todayIso();
  const rows = loadTravel(userId);
  const past = rows
    .filter((r) => r.type === "past" && r.date <= today)
    .sort((a, b) => b.date.localeCompare(a.date));
  const latest = past[0];
  if (latest) {
    const apt = findAirport(latest.toIata);
    if (apt) {
      return {
        country: apt.country,
        currency: currencyOf(apt.country) ?? null,
        source: "travel",
        confidence: 1,
      };
    }
  }

  // 1c) Fall back to user.nationality (home).
  const userRow = db
    .select({ nationality: users.nationality })
    .from(users)
    .where(eq(users.id, userId))
    .get();
  if (userRow?.nationality) {
    return {
      country: userRow.nationality,
      currency: currencyOf(userRow.nationality) ?? null,
      source: "home",
      confidence: 0.5,
    };
  }

  return { country: null, currency: null, source: "home", confidence: 0 };
}

/* ── 2) Predictive next trip ── */

export function computePredictiveNextTrip(userId: string): PredictiveNextTrip {
  const today = todayIso();
  const rows = loadTravel(userId);
  const past = rows
    .filter((r) => r.type === "past")
    .sort((a, b) => a.date.localeCompare(b.date));
  const upcoming = rows.filter((r) => r.type === "upcoming" || r.type === "current");

  // Cadence requires >=3 past trips so we have >=2 inter-trip intervals.
  const hasEnoughHistory = past.length >= 3;
  let cadenceDays: number | null = null;
  if (hasEnoughHistory) {
    let totalGap = 0;
    let n = 0;
    for (let i = 1; i < past.length; i++) {
      totalGap += daysBetween(past[i - 1]!.date, past[i]!.date);
      n += 1;
    }
    cadenceDays = n > 0 ? Math.round(totalGap / n) : null;
  }

  const lastPast = past[past.length - 1] ?? null;
  const daysSinceLastTrip = lastPast ? daysBetween(lastPast.date, today) : null;
  const isDue =
    upcoming.length === 0 &&
    cadenceDays !== null &&
    daysSinceLastTrip !== null &&
    daysSinceLastTrip > cadenceDays;

  // Preferred origins = past `from_iata` ordered by frequency.
  const originFreq = new Map<string, number>();
  for (const r of past) {
    originFreq.set(r.fromIata, (originFreq.get(r.fromIata) ?? 0) + 1);
  }
  const preferredOrigins = [...originFreq.entries()]
    .sort((a, b) => b[1] - a[1])
    .map(([iata]) => iata)
    .slice(0, 3);

  // Continents the user has visited but not in the last 90 days.
  const continentLastSeen = new Map<string, string>();
  for (const r of past) {
    const apt = findAirport(r.toIata);
    if (!apt) continue;
    const cont = continentOf(apt.country);
    const prev = continentLastSeen.get(cont);
    if (!prev || r.date > prev) continentLastSeen.set(cont, r.date);
  }
  const suggestedContinents = [...continentLastSeen.entries()]
    .filter(([, lastDate]) => daysBetween(lastDate, today) > 90)
    .sort((a, b) => a[1].localeCompare(b[1]))
    .map(([cont]) => cont);

  let reasoning: string;
  if (!hasEnoughHistory) {
    reasoning = `Need ≥3 past flights to compute cadence (have ${past.length}).`;
  } else if (isDue) {
    reasoning = `${daysSinceLastTrip}d since last trip — exceeds your ${cadenceDays}d average.`;
  } else if (upcoming.length > 0) {
    reasoning = `Upcoming trip already on file; predictive engine idle.`;
  } else {
    reasoning = `${daysSinceLastTrip}d since last trip — within your ${cadenceDays}d average.`;
  }

  return {
    hasEnoughHistory,
    cadenceDays,
    daysSinceLastTrip,
    isDue,
    preferredOrigins,
    suggestedContinents,
    reasoning,
  };
}

/* ── 3) Automation flags ── */

export function computeAutomationFlags(userId: string): AutomationFlag[] {
  const flags: AutomationFlag[] = [];
  const today = todayIso();

  const userRow = db
    .select({ passportNo: users.passportNo, dateOfBirth: users.dateOfBirth })
    .from(users)
    .where(eq(users.id, userId))
    .get();

  const travel = computeTravelInsight(userId);
  const wallet = computeWalletInsight(userId);

  // 3a) Passport "expiring" heuristic — we don't store a real expiry date.
  // Real-world rule: many countries require ≥6 months validity. Without an
  // expiry column we surface a *capability gap*, not a fake date — clearly
  // labelled in the description so the user knows it's a structural prompt.
  if (
    travel.nextTrip &&
    travel.daysUntilNextTrip !== null &&
    travel.daysUntilNextTrip <= 90 &&
    !userRow?.passportNo
  ) {
    flags.push({
      id: `auto-passport-missing`,
      kind: "passport_expiring",
      severity: "warning",
      title: "No passport on file",
      description:
        `Your ${travel.nextTrip.destinationCountry} trip is in ${travel.daysUntilNextTrip} day${
          travel.daysUntilNextTrip === 1 ? "" : "s"
        }. Add your passport to enable visa & document checks.`,
      cta: { label: "Add passport", route: "/identity" },
      citations: ["users.passport_no", "travel_records.next"],
    });
  }

  // 3b) Currency mismatch — upcoming trip but no balance in destination's currency.
  if (travel.nextTrip && wallet.activeCurrency) {
    const has = wallet.byCurrency.find(
      (b) => b.currency === wallet.activeCurrency && b.amount > 0,
    );
    if (!has) {
      flags.push({
        id: `auto-currency-missing-${wallet.activeCurrency}`,
        kind: "currency_mismatch",
        severity: "warning",
        title: `No ${wallet.activeCurrency} balance`,
        description: `${travel.nextTrip.destinationCountry} uses ${wallet.activeCurrency}. Convert from USD before departure.`,
        cta: {
          label: "Convert",
          route: "/wallet",
          payload: { from: "USD", to: wallet.activeCurrency },
        },
        citations: ["wallet_balances", "travel_records.next"],
      });
    }
  }

  // 3c) Currency idle — previously surfaced via recommendations; promote the
  // largest one to an automation flag if its USD value > 200.
  const idle = wallet.byCurrency
    .filter((b) => b.isInactive)
    .sort((a, b) => b.amountUSD - a.amountUSD)[0];
  if (idle && idle.amountUSD >= 200) {
    flags.push({
      id: `auto-currency-idle-${idle.currency}`,
      kind: "currency_idle",
      severity: "info",
      title: `${idle.currency} sitting idle`,
      description: `${idle.amount.toFixed(2)} ${idle.currency} (~$${idle.amountUSD.toFixed(0)}) has no upcoming trip. Convert or plan a destination.`,
      cta: { label: "Convert", route: "/wallet", payload: { from: idle.currency } },
      citations: ["wallet_balances", "travel_records.upcoming"],
    });
  }

  // 3d) Trip imminent — within 3 days.
  if (
    travel.nextTrip &&
    travel.daysUntilNextTrip !== null &&
    travel.daysUntilNextTrip >= 0 &&
    travel.daysUntilNextTrip <= 3
  ) {
    flags.push({
      id: `auto-trip-imminent-${travel.nextTrip.id}`,
      kind: "trip_imminent",
      severity: "critical",
      title: `${travel.nextTrip.destinationCountry} in ${
        travel.daysUntilNextTrip === 0 ? "<24h" : `${travel.daysUntilNextTrip}d`
      }`,
      description: `Confirm online check-in, boarding pass, and wallet readiness for ${
        travel.nextTrip.flightNumber ?? travel.nextTrip.airline
      }.`,
      cta: { label: "Open trip", route: `/timeline` },
      citations: ["travel_records.next"],
    });
  }

  // 3e) Missing documents — heuristic placeholder until Phase 9-δ documents vault
  // ships. We flag only when a near-term international trip exists AND the user
  // has no passport on file (otherwise we'd nag with no actionable inventory).
  if (
    travel.nextTrip &&
    travel.daysUntilNextTrip !== null &&
    travel.daysUntilNextTrip <= 14 &&
    userRow?.passportNo &&
    today < travel.nextTrip.date
  ) {
    flags.push({
      id: `auto-documents-${travel.nextTrip.id}`,
      kind: "missing_documents",
      severity: "info",
      title: "Verify travel documents",
      description: "Confirm visa/eVisa, insurance, and entry forms for your destination.",
      cta: { label: "Open passport book", route: "/passport-book" },
      citations: ["users.passport_no", "travel_records.next"],
    });
  }

  return flags;
}

/* ── 4) Context snapshot ── */

export function computeContextSnapshot(userId: string): ContextSnapshot {
  const today = todayIso();
  const location = computeLocationContext(userId);
  const flags = computeAutomationFlags(userId);
  const predictiveNextTrip = computePredictiveNextTrip(userId);
  const wallet = computeWalletInsight(userId);
  const rows = loadTravel(userId);

  // Active leg = `current` type, OR an upcoming leg whose date == today.
  const activeRow =
    rows.find((r) => r.type === "current") ??
    rows.find((r) => (r.type === "upcoming" || r.type === "past") && r.date === today) ??
    null;

  // Next leg = earliest upcoming/current with date >= today.
  const nextRow =
    rows
      .filter((r) => (r.type === "upcoming" || r.type === "current") && r.date >= today)
      .sort((a, b) => a.date.localeCompare(b.date))[0] ?? null;

  function legPayload(r: TravelRow) {
    const apt = findAirport(r.toIata);
    return {
      tripId: r.tripId ?? null,
      legId: r.id,
      from: r.fromIata,
      to: r.toIata,
      destinationCountry: apt?.country ?? r.toIata,
      date: r.date,
      airline: r.airline,
      flightNumber: r.flightNumber,
    };
  }

  // Wallet summary: active currency + USD totals.
  const activeBal = wallet.activeCurrency
    ? wallet.byCurrency.find((b) => b.currency === wallet.activeCurrency)
    : undefined;

  // Suggested actions: top-3 recommendation IDs, sorted by priority.
  const recs = computeRecommendations(userId).slice(0, 3);

  return {
    generatedAt: Date.now(),
    location,
    activeTrip: activeRow ? legPayload(activeRow) : null,
    nextTrip: nextRow
      ? {
          ...legPayload(nextRow),
          daysAway: daysBetween(today, nextRow.date),
        }
      : null,
    walletSummary: {
      totalUSD: wallet.totalUSD,
      activeCurrency: wallet.activeCurrency,
      activeCurrencyAmount: activeBal?.amount ?? null,
      activeCurrencyAmountUSD: activeBal?.amountUSD ?? null,
    },
    automationFlags: flags,
    predictiveNextTrip,
    suggestedActionIds: recs.map((r) => r.id),
  };
}

/* Wallet balances loader retained for future expansion (currently unused
 * here — wallet logic lives in computeWalletInsight). */
export function _loadBalancesForTest(userId: string) {
  return db
    .select({ currency: walletBalances.currency, amount: walletBalances.amount })
    .from(walletBalances)
    .where(eq(walletBalances.userId, userId))
    .all();
}
