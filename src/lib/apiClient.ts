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
import type { ContextSnapshot } from "@shared/types/intelligence";
import type { TripLifecycle, FlightStatus } from "@shared/types/lifecycle";
import type {
  WalletSnapshot,
  RecordTransactionRequest,
  RecordTransactionResponse,
  ConvertRequest,
  ConvertResponse,
  UpdateStateRequest,
  WalletStateView,
} from "@shared/types/wallet";
import type {
  LoyaltySnapshot,
  LoyaltyEarnRequest,
  LoyaltyRedeemRequest,
  LoyaltyMutationResponse,
} from "@shared/types/loyalty";
import type {
  EmergencyContact,
  EmergencyContactCreate,
  EmergencyContactPatch,
} from "@shared/types/safety";
import type { BudgetCap, BudgetCapUpsert, BudgetSnapshot, BudgetUsage } from "@shared/types/budget";
import type { TravelScore } from "@shared/types/score";
import type { WeatherForecast } from "@shared/types/weather";
import type { FraudFinding, FraudScanResponse } from "@shared/types/fraud";
import type { VisaPolicy } from "@shared/data/visaCatalog";
import type { InsurancePlan } from "@shared/data/insuranceCatalog";
import type { ESimPlan } from "@shared/data/esimCatalog";
import type { Hotel } from "@shared/data/hotelsCatalog";
import type { Restaurant } from "@shared/data/foodCatalog";
import type { LocalService, ServiceKind } from "@shared/data/localServicesCatalog";

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

  context: {
    current: () => authedFetch("/context/current").then(unwrap<ContextSnapshot>),
  },

  lifecycle: {
    trips: () => authedFetch("/lifecycle/trips").then(unwrap<TripLifecycle[]>),
    flightStatus: (legId: string) =>
      authedFetch(`/lifecycle/flights/${encodeURIComponent(legId)}`).then(unwrap<FlightStatus>),
  },

  wallet: {
    snapshot: () => authedFetch("/wallet").then(unwrap<WalletSnapshot>),
    record: (req: RecordTransactionRequest) =>
      authedFetch("/wallet/transactions", {
        method: "POST",
        body: JSON.stringify(req),
      }).then(unwrap<RecordTransactionResponse>),
    convert: (req: ConvertRequest) =>
      authedFetch("/wallet/convert", {
        method: "POST",
        body: JSON.stringify(req),
      }).then(unwrap<ConvertResponse>),
    updateState: (req: UpdateStateRequest) =>
      authedFetch("/wallet/state", {
        method: "PATCH",
        body: JSON.stringify(req),
      }).then(unwrap<WalletStateView>),
  },

  loyalty: {
    snapshot: () => authedFetch("/loyalty").then(unwrap<LoyaltySnapshot>),
    earn: (req: LoyaltyEarnRequest) =>
      authedFetch("/loyalty/earn", { method: "POST", body: JSON.stringify(req) }).then(
        unwrap<LoyaltyMutationResponse>,
      ),
    redeem: (req: LoyaltyRedeemRequest) =>
      authedFetch("/loyalty/redeem", { method: "POST", body: JSON.stringify(req) }).then(
        unwrap<LoyaltyMutationResponse>,
      ),
  },

  safety: {
    contacts: () => authedFetch("/safety/contacts").then(unwrap<EmergencyContact[]>),
    addContact: (req: EmergencyContactCreate) =>
      authedFetch("/safety/contacts", { method: "POST", body: JSON.stringify(req) }).then(
        unwrap<EmergencyContact>,
      ),
    patchContact: (id: string, patch: EmergencyContactPatch) =>
      authedFetch(`/safety/contacts/${encodeURIComponent(id)}`, {
        method: "PATCH",
        body: JSON.stringify(patch),
      }).then(unwrap<EmergencyContact>),
    deleteContact: (id: string) =>
      authedFetch(`/safety/contacts/${encodeURIComponent(id)}`, { method: "DELETE" }).then(
        unwrap<{ deleted: string }>,
      ),
  },

  score: {
    snapshot: () => authedFetch("/score").then(unwrap<TravelScore>),
  },

  weather: {
    forecast: (iata: string, days = 7) =>
      authedFetch(`/weather/forecast?iata=${encodeURIComponent(iata)}&days=${days}`).then(
        unwrap<WeatherForecast>,
      ),
  },

  budget: {
    snapshot: () => authedFetch("/budget").then(unwrap<BudgetSnapshot>),
    upsertCap: (req: BudgetCapUpsert) =>
      authedFetch("/budget/caps", { method: "PUT", body: JSON.stringify(req) }).then(
        unwrap<{ cap: BudgetCap; usage: BudgetUsage }>,
      ),
    deleteCap: (scope: string) =>
      authedFetch(`/budget/caps/${encodeURIComponent(scope)}`, { method: "DELETE" }).then(
        unwrap<{ deleted: string }>,
      ),
  },

  fraud: {
    findings: () =>
      authedFetch("/fraud/findings").then(
        unwrap<{ scanned: number; findings: FraudFinding[] }>,
      ),
    scan: () =>
      authedFetch("/fraud/scan", { method: "POST" }).then(unwrap<FraudScanResponse>),
  },

  exchange: {
    rates: (base = "USD") =>
      authedFetch(`/exchange/rates?base=${encodeURIComponent(base)}`).then(
        unwrap<{ base: string; asOf: string; rates: Record<string, number>; source: string }>,
      ),
    quote: (from: string, to: string, amount: number) =>
      authedFetch(
        `/exchange/quote?from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}&amount=${amount}`,
      ).then(
        unwrap<{
          from: string;
          to: string;
          amount: number;
          rate: number;
          converted: number;
          asOf: string;
          source: string;
        }>,
      ),
  },

  visa: {
    policies: (citizenship?: string) =>
      authedFetch(
        `/visa/policies${citizenship ? `?citizenship=${encodeURIComponent(citizenship)}` : ""}`,
      ).then(unwrap<{ policies: VisaPolicy[]; total: number }>),
    policy: (citizenship: string, destination: string) =>
      authedFetch(
        `/visa/policy?citizenship=${encodeURIComponent(citizenship)}&destination=${encodeURIComponent(destination)}`,
      ).then(unwrap<VisaPolicy>),
  },

  insurance: {
    plans: () => authedFetch("/insurance/plans").then(unwrap<{ plans: InsurancePlan[] }>),
    quote: (days: number, age: number, destination: string) =>
      authedFetch(
        `/insurance/quote?days=${days}&age=${age}&destination=${encodeURIComponent(destination)}`,
      ).then(
        unwrap<{
          region: string;
          quotes: Array<{
            plan: InsurancePlan;
            quote: { premiumUsd: number; ageMultiplier: number; regionMultiplier: number };
          }>;
        }>,
      ),
  },

  esim: {
    plans: (country?: string) =>
      authedFetch(
        `/esim/plans${country ? `?country=${encodeURIComponent(country)}` : ""}`,
      ).then(unwrap<{ plans: ESimPlan[]; total: number }>),
  },

  hotels: {
    search: (params: {
      city?: string;
      country?: string;
      minStar?: number;
      maxPrice?: number;
      minRating?: number;
      amenities?: string[];
      checkIn?: string;
      checkOut?: string;
      sort?: "price_asc" | "price_desc" | "rating_desc" | "stars_desc" | "distance_asc";
    }) => {
      const q = new URLSearchParams();
      if (params.city) q.set("city", params.city);
      if (params.country) q.set("country", params.country);
      if (params.minStar !== undefined) q.set("minStar", String(params.minStar));
      if (params.maxPrice !== undefined) q.set("maxPrice", String(params.maxPrice));
      if (params.minRating !== undefined) q.set("minRating", String(params.minRating));
      if (params.amenities && params.amenities.length) q.set("amenities", params.amenities.join(","));
      if (params.checkIn) q.set("checkIn", params.checkIn);
      if (params.checkOut) q.set("checkOut", params.checkOut);
      if (params.sort) q.set("sort", params.sort);
      return authedFetch(`/hotels/search?${q.toString()}`).then(
        unwrap<{
          total: number;
          nights: number | null;
          sort: string;
          results: Array<Hotel & { totalUsd: number | null; nights: number | null }>;
        }>,
      );
    },
    get: (id: string) => authedFetch(`/hotels/${encodeURIComponent(id)}`).then(unwrap<Hotel>),
  },

  food: {
    restaurants: (params: {
      city?: string;
      cuisine?: string;
      priceTier?: string;
      minRating?: number;
      sort?: "rating_desc" | "eta_asc" | "price_asc";
    }) => {
      const q = new URLSearchParams();
      if (params.city) q.set("city", params.city);
      if (params.cuisine) q.set("cuisine", params.cuisine);
      if (params.priceTier) q.set("priceTier", params.priceTier);
      if (params.minRating !== undefined) q.set("minRating", String(params.minRating));
      if (params.sort) q.set("sort", params.sort);
      return authedFetch(`/food/restaurants?${q.toString()}`).then(
        unwrap<{ total: number; sort: string; results: Restaurant[] }>,
      );
    },
    restaurant: (id: string) =>
      authedFetch(`/food/restaurants/${encodeURIComponent(id)}`).then(unwrap<Restaurant>),
    quote: (req: {
      restaurantId: string;
      items: Array<{ menuItemId: string; qty: number }>;
      taxRate?: number;
      tipFraction?: number;
    }) =>
      authedFetch("/food/quote", { method: "POST", body: JSON.stringify(req) }).then(
        unwrap<{
          restaurantId: string;
          lines: Array<{ menuItemId: string; name: string; qty: number; lineTotalUsd: number }>;
          subtotalUsd: number;
          taxUsd: number;
          tipUsd: number;
          deliveryUsd: number;
          totalUsd: number;
          etaMinutes: number;
        }>,
      ),
  },

  rides: {
    estimate: (req: {
      fromIata?: string;
      fromLat?: number;
      fromLng?: number;
      toLat: number;
      toLng: number;
      vehicle: "bike" | "auto" | "sedan" | "suv" | "premium";
      surge?: number;
    }) =>
      authedFetch("/rides/estimate", { method: "POST", body: JSON.stringify(req) }).then(
        unwrap<{
          distanceKm: number;
          fareUsd: number;
          etaMinutes: number;
          vehicle: string;
          label: string;
          capacity: number;
          surge: number;
        }>,
      ),
    vehicles: () =>
      authedFetch("/rides/vehicles").then(
        unwrap<{
          vehicles: Array<{
            id: string;
            perKmUsd: number;
            baseFare: number;
            capacity: number;
            etaMinPerKm: number;
            label: string;
          }>;
        }>,
      ),
  },

  local: {
    services: (params: { country?: string; kind?: ServiceKind }) => {
      const q = new URLSearchParams();
      if (params.country) q.set("country", params.country);
      if (params.kind) q.set("kind", params.kind);
      return authedFetch(`/local/services?${q.toString()}`).then(
        unwrap<{ total: number; kinds: ServiceKind[]; results: LocalService[] }>,
      );
    },
  },
};

export const apiBaseUrl = BASE_URL;
