import { Hono } from "hono";
import { eq } from "drizzle-orm";
import { db } from "../db/client.js";
import { users } from "../db/schema.js";
import { authMiddleware, getUserId } from "../auth/token.js";
import { ok, err } from "../lib/validate.js";

export const userRouter = new Hono();

userRouter.use("*", authMiddleware);

userRouter.get("/", (c) => {
  const userId = getUserId(c);
  const row = db.select().from(users).where(eq(users.id, userId)).get();
  if (!row) return err(c, "not_found", "User not found", 404);
  return ok(c, {
    id: row.id,
    email: row.email,
    fullName: row.fullName,
    nationality: row.nationality,
    passportNo: row.passportNo ?? undefined,
    dateOfBirth: row.dateOfBirth ?? undefined,
  });
});
