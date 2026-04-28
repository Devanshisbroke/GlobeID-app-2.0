import { z } from "zod";

/**
 * Slice-B — fraud detection (deterministic rules).
 *
 * No ML. The rules are:
 *  - **velocity**:    >N debits within the last X minutes
 *  - **amount-z**:    debit |amount| more than K stdev above the user's mean
 *  - **geo-jump**:    consecutive debits with country mismatch within Y minutes
 *  - **off-hours**:   debit between 02:00–05:00 user-local that's also above K stdev
 *  - **duplicate**:   identical (amount, merchant, currency) within Z minutes
 *
 * Each rule fires deterministically; no per-user model, so this is auditable
 * and replayable. Fired rules become server-side `alerts` rows with
 * severity=high and a stable signature so they don't duplicate on re-eval.
 */

export const fraudRuleEnum = z.enum([
  "velocity",
  "amount_z",
  "geo_jump",
  "off_hours",
  "duplicate",
]);
export type FraudRule = z.infer<typeof fraudRuleEnum>;

export const fraudFindingSchema = z.object({
  rule: fraudRuleEnum,
  transactionId: z.string(),
  severity: z.enum(["low", "medium", "high"]),
  message: z.string().min(1).max(200),
  /** Stable signature so repeated evaluations don't fan out alerts. */
  signature: z.string().min(1).max(120),
  /** Diagnostic fields used in the rule's threshold evaluation. */
  context: z.record(z.string(), z.union([z.string(), z.number(), z.boolean(), z.null()])),
});
export type FraudFinding = z.infer<typeof fraudFindingSchema>;

export const fraudScanResponseSchema = z.object({
  scanned: z.number().int().min(0),
  findings: z.array(fraudFindingSchema),
  alertsCreated: z.number().int().min(0),
  alertsDuplicate: z.number().int().min(0),
});
export type FraudScanResponse = z.infer<typeof fraudScanResponseSchema>;
