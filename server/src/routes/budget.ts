/**
 * Slice-B Phase-15 — budget caps + usage aggregation.
 *
 * Caps are scoped strings: "category:food", "trip:trip_abc", "global".
 * Usage is computed by SUMing wallet_transactions matching the scope, in
 * the cap's currency. We don't FX-convert per row; ledger rows in other
 * currencies are excluded and reported via `excludedCurrencies`.
 */
import { Hono } from "hono";
import { and, eq } from "drizzle-orm";
import { sqlite, db } from "../db/client.js";
import { budgetCaps, walletState } from "../db/schema.js";
import { authMiddleware, getUserId } from "../auth/token.js";
import { ok, err, parseBody } from "../lib/validate.js";
import {
  budgetCapUpsertSchema,
  type BudgetCap,
  type BudgetSnapshot,
  type BudgetUsage,
} from "../../../shared/types/budget.js";

export const budgetRouter = new Hono();
budgetRouter.use("*", authMiddleware);

function rowToCap(r: typeof budgetCaps.$inferSelect): BudgetCap {
  return {
    scope: r.scope,
    capAmount: r.capAmount,
    currency: r.currency,
    alertThreshold: r.alertThreshold,
    period: r.period,
    updatedAt: new Date(r.updatedAt).toISOString(),
  };
}

function parseScope(scope: string): { kind: "category" | "trip" | "global"; value: string } {
  if (scope === "global") return { kind: "global", value: "" };
  const [kind, ...rest] = scope.split(":");
  const value = rest.join(":");
  if (kind === "category" && value) return { kind: "category", value };
  if (kind === "trip" && value) return { kind: "trip", value };
  return { kind: "global", value: "" };
}

function aggregateForCap(userId: string, cap: BudgetCap): BudgetUsage {
  const parsed = parseScope(cap.scope);
  const params: (string | number)[] = [userId];
  let where = `user_id = ? AND kind = 'debit'`;
  if (parsed.kind === "category") {
    where += ` AND category = ?`;
    params.push(parsed.value);
  } else if (parsed.kind === "trip") {
    where += ` AND reference = ?`;
    params.push(parsed.value);
  }
  const all = sqlite
    .prepare(
      `SELECT amount, currency FROM wallet_transactions WHERE ${where}`,
    )
    .all(...params) as Array<{ amount: number; currency: string }>;
  let spent = 0;
  let rowCount = 0;
  const excluded = new Set<string>();
  for (const r of all) {
    if (r.currency === cap.currency) {
      spent += r.amount;
      rowCount += 1;
    } else {
      excluded.add(r.currency);
    }
  }
  const remaining = cap.capAmount - spent;
  const fractionUsed = cap.capAmount > 0 ? spent / cap.capAmount : 0;
  const status: BudgetUsage["status"] =
    fractionUsed >= 1 ? "over" : fractionUsed >= cap.alertThreshold ? "near" : "under";
  return {
    scope: cap.scope,
    cap,
    spent: Math.round(spent * 100) / 100,
    remaining: Math.round(remaining * 100) / 100,
    fractionUsed: Math.round(fractionUsed * 1000) / 1000,
    status,
    rowCount,
    excludedCurrencies: [...excluded].sort(),
  };
}

budgetRouter.get("/", (c) => {
  const userId = getUserId(c);
  const stateRow = db
    .select()
    .from(walletState)
    .where(eq(walletState.userId, userId))
    .get();
  const defaultCurrency = stateRow?.defaultCurrency ?? "USD";

  const capRows = db
    .select()
    .from(budgetCaps)
    .where(eq(budgetCaps.userId, userId))
    .all();
  const caps = capRows.map(rowToCap);
  const usage = caps.map((cap) => aggregateForCap(userId, cap));
  const snap: BudgetSnapshot = {
    defaultCurrency,
    caps,
    usage,
    computedAt: new Date().toISOString(),
  };
  return ok(c, snap);
});

budgetRouter.put("/caps", async (c) => {
  const userId = getUserId(c);
  const parsed = await parseBody(c, budgetCapUpsertSchema);
  if (parsed instanceof Response) return parsed;
  const body = parsed;

  const existing = db
    .select()
    .from(budgetCaps)
    .where(and(eq(budgetCaps.userId, userId), eq(budgetCaps.scope, body.scope)))
    .get();
  const now = Date.now();
  if (existing) {
    db.update(budgetCaps)
      .set({
        capAmount: body.capAmount,
        currency: body.currency,
        alertThreshold: body.alertThreshold ?? existing.alertThreshold,
        period: body.period,
        updatedAt: now,
      })
      .where(and(eq(budgetCaps.userId, userId), eq(budgetCaps.scope, body.scope)))
      .run();
  } else {
    db.insert(budgetCaps)
      .values({
        userId,
        scope: body.scope,
        capAmount: body.capAmount,
        currency: body.currency,
        alertThreshold: body.alertThreshold ?? 0.8,
        period: body.period,
        updatedAt: now,
      })
      .run();
  }
  const row = db
    .select()
    .from(budgetCaps)
    .where(and(eq(budgetCaps.userId, userId), eq(budgetCaps.scope, body.scope)))
    .get()!;
  const cap = rowToCap(row);
  return ok(c, { cap, usage: aggregateForCap(userId, cap) }, 201);
});

budgetRouter.delete("/caps/:scope", (c) => {
  const userId = getUserId(c);
  const scope = decodeURIComponent(c.req.param("scope"));
  const existing = db
    .select()
    .from(budgetCaps)
    .where(and(eq(budgetCaps.userId, userId), eq(budgetCaps.scope, scope)))
    .get();
  if (!existing) return err(c, "not_found", `No cap at scope ${scope}`, 404);
  db.delete(budgetCaps)
    .where(and(eq(budgetCaps.userId, userId), eq(budgetCaps.scope, scope)))
    .run();
  return ok(c, { deleted: scope });
});

// Exposed for tests and the fraud scanner.
export { aggregateForCap };
