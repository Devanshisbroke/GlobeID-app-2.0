import type { LoyaltyTier } from "../../../shared/types/loyalty.js";

/**
 * Slice-B — loyalty earn rates + tier thresholds.
 *
 * Earn rate is tied to the kind of activity. Multipliers are deliberately
 * boring — this is a real, auditable system, not a marketing engine.
 *
 *  - wallet_payment:    1 pt per 100 units of source currency (rounded down)
 *  - trip_completion:   500 pts flat
 *  - signup_bonus:      1000 pts (one-time, idempotent on key)
 *  - redemption:        client-supplied negative `points`
 *  - adjustment:        admin-only, client-supplied delta
 */

export function pointsForWalletPayment(amount: number): number {
  if (amount <= 0) return 0;
  return Math.floor(amount / 100);
}

export const POINTS_PER_TRIP_COMPLETION = 500;
export const POINTS_FOR_SIGNUP = 1000;

const TIER_THRESHOLDS: Array<{ tier: LoyaltyTier; min: number }> = [
  { tier: "bronze", min: 0 },
  { tier: "silver", min: 2_000 },
  { tier: "gold", min: 10_000 },
  { tier: "platinum", min: 50_000 },
];

export function tierFor(totalPoints: number): { tier: LoyaltyTier; pointsToNextTier: number | null } {
  let current: LoyaltyTier = "bronze";
  let next: { tier: LoyaltyTier; min: number } | null = null;
  for (const t of TIER_THRESHOLDS) {
    if (totalPoints >= t.min) current = t.tier;
    else {
      next = t;
      break;
    }
  }
  return {
    tier: current,
    pointsToNextTier: next ? Math.max(0, next.min - totalPoints) : null,
  };
}
