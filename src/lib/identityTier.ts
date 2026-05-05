/**
 * Identity verification tier badges (BACKLOG E 68).
 *
 * Maps a numeric `identityScore` (0–100) into a 4-tier ladder used to
 * show the user how close they are to the next privilege level.
 *
 *   Tier 0 — Unverified  (0–29)   — limited UX (no kiosk verify, no
 *                                   high-risk wallet ops).
 *   Tier 1 — Basic       (30–59)  — passport scanned + biometric
 *                                   enrollment complete.
 *   Tier 2 — Trusted     (60–84)  — multi-document corroboration +
 *                                   recent activity.
 *   Tier 3 — Sovereign   (85–100) — fully cross-verified, eligible for
 *                                   premium kiosk fast lanes.
 *
 * Each tier exposes:
 *   - `label` (UI badge copy)
 *   - `tone`  (UI accent colour band)
 *   - `nextThreshold` (so caller can render "23 pts to Trusted")
 *   - `unlocks` (sentence describing what the tier grants)
 */

export type IdentityTierId = 0 | 1 | 2 | 3;

export interface IdentityTier {
  id: IdentityTierId;
  label: string;
  /** Inclusive lower bound, e.g. tier 1 starts at 30. */
  minScore: number;
  /** Score required to upgrade. `null` for top tier. */
  nextThreshold: number | null;
  /** UI accent. */
  tone: "muted" | "info" | "success" | "premium";
  /** What this tier unlocks, in human language. */
  unlocks: string;
}

const TIERS: IdentityTier[] = [
  {
    id: 0,
    label: "Tier 0 · Unverified",
    minScore: 0,
    nextThreshold: 30,
    tone: "muted",
    unlocks: "Limited wallet access. Scan a passport to unlock more.",
  },
  {
    id: 1,
    label: "Tier 1 · Basic",
    minScore: 30,
    nextThreshold: 60,
    tone: "info",
    unlocks: "Standard wallet & boarding pass usage.",
  },
  {
    id: 2,
    label: "Tier 2 · Trusted",
    minScore: 60,
    nextThreshold: 85,
    tone: "success",
    unlocks: "Kiosk fast-lane verify, multi-doc corroboration.",
  },
  {
    id: 3,
    label: "Tier 3 · Sovereign",
    minScore: 85,
    nextThreshold: null,
    tone: "premium",
    unlocks: "Premium fast lanes, off-airport verification.",
  },
];

export function tierForScore(score: number): IdentityTier {
  // Walk descending — return the first whose `minScore` is <= score.
  for (let i = TIERS.length - 1; i >= 0; i--) {
    const t = TIERS[i]!;
    if (score >= t.minScore) return t;
  }
  return TIERS[0]!;
}

export function progressToNextTier(score: number): {
  current: IdentityTier;
  next: IdentityTier | null;
  /** 0..1 progress toward the next tier's threshold. 0 if at top. */
  pct: number;
  remaining: number;
} {
  const current = tierForScore(score);
  if (current.nextThreshold === null) {
    return { current, next: null, pct: 1, remaining: 0 };
  }
  const next = TIERS.find((t) => t.id === ((current.id + 1) as IdentityTierId)) ?? null;
  const span = current.nextThreshold - current.minScore;
  const within = Math.max(0, score - current.minScore);
  const pct = Math.min(1, within / span);
  return {
    current,
    next,
    pct,
    remaining: Math.max(0, current.nextThreshold - score),
  };
}

/** Lookup all tiers — used for the upgrade-path drawer. */
export function allTiers(): readonly IdentityTier[] {
  return TIERS;
}
