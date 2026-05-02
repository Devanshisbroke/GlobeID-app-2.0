/** Frontend airport directory + 3D rendering helpers.
 *  Static data is sourced from `shared/data/airports.ts` so the backend
 *  insights/recommendations engine can derive country/lat/lng off the
 *  same canonical list. */
import {
  airports as sharedAirports,
  findAirport,
  type Airport as SharedAirport,
} from "@shared/data/airports";

export type Airport = SharedAirport;
export const airports = sharedAirports;

/** Get airport by IATA code. */
export function getAirport(iata: string): Airport | undefined {
  return findAirport(iata);
}

/** Convert lat/lng to 3D sphere position */
export function latLngToVector3(lat: number, lng: number, radius: number): [number, number, number] {
  const phi = (90 - lat) * (Math.PI / 180);
  const theta = (lng + 180) * (Math.PI / 180);
  const x = -(radius * Math.sin(phi) * Math.cos(theta));
  const y = radius * Math.cos(phi);
  const z = radius * Math.sin(phi) * Math.sin(theta);
  return [x, y, z];
}

/* ── Arc point cache ─────────────────────────────────────────────
 * Arcs are deterministic given (from, to, segments, arcHeight). On the
 * GlobalMap screen multiple components (FlightArcs, history overlays,
 * preview tooltips) request the same arc, so we cache the result.
 *
 * Eviction: simple LRU bounded at 256 keys — matches the upper bound
 * of arcs we'd render on a heavy globe (~50 routes × dup factor).
 * Memory: ≈ 256 × 121 × 3 × 8 bytes ≈ 750 KB worst case. Acceptable.
 */
const ARC_CACHE = new Map<string, [number, number, number][]>();
const ARC_CACHE_LIMIT = 256;

function arcKey(
  from: [number, number, number],
  to: [number, number, number],
  segments: number,
  arcHeight: number,
): string {
  // 6-decimal precision is plenty for sphere surface points; rounding
  // here means caller-side jitter doesn't cause cache misses.
  const r = (n: number) => n.toFixed(6);
  return `${r(from[0])},${r(from[1])},${r(from[2])}|${r(to[0])},${r(to[1])},${r(to[2])}|${segments}|${arcHeight}`;
}

/** Create a curved arc between two points on a sphere. Memoised. */
export function createArcPoints(
  from: [number, number, number],
  to: [number, number, number],
  segments = 64,
  arcHeight = 0.3,
): [number, number, number][] {
  const key = arcKey(from, to, segments, arcHeight);
  const cached = ARC_CACHE.get(key);
  if (cached) {
    // LRU touch.
    ARC_CACHE.delete(key);
    ARC_CACHE.set(key, cached);
    return cached;
  }
  const points: [number, number, number][] = [];
  for (let i = 0; i <= segments; i++) {
    const t = i / segments;
    const x = from[0] + (to[0] - from[0]) * t;
    const y = from[1] + (to[1] - from[1]) * t;
    const z = from[2] + (to[2] - from[2]) * t;
    const len = Math.sqrt(x * x + y * y + z * z);
    const heightMultiplier = 1 + arcHeight * Math.sin(t * Math.PI);
    const nx = (x / len) * heightMultiplier;
    const ny = (y / len) * heightMultiplier;
    const nz = (z / len) * heightMultiplier;
    points.push([nx, ny, nz]);
  }
  if (ARC_CACHE.size >= ARC_CACHE_LIMIT) {
    const oldest = ARC_CACHE.keys().next().value;
    if (oldest !== undefined) ARC_CACHE.delete(oldest);
  }
  ARC_CACHE.set(key, points);
  return points;
}

/** Test-only: clear the arc cache. Re-exported via test helpers. */
export function _clearArcCache(): void {
  ARC_CACHE.clear();
}
