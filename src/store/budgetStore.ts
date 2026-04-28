import { create } from "zustand";
import { persist } from "zustand/middleware";
import { api, ApiError } from "@/lib/apiClient";
import type { BudgetSnapshot, BudgetCapUpsert } from "@shared/types/budget";

interface BudgetState {
  snapshot: BudgetSnapshot | null;
  hydrated: boolean;
  lastError: string | null;
  hydrate: () => Promise<void>;
  upsert: (req: BudgetCapUpsert) => Promise<void>;
  remove: (scope: string) => Promise<void>;
  clearError: () => void;
}

function errorMessage(e: unknown): string {
  if (e instanceof ApiError) return e.message;
  if (e instanceof Error) return e.message;
  return "Unknown budget error";
}

export const useBudgetStore = create<BudgetState>()(
  persist(
    (set) => ({
      snapshot: null,
      hydrated: false,
      lastError: null,

      hydrate: async () => {
        try {
          const snap = await api.budget.snapshot();
          set({ snapshot: snap, hydrated: true, lastError: null });
        } catch (e) {
          set({ hydrated: true, lastError: errorMessage(e) });
        }
      },

      upsert: async (req) => {
        try {
          await api.budget.upsertCap(req);
          const snap = await api.budget.snapshot();
          set({ snapshot: snap, lastError: null });
        } catch (e) {
          set({ lastError: errorMessage(e) });
          throw e;
        }
      },

      remove: async (scope) => {
        try {
          await api.budget.deleteCap(scope);
          const snap = await api.budget.snapshot();
          set({ snapshot: snap, lastError: null });
        } catch (e) {
          set({ lastError: errorMessage(e) });
          throw e;
        }
      },

      clearError: () => set({ lastError: null }),
    }),
    { name: "globe-budget.v1", partialize: (s) => ({ snapshot: s.snapshot }) },
  ),
);
