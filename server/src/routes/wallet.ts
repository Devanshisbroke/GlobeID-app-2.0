/**
 * Slice-A — real wallet ledger (Phase 8 subset).
 *
 * Append-only ledger. Every mutating call:
 *   1. opens an SQLite transaction
 *   2. checks `idempotencyKey` — if already used, returns the prior row
 *   3. inserts one (or two, for convert) rows into `wallet_transactions`
 *   4. atomically updates the corresponding `wallet_balances`
 *   5. rejects debits that would push a balance below zero
 *
 * The gateway (PSP) is intentionally NOT real. Responses include
 * `isDemoGateway: true` + `demoNote` so the UI can surface this and never
 * pretend a real bank rail processed the payment.
 */
import { Hono } from "hono";
import { and, desc, eq } from "drizzle-orm";
import { db, sqlite } from "../db/client.js";
import {
  walletBalances,
  walletState,
  walletTransactions,
} from "../db/schema.js";
import { authMiddleware, getUserId } from "../auth/token.js";
import { ok, err, parseBody } from "../lib/validate.js";
import { cacheInvalidate } from "../lib/cache.js";
import {
  recordTransactionRequestSchema,
  convertRequestSchema,
  updateStateSchema,
  type WalletBalance,
  type WalletTransaction,
  type WalletSnapshot,
  type RecordTransactionResponse,
  type ConvertResponse,
} from "../../../shared/types/wallet.js";

const DEMO_NOTE =
  "Demo gateway — the ledger is real and persistent, but no real PSP processed this. Wire STRIPE_SECRET_KEY (or RAZORPAY_KEY_ID) for live processing.";

const CURRENCY_SYMBOLS: Record<string, string> = {
  USD: "$",
  EUR: "€",
  GBP: "£",
  INR: "₹",
  SGD: "S$",
  JPY: "¥",
  AED: "د.إ",
  AUD: "A$",
  CAD: "C$",
  CHF: "Fr.",
  CNY: "¥",
  HKD: "HK$",
  KRW: "₩",
  THB: "฿",
};

function symbolFor(currency: string): string {
  return CURRENCY_SYMBOLS[currency] ?? currency;
}

function rowToTransaction(r: typeof walletTransactions.$inferSelect): WalletTransaction {
  return {
    id: r.id,
    type: (r.txType ?? "payment") as WalletTransaction["type"],
    description: r.description,
    merchant: r.merchant ?? undefined,
    amount: r.kind === "debit" ? -Math.abs(r.amount) : Math.abs(r.amount),
    currency: r.currency,
    date: r.date,
    category: (r.category ?? "transfer") as WalletTransaction["category"],
    location: undefined,
    country: r.country ?? undefined,
    countryFlag: r.countryFlag ?? undefined,
    icon: r.icon ?? "ArrowUpRight",
    reference: r.reference ?? undefined,
  };
}

function rowToBalance(r: typeof walletBalances.$inferSelect): WalletBalance {
  return {
    currency: r.currency,
    symbol: symbolFor(r.currency),
    amount: r.amount,
    flag: r.flag,
    rate: r.rate,
  };
}

export const walletRouter = new Hono();
walletRouter.use("*", authMiddleware);

walletRouter.get("/", (c) => {
  const userId = getUserId(c);
  const balanceRows = db
    .select()
    .from(walletBalances)
    .where(eq(walletBalances.userId, userId))
    .all();
  const txRows = db
    .select()
    .from(walletTransactions)
    .where(eq(walletTransactions.userId, userId))
    .orderBy(desc(walletTransactions.createdAt))
    .limit(200)
    .all();
  const stateRow = db
    .select()
    .from(walletState)
    .where(eq(walletState.userId, userId))
    .get();

  const snapshot: WalletSnapshot = {
    balances: balanceRows.map(rowToBalance),
    transactions: txRows.map(rowToTransaction),
    state: {
      defaultCurrency: stateRow?.defaultCurrency ?? "USD",
      activeCountry: stateRow?.activeCountry ?? null,
    },
  };
  return ok(c, snapshot);
});

