/**
 * Predictive leave-for-airport (BACKLOG I 110).
 *
 * Pure function. Given a departure timestamp + base commute minutes +
 * (optionally) a traffic factor + airport-buffer minutes, return the
 * fire time + a human-readable lead-time string.
 *
 * Traffic factor convention:
 *   1.0 = baseline (no change)
 *   0.8 = 20% faster than usual
 *   1.5 = 50% slower than usual (rush hour, weather, etc.)
 *
 * Caller passes `now` so the function stays deterministic in tests.
 */

export interface DeparturePrediction {
  /** ISO timestamp when the alarm should fire. */
  fireAtIso: string;
  /** Adjusted commute in minutes (may be 0 for failed predictions). */
  effectiveCommuteMinutes: number;
  /** Total lead time before departure (commute + buffer). */
  totalLeadMinutes: number;
  /** Pretty copy for the toast/notification body. */
  copy: string;
  /** True iff the alarm is in the past relative to `now`. */
  alreadyPast: boolean;
}

interface Args {
  departureIso: string;
  baseCommuteMinutes: number;
  airportBufferMinutes?: number;
  /** 1 = normal, >1 = slower than usual, <1 = faster. */
  trafficFactor?: number;
  now?: Date;
}

export function predictDeparture(args: Args): DeparturePrediction {
  const buffer = args.airportBufferMinutes ?? 90;
  const factor = clamp(args.trafficFactor ?? 1, 0.5, 3);
  const eff = Math.round(args.baseCommuteMinutes * factor);
  const total = eff + buffer;
  const dep = new Date(args.departureIso);
  const now = args.now ?? new Date();
  const fireAt = new Date(dep.getTime() - total * 60_000);
  const alreadyPast = fireAt.getTime() <= now.getTime();
  const factorCopy =
    factor > 1.1
      ? ` Traffic is ${Math.round((factor - 1) * 100)}% heavier than usual — head out a bit early.`
      : factor < 0.9
        ? ` Traffic is lighter than usual — small breathing room.`
        : "";
  return {
    fireAtIso: fireAt.toISOString(),
    effectiveCommuteMinutes: eff,
    totalLeadMinutes: total,
    copy:
      `Leave by ${formatHm(fireAt)}: ${eff} min commute + ${buffer} min at the airport.` +
      factorCopy,
    alreadyPast,
  };
}

function clamp(n: number, lo: number, hi: number): number {
  return Math.min(hi, Math.max(lo, n));
}

function formatHm(d: Date): string {
  const h = String(d.getHours()).padStart(2, "0");
  const m = String(d.getMinutes()).padStart(2, "0");
  return `${h}:${m}`;
}
