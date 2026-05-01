/**
 * Shared expiry classifier for travel documents. Used by PassStack,
 * PassDetail, DocumentVault, and the document-vault scanner overlays
 * to drive consistent chip colours and copy.
 *
 * Severity is based on whole days between *now* and the document's
 * expiry date. Boundaries:
 *   - past expiry  → "critical"  ("Expired …")
 *   - ≤ 7 days     → "critical"  ("Expires in N days")
 *   - ≤ 30 days    → "warning"   ("Expires in N days")
 *   - else         → "none"      (nothing to surface)
 */

export type ExpirySeverity = "none" | "warning" | "critical";

export interface ExpiryInfo {
  /** Whole days until expiry. Negative if already expired. */
  daysUntil: number;
  severity: ExpirySeverity;
  /** Surface-friendly label, e.g. "Expires in 3 days". */
  label: string;
}

const DAY_MS = 86_400_000;

function startOfUtcDay(d: Date): number {
  return Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate());
}

/**
 * Compute days-until-expiry, severity bucket, and a human label.
 * Accepts ISO date strings (YYYY-MM-DD) or full ISO timestamps.
 * Returns severity="none" with `label=""` when the doc is well in the
 * future and the caller can choose not to render anything.
 */
export function describeExpiry(
  expiry: string | null | undefined,
  now: string | Date = new Date(),
): ExpiryInfo {
  if (!expiry) return { daysUntil: Infinity, severity: "none", label: "" };
  const target = new Date(/^\d{4}-\d{2}-\d{2}$/.test(expiry) ? `${expiry}T00:00:00Z` : expiry);
  if (Number.isNaN(target.getTime())) {
    return { daysUntil: Infinity, severity: "none", label: "" };
  }
  const nowDate = now instanceof Date ? now : new Date(now);
  const diffDays = Math.floor((startOfUtcDay(target) - startOfUtcDay(nowDate)) / DAY_MS);

  if (diffDays < 0) {
    const absDays = Math.abs(diffDays);
    return {
      daysUntil: diffDays,
      severity: "critical",
      label:
        absDays === 1
          ? "Expired yesterday"
          : absDays < 30
            ? `Expired ${absDays} days ago`
            : `Expired on ${expiry.slice(0, 10)}`,
    };
  }
  if (diffDays === 0) {
    return { daysUntil: 0, severity: "critical", label: "Expires today" };
  }
  if (diffDays <= 7) {
    return {
      daysUntil: diffDays,
      severity: "critical",
      label: `Expires in ${diffDays} day${diffDays === 1 ? "" : "s"}`,
    };
  }
  if (diffDays <= 30) {
    return {
      daysUntil: diffDays,
      severity: "warning",
      label: `Expires in ${diffDays} days`,
    };
  }
  return { daysUntil: diffDays, severity: "none", label: "" };
}
