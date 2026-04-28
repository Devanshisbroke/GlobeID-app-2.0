/**
 * Slice-B Phase-11 — local services (region-aware).
 *
 *   GET /local/services?country=SG&kind=hospital
 */
import { Hono } from "hono";
import { authMiddleware } from "../auth/token.js";
import { ok } from "../lib/validate.js";
import { localServicesCatalog, type ServiceKind } from "../../../shared/data/localServicesCatalog.js";

const ALL_KINDS: ServiceKind[] = [
  "embassy",
  "hospital",
  "pharmacy",
  "laundry",
  "sim_store",
  "atm",
  "police",
  "tourism_info",
  "lost_property",
];

export const localRouter = new Hono();
localRouter.use("*", authMiddleware);

localRouter.get("/services", (c) => {
  const country = c.req.query("country")?.toUpperCase();
  const kind = c.req.query("kind") as ServiceKind | undefined;
  const results = localServicesCatalog.filter((s) => {
    if (country && s.countryIso2 !== country) return false;
    if (kind && s.kind !== kind) return false;
    return true;
  });
  return ok(c, { total: results.length, kinds: ALL_KINDS, results });
});
