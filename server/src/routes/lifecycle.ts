/**
 * Phase 9-β — Lifecycle + flight status routes.
 *
 * GET /lifecycle/trips         → TripLifecycle[]
 * GET /lifecycle/flights/:id   → FlightStatus (demo-mode, isDemoData=true)
 *
 * Both are pure read endpoints. The lifecycle list is derived on every call;
 * the cache TTL is short (5s) so save/delete in /planner/trips reflects on
 * the next mount.
 */
import { Hono } from "hono";
import { authMiddleware, getUserId } from "../auth/token.js";
import { ok, err } from "../lib/validate.js";
import { cacheGet, cacheSet } from "../lib/cache.js";
import { computeTripLifecycles } from "../lib/lifecycle.js";
import { getFlightStatus } from "../lib/flightStatus.js";

export const lifecycleRouter = new Hono();
lifecycleRouter.use("*", authMiddleware);

lifecycleRouter.get("/trips", (c) => {
  const userId = getUserId(c);
  const key = `lifecycle:trips:${userId}`;
  const cached = cacheGet<unknown>(key);
  if (cached) return ok(c, cached);
  const data = computeTripLifecycles(userId);
  cacheSet(key, data);
  return ok(c, data);
});

lifecycleRouter.get("/flights/:id", (c) => {
  const userId = getUserId(c);
  const id = c.req.param("id");
  const status = getFlightStatus({ legId: id, userId });
  if (!status) return err(c, "not_found", "Flight leg not found", 404);
  return ok(c, status);
});
