/** Derivation engine — pure functions over loaded DB rows.
 *  Read-only by design. No network, no external APIs. */

import { eq } from "drizzle-orm";
import { db } from "../db/client.js";
import { travelRecords, walletBalances, alerts as alertsTable, walletState } from "../db/schema.js";
import {
  findAirport,
  continentOf,
  currencyOf,
  haversineKm,
} from "../../../shared/data/airports.js";
import type {
  TravelInsight,
  WalletInsight,
  ActivityInsight,
  Recommendation,
} from "../../../shared/types/insights.js";

interface TravelRow {
  id: string;
  fromIata: string;
  toIata: string;
  date: string;
  airline: string;
  type: "upcoming" | "past" | "current";
  flightNumber: string | null;
  source: "history" | "planner";
}

interface BalanceRow {
  currency: string;
  amount: number;
  rate: number;
  flag: string;
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
      source: travelRecords.source,
    })
    .from(travelRecords)
    .where(eq(travelRecords.userId, userId))
    .all();
}

function loadBalances(userId: string): BalanceRow[] {
  return db
    .select({
      currency: walletBalances.currency,
      amount: walletBalances.amount,
      rate: walletBalances.rate,
      flag: walletBalances.flag,
    })
    .from(walletBalances)
    .where(eq(walletBalances.userId, userId))
    .all();
}

function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
}

function daysBetween(fromIso: string, toIso: string): number {
  // Days between two YYYY-MM-DD strings; +N if `toIso` is after `fromIso`.
  const a = Date.UTC(
    Number(fromIso.slice(0, 4)),
    Number(fromIso.slice(5, 7)) - 1,
    Number(fromIso.slice(8, 10))
  );
  const b = Date.UTC(
    Number(toIso.slice(0, 4)),
    Number(toIso.slice(5, 7)) - 1,
    Number(toIso.slice(8, 10))
  );
  return Math.round((b - a) / 86_400_000);
}

/* ── Travel insights ── */

export function computeTravelInsight(userId: string): TravelInsight {
  const rows = loadTravel(userId);
  const today = todayIso();

  const visited = new Set<string>();
  const upcoming = new Set<string>();
  const continentMap = new Map<string, Set<string>>();
  let totalDistanceKm = 0;
  let longestKm = 0;
  let longestRoute: string | null = null;
  let tripsThisYear = 0;
  const yearNow = today.slice(0, 4);
  const regionCount = new Map<string, number>();

  for (const r of rows) {
    const from = findAirport(r.fromIata);
    const to = findAirport(r.toIata);
    if (!from || !to) continue;
    const km = haversineKm(from, to);
    totalDistanceKm += km;
    if (km > longestKm) {
      longestKm = km;
      longestRoute = `${r.fromIata} → ${r.toIata}`;
    }
    const cont = continentOf(to.country);
    regionCount.set(cont, (regionCount.get(cont) ?? 0) + 1);
    if (!continentMap.has(cont)) continentMap.set(cont, new Set());
    continentMap.get(cont)!.add(to.country);

    if (r.type === "past") {
      visited.add(from.country);
      visited.add(to.country);
    }
    if (r.type === "upcoming" || r.type === "current") {
      upcoming.add(to.country);
    }
    if (r.date.slice(0, 4) === yearNow) tripsThisYear += 1;
  }

  const upcomingSorted = rows
    .filter((r) => (r.type === "upcoming" || r.type === "current") && r.date >= today)
    .sort((a, b) => a.date.localeCompare(b.date));
  const next = upcomingSorted[0];
  const nextAirportTo = next ? findAirport(next.toIata) : null;

  const allContinents = ["Asia", "Europe", "North America", "South America", "Oceania", "Africa"];
  const byContinent = allContinents.map((name) => {
    const set = continentMap.get(name);
    return {
      name,
      countries: set ? Array.from(set) : [],
      count: set?.size ?? 0,
    };
  });

  let mostVisitedRegion: string | null = null;
  let mostVisitedCount = 0;
  for (const [region, n] of regionCount.entries()) {
    if (n > mostVisitedCount) {
      mostVisitedCount = n;
      mostVisitedRegion = region;
    }
  }

  return {
    totalCountries: visited.size,
    totalFlights: rows.length,
    totalDistanceKm: Math.round(totalDistanceKm),
    longestFlightKm: Math.round(longestKm),
    longestRoute,
    byContinent,
    visitedCountries: Array.from(visited).sort(),
    upcomingCountries: Array.from(upcoming).sort(),
    nextTrip: next && nextAirportTo
      ? {
          id: next.id,
          from: next.fromIata,
          to: next.toIata,
          destinationCountry: nextAirportTo.country,
          date: next.date,
          airline: next.airline,
          flightNumber: next.flightNumber ?? undefined,
        }
      : null,
    daysUntilNextTrip: next ? daysBetween(today, next.date) : null,
    tripsThisYear,
    mostVisitedRegion,
  };
}

