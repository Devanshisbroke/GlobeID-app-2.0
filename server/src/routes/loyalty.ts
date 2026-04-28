/**
 * Slice-B Phase-15 — loyalty ledger.
 *
 * Same pattern as wallet: append-only, idempotency keys, atomic inserts.
 * Snapshot computes lifetime totals from a SUM, never trusting a cached
 * balance. Tier thresholds live in `lib/loyalty.ts` so they're testable.
 */
import { Hono } from "hono";
import { and, desc, eq } from "drizzle-orm";
import { sql } from "drizzle-orm";
import { db, sqlite } from "../db/client.js";
import { loyaltyTransactions } from "../db/schema.js";
import { authMiddleware, getUserId } from "../auth/token.js";
import { ok, err, parseBody } from "../lib/validate.js";
import {
  loyaltyEarnRequestSchema,
  loyaltyRedeemRequestSchema,
  type LoyaltySnapshot,
  type LoyaltyTx,
  type LoyaltyMutationResponse,
} from "../../../shared/types/loyalty.js";
import {
  pointsForWalletPayment,
  POINTS_PER_TRIP_COMPLETION,
  POINTS_FOR_SIGNUP,
  tierFor,
} from "../lib/loyalty.js";

export const loyaltyRouter = new Hono();
loyaltyRouter.use("*", authMiddleware);

function rowToTx(r: typeof loyaltyTransactions.$inferSelect): LoyaltyTx {
  return {
    id: r.id,
    points: r.points,
    kind: r.kind,
    description: r.description,
    reference: r.reference ?? undefined,
    createdAt: new Date(r.createdAt).toISOString(),
  };
}

function snapshotFor(userId: string): LoyaltySnapshot {
  const totals = sqlite
    .prepare(
      `SELECT
         COALESCE(SUM(CASE WHEN points > 0 THEN points ELSE 0 END), 0) AS earned,
         COALESCE(SUM(CASE WHEN points < 0 THEN -points ELSE 0 END), 0) AS redeemed
       FROM loyalty_transactions WHERE user_id = ?`,
    )
    .get(userId) as { earned: number; redeemed: number };
  const totalPoints = Math.max(0, totals.earned - totals.redeemed);
  const recent = db
    .select()
    .from(loyaltyTransactions)
    .where(eq(loyaltyTransactions.userId, userId))
    .orderBy(desc(loyaltyTransactions.createdAt))
    .limit(50)
    .all();
  const tierInfo = tierFor(totalPoints);
  return {
    totalPoints,
    earnedLifetime: totals.earned,
    redeemedLifetime: totals.redeemed,
    tier: tierInfo.tier,
    pointsToNextTier: tierInfo.pointsToNextTier,
    recent: recent.map(rowToTx),
  };
}

loyaltyRouter.get("/", (c) => {
  const userId = getUserId(c);
  return ok(c, snapshotFor(userId));
});

loyaltyRouter.post("/earn", async (c) => {
  const userId = getUserId(c);
  const parsed = await parseBody(c, loyaltyEarnRequestSchema);
  if (parsed instanceof Response) return parsed;
  const body = parsed;

  // Idempotency lookup — if we already committed this exact key, return that row.
  const existing = db
    .select()
    .from(loyaltyTransactions)
    .where(
      and(
        eq(loyaltyTransactions.userId, userId),
        eq(loyaltyTransactions.idempotencyKey, body.idempotencyKey),
      ),
    )
    .get();
  if (existing) {
    const snap = snapshotFor(userId);
    const response: LoyaltyMutationResponse = {
      transaction: rowToTx(existing),
      totalPoints: snap.totalPoints,
      tier: snap.tier,
      duplicate: true,
    };
    return ok(c, response);
  }

  let points: number;
  switch (body.kind) {
    case "wallet_payment":
      if (!body.sourceAmount) return err(c, "missing_source", "wallet_payment earn requires sourceAmount", 400);
      points = pointsForWalletPayment(body.sourceAmount);
      break;
    case "trip_completion":
      points = POINTS_PER_TRIP_COMPLETION;
      break;
    case "signup_bonus":
      points = POINTS_FOR_SIGNUP;
      break;
    case "adjustment":
      if (!body.sourceAmount) return err(c, "missing_amount", "adjustment requires sourceAmount", 400);
      points = Math.floor(body.sourceAmount);
      break;
    case "redemption":
      return err(c, "wrong_endpoint", "Use /loyalty/redeem for redemptions", 400);
  }
  if (points <= 0) return err(c, "no_points_earned", "Source amount earned 0 points", 400);

  const id = `lt-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
  const now = Date.now();
  db.insert(loyaltyTransactions)
    .values({
      id,
      userId,
      points,
      kind: body.kind,
      description: body.description,
      reference: body.reference ?? null,
      idempotencyKey: body.idempotencyKey,
      createdAt: now,
    })
    .run();

  const inserted = db
    .select()
    .from(loyaltyTransactions)
    .where(eq(loyaltyTransactions.id, id))
    .get()!;
  const snap = snapshotFor(userId);
  const response: LoyaltyMutationResponse = {
    transaction: rowToTx(inserted),
    totalPoints: snap.totalPoints,
    tier: snap.tier,
    duplicate: false,
  };
  return ok(c, response, 201);
});

loyaltyRouter.post("/redeem", async (c) => {
  const userId = getUserId(c);
  const parsed = await parseBody(c, loyaltyRedeemRequestSchema);
  if (parsed instanceof Response) return parsed;
  const body = parsed;

  const existing = db
    .select()
    .from(loyaltyTransactions)
    .where(
      and(
        eq(loyaltyTransactions.userId, userId),
        eq(loyaltyTransactions.idempotencyKey, body.idempotencyKey),
      ),
    )
    .get();
  if (existing) {
    const snap = snapshotFor(userId);
    const response: LoyaltyMutationResponse = {
      transaction: rowToTx(existing),
      totalPoints: snap.totalPoints,
      tier: snap.tier,
      duplicate: true,
    };
    return ok(c, response);
  }

  // Atomic balance check + insert.
  const id = `lt-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
  const now = Date.now();
  try {
    sqlite.transaction(() => {
      const totals = sqlite
        .prepare(
          `SELECT COALESCE(SUM(points), 0) AS balance FROM loyalty_transactions WHERE user_id = ?`,
        )
        .get(userId) as { balance: number };
      const balance = Math.max(0, totals.balance);
      if (balance < body.points) {
        throw new LoyaltyError(
          "insufficient_points",
          `Insufficient points. Available ${balance}, requested ${body.points}.`,
          400,
        );
      }
      db.insert(loyaltyTransactions)
        .values({
          id,
          userId,
          points: -body.points,
          kind: "redemption",
          description: body.description,
          reference: body.reference ?? null,
          idempotencyKey: body.idempotencyKey,
          createdAt: now,
        })
        .run();
    })();
  } catch (e) {
    if (e instanceof LoyaltyError) return err(c, e.code, e.message, e.status);
    throw e;
  }

  const inserted = db
    .select()
    .from(loyaltyTransactions)
    .where(eq(loyaltyTransactions.id, id))
    .get()!;
  const snap = snapshotFor(userId);
  const response: LoyaltyMutationResponse = {
    transaction: rowToTx(inserted),
    totalPoints: snap.totalPoints,
    tier: snap.tier,
    duplicate: false,
  };
  return ok(c, response, 201);
});

class LoyaltyError extends Error {
  constructor(public code: string, message: string, public status: 400 | 401 | 404 | 500) {
    super(message);
  }
}

// Re-export sql for tests if needed.
export { sql };
