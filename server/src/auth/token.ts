import { createHmac, timingSafeEqual } from "node:crypto";
import type { Context, MiddlewareHandler } from "hono";
import { DEMO_USER_ID } from "../db/seed.js";

const SECRET = process.env.GLOBE_TOKEN_SECRET ?? "globe-dev-secret-change-me";

/** Issue an HMAC-signed bearer token: `<userId>.<sig>`. */
export function issueToken(userId: string): string {
  const sig = createHmac("sha256", SECRET).update(userId).digest("hex");
  return `${userId}.${sig}`;
}

export function verifyToken(token: string): string | null {
  const dot = token.lastIndexOf(".");
  if (dot < 0) return null;
  const userId = token.slice(0, dot);
  const sig = token.slice(dot + 1);
  const expected = createHmac("sha256", SECRET).update(userId).digest("hex");
  if (sig.length !== expected.length) return null;
  try {
    if (!timingSafeEqual(Buffer.from(sig, "hex"), Buffer.from(expected, "hex"))) return null;
  } catch {
    return null;
  }
  return userId;
}

export const authMiddleware: MiddlewareHandler = async (c, next) => {
  const header = c.req.header("authorization") ?? "";
  const match = header.match(/^Bearer\s+(.+)$/i);
  const tok = match?.[1];
  if (!tok) return c.json({ ok: false, error: { code: "missing_token", message: "Authorization required" } }, 401);
  const userId = verifyToken(tok);
  if (!userId) return c.json({ ok: false, error: { code: "invalid_token", message: "Invalid token" } }, 401);
  c.set("userId", userId);
  await next();
};

export function getUserId(c: Context): string {
  const id = c.get("userId");
  if (!id || typeof id !== "string") throw new Error("auth middleware not applied");
  return id;
}

export { DEMO_USER_ID };
