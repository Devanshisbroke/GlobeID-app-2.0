/**
 * Slice-B Phase-11 — travel insurance endpoints.
 *
 *   GET /insurance/plans                     full plan catalog
 *   GET /insurance/quote?days=&age=&dest=    deterministic premium per plan
 */
import { Hono } from "hono";
import { authMiddleware } from "../auth/token.js";
import { ok, err } from "../lib/validate.js";
import { insuranceCatalog, quotePremium, classifyRegion } from "../../../shared/data/insuranceCatalog.js";

export const insuranceRouter = new Hono();
insuranceRouter.use("*", authMiddleware);

insuranceRouter.get("/plans", (c) => ok(c, { plans: insuranceCatalog }));

insuranceRouter.get("/quote", (c) => {
  const days = Number(c.req.query("days") ?? 7);
  const age = Number(c.req.query("age") ?? 30);
  const destination = (c.req.query("destination") ?? "").toUpperCase();
  if (!(days > 0 && days < 366)) return err(c, "invalid_days", "days must be 1..365", 400);
  if (!(age >= 0 && age < 120)) return err(c, "invalid_age", "age must be 0..119", 400);
  if (!/^[A-Z]{2}$/.test(destination)) return err(c, "invalid_destination", "destination must be ISO-2", 400);

  const region = classifyRegion(destination);
  const quotes = insuranceCatalog.map((plan) => ({
    plan,
    quote: quotePremium(plan, days, age, destination),
  }));
  return ok(c, { region, quotes });
});
