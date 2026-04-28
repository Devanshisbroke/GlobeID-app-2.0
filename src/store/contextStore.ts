/**
 * Phase 9-β — Context store (hydrate-only).
 *
 * Mirrors `insightsStore` / `recommendationsStore`: a single read-only
 * snapshot from the backend's `/context/current` endpoint. No mutations,
 * no offline queue — the snapshot is always derived from canonical state.
 */
import { create } from "zustand";
import { api, ApiError } from "@/lib/apiClient";
import type { ContextSnapshot } from "@shared/types/intelligence";

type Status = "idle" | "loading" | "ready" | "error";

interface ContextState {
  snapshot: ContextSnapshot | null;
  status: Status;
  lastHydratedAt: number | null;
  hydrate: () => Promise<void>;
}

export const useContextStore = create<ContextState>((set) => ({
  snapshot: null,
  status: "idle",
  lastHydratedAt: null,

  hydrate: async () => {
    set({ status: "loading" });
    try {
      const snapshot = await api.context.current();
      set({ snapshot, status: "ready", lastHydratedAt: Date.now() });
    } catch (e) {
      if (!(e instanceof ApiError) || e.status >= 500 || e.status === 0) {
        set((s) => ({ status: s.snapshot ? "ready" : "error" }));
        return;
      }
      set({ status: "error" });
    }
  },
}));
