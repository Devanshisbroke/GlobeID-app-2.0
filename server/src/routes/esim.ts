/**
 * Slice-B Phase-11 — eSIM catalog.
 *
 *   GET /esim/plans                         full catalog
 *   GET /esim/plans?country=US              filtered to country (or GLOBAL)
 *
 * Activation lives separately (not in this slice — would require a partner
 * like Airalo to provision real ICCIDs).
 */
import { Hono } from "hono";
import { authMiddleware } from "../auth/token.js";
import { ok } from "../lib/validate.js";
import { esimCatalog } from "../../../shared/data/esimCatalog.js";

export const esimRouter = new Hono();
esimRouter.use("*", authMiddleware);

esimRouter.get("/plans", (c) => {
  const country = c.req.query("country")?.toUpperCase();
  const filtered = country
    ? esimCatalog.filter((p) => p.countryIso2 === country || p.countryIso2 === "GLOBAL")
    : esimCatalog;
  return ok(c, { plans: filtered, total: filtered.length });
});
