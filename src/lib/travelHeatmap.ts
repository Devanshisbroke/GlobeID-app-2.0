/**
 * Travel heatmap — deterministic density map (BACKLOG G 86).
 *
 * Bins per-trip arrival airports into a coarse grid keyed by
 * (latBucket, lngBucket) so a globe layer can render a heat dot at
 * each cell with size proportional to visit count.
 *
 * Pure function — no IO, no random. Same input → same output.
 *
 * Choice of bucket size:
 *   - 5° × 5° (= 72 × 36 cells globally) is coarse enough to merge
 *     "Bay Area" into one cell yet fine enough to distinguish, e.g.,
 *     Tokyo from Osaka. Caller may override.
 */

export interface HeatPoint {
  /** Bucket centroid latitude. */
  lat: number;
  /** Bucket centroid longitude. */
  lng: number;
  /** Number of visits in this bucket. */
  count: number;
}

export interface HeatPointWithIntensity extends HeatPoint {
  /** 0..1 normalised intensity (count / max). */
  intensity: number;
}

interface Coord {
  lat: number;
  lng: number;
}

interface Options {
  /** Bucket size in degrees. Default 5. */
  bucketDeg?: number;
}

/**
 * Build a heatmap from a list of (lat,lng) coordinates.
 *
 *   buildTravelHeatmap([{lat:35.66,lng:139.65}, ...])
 *     → [{ lat: 32.5, lng: 137.5, count: 1, intensity: 1 }, ...]
 */
export function buildTravelHeatmap(
  coords: Coord[],
  opts: Options = {},
): HeatPointWithIntensity[] {
  const bucket = opts.bucketDeg ?? 5;
  const map = new Map<string, HeatPoint>();
  for (const c of coords) {
    const latBucket = Math.floor(c.lat / bucket) * bucket + bucket / 2;
    const lngBucket = Math.floor(c.lng / bucket) * bucket + bucket / 2;
    const key = `${latBucket}|${lngBucket}`;
    const cur = map.get(key);
    if (cur) {
      cur.count += 1;
    } else {
      map.set(key, { lat: latBucket, lng: lngBucket, count: 1 });
    }
  }
  const max = Math.max(1, ...Array.from(map.values()).map((p) => p.count));
  return Array.from(map.values()).map((p) => ({
    ...p,
    intensity: p.count / max,
  }));
}
