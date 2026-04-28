/**
 * Slice-B Phase-15 — emergency contacts.
 *
 * CRUD with E.164 phone validation. The first contact is auto-primary;
 * promoting a different one demotes the current primary in the same
 * transaction so we never have two primaries.
 */
import { Hono } from "hono";
import { and, eq } from "drizzle-orm";
import { db, sqlite } from "../db/client.js";
import { emergencyContacts } from "../db/schema.js";
import { authMiddleware, getUserId } from "../auth/token.js";
import { ok, err, parseBody } from "../lib/validate.js";
import {
  emergencyContactCreateSchema,
  emergencyContactPatchSchema,
  type EmergencyContact,
} from "../../../shared/types/safety.js";

export const safetyRouter = new Hono();
safetyRouter.use("*", authMiddleware);

function rowToContact(r: typeof emergencyContacts.$inferSelect): EmergencyContact {
  return {
    id: r.id,
    name: r.name,
    relationship: r.relationship,
    phoneE164: r.phoneE164,
    email: r.email ?? null,
    isPrimary: r.isPrimary === 1,
    createdAt: new Date(r.createdAt).toISOString(),
  };
}

safetyRouter.get("/contacts", (c) => {
  const userId = getUserId(c);
  const rows = db
    .select()
    .from(emergencyContacts)
    .where(eq(emergencyContacts.userId, userId))
    .all();
  return ok(c, rows.map(rowToContact));
});

safetyRouter.post("/contacts", async (c) => {
  const userId = getUserId(c);
  const parsed = await parseBody(c, emergencyContactCreateSchema);
  if (parsed instanceof Response) return parsed;
  const body = parsed;

  const existingCount = (
    sqlite
      .prepare(`SELECT COUNT(*) AS n FROM emergency_contacts WHERE user_id = ?`)
      .get(userId) as { n: number }
  ).n;

  const id = `ec-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 6)}`;
  const wantPrimary = body.isPrimary === true || existingCount === 0;

  sqlite.transaction(() => {
    if (wantPrimary && existingCount > 0) {
      db.update(emergencyContacts)
        .set({ isPrimary: 0 })
        .where(eq(emergencyContacts.userId, userId))
        .run();
    }
    db.insert(emergencyContacts)
      .values({
        id,
        userId,
        name: body.name,
        relationship: body.relationship,
        phoneE164: body.phoneE164,
        email: body.email ?? null,
        isPrimary: wantPrimary ? 1 : 0,
        createdAt: Date.now(),
      })
      .run();
  })();

  const row = db
    .select()
    .from(emergencyContacts)
    .where(eq(emergencyContacts.id, id))
    .get()!;
  return ok(c, rowToContact(row), 201);
});

safetyRouter.patch("/contacts/:id", async (c) => {
  const userId = getUserId(c);
  const id = c.req.param("id");
  const parsed = await parseBody(c, emergencyContactPatchSchema);
  if (parsed instanceof Response) return parsed;
  const body = parsed;

  const existing = db
    .select()
    .from(emergencyContacts)
    .where(and(eq(emergencyContacts.userId, userId), eq(emergencyContacts.id, id)))
    .get();
  if (!existing) return err(c, "not_found", "Contact not found", 404);

  sqlite.transaction(() => {
    if (body.isPrimary === true && existing.isPrimary !== 1) {
      db.update(emergencyContacts)
        .set({ isPrimary: 0 })
        .where(eq(emergencyContacts.userId, userId))
        .run();
    }
    db.update(emergencyContacts)
      .set({
        name: body.name ?? existing.name,
        relationship: body.relationship ?? existing.relationship,
        phoneE164: body.phoneE164 ?? existing.phoneE164,
        email: body.email !== undefined ? body.email ?? null : existing.email,
        isPrimary: body.isPrimary !== undefined ? (body.isPrimary ? 1 : 0) : existing.isPrimary,
      })
      .where(eq(emergencyContacts.id, id))
      .run();
  })();

  const row = db
    .select()
    .from(emergencyContacts)
    .where(eq(emergencyContacts.id, id))
    .get()!;
  return ok(c, rowToContact(row));
});

safetyRouter.delete("/contacts/:id", (c) => {
  const userId = getUserId(c);
  const id = c.req.param("id");
  const existing = db
    .select()
    .from(emergencyContacts)
    .where(and(eq(emergencyContacts.userId, userId), eq(emergencyContacts.id, id)))
    .get();
  if (!existing) return err(c, "not_found", "Contact not found", 404);

  // If we're deleting the primary and others exist, promote the oldest other.
  sqlite.transaction(() => {
    db.delete(emergencyContacts)
      .where(eq(emergencyContacts.id, id))
      .run();
    if (existing.isPrimary === 1) {
      const next = sqlite
        .prepare(
          `SELECT id FROM emergency_contacts
           WHERE user_id = ?
           ORDER BY created_at ASC
           LIMIT 1`,
        )
        .get(userId) as { id: string } | undefined;
      if (next) {
        db.update(emergencyContacts)
          .set({ isPrimary: 1 })
          .where(eq(emergencyContacts.id, next.id))
          .run();
      }
    }
  })();

  return ok(c, { deleted: id });
});
