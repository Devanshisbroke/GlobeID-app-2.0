/**
 * Slice-B Phase-15 — travel score endpoint.
 *
 * Pure derived; never persists. Reads `travel_records` for the user and
 * runs `buildTravelScore`.
 */
import { Hono } from "hono";
import { eq } from "drizzle-orm";
import { db } from "../db/client.js";
import { travelRecords } from "../db/schema.js";
import { authMiddleware, getUserId } from "../auth/token.js";
import { ok } from "../lib/validate.js";
import { buildTravelScore } from "../lib/score.js";
import type { TravelRecord } from "../../../shared/types/travel.js";

export const scoreRouter = new Hono();
scoreRouter.use("*", authMiddleware);

scoreRouter.get("/", (c) => {
  const userId = getUserId(c);
  const rows = db
    .select()
    .from(travelRecords)
    .where(eq(travelRecords.userId, userId))
    .all();
  const records: TravelRecord[] = rows.map((r) => ({
    id: r.id,
    from: r.fromIata,
    to: r.toIata,
    date: r.date,
    airline: r.airline,
    duration: r.duration,
    type: r.type,
    flightNumber: r.flightNumber ?? undefined,
    source: r.source,
  }));
  return ok(c, buildTravelScore(records));
});
