import { Hono } from "hono";
import { authMiddleware, getUserId } from "../auth/token.js";
import { ok } from "../lib/validate.js";
import { cacheGet, cacheSet } from "../lib/cache.js";
import { computeRecommendations } from "../lib/insights.js";

export const recommendationsRouter = new Hono();
recommendationsRouter.use("*", authMiddleware);

recommendationsRouter.get("/", (c) => {
  const userId = getUserId(c);
  const key = `recommendations:${userId}`;
  const cached = cacheGet<unknown>(key);
  if (cached) return ok(c, cached);
  const items = computeRecommendations(userId);
  const payload = { generatedAt: Date.now(), items };
  cacheSet(key, payload);
  return ok(c, payload);
});
