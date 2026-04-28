/**
 * Slice-B Phase-11 — visa system endpoints.
 *
 * Read-only against `shared/data/visaCatalog.ts` (curated). Apply state is
 * an honest demo: we surface the policy + checklist; without real partner
 * APIs (VFS Global, BLS, CKGS) we don't pretend to submit applications.
 */
import { Hono } from "hono";
import { authMiddleware } from "../auth/token.js";
import { ok, err } from "../lib/validate.js";
import { findVisaPolicy, visaCatalog } from "../../../shared/data/visaCatalog.js";

export const visaRouter = new Hono();
visaRouter.use("*", authMiddleware);

visaRouter.get("/policies", (c) => {
  const citizenship = c.req.query("citizenship")?.toUpperCase();
  const filtered = citizenship
    ? visaCatalog.filter((p) => p.citizenshipIso2 === citizenship)
    : visaCatalog;
  return ok(c, { policies: filtered, total: filtered.length });
});

visaRouter.get("/policy", (c) => {
  const citizenship = (c.req.query("citizenship") ?? "").toUpperCase();
  const destination = (c.req.query("destination") ?? "").toUpperCase();
  if (!/^[A-Z]{2}$/.test(citizenship) || !/^[A-Z]{2}$/.test(destination)) {
    return err(c, "invalid_iso2", "citizenship and destination must be ISO-2 codes", 400);
  }
  const p = findVisaPolicy(citizenship, destination);
  if (!p) return err(c, "no_policy", `No catalog entry for ${citizenship}→${destination}`, 404);
  return ok(c, p);
});
