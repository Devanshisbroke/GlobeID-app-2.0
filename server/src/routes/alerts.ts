import { Hono } from "hono";
import { z } from "zod";
import { eq, and } from "drizzle-orm";
import { db } from "../db/client.js";
import { alerts as alertsTable } from "../db/schema.js";
import { authMiddleware, getUserId } from "../auth/token.js";
import { ok, err, parseBody } from "../lib/validate.js";
import { cacheInvalidate } from "../lib/cache.js";
import { deriveSystemAlerts } from "../lib/insights.js";
import type { Alert } from "../../../shared/types/alerts.js";

export const alertsRouter = new Hono();
alertsRouter.use("*", authMiddleware);

interface AlertRow {
  id: string;
  userId: string;
  category: string;
  title: string;
  message: string;
  severity: "low" | "medium" | "high";
  source: "seed" | "system";
  signature: string | null;
  createdAt: number;
  readAt: number | null;
  dismissed: number;
}

function rowToAlert(row: AlertRow): Alert {
  const cat: Alert["category"] = (() => {
    switch (row.category) {
      case "visa":
      case "flight":
      case "wallet":
      case "advisory":
      case "info":
      case "system":
        return row.category;
      default:
        return "info";
    }
  })();
  return {
    id: row.id,
    category: cat,
    title: row.title,
    message: row.message,
    severity: row.severity,
    source: row.source,
    signature: row.signature ?? undefined,
    createdAt: row.createdAt,
    read: row.readAt !== null,
    dismissed: row.dismissed === 1,
  };
}

/** Insert any system-derived alerts whose signature does not yet exist for
 *  this user. Idempotent — relies on the (user_id, signature) unique index. */
function ensureSystemAlerts(userId: string): void {
  const derived = deriveSystemAlerts(userId);
  if (derived.length === 0) return;
  const now = Date.now();
  for (const d of derived) {
    db.insert(alertsTable)
      .values({
        id: `sys-${d.signature}-${now}`,
        userId,
        category: d.category,
        title: d.title,
        message: d.message,
        severity: d.severity,
        source: "system",
        signature: d.signature,
        createdAt: now,
        readAt: null,
        dismissed: 0,
      })
      .onConflictDoNothing()
      .run();
  }
}

alertsRouter.get("/", (c) => {
  const userId = getUserId(c);
  ensureSystemAlerts(userId);
  const rows = db
    .select()
    .from(alertsTable)
    .where(eq(alertsTable.userId, userId))
    .all() as AlertRow[];
  const alerts = rows
    .map(rowToAlert)
    .sort((a, b) => b.createdAt - a.createdAt);
  return ok(c, alerts);
});

const patchSchema = z.object({
  read: z.boolean().optional(),
  dismissed: z.boolean().optional(),
});

alertsRouter.patch("/:id", async (c) => {
  const userId = getUserId(c);
  const id = c.req.param("id");
  const parsed = await parseBody(c, patchSchema);
  if (parsed instanceof Response) return parsed;

  const existing = db
    .select()
    .from(alertsTable)
    .where(and(eq(alertsTable.id, id), eq(alertsTable.userId, userId)))
    .get() as AlertRow | undefined;
  if (!existing) return err(c, "not_found", "Alert not found", 404);

  const patch: Partial<AlertRow> = {};
  if (parsed.read === true) patch.readAt = Date.now();
  if (parsed.read === false) patch.readAt = null;
  if (parsed.dismissed === true) patch.dismissed = 1;
  if (parsed.dismissed === false) patch.dismissed = 0;

  if (Object.keys(patch).length > 0) {
    db.update(alertsTable)
      .set(patch)
      .where(and(eq(alertsTable.id, id), eq(alertsTable.userId, userId)))
      .run();
    cacheInvalidate(`insights:activity:${userId}`);
  }

  const updated = db
    .select()
    .from(alertsTable)
    .where(eq(alertsTable.id, id))
    .get() as AlertRow;
  return ok(c, rowToAlert(updated));
});
