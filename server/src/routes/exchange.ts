/**
 * Slice-B Phase-11 — currency exchange (real, keyless).
 *
 * Backed by exchangerate.host (free, no key). The server proxies, caches
 * (15 min TTL), and returns rates in the GlobeID rate envelope.
 *
 * https://exchangerate.host
 */
import { Hono } from "hono";
import { authMiddleware } from "../auth/token.js";
import { ok, err } from "../lib/validate.js";
import { cacheGet, cacheSet } from "../lib/cache.js";

export const exchangeRouter = new Hono();
exchangeRouter.use("*", authMiddleware);

interface UpstreamRates {
  base: string;
  date: string;
  rates: Record<string, number>;
}

const UPSTREAM = "https://api.exchangerate.host/latest";

async function fetchRates(base: string): Promise<UpstreamRates> {
  const cached = cacheGet<UpstreamRates>(`fx:${base}`);
  if (cached) return cached;
  const url = `${UPSTREAM}?base=${encodeURIComponent(base)}`;
  const res = await fetch(url, { headers: { "user-agent": "globe-id-app/1.0 (+slice-b)" } });
  if (!res.ok) throw new Error(`upstream ${res.status} ${res.statusText}`);
  const json = (await res.json()) as { base: string; date: string; rates: Record<string, number> };
  if (!json.rates || typeof json.rates !== "object") throw new Error("upstream returned no rates");
  const value: UpstreamRates = { base: json.base, date: json.date, rates: json.rates };
  cacheSet(`fx:${base}`, value, 15 * 60 * 1000);
  return value;
}

exchangeRouter.get("/rates", async (c) => {
  const base = (c.req.query("base") ?? "USD").toUpperCase();
  if (!/^[A-Z]{3}$/.test(base)) {
    return err(c, "invalid_base", "Provide a 3-letter currency code", 400);
  }
  try {
    const data = await fetchRates(base);
    return ok(c, {
      base: data.base,
      asOf: data.date,
      rates: data.rates,
      source: "exchangerate.host",
    });
  } catch (e) {
    return err(c, "upstream_error", `FX provider unreachable: ${e instanceof Error ? e.message : String(e)}`, 500);
  }
});

exchangeRouter.get("/quote", async (c) => {
  const from = (c.req.query("from") ?? "").toUpperCase();
  const to = (c.req.query("to") ?? "").toUpperCase();
  const amount = Number(c.req.query("amount") ?? 0);
  if (!/^[A-Z]{3}$/.test(from) || !/^[A-Z]{3}$/.test(to)) {
    return err(c, "invalid_currency", "Both from and to must be 3-letter codes", 400);
  }
  if (!(amount > 0)) return err(c, "invalid_amount", "amount must be positive", 400);

  try {
    const data = await fetchRates(from);
    const rate = data.rates[to];
    if (typeof rate !== "number") {
      return err(c, "unsupported_currency", `${to} not in upstream rates`, 404);
    }
    const converted = amount * rate;
    return ok(c, {
      from,
      to,
      amount,
      rate,
      converted: Math.round(converted * 100) / 100,
      asOf: data.date,
      source: "exchangerate.host",
    });
  } catch (e) {
    return err(c, "upstream_error", `FX provider unreachable: ${e instanceof Error ? e.message : String(e)}`, 500);
  }
});
