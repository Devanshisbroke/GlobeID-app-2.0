/**
 * Tiny typed wrapper around fetch.
 *
 * - Reads the API base URL from `import.meta.env.VITE_API_BASE_URL`
 *   (falls back to http://localhost:4000/api/v1 in dev).
 * - Issues a static demo token on first hit and persists it in
 *   localStorage as `globe-auth.token` so the second tab/refresh
 *   reuses it.
 * - Unwraps the `{ ok, data | error }` envelope so callers get plain
 *   typed values or a thrown ApiError.
 */
import type { TravelRecord, UserProfile } from "@shared/types/travel";

export class ApiError extends Error {
  constructor(public code: string, message: string, public status: number) {
    super(message);
    this.name = "ApiError";
  }
}

type ApiEnvelope<T> =
  | { ok: true; data: T }
  | { ok: false; error: { code: string; message: string } };

const BASE_URL: string =
  (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? "http://localhost:4000/api/v1";

const TOKEN_KEY = "globe-auth.token";

function getToken(): string | null {
  try {
    return localStorage.getItem(TOKEN_KEY);
  } catch {
    return null;
  }
}

function setToken(t: string): void {
  try {
    localStorage.setItem(TOKEN_KEY, t);
  } catch {
    /* ignore */
  }
}

async function bootstrapToken(): Promise<string> {
  const res = await fetch(`${BASE_URL}/auth/demo`, { method: "POST" });
  const json = (await res.json()) as ApiEnvelope<{ token: string; userId: string }>;
  if (!json.ok) throw new ApiError(json.error.code, json.error.message, res.status);
  setToken(json.data.token);
  return json.data.token;
}

async function authedFetch(path: string, init: RequestInit = {}): Promise<Response> {
  let token = getToken();
  if (!token) token = await bootstrapToken();

  const headers = new Headers(init.headers);
  headers.set("Authorization", `Bearer ${token}`);
  if (init.body && !headers.has("Content-Type")) headers.set("Content-Type", "application/json");

  let res = await fetch(`${BASE_URL}${path}`, { ...init, headers });

  // Token rotation: on 401, mint a new one and retry once.
  if (res.status === 401) {
    token = await bootstrapToken();
    headers.set("Authorization", `Bearer ${token}`);
    res = await fetch(`${BASE_URL}${path}`, { ...init, headers });
  }
  return res;
}

async function unwrap<T>(res: Response): Promise<T> {
  const json = (await res.json()) as ApiEnvelope<T>;
  if (!json.ok) throw new ApiError(json.error.code, json.error.message, res.status);
  return json.data;
}

export const api = {
  health: () => fetch(`${BASE_URL}/health`).then((r) => r.ok),

  user: {
    me: () => authedFetch("/user").then(unwrap<UserProfile>),
  },

  trips: {
    list: () => authedFetch("/trips").then(unwrap<TravelRecord[]>),
    create: (records: TravelRecord[]) =>
      authedFetch("/trips", { method: "POST", body: JSON.stringify({ records }) }).then(
        unwrap<{ added: number; skipped: number; records: TravelRecord[] }>
      ),
    remove: (id: string) =>
      authedFetch(`/trips/${encodeURIComponent(id)}`, { method: "DELETE" }).then(
        unwrap<{ id: string; deleted: true }>
      ),
  },
};

export const apiBaseUrl = BASE_URL;