/* ── Wallet insights ── */

export function computeWalletInsight(userId: string): WalletInsight {
  const balances = loadBalances(userId);
  const travel = loadTravel(userId);
  const today = todayIso();

  // Active currencies = currencies of the next ≤30 day upcoming destinations.
  const activeCurrencies = new Set<string>();
  let primaryActive: string | null = null;
  const nextRows = travel
    .filter((r) => (r.type === "upcoming" || r.type === "current") && r.date >= today)
    .sort((a, b) => a.date.localeCompare(b.date));
  for (const r of nextRows) {
    const apt = findAirport(r.toIata);
    if (!apt) continue;
    const cur = currencyOf(apt.country);
    if (cur) {
      activeCurrencies.add(cur);
      if (!primaryActive) primaryActive = cur;
    }
  }
  // Always treat the user's home/default currency as "not inactive".
  const stateRow = db
    .select({ defaultCurrency: walletState.defaultCurrency })
    .from(walletState)
    .where(eq(walletState.userId, userId))
    .get();
  const defaultCur = stateRow?.defaultCurrency ?? "USD";

  let totalUSD = 0;
  let dominantCurrency: string | null = null;
  let dominantUsd = 0;
  const inactive: string[] = [];

  const byCurrency = balances.map((b) => {
    const usd = b.amount * b.rate;
    totalUSD += usd;
    if (usd > dominantUsd) {
      dominantUsd = usd;
      dominantCurrency = b.currency;
    }
    const isActive = activeCurrencies.has(b.currency);
    const isInactive =
      !isActive &&
      b.currency !== defaultCur &&
      b.amount > 0 &&
      usd >= 50;
    if (isInactive) inactive.push(b.currency);
    return {
      currency: b.currency,
      amount: b.amount,
      amountUSD: Math.round(usd * 100) / 100,
      flag: b.flag,
      isInactive,
      isActive,
      reason: isActive
        ? "Active for upcoming trip"
        : isInactive
        ? "No upcoming trip uses this currency"
        : undefined,
    };
  });

  return {
    totalUSD: Math.round(totalUSD * 100) / 100,
    balanceCount: balances.length,
    byCurrency,
    dominantCurrency,
    inactiveCurrencies: inactive,
    activeCurrency: primaryActive,
  };
}

/* ── Activity insights ── */

export function computeActivityInsight(userId: string): ActivityInsight {
  const travel = loadTravel(userId);
  const today = todayIso();
  const nowMonth = today.slice(0, 7);

  let tripsThisMonth = 0;
  let tripsLast30Days = 0;
  let upcomingNext7Days = 0;
  let upcomingNext30Days = 0;

  for (const r of travel) {
    const delta = daysBetween(today, r.date);
    if (r.date.slice(0, 7) === nowMonth) tripsThisMonth += 1;
    if (r.type === "past" && delta >= -30 && delta <= 0) tripsLast30Days += 1;
    if ((r.type === "upcoming" || r.type === "current") && delta >= 0) {
      if (delta <= 7) upcomingNext7Days += 1;
      if (delta <= 30) upcomingNext30Days += 1;
    }
  }

  const allUserAlerts = db
    .select({ readAt: alertsTable.readAt, dismissed: alertsTable.dismissed })
    .from(alertsTable)
    .where(eq(alertsTable.userId, userId))
    .all();
  const unread = allUserAlerts.filter(
    (r) => !r.dismissed && r.readAt === null
  ).length;

  // Travel readiness: 100 if next-trip wallet active currency is in balances
  // and at least one upcoming exists; degrades by missing pieces.
  const wallet = computeWalletInsight(userId);
  let readiness = 0;
  const next = travel
    .filter((r) => (r.type === "upcoming" || r.type === "current") && r.date >= today)
    .sort((a, b) => a.date.localeCompare(b.date))[0];
  if (next) {
    readiness += 40; // has an upcoming trip
    const apt = findAirport(next.toIata);
    const cur = apt ? currencyOf(apt.country) : null;
    if (cur && wallet.byCurrency.some((b) => b.currency === cur && b.amount > 0)) {
      readiness += 30; // currency available
    }
    if (daysBetween(today, next.date) >= 1) readiness += 15; // not departing today / past
    if (wallet.totalUSD > 100) readiness += 15; // some funds
  }

  return {
    tripsThisMonth,
    tripsLast30Days,
    upcomingNext7Days,
    upcomingNext30Days,
    alertsUnread: unread,
    travelReadinessScore: Math.min(100, readiness),
  };
}

