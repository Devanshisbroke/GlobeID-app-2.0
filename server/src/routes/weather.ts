/**
 * Slice-B Phase-15 — weather endpoint (Open-Meteo proxy).
 *
 *   GET /weather/forecast?iata=LHR&days=7
 *
 * Cached server-side (15 min TTL) keyed by (iata, days). Returns a real
 * forecast in the location's local timezone — never a placeholder.
 */
import { Hono } from "hono";
import { authMiddleware } from "../auth/token.js";
import { ok, err } from "../lib/validate.js";
import { findAirport } from "../lib/geo.js";
import { fetchOpenMeteo, parseOpenMeteo } from "../lib/weather.js";
import { cacheGet, cacheSet } from "../lib/cache.js";
import type { WeatherForecast } from "../../../shared/types/weather.js";

export const weatherRouter = new Hono();
weatherRouter.use("*", authMiddleware);

weatherRouter.get("/forecast", async (c) => {
  const iata = (c.req.query("iata") ?? "").toUpperCase();
  const days = Math.max(1, Math.min(16, Number(c.req.query("days") ?? 7)));
  if (!/^[A-Z]{3}$/.test(iata)) {
    return err(c, "invalid_iata", "Provide a 3-letter IATA code", 400);
  }
  const airport = findAirport(iata);
  if (!airport) {
    return err(c, "unknown_airport", `Airport ${iata} not in catalog`, 404);
  }

  const cacheKey = `weather:${iata}:${days}`;
  const cached = cacheGet<WeatherForecast>(cacheKey);
  if (cached) return ok(c, cached);

  try {
    const upstream = await fetchOpenMeteo(airport.lat, airport.lng, days);
    const forecast = parseOpenMeteo(upstream, {
      iata: airport.iata,
      city: airport.city,
      country: airport.country,
    });
    cacheSet(cacheKey, forecast, 15 * 60 * 1000);
    return ok(c, forecast);
  } catch (e) {
    return err(
      c,
      "upstream_error",
      `Weather provider unreachable: ${e instanceof Error ? e.message : String(e)}`,
      500,
    );
  }
});
