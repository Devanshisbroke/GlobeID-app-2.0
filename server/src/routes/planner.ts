/**
 * Phase 8 — Planner persistence route (closes deferred Phase 4.5 PR-C).
 *
 * - GET    /planner/trips         → list saved planned trips for the user.
 * - POST   /planner/trips         → upsert a saved planned trip.
 *                                   destinations[] is stored JSON-encoded.
 * - DELETE /planner/trips/:id     → delete the trip metadata AND cascade-delete
 *                                   its derived legs from `travel_records`
 *                                   (anything with `trip_id = :id` OR id LIKE
 *                                   'tr-planner-:id-%' for legacy IDs).
 *
 * Authoritative source: `planned_trips` (already in DDL). Frontend mirrors the
 * payload into `tripPlannerStore.savedTrips` after a successful round-trip.
 */
import { Hono } from "hono";
import { and, eq, like, or } from "drizzle-orm";
import { z } from "zod";
import { db } from "../db/client.js";
import { plannedTrips, travelRecords } from "../db/schema.js";
import { authMiddleware, getUserId } from "../auth/token.js";
import { ok, err, parseBody } from "../lib/validate.js";

export const plannerRouter = new Hono();
plannerRouter.use("*", authMiddleware);

const themeEnum = z.enum(["vacation", "business", "backpacking", "world_tour"]);

const upsertBody = z.object({
  id: z.string().min(1),
  name: z.string().min(1).max(120),
  theme: themeEnum,
  destinations: z.array(z.string().length(3)).min(2).max(20),
  createdAt: z.string().optional(),
});

interface PlannedTripRow {
  id: string;
  name: string;
  theme: "vacation" | "business" | "backpacking" | "world_tour";
  destinations: string[];
  createdAt: string;
}

function rowToTrip(r: typeof plannedTrips.$inferSelect): PlannedTripRow {
  let destinations: string[] = [];
  try {
    const raw = JSON.parse(r.destinations) as unknown;
    if (Array.isArray(raw)) destinations = raw.filter((s): s is string => typeof s === "string");
  } catch {
    /* malformed row — return empty list rather than 500 the whole response */
  }
  return {
    id: r.id,
    name: r.name,
    theme: r.theme,
    destinations,
    createdAt: new Date(r.createdAt).toISOString(),
  };
}

plannerRouter.get("/", (c) => {
  const userId = getUserId(c);
  const rows = db.select().from(plannedTrips).where(eq(plannedTrips.userId, userId)).all();
  return ok(c, rows.map(rowToTrip));
});

plannerRouter.post("/", async (c) => {
  const userId = getUserId(c);
  const parsed = await parseBody(c, upsertBody);
  if (parsed instanceof Response) return parsed;

  const createdAt = parsed.createdAt ? Date.parse(parsed.createdAt) : Date.now();
  if (Number.isNaN(createdAt)) return err(c, "invalid_date", "createdAt must be ISO-8601", 400);

  const existing = db
    .select({ id: plannedTrips.id })
    .from(plannedTrips)
    .where(and(eq(plannedTrips.userId, userId), eq(plannedTrips.id, parsed.id)))
    .get();

  if (existing) {
    db.update(plannedTrips)
      .set({
        name: parsed.name,
        theme: parsed.theme,
        destinations: JSON.stringify(parsed.destinations),
      })
      .where(and(eq(plannedTrips.userId, userId), eq(plannedTrips.id, parsed.id)))
      .run();
  } else {
    db.insert(plannedTrips)
      .values({
        id: parsed.id,
        userId,
        name: parsed.name,
        theme: parsed.theme,
        destinations: JSON.stringify(parsed.destinations),
        createdAt,
      })
      .run();
  }

  return ok(
    c,
    {
      id: parsed.id,
      name: parsed.name,
      theme: parsed.theme,
      destinations: parsed.destinations,
      createdAt: new Date(createdAt).toISOString(),
    },
    existing ? 200 : 201,
  );
});

plannerRouter.delete("/:id", (c) => {
  const userId = getUserId(c);
  const id = c.req.param("id");

  const tripResult = db
    .delete(plannedTrips)
    .where(and(eq(plannedTrips.userId, userId), eq(plannedTrips.id, id)))
    .run();

  // Cascade legs from travel_records — match by tripId (Phase 8) OR legacy id
  // prefix `tr-planner-<id>-N` (kept for back-compat with prior planner saves).
  const legResult = db
    .delete(travelRecords)
    .where(
      and(
        eq(travelRecords.userId, userId),
        or(eq(travelRecords.tripId, id), like(travelRecords.id, `tr-planner-${id}-%`)),
      ),
    )
    .run();

  if (tripResult.changes === 0 && legResult.changes === 0) {
    return err(c, "not_found", "Planned trip not found", 404);
  }
  return ok(c, { id, tripDeleted: tripResult.changes > 0, legsDeleted: legResult.changes });
});
