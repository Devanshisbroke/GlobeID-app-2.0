import { db } from "./client.js";
import { users, travelRecords, walletState, walletBalances, alerts } from "./schema.js";
import { sql } from "drizzle-orm";

export const DEMO_USER_ID = "usr-demo";

interface SeedRecord {
  id: string;
  from: string;
  to: string;
  date: string;
  airline: string;
  duration: string;
  type: "upcoming" | "past" | "current";
  flightNumber?: string;
}

/* Dates are relative to seed time so the demo always renders fresh
 * upcoming + recent-past mix instead of going stale. */
function dateAt(offsetDays: number): string {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() + offsetDays);
  return d.toISOString().slice(0, 10);
}

const SEED_TRAVEL: SeedRecord[] = [
  // Past trips — staggered over the last ~60 days
  { id: "tr-f2", from: "JFK", to: "LHR", date: dateAt(-58), airline: "British Airways",   duration: "7h 10m",  type: "past",     flightNumber: "BA 178" },
  { id: "tr-f3", from: "LHR", to: "CDG", date: dateAt(-55), airline: "Air France",        duration: "1h 20m",  type: "past",     flightNumber: "AF 1681" },
  { id: "tr-f4", from: "CDG", to: "DXB", date: dateAt(-50), airline: "Emirates",          duration: "6h 40m",  type: "past",     flightNumber: "EK 73" },
  { id: "tr-f5", from: "DXB", to: "DEL", date: dateAt(-46), airline: "Emirates",          duration: "3h 30m",  type: "past",     flightNumber: "EK 510" },
  { id: "tr-f6", from: "DEL", to: "BOM", date: dateAt(-40), airline: "Air India",         duration: "2h 10m",  type: "past",     flightNumber: "AI 865" },
  { id: "tr-f7", from: "BOM", to: "SFO", date: dateAt(-30), airline: "United Airlines",   duration: "17h 45m", type: "past",     flightNumber: "UA 23" },
  // Upcoming trips — next ~3 weeks
  { id: "tr-f1", from: "SFO", to: "SIN", date: dateAt(12),  airline: "Singapore Airlines", duration: "18h 15m", type: "upcoming", flightNumber: "SQ 31" },
  { id: "tr-f8", from: "SIN", to: "NRT", date: dateAt(20),  airline: "ANA",                duration: "6h 50m",  type: "upcoming", flightNumber: "NH 802" },
];

const SEED_WALLET: { currency: string; amount: number; rate: number; flag: string }[] = [
  { currency: "USD", amount: 2500.00, rate: 1.0000, flag: "🇺🇸" },
  { currency: "EUR", amount: 1200.00, rate: 1.0850, flag: "🇪🇺" },
  { currency: "INR", amount: 85000.00, rate: 0.0120, flag: "🇮🇳" },
  { currency: "AED", amount: 3200.00, rate: 0.2723, flag: "🇦🇪" },
  { currency: "JPY", amount: 45000.00, rate: 0.0067, flag: "🇯🇵" },
  { currency: "GBP", amount: 800.00, rate: 1.2700, flag: "🇬🇧" },
  { currency: "SGD", amount: 1500.00, rate: 0.7400, flag: "🇸🇬" },
];

const SEED_ALERTS: {
  id: string;
  category: string;
  title: string;
  message: string;
  severity: "low" | "medium" | "high";
}[] = [
  { id: "al-1", category: "visa",   title: "Japan Visa Policy Update", message: "Japan now offers e-visa for Indian nationals for short-term stays up to 30 days.", severity: "medium" },
  { id: "al-2", category: "flight", title: "SQ 31 — Boarding tomorrow", message: "Your SFO → SIN flight departs tomorrow 23:25. Online check-in opens in 6 hours.", severity: "high" },
  { id: "al-3", category: "wallet", title: "JPY rate alert",            message: "JPY/USD has dropped 1.8% in the last 24h. Good time to top up.",                  severity: "low" },
];

export function seedIfEmpty() {
  const existing = db.select({ count: sql<number>`count(*)` }).from(users).all();
  const count = existing[0]?.count ?? 0;
  if (count > 0) return { seeded: false };

  const now = Date.now();

  db.insert(users).values({
    id: DEMO_USER_ID,
    email: "devansh@globeid.io",
    fullName: "Devansh Barai",
    nationality: "India",
    passportNo: "P•••••48",
    dateOfBirth: "1998-07-12",
    createdAt: now,
  }).run();

  db.insert(walletState).values({
    userId: DEMO_USER_ID,
    activeCountry: null,
    defaultCurrency: "USD",
  }).run();

  for (const r of SEED_TRAVEL) {
    db.insert(travelRecords).values({
      id: r.id,
      userId: DEMO_USER_ID,
      fromIata: r.from,
      toIata: r.to,
      date: r.date,
      airline: r.airline,
      duration: r.duration,
      type: r.type,
      flightNumber: r.flightNumber ?? null,
      source: "history",
      tripId: null,
      createdAt: now,
    }).run();
  }

  for (const b of SEED_WALLET) {
    db.insert(walletBalances).values({
      userId: DEMO_USER_ID,
      currency: b.currency,
      amount: b.amount,
      rate: b.rate,
      flag: b.flag,
    }).run();
  }

  for (const a of SEED_ALERTS) {
    db.insert(alerts).values({
      id: a.id,
      userId: DEMO_USER_ID,
      category: a.category,
      title: a.title,
      message: a.message,
      severity: a.severity,
      source: "seed",
      signature: null,
      createdAt: now,
      readAt: null,
      dismissed: 0,
    }).run();
  }

  return { seeded: true };
}
