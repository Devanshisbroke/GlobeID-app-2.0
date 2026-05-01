/**
 * Live countdown formatter shared between TripDetail and any other
 * surface that wants "T-3d 2h 14m" pre-departure copy.
 *
 * Input is the target date (YYYY-MM-DD or full ISO). Output is broken
 * down into components so the caller can render the parts however the
 * surface wants. Pure function — no React, no time mocks; pass `now` in
 * for tests.
 */

export interface Countdown {
  /** Total milliseconds remaining (negative if `target` already passed). */
  totalMs: number;
  /** True when the target is in the past. */
  past: boolean;
  /** Days component (0-9999), always positive (sign on `past`). */
  days: number;
  /** Hours component (0-23), always positive. */
  hours: number;
  /** Minutes component (0-59), always positive. */
  minutes: number;
  /** Seconds component (0-59), always positive. */
  seconds: number;
}

const DAY_MS = 86_400_000;
const HOUR_MS = 3_600_000;
const MINUTE_MS = 60_000;

/**
 * Coerce `YYYY-MM-DD` to a Date at 00:00 UTC. Full ISO strings are
 * passed through to `new Date()` directly. Throws RangeError if the
 * input can't be parsed.
 */
function toDate(input: string | Date): Date {
  if (input instanceof Date) return input;
  if (/^\d{4}-\d{2}-\d{2}$/.test(input)) {
    return new Date(`${input}T00:00:00Z`);
  }
  const d = new Date(input);
  if (Number.isNaN(d.getTime())) throw new RangeError(`Invalid date: ${input}`);
  return d;
}

/**
 * Compute the countdown from `now` to `target`. Both inputs accept ISO
 * strings (`YYYY-MM-DD` or full ISO 8601) or `Date` instances.
 */
export function countdownTo(target: string | Date, now: string | Date = new Date()): Countdown {
  const t = toDate(target).getTime();
  const n = toDate(now).getTime();
  const totalMs = t - n;
  const abs = Math.abs(totalMs);
  const days = Math.floor(abs / DAY_MS);
  const hours = Math.floor((abs % DAY_MS) / HOUR_MS);
  const minutes = Math.floor((abs % HOUR_MS) / MINUTE_MS);
  const seconds = Math.floor((abs % MINUTE_MS) / 1000);
  return {
    totalMs,
    past: totalMs < 0,
    days,
    hours,
    minutes,
    seconds,
  };
}

/**
 * Compact "T-3d 02h 14m" / "T+12m 03s" style text. `precision` controls
 * the smallest unit shown; defaults to "minute" since the wallet pass
 * surfaces don't need second-by-second updates pre-trip.
 */
export function formatCountdown(
  cd: Countdown,
  precision: "minute" | "second" = "minute",
): string {
  const sign = cd.past ? "T+" : "T-";
  if (cd.days > 0) {
    return `${sign}${cd.days}d ${pad(cd.hours)}h ${pad(cd.minutes)}m`;
  }
  if (cd.hours > 0) {
    return `${sign}${cd.hours}h ${pad(cd.minutes)}m`;
  }
  if (precision === "second") {
    return `${sign}${cd.minutes}m ${pad(cd.seconds)}s`;
  }
  return `${sign}${cd.minutes}m`;
}

function pad(n: number): string {
  return n < 10 ? `0${n}` : String(n);
}
