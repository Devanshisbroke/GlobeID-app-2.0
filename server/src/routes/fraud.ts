/**
 * Slice-B Phase-15 — fraud scan endpoint.
 *
 *   POST /fraud/scan       runs the rule set + creates alerts (idempotent on signature)
 *   GET  /fraud/findings   returns the most recent rule findings without creating alerts
 *
 * Alerts use the existing `alerts` table with a stable signature so reruns
 * don't multiply rows. The unique index on (user_id, signature) enforces this.
 */
import { Hono } from "hono";
import { desc, eq } from "drizzle-orm";
import { db, sqlite } from "../db/client.js";
import { walletTransactions, alerts } from "../db/schema.js";
import { authMiddleware, getUserId } from "../auth/token.js";
import { ok } from "../lib/validate.js";
import { evaluateFraudRules } from "../lib/fraud.js";
import type { FraudScanResponse } from "../../../shared/types/fraud.js";

export const fraudRouter = new Hono();
fraudRouter.use("*", authMiddleware);

function loadDebits(userId: string) {
  const rows = db
    .select()
    .from(walletTransactions)
    .where(eq(walletTransactions.userId, userId))
    .orderBy(desc(walletTransactions.createdAt))
    .limit(500)
    .all()
    .filter((r) => r.kind === "debit");
  // sort ascending for the rule evaluator (it relies on sequential order)
  return rows
    .map((r) => ({
      id: r.id,
      amount: Math.abs(r.amount),
      currency: r.currency,
      merchant: r.merchant,
      country: r.country,
      date: r.date,
      createdAt: r.createdAt,
    }))
    .reverse();
}

fraudRouter.get("/findings", (c) => {
  const userId = getUserId(c);
  const debits = loadDebits(userId);
  const findings = evaluateFraudRules(debits);
  return ok(c, { scanned: debits.length, findings });
});

fraudRouter.post("/scan", (c) => {
  const userId = getUserId(c);
  const debits = loadDebits(userId);
  const findings = evaluateFraudRules(debits);

  let created = 0;
  let duplicate = 0;
  // Use INSERT OR IGNORE to leverage the unique index on (user_id, signature).
  const stmt = sqlite.prepare(
    `INSERT OR IGNORE INTO alerts
       (id, user_id, category, title, message, severity, source, signature, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
  );
  for (const f of findings) {
    const id = `al-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 6)}`;
    const result = stmt.run(
      id,
      userId,
      "fraud",
      `Suspicious ${f.rule.replace("_", " ")} pattern`,
      f.message,
      f.severity,
      "system",
      f.signature,
      Date.now(),
    );
    if (result.changes === 1) created += 1;
    else duplicate += 1;
  }

  const response: FraudScanResponse = {
    scanned: debits.length,
    findings,
    alertsCreated: created,
    alertsDuplicate: duplicate,
  };
  return ok(c, response, 201);
});
