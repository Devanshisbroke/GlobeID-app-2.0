import { create } from "zustand";
import { api, ApiError } from "@/lib/apiClient";
import type { WeatherForecast } from "@shared/types/weather";

interface WeatherState {
  byIata: Record<string, { forecast: WeatherForecast; fetchedAt: number }>;
  loading: Set<string>;
  lastError: string | null;
  fetchFor: (iata: string, days?: number, force?: boolean) => Promise<void>;
}

const TTL_MS = 15 * 60 * 1000;

function errorMessage(e: unknown): string {
  if (e instanceof ApiError) return e.message;
  if (e instanceof Error) return e.message;
  return "Unknown weather error";
}

export const useWeatherStore = create<WeatherState>((set, get) => ({
  byIata: {},
  loading: new Set<string>(),
  lastError: null,

  fetchFor: async (iata, days = 7, force = false) => {
    const code = iata.toUpperCase();
    const existing = get().byIata[code];
    if (!force && existing && Date.now() - existing.fetchedAt < TTL_MS) return;
    if (get().loading.has(code)) return;
    set((s) => {
      const next = new Set(s.loading);
      next.add(code);
      return { loading: next };
    });
    try {
      const forecast = await api.weather.forecast(code, days);
      set((s) => ({
        byIata: { ...s.byIata, [code]: { forecast, fetchedAt: Date.now() } },
        lastError: null,
      }));
    } catch (e) {
      set({ lastError: errorMessage(e) });
    } finally {
      set((s) => {
        const next = new Set(s.loading);
        next.delete(code);
        return { loading: next };
      });
    }
  },
}));
