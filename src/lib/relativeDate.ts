/**
 * Relative date formatter — used by trip cards and notification rows.
 *
 * Returns short, mobile-first labels:
 *   - "Today", "Tomorrow", "Yesterday"
 *   - "In 3 days", "3 days ago"
 *   - "In 2 weeks"
 *   - For anything > 30 days returns the ISO-like short form so we
 *     don't accidentally show "In 254 days" on a card.
 *
 * Pure function. Pass `now` in for tests.
 */

const DAY_MS = 86_400_000;

function startOfUtcDay(d: Date): number {
  return Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate());
}

export function relativeDate(
  iso: string | null | undefined,
  now: string | Date = new Date(),
): string {
  if (!iso) return "";
  const target = new Date(/^\d{4}-\d{2}-\d{2}$/.test(iso) ? `${iso}T00:00:00Z` : iso);
  if (Number.isNaN(target.getTime())) return "";
  const nowDate = now instanceof Date ? now : new Date(now);
  const days = Math.floor(
    (startOfUtcDay(target) - startOfUtcDay(nowDate)) / DAY_MS,
  );

  if (days === 0) return "Today";
  if (days === 1) return "Tomorrow";
  if (days === -1) return "Yesterday";
  if (days > 1 && days <= 7) return `In ${days} days`;
  if (days < -1 && days >= -7) return `${Math.abs(days)} days ago`;
  if (days > 7 && days <= 30) {
    const weeks = Math.round(days / 7);
    return `In ${weeks} week${weeks === 1 ? "" : "s"}`;
  }
  if (days < -7 && days >= -30) {
    const weeks = Math.round(Math.abs(days) / 7);
    return `${weeks} week${weeks === 1 ? "" : "s"} ago`;
  }
  // Beyond ~30 days fall back to the original ISO so cards don't
  // mislead with implausible-sounding "In 213 days".
  return iso.slice(0, 10);
}
