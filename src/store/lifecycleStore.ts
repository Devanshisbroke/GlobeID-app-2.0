/**
 * Phase 9-β — Trip lifecycle store.
 *
 * Two distinct concerns sharing one store:
 *   1. `trips`           — array of TripLifecycle, hydrated from /lifecycle/trips
 *   2. `flightStatuses`  — per-leg cache of FlightStatus, lazy-fetched on demand
 *      via fetchFlightStatus(legId).
 *
 * Both are read-only. Lifecycle states are derived server-side; the client
 * never writes them. Flight status is demo-mode (server returns `isDemoData:
 * true`); the cache here just collapses repeat fetches in a session.
 */
import { create } from "zustand";
import { api, ApiError } from "@/lib/apiClient";
import type { TripLifecycle, FlightStatus } from "@shared/types/lifecycle";

type Status = "idle" | "loading" | "ready" | "error";

interface LifecycleState {
  trips: TripLifecycle[];
  status: Status;
  lastHydratedAt: number | null;
  flightStatuses: Record<string, FlightStatus>;
  hydrate: () => Promise<void>;
  fetchFlightStatus: (legId: string) => Promise<FlightStatus | null>;
}

export const useLifecycleStore = create<LifecycleState>((set, get) => ({
  trips: [],
  status: "idle",
  lastHydratedAt: null,
  flightStatuses: {},

  hydrate: async () => {
    set({ status: "loading" });
    try {
      const trips = await api.lifecycle.trips();
      set({ trips, status: "ready", lastHydratedAt: Date.now() });
    } catch (e) {
      if (!(e instanceof ApiError) || e.status >= 500 || e.status === 0) {
        set((s) => ({ status: s.trips.length > 0 ? "ready" : "error" }));
        return;
      }
      set({ status: "error" });
    }
  },

  fetchFlightStatus: async (legId: string) => {
    const existing = get().flightStatuses[legId];
    if (existing) return existing;
    try {
      const status = await api.lifecycle.flightStatus(legId);
      set((s) => ({ flightStatuses: { ...s.flightStatuses, [legId]: status } }));
      return status;
    } catch {
      return null;
    }
  },
}));