/* ── Recommendations engine ── */

const NEIGHBOR_HINTS: Record<string, string[]> = {
  Singapore: ["Malaysia", "Thailand", "Indonesia"],
  Japan: ["South Korea", "China", "Thailand"],
  India: ["Thailand", "UAE", "Singapore"],
  France: ["United Kingdom", "Germany", "Spain"],
  "United Kingdom": ["France", "Netherlands", "Germany"],
  UAE: ["Qatar", "India", "Egypt"],
  "United States": ["Canada", "Mexico"],
  Thailand: ["Malaysia", "Singapore", "Japan"],
  Australia: ["New Zealand", "Singapore"],
  Brazil: ["Colombia", "Peru"],
};

const COUNTRY_TO_HUB: Record<string, string> = {
  Japan: "NRT",
  "South Korea": "ICN",
  China: "PVG",
  Thailand: "BKK",
  Singapore: "SIN",
  Malaysia: "KUL",
  Indonesia: "SIN",
  India: "DEL",
  UAE: "DXB",
  Qatar: "DOH",
  France: "CDG",
  Germany: "FRA",
  Spain: "MAD",
  "United Kingdom": "LHR",
  Netherlands: "AMS",
  Switzerland: "ZRH",
  Turkey: "IST",
  "United States": "JFK",
  Canada: "YYZ",
  Mexico: "CUN",
  Australia: "SYD",
  "New Zealand": "AKL",
  Brazil: "GRU",
  Colombia: "BOG",
  Peru: "LIM",
  "South Africa": "JNB",
  Egypt: "CAI",
  Kenya: "NBO",
};

export function computeRecommendations(userId: string): Recommendation[] {
  const travel = computeTravelInsight(userId);
  const wallet = computeWalletInsight(userId);
  const items: Recommendation[] = [];

  // 1) Trip continuation — based on most recent past leg.
  const lastPastDest = (() => {
    const rows = loadTravel(userId)
      .filter((r) => r.type === "past")
      .sort((a, b) => b.date.localeCompare(a.date));
    return rows[0] ? findAirport(rows[0].toIata) ?? null : null;
  })();
  if (lastPastDest) {
    const neighbours = (NEIGHBOR_HINTS[lastPastDest.country] ?? []).filter(
      (c) => !travel.visitedCountries.includes(c)
    );
    if (neighbours.length > 0) {
      items.push({
        id: `rec-cont-${lastPastDest.iata}`,
        kind: "trip_continuation",
        title: `Continue from ${lastPastDest.city}`,
        description: `You were last in ${lastPastDest.country}. ${neighbours[0]} pairs naturally as a follow-up.`,
        payload: {
          from: lastPastDest.iata,
          suggestions: neighbours.slice(0, 3).map((c) => COUNTRY_TO_HUB[c]).filter(Boolean),
        },
        citations: ["travel_records.past.most_recent"],
        priority: 80,
      });
    }
  }

  // 2) Currency action — surface inactive balances.
  if (wallet.inactiveCurrencies.length > 0) {
    const cur = wallet.inactiveCurrencies[0];
    const bal = wallet.byCurrency.find((b) => b.currency === cur);
    if (bal) {
      items.push({
        id: `rec-cur-inactive-${cur}`,
        kind: "currency_action",
        title: `${cur} balance idle`,
        description: `You have ${bal.amount.toFixed(2)} ${cur} (~$${bal.amountUSD.toFixed(0)}) with no trip planned. Convert or plan a destination using ${cur}.`,
        payload: { from: cur, to: wallet.activeCurrency ?? "USD" },
        citations: ["wallet_balances", "travel_records.upcoming"],
        priority: 60,
      });
    }
  }

  // 3) Currency action — top-up for upcoming trip.
  if (travel.nextTrip && wallet.activeCurrency) {
    const bal = wallet.byCurrency.find((b) => b.currency === wallet.activeCurrency);
    if (!bal || bal.amountUSD < 100) {
      items.push({
        id: `rec-cur-topup-${wallet.activeCurrency}`,
        kind: "currency_action",
        title: `Top up ${wallet.activeCurrency} for ${travel.nextTrip.destinationCountry}`,
        description: `Your ${travel.nextTrip.destinationCountry} trip is ${travel.daysUntilNextTrip} day${travel.daysUntilNextTrip === 1 ? "" : "s"} away. Convert to ${wallet.activeCurrency} now.`,
        payload: { from: "USD", to: wallet.activeCurrency },
        citations: ["travel_records.next", "wallet_balances"],
        priority: 90,
      });
    }
  }

  // 4) Next destination — visa-friendly suggestion using continent diversity.
  const visitedContinents = new Set(
    travel.byContinent.filter((c) => c.count > 0).map((c) => c.name)
  );
  const allContinents = ["Asia", "Europe", "North America", "South America", "Oceania", "Africa"];
  const unseen = allContinents.find((c) => !visitedContinents.has(c));
  if (unseen) {
    const continentToHub: Record<string, string> = {
      "South America": "GRU",
      Africa: "JNB",
      Oceania: "SYD",
      "North America": "JFK",
      Asia: "SIN",
      Europe: "LHR",
    };
    const hub = continentToHub[unseen];
    if (hub) {
      items.push({
        id: `rec-next-${unseen.toLowerCase().replace(/\s+/g, "-")}`,
        kind: "next_destination",
        title: `Add ${unseen} to your map`,
        description: `You have not visited ${unseen} yet. Starting from ${hub} unlocks the region.`,
        payload: { suggestions: [hub] },
        citations: ["travel_records.byContinent"],
        priority: 50,
      });
    }
  }

  // 5) Readiness if score < 100 and there is a next trip.
  if (travel.nextTrip && travel.daysUntilNextTrip !== null && travel.daysUntilNextTrip <= 30) {
    items.push({
      id: `rec-ready-${travel.nextTrip.id}`,
      kind: "readiness",
      title: `Ready for ${travel.nextTrip.destinationCountry}?`,
      description: `${travel.daysUntilNextTrip === 0 ? "Today" : `In ${travel.daysUntilNextTrip} day${travel.daysUntilNextTrip === 1 ? "" : "s"}`} — confirm passport, currency, and bookings.`,
      payload: { tripId: travel.nextTrip.id },
      citations: ["travel_records.next"],
      priority: 70,
    });
  }

  return items.sort((a, b) => b.priority - a.priority);
}

