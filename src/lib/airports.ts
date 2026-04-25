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

/** Create a curved arc between two points on a sphere */
export function createArcPoints(
  from: [number, number, number],
  to: [number, number, number],
  segments = 64,
  arcHeight = 0.3
): [number, number, number][] {
  const points: [number, number, number][] = [];
  for (let i = 0; i <= segments; i++) {
    const t = i / segments;
    // Lerp
    const x = from[0] + (to[0] - from[0]) * t;
    const y = from[1] + (to[1] - from[1]) * t;
    const z = from[2] + (to[2] - from[2]) * t;
    // Normalize to sphere surface
    const len = Math.sqrt(x * x + y * y + z * z);
    // Arc height peaks at midpoint
    const heightMultiplier = 1 + arcHeight * Math.sin(t * Math.PI);
    const nx = (x / len) * heightMultiplier;
    const ny = (y / len) * heightMultiplier;
    const nz = (z / len) * heightMultiplier;
    points.push([nx, ny, nz]);
  }
  return points;
}
