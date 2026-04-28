import { airports, type Airport } from "../../../shared/data/airports.js";

/**
 * Slice-B — geo helpers for travel scoring + weather lookups.
 *
 * `airports` is a curated list (~80 entries). Anything not in it falls
 * back to the IATA code itself for `country` / `city` so the score still
 * counts the leg, but the geo-derived metrics (km, continent) skip it.
 */

const airportByIata = new Map<string, Airport>(airports.map((a) => [a.iata, a]));

export function findAirport(iata: string): Airport | undefined {
  return airportByIata.get(iata.toUpperCase());
}

/** Great-circle distance via the haversine formula. */
export function greatCircleKm(a: Airport, b: Airport): number {
  const R = 6371; // mean Earth radius in km
  const toRad = (deg: number): number => (deg * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLon = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const h =
    Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(h)));
}

/** Two-letter continent code from latitude/longitude. Approximate but
 *  deterministic — all that the score needs is "did this leg cross a
 *  continent boundary?". Bounding-box discrimination is sufficient. */
export function continentFor(lat: number, lng: number): "AF" | "AN" | "AS" | "EU" | "NA" | "OC" | "SA" {
  if (lat < -60) return "AN";
  if (lng >= -170 && lng <= -30 && lat >= 7) return "NA";
  if (lng >= -85 && lng <= -30 && lat < 7 && lat >= -60) return "SA";
  if (lng >= -25 && lng <= 60 && lat >= 36) return "EU";
  if (lng >= -20 && lng <= 55 && lat < 36 && lat >= -40) return "AF";
  if (lng >= 110 || lng <= -160 || (lng >= 55 && lat < 0)) return "OC";
  return "AS";
}