/* ── System alert derivation ── */
/** Build a list of system alerts from current state. The signature is the
 *  dedup key — re-deriving on hydrate is idempotent. */

export interface DerivedAlert {
  signature: string;
  category: "wallet" | "flight" | "advisory" | "system";
  title: string;
  message: string;
  severity: "low" | "medium" | "high";
}

export function deriveSystemAlerts(userId: string): DerivedAlert[] {
  const travel = computeTravelInsight(userId);
  const wallet = computeWalletInsight(userId);
  const out: DerivedAlert[] = [];

  // 1) Upcoming trip — currency check.
  if (travel.nextTrip && wallet.activeCurrency && travel.daysUntilNextTrip !== null) {
    const sig = `sys-trip-currency:${travel.nextTrip.to}:${travel.nextTrip.date}`;
    const bal = wallet.byCurrency.find((b) => b.currency === wallet.activeCurrency);
    const usd = bal?.amountUSD ?? 0;
    out.push({
      signature: sig,
      category: "flight",
      title: `Trip to ${travel.nextTrip.destinationCountry} in ${travel.daysUntilNextTrip} day${travel.daysUntilNextTrip === 1 ? "" : "s"}`,
      message:
        usd >= 100
          ? `${wallet.activeCurrency} ready (~$${usd.toFixed(0)}). Confirm boarding pass for ${travel.nextTrip.flightNumber ?? travel.nextTrip.airline}.`
          : `Top up ${wallet.activeCurrency} — current balance is ~$${usd.toFixed(0)}.`,
      severity: travel.daysUntilNextTrip <= 3 ? "high" : "medium",
    });
  }

  // 2) Inactive currency — only one alert, picks the largest.
  if (wallet.inactiveCurrencies.length > 0) {
    const top = wallet.byCurrency
      .filter((b) => wallet.inactiveCurrencies.includes(b.currency))
      .sort((a, b) => b.amountUSD - a.amountUSD)[0];
    if (top) {
      out.push({
        signature: `sys-wallet-inactive:${top.currency}`,
        category: "wallet",
        title: `${top.currency} balance unused`,
        message: `${top.amount.toFixed(2)} ${top.currency} (~$${top.amountUSD.toFixed(0)}) sits idle with no upcoming trip. Convert or plan one.`,
        severity: "low",
      });
    }
  }

  return out;
}