walletRouter.post("/transactions", async (c) => {
  const userId = getUserId(c);
  const parsed = await parseBody(c, recordTransactionRequestSchema);
  if (parsed instanceof Response) return parsed;

  const body = parsed;
  const isDebit = body.type === "payment" || body.type === "send" || body.type === "convert";
  const kind: "credit" | "debit" = isDebit ? "debit" : "credit";
  const absAmount = Math.abs(body.amount);

  // Idempotency lookup — if we've already committed this exact key, return
  // the prior row + current balance rather than double-charging.
  const existing = db
    .select()
    .from(walletTransactions)
    .where(
      and(
        eq(walletTransactions.userId, userId),
        eq(walletTransactions.idempotencyKey, body.idempotencyKey),
      ),
    )
    .get();
  if (existing) {
    const balRow = db
      .select()
      .from(walletBalances)
      .where(
        and(
          eq(walletBalances.userId, userId),
          eq(walletBalances.currency, existing.currency),
        ),
      )
      .get();
    if (!balRow) return err(c, "balance_missing", `No balance row for ${existing.currency}`, 404);
    const response: RecordTransactionResponse = {
      transaction: rowToTransaction(existing),
      balance: rowToBalance(balRow),
      duplicate: true,
      isDemoGateway: true,
      demoNote: DEMO_NOTE,
    };
    return ok(c, response);
  }

  // Atomic ledger write. better-sqlite3 transactions throw to roll back, so
  // we surface insufficient-funds + missing-balance as thrown errors and
  // catch them outside the closure.
  const txId = `tx-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
  const date = body.date ?? new Date().toISOString().slice(0, 10);
  const now = Date.now();

  let resultBalance: WalletBalance;
  try {
    resultBalance = sqlite.transaction(() => {
      const balRow = db
        .select()
        .from(walletBalances)
        .where(
          and(
            eq(walletBalances.userId, userId),
            eq(walletBalances.currency, body.currency),
          ),
        )
        .get();
      if (!balRow) throw new LedgerError("balance_missing", `No balance row for ${body.currency}. Top up first.`, 404);

      const next = isDebit ? balRow.amount - absAmount : balRow.amount + absAmount;
      if (isDebit && next < 0) {
        throw new LedgerError(
          "insufficient_funds",
          `Insufficient ${body.currency} balance. Available ${balRow.amount}, requested ${absAmount}.`,
          400,
        );
      }

      db.update(walletBalances)
        .set({ amount: next })
        .where(
          and(
            eq(walletBalances.userId, userId),
            eq(walletBalances.currency, body.currency),
          ),
        )
        .run();

      db.insert(walletTransactions)
        .values({
          id: txId,
          userId,
          currency: body.currency,
          amount: absAmount,
          kind,
          description: body.description,
          date,
          createdAt: now,
          idempotencyKey: body.idempotencyKey,
          txType: body.type,
          merchant: body.merchant ?? null,
          category: body.category,
          country: body.country ?? null,
          countryFlag: body.countryFlag ?? null,
          icon: body.icon,
          reference: body.reference ?? null,
        })
        .run();

      return rowToBalance({ ...balRow, amount: next });
    })();
  } catch (e) {
    if (e instanceof LedgerError) return err(c, e.code, e.message, e.status);
    throw e;
  }

  cacheInvalidate(`insights:wallet:${userId}`);

  const insertedRow = db
    .select()
    .from(walletTransactions)
    .where(eq(walletTransactions.id, txId))
    .get()!;
  const response: RecordTransactionResponse = {
    transaction: rowToTransaction(insertedRow),
    balance: resultBalance,
    duplicate: false,
    isDemoGateway: true,
    demoNote: DEMO_NOTE,
  };
  return ok(c, response, 201);
});

walletRouter.post("/convert", async (c) => {
  const userId = getUserId(c);
  const parsed = await parseBody(c, convertRequestSchema);
  if (parsed instanceof Response) return parsed;
  const body = parsed;

  if (body.fromCurrency === body.toCurrency) {
    return err(c, "invalid_conversion", "from and to currencies must differ", 400);
  }

  // Idempotency: convert is two rows, both tagged with the same key + suffix.
  const existingDebit = db
    .select()
    .from(walletTransactions)
    .where(
      and(
        eq(walletTransactions.userId, userId),
        eq(walletTransactions.idempotencyKey, `${body.idempotencyKey}:debit`),
      ),
    )
    .get();
  if (existingDebit) {
    const existingCredit = db
      .select()
      .from(walletTransactions)
      .where(
        and(
          eq(walletTransactions.userId, userId),
          eq(walletTransactions.idempotencyKey, `${body.idempotencyKey}:credit`),
        ),
      )
      .get();
    const balanceRows = db
      .select()
      .from(walletBalances)
      .where(eq(walletBalances.userId, userId))
      .all();
    if (!existingCredit) {
      return err(c, "ledger_corrupt", "Convert idempotency partial — debit without credit", 500);
    }
    const response: ConvertResponse = {
      debit: rowToTransaction(existingDebit),
      credit: rowToTransaction(existingCredit),
      balances: balanceRows.map(rowToBalance),
      duplicate: true,
    };
    return ok(c, response);
  }

  const debitId = `tx-${Date.now().toString(36)}-d-${Math.random().toString(36).slice(2, 6)}`;
  const creditId = `tx-${Date.now().toString(36)}-c-${Math.random().toString(36).slice(2, 6)}`;
  const date = new Date().toISOString().slice(0, 10);
  const now = Date.now();

  let updatedBalances: WalletBalance[];
  try {
    updatedBalances = sqlite.transaction(() => {
      const fromRow = db
        .select()
        .from(walletBalances)
        .where(
          and(eq(walletBalances.userId, userId), eq(walletBalances.currency, body.fromCurrency)),
        )
        .get();
      const toRow = db
        .select()
        .from(walletBalances)
        .where(
          and(eq(walletBalances.userId, userId), eq(walletBalances.currency, body.toCurrency)),
        )
        .get();
      if (!fromRow) throw new LedgerError("balance_missing", `No balance for ${body.fromCurrency}`, 404);
      if (!toRow) throw new LedgerError("balance_missing", `No balance for ${body.toCurrency}`, 404);
      if (fromRow.amount < body.amount) {
        throw new LedgerError(
          "insufficient_funds",
          `Insufficient ${body.fromCurrency} balance. Available ${fromRow.amount}, requested ${body.amount}.`,
          400,
        );
      }

      // Convert via USD-pivot using stored rates.
      const usdValue = body.amount * fromRow.rate;
      const convertedAmount = usdValue / toRow.rate;

      db.update(walletBalances)
        .set({ amount: fromRow.amount - body.amount })
        .where(
          and(eq(walletBalances.userId, userId), eq(walletBalances.currency, body.fromCurrency)),
        )
        .run();
      db.update(walletBalances)
        .set({ amount: toRow.amount + convertedAmount })
        .where(
          and(eq(walletBalances.userId, userId), eq(walletBalances.currency, body.toCurrency)),
        )
        .run();

      db.insert(walletTransactions)
        .values({
          id: debitId,
          userId,
          currency: body.fromCurrency,
          amount: body.amount,
          kind: "debit",
          description: `${body.fromCurrency} → ${body.toCurrency}`,
          date,
          createdAt: now,
          idempotencyKey: `${body.idempotencyKey}:debit`,
          txType: "convert",
          merchant: null,
          category: "transfer",
          country: null,
          countryFlag: null,
          icon: "RefreshCw",
          reference: creditId,
        })
        .run();
      db.insert(walletTransactions)
        .values({
          id: creditId,
          userId,
          currency: body.toCurrency,
          amount: convertedAmount,
          kind: "credit",
          description: `${body.fromCurrency} → ${body.toCurrency}`,
          date,
          createdAt: now + 1, // ensure stable ordering for the credit-after-debit display
          idempotencyKey: `${body.idempotencyKey}:credit`,
          txType: "convert",
          merchant: null,
          category: "transfer",
          country: null,
          countryFlag: null,
          icon: "RefreshCw",
          reference: debitId,
        })
        .run();

      return [
        rowToBalance({ ...fromRow, amount: fromRow.amount - body.amount }),
        rowToBalance({ ...toRow, amount: toRow.amount + convertedAmount }),
      ];
    })();
  } catch (e) {
    if (e instanceof LedgerError) return err(c, e.code, e.message, e.status);
    throw e;
  }

  cacheInvalidate(`insights:wallet:${userId}`);

  const debitRow = db
    .select()
    .from(walletTransactions)
    .where(eq(walletTransactions.id, debitId))
    .get()!;
  const creditRow = db
    .select()
    .from(walletTransactions)
    .where(eq(walletTransactions.id, creditId))
    .get()!;
  const allBalances = db
    .select()
    .from(walletBalances)
    .where(eq(walletBalances.userId, userId))
    .all();

  // Merge: keep latest values for converted currencies, keep existing for others.
  const updatedMap = new Map(updatedBalances.map((b) => [b.currency, b]));
  const merged = allBalances.map((r) => updatedMap.get(r.currency) ?? rowToBalance(r));

  const response: ConvertResponse = {
    debit: rowToTransaction(debitRow),
    credit: rowToTransaction(creditRow),
    balances: merged,
    duplicate: false,
  };
  return ok(c, response, 201);
});

walletRouter.patch("/state", async (c) => {
  const userId = getUserId(c);
  const parsed = await parseBody(c, updateStateSchema);
  if (parsed instanceof Response) return parsed;
  const patch = parsed;

  const existing = db
    .select()
    .from(walletState)
    .where(eq(walletState.userId, userId))
    .get();

  if (!existing) {
    db.insert(walletState).values({
      userId,
      activeCountry: patch.activeCountry ?? null,
      defaultCurrency: patch.defaultCurrency ?? "USD",
    }).run();
  } else {
    const next = {
      activeCountry: patch.activeCountry !== undefined ? patch.activeCountry : existing.activeCountry,
      defaultCurrency: patch.defaultCurrency ?? existing.defaultCurrency,
    };
    db.update(walletState)
      .set(next)
      .where(eq(walletState.userId, userId))
      .run();
  }

  const stateRow = db
    .select()
    .from(walletState)
    .where(eq(walletState.userId, userId))
    .get()!;
  return ok(c, {
    defaultCurrency: stateRow.defaultCurrency,
    activeCountry: stateRow.activeCountry,
  });
});

class LedgerError extends Error {
  constructor(public code: string, message: string, public status: 400 | 401 | 404 | 500) {
    super(message);
  }
}
