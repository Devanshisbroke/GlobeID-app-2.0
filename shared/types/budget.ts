import { z } from "zod";

/**
 * Slice-B — budget planner types.
 *
 * Caps are stored at scope keys like `category:food`, `category:hotel`,
 * `trip:trip_abc`, or `global`. Aggregation is server-side: SUM of
 * |amount| over wallet_transactions matching the scope, in the cap's
 * currency. We don't FX-convert per-row — caps are denominated in a
 * single currency, and ledger rows in other currencies are excluded
 * (annotated in the response).
 */

export const budgetPeriodEnum = z.enum(["trip", "monthly", "yearly", "global"]);
export type BudgetPeriod = z.infer<typeof budgetPeriodEnum>;

export const budgetCapSchema = z.object({
  scope: z.string().min(1).max(80),
  capAmount: z.number().positive(),
  currency: z.string().min(3).max(8),
  alertThreshold: z.number().min(0.1).max(1),
  period: budgetPeriodEnum,
  updatedAt: z.string(),
});
export type BudgetCap = z.infer<typeof budgetCapSchema>;

export const budgetCapUpsertSchema = z.object({
  scope: z.string().min(1).max(80),
  capAmount: z.number().positive(),
  currency: z.string().min(3).max(8),
  alertThreshold: z.number().min(0.1).max(1).optional(),
  period: budgetPeriodEnum,
});
export type BudgetCapUpsert = z.infer<typeof budgetCapUpsertSchema>;

export const budgetUsageSchema = z.object({
  scope: z.string(),
  cap: budgetCapSchema,
  spent: z.number().min(0),
  remaining: z.number(),
  fractionUsed: z.number().min(0),
  status: z.enum(["under", "near", "over"]),
  /** Number of ledger rows that contributed to `spent`. */
  rowCount: z.number().int().min(0),
  /** Currencies that were *excluded* because they didn't match `cap.currency`. */
  excludedCurrencies: z.array(z.string()),
});
export type BudgetUsage = z.infer<typeof budgetUsageSchema>;

export const budgetSnapshotSchema = z.object({
  defaultCurrency: z.string(),
  caps: z.array(budgetCapSchema),
  usage: z.array(budgetUsageSchema),
  /** ISO timestamp of computation, for cache headers / staleness display. */
  computedAt: z.string(),
});
export type BudgetSnapshot = z.infer<typeof budgetSnapshotSchema>;
