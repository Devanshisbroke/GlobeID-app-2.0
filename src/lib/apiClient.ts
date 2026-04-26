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
import type {
  TravelInsight,
  WalletInsight,
  ActivityInsight,
  RecommendationsResponse,
} from "@shared/types/insights";
import type { Alert, AlertPatch } from "@shared/types/alerts";

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

  insights: {
    travel: () => authedFetch("/insights/travel").then(unwrap<TravelInsight>),
    wallet: () => authedFetch("/insights/wallet").then(unwrap<WalletInsight>),
    activity: () => authedFetch("/insights/activity").then(unwrap<ActivityInsight>),
  },

  recommendations: {
    list: () => authedFetch("/recommendations").then(unwrap<RecommendationsResponse>),
  },

  alerts: {
    list: () => authedFetch("/alerts").then(unwrap<Alert[]>),
    patch: (id: string, patch: AlertPatch) =>
      authedFetch(`/alerts/${encodeURIComponent(id)}`, {
        method: "PATCH",
        body: JSON.stringify(patch),
      }).then(unwrap<Alert>),
  },

  copilot: {
    respond: (prompt: string) =>
      authedFetch("/copilot/respond", { method: "POST", body: JSON.stringify({ prompt }) })
        .then(unwrap<{
          userMessageId: string;
          reply: {
            id: string;
            message: string;
            action?: { type: string; payload: Record<string, unknown> };
            citations: string[];
          };
        }>),
    history: () =>
      authedFetch("/copilot/history").then(
        unwrap<Array<{ id: string; role: "user" | "assistant"; content: string; createdAt: number }>>,
      ),
    clear: () =>
      authedFetch("/copilot/history", { method: "DELETE" }).then(unwrap<{ deleted: number }>),
  },

  planner: {
    list: () =>
      authedFetch("/planner/trips").then(
        unwrap<Array<{
          id: string;
          name: string;
          theme: "vacation" | "business" | "backpacking" | "world_tour";
          destinations: string[];
          createdAt: string;
        }>>,
      ),
    upsert: (trip: {
      id: string;
      name: string;
      theme: "vacation" | "business" | "backpacking" | "world_tour";
      destinations: string[];
      createdAt?: string;
    }) =>
      authedFetch("/planner/trips", { method: "POST", body: JSON.stringify(trip) }).then(
        unwrap<{
          id: string;
          name: string;
          theme: "vacation" | "business" | "backpacking" | "world_tour";
          destinations: string[];
          createdAt: string;
        }>,
      ),
    remove: (id: string) =>
      authedFetch(`/planner/trips/${encodeURIComponent(id)}`, { method: "DELETE" }).then(
        unwrap<{ id: string; tripDeleted: boolean; legsDeleted: number }>,
      ),
  },
};

export const apiBaseUrl = BASE_URL;
