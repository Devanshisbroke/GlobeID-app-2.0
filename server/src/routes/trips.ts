import { Hono } from "hono";
import { and, eq, inArray } from "drizzle-orm";
import { z } from "zod";
import { db } from "../db/client.js";
import { travelRecords } from "../db/schema.js";
import { authMiddleware, getUserId } from "../auth/token.js";
import { ok, err, parseBody } from "../lib/validate.js";
import { cacheInvalidate } from "../lib/cache.js";
import { travelRecordSchema, type TravelRecord } from "../../../shared/types/travel.js";

/** Invalidate downstream derivation caches whenever travel_records change.
 *  Phase 9-β contextSnapshot + lifecycle entries are pure derivations of
 *  these rows, so a stale cache would lie about the user's current state. */
function invalidateDerived(userId: string): void {
  cacheInvalidate(`insights:travel:${userId}`);
  cacheInvalidate(`insights:wallet:${userId}`);
  cacheInvalidate(`insights:activity:${userId}`);
  cacheInvalidate(`recommendations:${userId}`);
  cacheInvalidate(`context:current:${userId}`);
  cacheInvalidate(`lifecycle:trips:${userId}`);
}

export const tripsRouter = new Hono();

tripsRouter.use("*", authMiddleware);

function rowToRecord(r: typeof travelRecords.$inferSelect): TravelRecord {
  return {
    id: r.id,
    from: r.fromIata,
    to: r.toIata,
    date: r.date,
    airline: r.airline,
    duration: r.duration,
    type: r.type,
    flightNumber: r.flightNumber ?? undefined,
    source: r.source,
  };
}

tripsRouter.get("/", (c) => {
  const userId = getUserId(c);
  const rows = db.select().from(travelRecords).where(eq(travelRecords.userId, userId)).all();
  return ok(c, rows.map(rowToRecord));
});

const createBody = z.object({
  records: z.array(travelRecordSchema).min(1),
});

tripsRouter.post("/", async (c) => {
  const userId = getUserId(c);
  const parsed = await parseBody(c, createBody);
  if (parsed instanceof Response) return parsed;

  const incomingIds = parsed.records.map((r) => r.id);
  const existing = db
    .select({ id: travelRecords.id })
    .from(travelRecords)
    .where(and(eq(travelRecords.userId, userId), inArray(travelRecords.id, incomingIds)))
    .all();
  const existingSet = new Set(existing.map((r) => r.id));

  const fresh = parsed.records.filter((r) => !existingSet.has(r.id));
  const now = Date.now();

  if (fresh.length > 0) {
    db.insert(travelRecords).values(
      fresh.map((r) => ({
        id: r.id,
        userId,
        fromIata: r.from,
        toIata: r.to,
        date: r.date,
        airline: r.airline,
        duration: r.duration,
        type: r.type,
        flightNumber: r.flightNumber ?? null,
        source: r.source,
        tripId: r.id.startsWith("tr-planner-") ? r.id.split("-").slice(2, -1).join("-") : null,
        createdAt: now,
      }))
    ).run();
  }

  if (fresh.length > 0) invalidateDerived(userId);

  return ok(c, { added: fresh.length, skipped: parsed.records.length - fresh.length, records: fresh }, 201);
});

tripsRouter.delete("/:id", (c) => {
  const userId = getUserId(c);
  const id = c.req.param("id");
  const result = db
    .delete(travelRecords)
    .where(and(eq(travelRecords.userId, userId), eq(travelRecords.id, id)))
    .run();
  if (result.changes === 0) return err(c, "not_found", "Travel record not found", 404);
  invalidateDerived(userId);
  return ok(c, { id, deleted: true });
});
