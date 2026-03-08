import { latLngToVector3 } from "@/lib/airports";

const GLOBE_R = 1;

/**
 * Calculate a cinematic camera position that looks at a destination on the globe.
 * Returns { position, lookAt } vectors as [x,y,z] tuples.
 */
export function getCameraTarget(lat: number, lng: number, distance = 2.2): {
  position: [number, number, number];
  lookAt: [number, number, number];
} {
  const surfacePoint = latLngToVector3(lat, lng, GLOBE_R);

  // Camera sits at the surface normal direction, at `distance` from center
  const len = Math.sqrt(surfacePoint[0] ** 2 + surfacePoint[1] ** 2 + surfacePoint[2] ** 2);
  const nx = surfacePoint[0] / len;
  const ny = surfacePoint[1] / len;
  const nz = surfacePoint[2] / len;

  return {
    position: [nx * distance, ny * distance + 0.3, nz * distance],
    lookAt: [0, 0, 0],
  };
}

/**
 * Interpolate between two [x,y,z] positions with easing.
 */
export function lerpPosition(
  from: [number, number, number],
  to: [number, number, number],
  t: number
): [number, number, number] {
  // Smooth step easing
  const s = t * t * (3 - 2 * t);
  return [
    from[0] + (to[0] - from[0]) * s,
    from[1] + (to[1] - from[1]) * s,
    from[2] + (to[2] - from[2]) * s,
  ];
}
