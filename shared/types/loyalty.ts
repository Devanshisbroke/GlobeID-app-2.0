import { z } from "zod";

/**
 * Slice-B — loyalty ledger types.
 *
 * Same idempotency model as the wallet ledger: `idempotencyKey` is unique
 * per (user, key) and retried POSTs return the original row with
 * `duplicate: true`. Earn rates live in the server (`server/src/lib/loyalty.ts`).
 */

export const loyaltyKindEnum = z.enum([
  "wallet_payment",
  "trip_completion",
  "signup_bonus",
  "redemption",
  "adjustment",
]);
export type LoyaltyKind = z.infer<typeof loyaltyKindEnum>;

export const loyaltyTxSchema = z.object({
  id: z.string().min(1),
  /** Positive for earns, negative for redemptions. */
  points: z.number().int().refine((n) => n !== 0, "points must be non-zero"),
  kind: loyaltyKindEnum,
  description: z.string().min(1).max(200),
  reference: z.string().max(200).optional(),
  createdAt: z.string(),
});
export type LoyaltyTx = z.infer<typeof loyaltyTxSchema>;

export const loyaltyTierEnum = z.enum(["bronze", "silver", "gold", "platinum"]);
export type LoyaltyTier = z.infer<typeof loyaltyTierEnum>;

export const loyaltySnapshotSchema = z.object({
  totalPoints: z.number().int().min(0),
  earnedLifetime: z.number().int().min(0),
  redeemedLifetime: z.number().int().min(0),
  tier: loyaltyTierEnum,
  /** Points until the next tier (null if already platinum). */
  pointsToNextTier: z.number().int().nullable(),
  recent: z.array(loyaltyTxSchema),
});
export type LoyaltySnapshot = z.infer<typeof loyaltySnapshotSchema>;

export const loyaltyEarnRequestSchema = z.object({
  idempotencyKey: z.string().min(8).max(128),
  kind: loyaltyKindEnum,
  /** Source amount (e.g. wallet payment in user's default currency). Server
   * applies the earn rate; client only sends the ground-truth amount. */
  sourceAmount: z.number().positive().optional(),
  description: z.string().min(1).max(200),
  reference: z.string().max(200).optional(),
});
export type LoyaltyEarnRequest = z.infer<typeof loyaltyEarnRequestSchema>;

export const loyaltyRedeemRequestSchema = z.object({
  idempotencyKey: z.string().min(8).max(128),
  points: z.number().int().positive().max(1_000_000),
  description: z.string().min(1).max(200),
  reference: z.string().max(200).optional(),
});
export type LoyaltyRedeemRequest = z.infer<typeof loyaltyRedeemRequestSchema>;

export const loyaltyMutationResponseSchema = z.object({
  transaction: loyaltyTxSchema,
  totalPoints: z.number().int().min(0),
  tier: loyaltyTierEnum,
  duplicate: z.boolean(),
});
export type LoyaltyMutationResponse = z.infer<typeof loyaltyMutationResponseSchema>;
