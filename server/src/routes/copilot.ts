/**
 * Phase 8 — Copilot Evolution route (closes deferred Phase 4.5 PR-B).
 *
 * - POST /copilot/respond
 *     body: { prompt: string }
 *     persists the user prompt + assistant reply into `copilot_messages`,
 *     and returns a grounded response. Trip-itinerary intents are surfaced
 *     as an `action` envelope so the client runs its existing tripGenerator
 *     (avoids porting the whole airport + distance engine server-side).
 *     Data-query intents (next trip, currency holdings, country count, etc.)
 *     are answered with values pulled directly from the DB.
 *
 * - GET /copilot/history
 *     returns the last N messages for the authenticated user, oldest first.
 *
 * - DELETE /copilot/history
 *     clears the user's history (used for the "clear chat" UI).
 *
 * Sync safety: queries-only flow, NOT subject to pendingMutations.
 * If the client falls back to the local generator on network failure, the
 * server simply has no record of that turn — which is correct, since the
 * server is meant to be authoritative ONLY for what reached it.
 */
import { Hono } from "hono";
import { and, desc, eq, gte } from "drizzle-orm";
import { z } from "zod";
import { db } from "../db/client.js";
import { copilotMessages, travelRecords, walletBalances, walletState } from "../db/schema.js";
import { authMiddleware, getUserId } from "../auth/token.js";
import { ok, parseBody } from "../lib/validate.js";
import { findAirport } from "../../../shared/data/airports.js";

export const copilotRouter = new Hono();
copilotRouter.use("*", authMiddleware);

const HISTORY_LIMIT = 50;

interface CopilotAction {
  type: "generate_trip" | "open_planner" | "navigate" | "open_converter";
  payload: Record<string, unknown>;
}

interface CopilotReplyEnvelope {
  id: string;
  message: string;
  action?: CopilotAction;
  citations: string[];
}

/** Lightweight intent classifier — pure regex, no model. */
type Intent =
  | "next_trip"
  | "trip_count"
  | "country_count"
  | "currency_holdings"
  | "active_country"
  | "generate_trip"
  | "greeting"
  | "unknown";

function classify(prompt: string): Intent {
  const p = prompt.toLowerCase().trim();
  if (/\b(hi|hey|hello|yo)\b/.test(p) && p.length < 20) return "greeting";
  if (/\b(next|upcoming).{0,15}(trip|flight|travel|destination)\b/.test(p)) return "next_trip";
  if (/\b(trip|flight)s?\b/.test(p) && /\b(how many|total|count|taken|been on)\b/.test(p))
    return "trip_count";
  if (/\b(countr|continen)/.test(p) && /\b(how many|total|count|visited|been to)\b/.test(p))
    return "country_count";
  if (/\b(my )?(currenc(y|ies)|wallet|holding|balance)s?\b/.test(p)) return "currency_holdings";
  if (/\b(where am i|active country|current(ly)? in)\b/.test(p)) return "active_country";
  if (
    /\b(plan|build|design|create).{0,15}(trip|tour|itinerary|adventure|vacation|holiday)\b/.test(p) ||
    /\b\d+\s*(day|week|night).{0,30}(trip|tour|itinerary)\b/.test(p) ||
    /\b(round the world|world tour|backpack|capitals tour)\b/.test(p)
  )
    return "generate_trip";
  return "unknown";
}

function fmtDays(n: number): string {
  if (n === 0) return "today";
  if (n === 1) return "tomorrow";
  return `in ${n} days`;
}

function nextTripReply(userId: string): { message: string; citations: string[] } {
  const today = new Date().toISOString().slice(0, 10);
  const rows = db
    .select()
    .from(travelRecords)
    .where(and(eq(travelRecords.userId, userId), gte(travelRecords.date, today)))
    .all();
  const upcoming = rows
    .filter((r) => r.type === "upcoming" || r.type === "current")
    .sort((a, b) => a.date.localeCompare(b.date));

  const nx = upcoming[0];
  if (!nx) {
    return {
      message: "You have no upcoming trips on file. Want me to plan one? Try: 'Plan a 10 day Asia trip'.",
      citations: ["travel_records:none"],
    };
  }
  const fromAp = findAirport(nx.fromIata);
  const toAp = findAirport(nx.toIata);
  const days = Math.max(0, Math.round((Date.parse(nx.date) - Date.parse(today)) / 86_400_000));
  const route = `${fromAp?.city ?? nx.fromIata} → ${toAp?.city ?? nx.toIata}`;
  return {
    message: `Your next trip is **${route}** on ${nx.date} (${fmtDays(days)}) — ${nx.airline} ${nx.flightNumber ?? ""}.`.trim(),
    citations: [`travel_records:${nx.id}`],
  };
}

function tripCountReply(userId: string): { message: string; citations: string[] } {
  const rows = db
    .select({ id: travelRecords.id, type: travelRecords.type })
    .from(travelRecords)
    .where(eq(travelRecords.userId, userId))
    .all();
  const past = rows.filter((r) => r.type === "past").length;
  const upcoming = rows.filter((r) => r.type === "upcoming" || r.type === "current").length;
  return {
    message: `You have **${past}** past flights and **${upcoming}** upcoming. ${rows.length} total on file.`,
    citations: [`travel_records:count(${rows.length})`],
  };
}

