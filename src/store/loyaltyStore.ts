import { create } from "zustand";
import { persist } from "zustand/middleware";
import { api, ApiError } from "@/lib/apiClient";
import type {
  LoyaltySnapshot,
  LoyaltyEarnRequest,
  LoyaltyRedeemRequest,
} from "@shared/types/loyalty";

/**
 * Slice-B Phase-15 — loyalty store.
 *
 * Mirrors the wallet pattern: backend is the source of truth, persist is
 * just a hot cache. Earn/redeem return the new server snapshot in one
 * round trip (so the UI doesn't need a follow-up GET).
 */

interface LoyaltyState {
  snapshot: LoyaltySnapshot | null;
  hydrated: boolean;
  lastError: string | null;
  hydrate: () => Promise<void>;
  earn: (req: Omit<LoyaltyEarnRequest, "idempotencyKey"> & { idempotencyKey?: string }) => Promise<void>;
  redeem: (
    req: Omit<LoyaltyRedeemRequest, "idempotencyKey"> & { idempotencyKey?: string },
  ) => Promise<void>;
  clearError: () => void;
}

function newKey(): string {
  if (typeof crypto !== "undefined" && "randomUUID" in crypto) return crypto.randomUUID();
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 12)}`;
}

function errorMessage(e: unknown): string {
  if (e instanceof ApiError) return e.message;
  if (e instanceof Error) return e.message;
  return "Unknown loyalty error";
}

export const useLoyaltyStore = create<LoyaltyState>()(
  persist(
    (set) => ({
      snapshot: null,
      hydrated: false,
      lastError: null,

      hydrate: async () => {
        try {
          const snap = await api.loyalty.snapshot();
          set({ snapshot: snap, hydrated: true, lastError: null });
        } catch (e) {
          set({ hydrated: true, lastError: errorMessage(e) });
        }
      },

      earn: async (req) => {
        const fullReq: LoyaltyEarnRequest = { ...req, idempotencyKey: req.idempotencyKey ?? newKey() };
        try {
          await api.loyalty.earn(fullReq);
          const snap = await api.loyalty.snapshot();
          set({ snapshot: snap, lastError: null });
        } catch (e) {
          set({ lastError: errorMessage(e) });
          throw e;
        }
      },

      redeem: async (req) => {
        const fullReq: LoyaltyRedeemRequest = { ...req, idempotencyKey: req.idempotencyKey ?? newKey() };
        try {
          await api.loyalty.redeem(fullReq);
          const snap = await api.loyalty.snapshot();
          set({ snapshot: snap, lastError: null });
        } catch (e) {
          set({ lastError: errorMessage(e) });
          throw e;
        }
      },

      clearError: () => set({ lastError: null }),
    }),
    { name: "globe-loyalty.v1", partialize: (s) => ({ snapshot: s.snapshot }) },
  ),
);
