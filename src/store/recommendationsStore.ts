/** Hydrate-only store for backend-derived recommendations.
 *  Mirrors `insightsStore` — no mutations, no queue. */
import { create } from "zustand";
import { api, ApiError } from "@/lib/apiClient";
import type { Recommendation } from "@shared/types/insights";

type Status = "idle" | "loading" | "ready" | "error";

interface RecommendationsState {
  items: Recommendation[];
  generatedAt: number | null;
  status: Status;
  hydrate: () => Promise<void>;
}

export const useRecommendationsStore = create<RecommendationsState>((set) => ({
  items: [],
  generatedAt: null,
  status: "idle",

  hydrate: async () => {
    set({ status: "loading" });
    try {
      const res = await api.recommendations.list();
      set({ items: res.items, generatedAt: res.generatedAt, status: "ready" });
    } catch (e) {
      if (!(e instanceof ApiError) || e.status >= 500 || e.status === 0) {
        set((s) => ({ status: s.items.length > 0 ? "ready" : "error" }));
        return;
      }
      set({ status: "error" });
    }
  },
}));
