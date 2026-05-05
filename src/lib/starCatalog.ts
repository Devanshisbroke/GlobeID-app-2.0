/**
 * Star catalog helpers (BACKLOG G 84).
 *
 * Real bright-star data for the globe scene's star background. We don't
 * ship the full Yale BSC (~9,000 entries) yet — that's a separate asset
 * lane. This module provides:
 *
 *   - A tiny seed catalog of 30 navigation-grade stars (the ones used
 *     by aviators / sextant nav, all magnitude ≤ 2.0). Real RA/Dec from
 *     SIMBAD epoch J2000.
 *   - `equatorialToCartesian` to convert (RA hours, Dec deg) into the
 *     unit-sphere Cartesian a Three.js Points geometry can consume.
 *   - `magnitudeToSize` to turn apparent magnitude into a sensible
 *     point-size (brighter = bigger) so the rendered field looks right.
 *
 * The fuller catalog can be added by dropping a JSON of the BSC into
 * `src/assets/stars/bsc.json` and importing here — same shape.
 */

export interface Star {
  /** Henry Draper or BSC catalogue number. */
  id: string;
  name: string;
  /** Right ascension in hours (0..24). */
  ra: number;
  /** Declination in degrees (-90..90). */
  dec: number;
  /** Apparent V-band magnitude. Lower = brighter. */
  mag: number;
}

export const NAV_STARS: readonly Star[] = [
  { id: "alpCMa", name: "Sirius", ra: 6.7525, dec: -16.7161, mag: -1.46 },
  { id: "alpCar", name: "Canopus", ra: 6.3992, dec: -52.6957, mag: -0.74 },
  { id: "alpCenAB", name: "Rigil Kentaurus", ra: 14.6599, dec: -60.8354, mag: -0.27 },
  { id: "alpBoo", name: "Arcturus", ra: 14.2611, dec: 19.1825, mag: -0.05 },
  { id: "alpLyr", name: "Vega", ra: 18.6156, dec: 38.7837, mag: 0.03 },
  { id: "alpAur", name: "Capella", ra: 5.2782, dec: 45.998, mag: 0.08 },
  { id: "betOri", name: "Rigel", ra: 5.2423, dec: -8.2017, mag: 0.13 },
  { id: "alpCMi", name: "Procyon", ra: 7.6551, dec: 5.225, mag: 0.34 },
  { id: "alpEri", name: "Achernar", ra: 1.6286, dec: -57.2367, mag: 0.46 },
  { id: "alpOri", name: "Betelgeuse", ra: 5.9195, dec: 7.4071, mag: 0.5 },
  { id: "betCen", name: "Hadar", ra: 14.0637, dec: -60.373, mag: 0.61 },
  { id: "alpAql", name: "Altair", ra: 19.8463, dec: 8.8683, mag: 0.77 },
  { id: "alpCru", name: "Acrux", ra: 12.4433, dec: -63.099, mag: 0.81 },
  { id: "alpTau", name: "Aldebaran", ra: 4.5987, dec: 16.5093, mag: 0.85 },
  { id: "alpVir", name: "Spica", ra: 13.4199, dec: -11.1614, mag: 1.04 },
  { id: "alpSco", name: "Antares", ra: 16.4901, dec: -26.4319, mag: 1.09 },
  { id: "betGem", name: "Pollux", ra: 7.7553, dec: 28.0262, mag: 1.14 },
  { id: "alpPsA", name: "Fomalhaut", ra: 22.9608, dec: -29.6222, mag: 1.16 },
  { id: "alpCyg", name: "Deneb", ra: 20.6905, dec: 45.2803, mag: 1.25 },
  { id: "betCru", name: "Mimosa", ra: 12.7953, dec: -59.6886, mag: 1.25 },
  { id: "alpLeo", name: "Regulus", ra: 10.1395, dec: 11.9672, mag: 1.36 },
  { id: "alpGem", name: "Castor", ra: 7.5764, dec: 31.8883, mag: 1.58 },
  { id: "gamCru", name: "Gacrux", ra: 12.5194, dec: -57.1133, mag: 1.63 },
  { id: "lamSco", name: "Shaula", ra: 17.5602, dec: -37.1037, mag: 1.62 },
  { id: "betCar", name: "Miaplacidus", ra: 9.2199, dec: -69.7172, mag: 1.69 },
  { id: "alpPav", name: "Peacock", ra: 20.4275, dec: -56.7351, mag: 1.94 },
  { id: "alpHya", name: "Alphard", ra: 9.4597, dec: -8.6587, mag: 1.99 },
  { id: "polaris", name: "Polaris", ra: 2.5302, dec: 89.2641, mag: 1.98 },
  { id: "alpPer", name: "Mirfak", ra: 3.4054, dec: 49.8612, mag: 1.79 },
  { id: "alpUMa", name: "Dubhe", ra: 11.0623, dec: 61.7511, mag: 1.81 },
];

export interface CartesianStar extends Star {
  x: number;
  y: number;
  z: number;
  /** 0..1 normalised brightness, where 1 = brightest in this catalog. */
  brightness: number;
}

/**
 * Convert (RA hours, Dec deg) → unit-sphere Cartesian (right-handed,
 * Y-up). RA = 0 is +X; +Y points to north celestial pole.
 *
 * Useful when projecting stars onto a far sphere in the globe scene.
 */
export function equatorialToCartesian(
  raHours: number,
  decDeg: number,
  radius = 1,
): { x: number; y: number; z: number } {
  const raRad = (raHours / 24) * 2 * Math.PI;
  const decRad = (decDeg * Math.PI) / 180;
  const cosDec = Math.cos(decRad);
  return {
    x: radius * cosDec * Math.cos(raRad),
    y: radius * Math.sin(decRad),
    z: radius * cosDec * Math.sin(raRad),
  };
}

/**
 * Magnitude → point-size map. Astronomical magnitudes are *inverted*
 * (smaller = brighter) and roughly logarithmic, so we squash to 0.4..2.5.
 */
export function magnitudeToSize(mag: number): number {
  // m=-1.5 → ~2.5, m=2 → ~0.5, clamped.
  const v = 2 - mag * 0.5;
  return Math.max(0.4, Math.min(2.5, v));
}

/**
 * Project the seed catalog onto a sphere of `radius` and attach a
 * normalised brightness. Suitable for `<Points />` in Three.js.
 */
export function projectStars(radius: number): CartesianStar[] {
  const minMag = Math.min(...NAV_STARS.map((s) => s.mag));
  const maxMag = Math.max(...NAV_STARS.map((s) => s.mag));
  const span = maxMag - minMag || 1;
  return NAV_STARS.map((s) => {
    const c = equatorialToCartesian(s.ra, s.dec, radius);
    // Brighter stars (lower mag) → higher brightness fraction.
    const brightness = 1 - (s.mag - minMag) / span;
    return { ...s, ...c, brightness };
  });
}
