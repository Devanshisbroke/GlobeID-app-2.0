import { z } from "zod";

/**
 * Slice-A canonical wallet types.
 *
 * The backend ledger is append-only:
 *  - every mutation appends one or more rows to `wallet_transactions`
 *  - balances are atomically updated in the same SQLite transaction
 *  - retried POSTs collapse onto a single row via `idempotencyKey`
 *
 * The "gateway" (the thing that talks to a real PSP) is intentionally
 * separate. The ledger is real and production-grade; the gateway in this
 * repo is a demo passthrough until a real PSP is wired in a future PR.
 */

export const txTypeEnum = z.enum([
  "payment",
  "send",
  "receive",
  "convert",
  "refund",
]);
export type TxType = z.infer<typeof txTypeEnum>;

export const txCategoryEnum = z.enum([
  "transport",
  "food",
  "hotel",
  "shopping",
  "flight",
  "transfer",
  "entertainment",
]);
export type TxCategory = z.infer<typeof txCategoryEnum>;

export const walletBalanceSchema = z.object({
  currency: z.string().min(3).max(8),
  symbol: z.string().min(1).max(8),
  amount: z.number(),
  flag: z.string().min(1),
  rate: z.number().positive(),
});
export type WalletBalance = z.infer<typeof walletBalanceSchema>;

export const walletTransactionSchema = z.object({
  id: z.string().min(1),
  type: txTypeEnum,
  description: z.string().min(1),
  merchant: z.string().optional(),
  amount: z.number(), // Negative for debits, positive for credits — matches client convention.
  currency: z.string().min(3).max(8),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  category: txCategoryEnum,
  location: z.string().optional(),
  country: z.string().optional(),
  countryFlag: z.string().optional(),
  icon: z.string().min(1),
  reference: z.string().optional(),
});
export type WalletTransaction = z.infer<typeof walletTransactionSchema>;

export const walletStateSchema = z.object({
  defaultCurrency: z.string().min(3).max(8),
  activeCountry: z.string().nullable(),
});
export type WalletStateView = z.infer<typeof walletStateSchema>;

export const walletSnapshotSchema = z.object({
  balances: z.array(walletBalanceSchema),
  transactions: z.array(walletTransactionSchema),
  state: walletStateSchema,
});
export type WalletSnapshot = z.infer<typeof walletSnapshotSchema>;

/**
 * Request body for `POST /wallet/transactions`.
 *
 * `idempotencyKey` MUST be sent for every mutating call. Repeated calls
 * with the same key return the original transaction unchanged (HTTP 200
 * with `{ duplicate: true }`) instead of double-charging.
 */
export const recordTransactionRequestSchema = z.object({
  idempotencyKey: z.string().min(8).max(128),
  type: txTypeEnum,
  amount: z.number().refine((n) => n !== 0, "amount must be non-zero"),
  currency: z.string().min(3).max(8),
  description: z.string().min(1).max(200),
  merchant: z.string().max(200).optional(),
  category: txCategoryEnum,
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  location: z.string().max(200).optional(),
  country: z.string().max(120).optional(),
  countryFlag: z.string().max(8).optional(),
  icon: z.string().min(1).max(60),
  reference: z.string().max(200).optional(),
});
export type RecordTransactionRequest = z.infer<typeof recordTransactionRequestSchema>;

export const recordTransactionResponseSchema = z.object({
  transaction: walletTransactionSchema,
  balance: walletBalanceSchema,
  duplicate: z.boolean(),
  isDemoGateway: z.literal(true),
  demoNote: z.string(),
});
export type RecordTransactionResponse = z.infer<typeof recordTransactionResponseSchema>;

export const convertRequestSchema = z.object({
  idempotencyKey: z.string().min(8).max(128),
  fromCurrency: z.string().min(3).max(8),
  toCurrency: z.string().min(3).max(8),
  amount: z.number().positive(),
});
export type ConvertRequest = z.infer<typeof convertRequestSchema>;

export const convertResponseSchema = z.object({
  debit: walletTransactionSchema,
  credit: walletTransactionSchema,
  balances: z.array(walletBalanceSchema),
  duplicate: z.boolean(),
});
export type ConvertResponse = z.infer<typeof convertResponseSchema>;

export const updateStateSchema = z.object({
  defaultCurrency: z.string().min(3).max(8).optional(),
  activeCountry: z.string().nullable().optional(),
});
export type UpdateStateRequest = z.infer<typeof updateStateSchema>;
