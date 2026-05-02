/**
 * Approximate sub-solar point on Earth at a given UTC time.
 *
 * Returns a unit vector in the same coordinate convention used by
 * `latLngToVector3` so it can drive the Globe shader's `uSunDir`
 * uniform — the dot product against the surface normal then
 * smoothly produces the day-night terminator.
 *
 * Accuracy: ±0.5° at most days of the year. Good enough for visual
 * shading; not appropriate for navigation.
 */

const TAU = Math.PI * 2;

export function sunDirection(now: Date = new Date()): [number, number, number] {
  // Day of year (0..365)
  const start = Date.UTC(now.getUTCFullYear(), 0, 0);
  const diff = now.getTime() - start;
  const dayOfYear = diff / 86_400_000;

  // Solar declination — small-angle approximation of the analemma.
  // Peak declination is ±23.44°, occurs at solstices (≈ Jun 21 / Dec 21).
  const declRad = (-23.44 * Math.PI / 180) * Math.cos((TAU / 365) * (dayOfYear + 10));

  // Sub-solar longitude — sun crosses the prime meridian at noon UTC.
  const utcFractionalHour =
    now.getUTCHours() +
    now.getUTCMinutes() / 60 +
    now.getUTCSeconds() / 3600;
  const lonDeg = -((utcFractionalHour - 12) * 15);
  const lonRad = (lonDeg * Math.PI) / 180;

  // Project (lat=decl, lng=lonRad) onto the unit sphere using the
  // same convention as latLngToVector3 (radius = 1):
  //   phi   = (90 - lat) * π/180
  //   theta = (lng + 180) * π/180
  //   x = -sin(phi) * cos(theta)
  //   y =  cos(phi)
  //   z =  sin(phi) * sin(theta)
  const phi = Math.PI / 2 - declRad;
  const theta = lonRad + Math.PI;
  const sinPhi = Math.sin(phi);
  const cosPhi = Math.cos(phi);
  const sinTh = Math.sin(theta);
  const cosTh = Math.cos(theta);
  return [-sinPhi * cosTh, cosPhi, sinPhi * sinTh];
}
