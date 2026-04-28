/**
 * Phase 9-β — Context engine route.
 *
 * GET /context/current → ContextSnapshot
 *
 * Cached briefly (5s) so screen-mount bursts collapse, but short enough that
 * fresh state is visible on the next interaction.
 */
import { Hono } from "hono";
import { authMiddleware, getUserId } from "../auth/token.js";
import { ok } from "../lib/validate.js";
import { cacheGet, cacheSet } from "../lib/cache.js";
import { computeContextSnapshot } from "../lib/intelligence.js";

export const contextRouter = new Hono();
contextRouter.use("*", authMiddleware);

contextRouter.get("/current", (c) => {
  const userId = getUserId(c);
  const key = `context:current:${userId}`;
  const cached = cacheGet<unknown>(key);
  if (cached) return ok(c, cached);
  const snapshot = computeContextSnapshot(userId);
  cacheSet(key, snapshot);
  return ok(c, snapshot);
});