function countryCountReply(userId: string): { message: string; citations: string[] } {
  const rows = db
    .select({ from: travelRecords.fromIata, to: travelRecords.toIata, type: travelRecords.type })
    .from(travelRecords)
    .where(eq(travelRecords.userId, userId))
    .all();
  const past = rows.filter((r) => r.type === "past");
  const countries = new Set<string>();
  for (const r of past) {
    const f = findAirport(r.from);
    const t = findAirport(r.to);
    if (f) countries.add(f.country);
    if (t) countries.add(t.country);
  }
  return {
    message: `You've visited **${countries.size}** countr${countries.size === 1 ? "y" : "ies"} across ${past.length} past flight${past.length === 1 ? "" : "s"}.`,
    citations: [`travel_records:past(${past.length})`],
  };
}

function currencyHoldingsReply(userId: string): { message: string; citations: string[] } {
  const rows = db.select().from(walletBalances).where(eq(walletBalances.userId, userId)).all();
  const sorted = [...rows].sort((a, b) => b.amount * b.rate - a.amount * a.rate);
  if (sorted.length === 0) {
    return { message: "No wallet balances on file.", citations: ["wallet_balances:none"] };
  }
  const top = sorted.slice(0, 3).map((r) => `${r.flag} ${r.currency} ${r.amount.toLocaleString()}`).join(" · ");
  return {
    message: `Top holdings: ${top}. Total currencies: ${sorted.length}.`,
    citations: [`wallet_balances:count(${sorted.length})`],
  };
}

function activeCountryReply(userId: string): { message: string; citations: string[] } {
  const row = db.select().from(walletState).where(eq(walletState.userId, userId)).get();
  if (!row?.activeCountry) {
    return {
      message: "I don't have your active country on file yet — drop a wallet pin to set it.",
      citations: ["wallet_state:none"],
    };
  }
  return {
    message: `You're currently in **${row.activeCountry}** (default currency ${row.defaultCurrency}).`,
    citations: [`wallet_state:${row.activeCountry}`],
  };
}

function buildReply(
  userId: string,
  prompt: string,
): CopilotReplyEnvelope {
  const intent = classify(prompt);
  const id = crypto.randomUUID();

  switch (intent) {
    case "greeting":
      return {
        id,
        message: "Hey! I can plan trips, recap your travel, or look up wallet holdings. Try: 'What's my next trip?' or 'Plan a 10 day Asia trip'.",
        citations: [],
      };
    case "next_trip": {
      const r = nextTripReply(userId);
      return { id, ...r };
    }
    case "trip_count": {
      const r = tripCountReply(userId);
      return { id, ...r };
    }
    case "country_count": {
      const r = countryCountReply(userId);
      return { id, ...r };
    }
    case "currency_holdings": {
      const r = currencyHoldingsReply(userId);
      return { id, ...r };
    }
    case "active_country": {
      const r = activeCountryReply(userId);
      return { id, ...r };
    }
    case "generate_trip":
      return {
        id,
        message: "On it — generating your itinerary now.",
        action: { type: "generate_trip", payload: { prompt } },
        citations: [],
      };
    case "unknown":
    default:
      return {
        id,
        message: "I'm not sure I caught that. Try asking about your next trip, country count, currency holdings, or say 'Plan a 10 day Asia trip'.",
        citations: [],
      };
  }
}

const respondBody = z.object({ prompt: z.string().min(1).max(500) });

copilotRouter.post("/respond", async (c) => {
  const userId = getUserId(c);
  const parsed = await parseBody(c, respondBody);
  if (parsed instanceof Response) return parsed;

  const now = Date.now();
  const userMsgId = crypto.randomUUID();
  const reply = buildReply(userId, parsed.prompt);

  // Persist both turns atomically.
  db.insert(copilotMessages)
    .values([
      { id: userMsgId, userId, role: "user", content: parsed.prompt, createdAt: now },
      { id: reply.id, userId, role: "assistant", content: reply.message, createdAt: now + 1 },
    ])
    .run();

  return ok(c, {
    userMessageId: userMsgId,
    reply,
  });
});

copilotRouter.get("/history", (c) => {
  const userId = getUserId(c);
  const rows = db
    .select()
    .from(copilotMessages)
    .where(eq(copilotMessages.userId, userId))
    .orderBy(desc(copilotMessages.createdAt))
    .limit(HISTORY_LIMIT)
    .all();
  // Return oldest-first for a natural chat-history view.
  return ok(
    c,
    rows
      .slice()
      .reverse()
      .map((r) => ({
        id: r.id,
        role: r.role,
        content: r.content,
        createdAt: r.createdAt,
      })),
  );
});

copilotRouter.delete("/history", (c) => {
  const userId = getUserId(c);
  const result = db.delete(copilotMessages).where(eq(copilotMessages.userId, userId)).run();
  return ok(c, { deleted: result.changes });
});

