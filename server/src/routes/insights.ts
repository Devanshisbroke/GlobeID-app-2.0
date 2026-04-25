import { Hono } from "hono";
import { authMiddleware, getUserId } from "../auth/token.js";
import { ok } from "../lib/validate.js";
import { cacheGet, cacheSet } from "../lib/cache.js";
import {
  computeTravelInsight,
  computeWalletInsight,
  computeActivityInsight,
} from "../lib/insights.js";

export const insightsRouter = new Hono();
insightsRouter.use("*", authMiddleware);

insightsRouter.get("/travel", (c) => {
  const userId = getUserId(c);
  const key = `insights:travel:${userId}`;
  const cached = cacheGet<unknown>(key);
  if (cached) return ok(c, cached);
  const data = computeTravelInsight(userId);
  cacheSet(key, data);
  return ok(c, data);
});

insightsRouter.get("/wallet", (c) => {
  const userId = getUserId(c);
  const key = `insights:wallet:${userId}`;
  const cached = cacheGet<unknown>(key);
  if (cached) return ok(c, cached);
  const data = computeWalletInsight(userId);
  cacheSet(key, data);
  return ok(c, data);
});

insightsRouter.get("/activity", (c) => {
  const userId = getUserId(c);
  const key = `insights:activity:${userId}`;
  const cached = cacheGet<unknown>(key);
  if (cached) return ok(c, cached);
  const data = computeActivityInsight(userId);
  cacheSet(key, data);
  return ok(c, data);
});
