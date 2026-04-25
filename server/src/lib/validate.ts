import type { Context } from "hono";
import { z, type ZodTypeAny } from "zod";

export async function parseBody<S extends ZodTypeAny>(c: Context, schema: S): Promise<z.infer<S> | Response> {
  let raw: unknown;
  try {
    raw = await c.req.json();
  } catch {
    return c.json({ ok: false, error: { code: "invalid_json", message: "Body must be JSON" } }, 400);
  }
  const parsed = schema.safeParse(raw);
  if (!parsed.success) {
    return c.json({ ok: false, error: { code: "invalid_body", message: parsed.error.message } }, 400);
  }
  return parsed.data;
}

export function ok<T>(c: Context, data: T, status: 200 | 201 = 200) {
  return c.json({ ok: true as const, data }, status);
}

export function err(c: Context, code: string, message: string, status: 400 | 401 | 404 | 500 = 400) {
  return c.json({ ok: false as const, error: { code, message } }, status);
}
