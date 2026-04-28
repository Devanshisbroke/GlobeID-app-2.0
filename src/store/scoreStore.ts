import { create } from "zustand";
import { persist } from "zustand/middleware";
import { api, ApiError } from "@/lib/apiClient";
import type { TravelScore } from "@shared/types/score";

interface ScoreState {
  score: TravelScore | null;
  hydrated: boolean;
  lastError: string | null;
  hydrate: () => Promise<void>;
}

function errorMessage(e: unknown): string {
  if (e instanceof ApiError) return e.message;
  if (e instanceof Error) return e.message;
  return "Unknown score error";
}

export const useScoreStore = create<ScoreState>()(
  persist(
    (set) => ({
      score: null,
      hydrated: false,
      lastError: null,

      hydrate: async () => {
        try {
          const score = await api.score.snapshot();
          set({ score, hydrated: true, lastError: null });
        } catch (e) {
          set({ hydrated: true, lastError: errorMessage(e) });
        }
      },
    }),
    { name: "globe-score.v1", partialize: (s) => ({ score: s.score }) },
  ),
);
