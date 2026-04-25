/** Hydrate-only store for backend-derived insights.
 *
 *  Lifecycle:
 *  - `hydrate()` fetches /insights/{travel,wallet,activity} in parallel and
 *    sets the local cache. Failure leaves the previous values intact.
 *  - There are NO mutations from the client side — these views are
 *    derivations of canonical state, not separate writes. Therefore there
 *    is no `pendingMutations` queue and no offline path beyond "use the
 *    last successful snapshot." */
import { create } from "zustand";
import { api, ApiError } from "@/lib/apiClient";
import type {
  TravelInsight,
  WalletInsight,
  ActivityInsight,
} from "@shared/types/insights";

type Status = "idle" | "loading" | "ready" | "error";

interface InsightsState {
  travel: TravelInsight | null;
  wallet: WalletInsight | null;
  activity: ActivityInsight | null;
  status: Status;
  lastHydratedAt: number | null;
  hydrate: () => Promise<void>;
}

export const useInsightsStore = create<InsightsState>((set) => ({
  travel: null,
  wallet: null,
  activity: null,
  status: "idle",
  lastHydratedAt: null,

  hydrate: async () => {
    set({ status: "loading" });
    try {
      const [travel, wallet, activity] = await Promise.all([
        api.insights.travel(),
        api.insights.wallet(),
        api.insights.activity(),
      ]);
      set({
        travel,
        wallet,
        activity,
        status: "ready",
        lastHydratedAt: Date.now(),
      });
    } catch (e) {
      // Network error → leave existing snapshot in place.
      if (!(e instanceof ApiError) || e.status >= 500 || e.status === 0) {
        set((s) => ({ status: s.travel ? "ready" : "error" }));
        return;
      }
      set({ status: "error" });
    }
  },
}));
