/**
 * Globe camera presets (BACKLOG G 88).
 *
 * Pure helpers that compute target lat/lng/zoom for the three named
 * camera presets:
 *   - "home"        : centred over the user's home airport (or origin)
 *   - "next-trip"   : centred between origin and the next trip's
 *                     destination, with zoom that fits both endpoints
 *   - "flight-tracker" : tightly framed on the leg in progress
 *
 * Returns a `CameraTarget` so the calling Three/R3F scene can lerp into
 * it. No Three imports here — keeps this module unit-testable in node.
 */

export interface Coord {
  lat: number;
  lng: number;
}

export interface CameraTarget {
  /** Camera lookAt latitude (deg). */
  lat: number;
  /** Camera lookAt longitude (deg). */
  lng: number;
  /** 1 = closest, 5 = farthest. Used by the renderer to derive distance. */
  zoom: number;
  /** Convenience copy for UI ("Home view", "Next trip", etc.). */
  label: string;
}

const DEFAULT_HOME: Coord = { lat: 37.7749, lng: -122.4194 }; // SFO

/**
 * Centre camera on the user's home airport (or default).
 */
export function homeView(home: Coord | null = null): CameraTarget {
  const c = home ?? DEFAULT_HOME;
  return {
    lat: c.lat,
    lng: c.lng,
    zoom: 3,
    label: "Home view",
  };
}

/**
 * Camera target for the next upcoming trip — centred on the great-circle
 * midpoint between origin & destination so both endpoints are visible.
 */
export function nextTripView(
  origin: Coord,
  destination: Coord,
): CameraTarget {
  const mid = greatCircleMidpoint(origin, destination);
  // The wider the leg, the farther the camera pulls back.
  const sep = haversineKm(origin, destination);
  const zoom = sep < 800 ? 2 : sep < 4000 ? 3 : sep < 9000 ? 4 : 5;
  return {
    lat: mid.lat,
    lng: mid.lng,
    zoom,
    label: "Next trip",
  };
}

/**
 * Tracker view — tightly frames the active leg with the camera leaning
 * over the current position (assumed to be `current`).
 */
export function flightTrackerView(current: Coord): CameraTarget {
  return {
    lat: current.lat,
    lng: current.lng,
    zoom: 1.5,
    label: "Flight tracker",
  };
}

/* ---------- maths ---------- */

const toRad = (d: number) => (d * Math.PI) / 180;
const toDeg = (r: number) => (r * 180) / Math.PI;

export function haversineKm(a: Coord, b: Coord): number {
  const R = 6371;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const x =
    Math.sin(dLat / 2) ** 2 +
    Math.sin(dLng / 2) ** 2 * Math.cos(lat1) * Math.cos(lat2);
  return 2 * R * Math.asin(Math.sqrt(x));
}

export function greatCircleMidpoint(a: Coord, b: Coord): Coord {
  const dLng = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const lng1 = toRad(a.lng);
  const Bx = Math.cos(lat2) * Math.cos(dLng);
  const By = Math.cos(lat2) * Math.sin(dLng);
  const lat = Math.atan2(
    Math.sin(lat1) + Math.sin(lat2),
    Math.sqrt((Math.cos(lat1) + Bx) ** 2 + By ** 2),
  );
  const lng = lng1 + Math.atan2(By, Math.cos(lat1) + Bx);
  return { lat: toDeg(lat), lng: ((toDeg(lng) + 540) % 360) - 180 };
}
