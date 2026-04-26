import { create } from "zustand";
import { persist } from "zustand/middleware";
import { useUserStore, type TravelRecord } from "@/store/userStore";
import { api, ApiError } from "@/lib/apiClient";

export type TripTheme = "vacation" | "business" | "backpacking" | "world_tour";

export interface PlannedTrip {
  id: string;
  name: string;
  destinations: string[]; // IATA codes
  theme: TripTheme;
  createdAt: string;
}

export type PlannerSyncStatus = "idle" | "loading" | "synced" | "offline-pending" | "error";

type PendingPlannerMutation =
  | { kind: "upsert"; trip: PlannedTrip }
  | { kind: "remove"; id: string };

interface TripPlannerState {
  // Current planning session
  currentDestinations: string[];
  currentName: string;
  currentTheme: TripTheme;
  // Saved trips
  savedTrips: PlannedTrip[];
  // Sync state (mirrors userStore pattern)
  syncStatus: PlannerSyncStatus;
  lastSyncedAt: number | null;
  pendingMutations: PendingPlannerMutation[];
  // Actions
  addDestination: (iata: string) => void;
  removeDestination: (iata: string) => void;
  reorderDestinations: (from: number, to: number) => void;
  setCurrentName: (name: string) => void;
  setCurrentTheme: (theme: TripTheme) => void;
  saveCurrentTrip: () => Promise<void>;
  loadTrip: (id: string) => void;
  deleteTrip: (id: string) => Promise<void>;
  clearCurrent: () => void;
  /** Fetch canonical state from server. Call once on app boot. */
  hydrate: () => Promise<void>;
  /** Replay queued mutations after reconnect. */
  drainPendingMutations: () => Promise<void>;
}

/* ── Trip → travel-record bridge ─────────────────────────────────
 * When a planner trip is saved, we expand its destinations into
 * a chain of TravelRecords (one per leg) and append them to the
 * user store. Each leg is tagged source: "planner" and prefixed
 * `tr-planner-<tripId>-<n>` so it can be removed when the trip
 * itself is deleted.
 *
 * Dates are estimated as today + (legIndex * 3 days) so the legs
 * land in a sensible upcoming order on the timeline / map.
 */
function legId(tripId: string, index: number): string {
  return `tr-planner-${tripId}-${index}`;
}

function legDate(baseOffsetDays: number): string {
  const d = new Date();
  d.setDate(d.getDate() + baseOffsetDays);
  return d.toISOString().slice(0, 10); // YYYY-MM-DD
}

function buildTripLegs(trip: PlannedTrip): TravelRecord[] {
  const legs: TravelRecord[] = [];
  for (let i = 0; i < trip.destinations.length - 1; i++) {
    legs.push({
      id: legId(trip.id, i),
      from: trip.destinations[i],
      to: trip.destinations[i + 1],
      date: legDate(7 + i * 3),
      airline: "Planned",
      duration: "—",
      type: "upcoming",
      source: "planner",
    });
  }
  return legs;
}

/** De-duplicating merge — server-canonical wins on id collision. */
function mergeSavedTrips(local: PlannedTrip[], remote: PlannedTrip[]): PlannedTrip[] {
  const byId = new Map<string, PlannedTrip>();
  for (const t of local) byId.set(t.id, t);
  for (const t of remote) byId.set(t.id, t);
  return [...byId.values()].sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}

export const useTripPlannerStore = create<TripPlannerState>()(
  persist(
    (set, get) => ({
      currentDestinations: [],
      currentName: "New Trip",
      currentTheme: "vacation",
      savedTrips: [],
      syncStatus: "idle",
      lastSyncedAt: null,
      pendingMutations: [],

      addDestination: (iata) =>
        set((s) => ({
          currentDestinations: s.currentDestinations.includes(iata)
            ? s.currentDestinations
            : [...s.currentDestinations, iata],
        })),

      removeDestination: (iata) =>
        set((s) => ({
          currentDestinations: s.currentDestinations.filter((d) => d !== iata),
        })),

      reorderDestinations: (from, to) =>
        set((s) => {
          const arr = [...s.currentDestinations];
          const [item] = arr.splice(from, 1);
          arr.splice(to, 0, item);
          return { currentDestinations: arr };
        }),

      setCurrentName: (name) => set({ currentName: name }),
      setCurrentTheme: (theme) => set({ currentTheme: theme }),

      saveCurrentTrip: async () => {
        const s = get();
        if (s.currentDestinations.length < 2) return;
        const trip: PlannedTrip = {
          id: crypto.randomUUID(),
          name: s.currentName,
          destinations: [...s.currentDestinations],
          theme: s.currentTheme,
          createdAt: new Date().toISOString(),
        };
        // Mirror trip legs into the canonical travel store so the
        // map / timeline / location-aware modules light up.
        const legs = buildTripLegs(trip);
        if (legs.length > 0) {
          await useUserStore.getState().addTravelRecords(legs);
        }
        // Optimistic local insert.
        set((state) => ({
          savedTrips: [trip, ...state.savedTrips],
          currentDestinations: [],
          currentName: "New Trip",
          currentTheme: "vacation",
        }));
        // Server upsert (with offline queue fallback).
        try {
          await api.planner.upsert(trip);
          set((state) => ({
            syncStatus: state.pendingMutations.length > 0 ? "offline-pending" : "synced",
            lastSyncedAt: Date.now(),
          }));
        } catch (e) {
          if (!(e instanceof ApiError) || e.status >= 500 || e.status === 0) {
            set((state) => ({
              syncStatus: "offline-pending",
              pendingMutations: [...state.pendingMutations, { kind: "upsert", trip }],
            }));
            return;
          }
          // 4xx is a hard failure — surface error but keep optimistic insert
          // so the user can retry. (Mirrors userStore.addTravelRecords.)
          set({ syncStatus: "error" });
          throw e;
        }
      },

      loadTrip: (id) => {
        const trip = get().savedTrips.find((t) => t.id === id);
        if (trip) {
          set({
            currentDestinations: [...trip.destinations],
            currentName: trip.name,
            currentTheme: trip.theme,
          });
        }
      },

      deleteTrip: async (id) => {
        // Drop the matching planner-derived records too (legacy id pattern).
        const userStore = useUserStore.getState();
        const prefix = `tr-planner-${id}-`;
        const matchingLegs = userStore.travelHistory.filter((r) => r.id.startsWith(prefix));
        for (const r of matchingLegs) {
          await userStore.removeTravelRecord(r.id);
        }
        const previous = get().savedTrips.find((t) => t.id === id);
        set((s) => ({ savedTrips: s.savedTrips.filter((t) => t.id !== id) }));
        try {
          await api.planner.remove(id);
          set((state) => ({
            syncStatus: state.pendingMutations.length > 0 ? "offline-pending" : "synced",
            lastSyncedAt: Date.now(),
          }));
        } catch (e) {
          if (!(e instanceof ApiError) || e.status >= 500 || e.status === 0) {
            set((state) => ({
              syncStatus: "offline-pending",
              pendingMutations: [...state.pendingMutations, { kind: "remove", id }],
            }));
            return;
          }
          // 404 just means the server already lost it — still success.
          if (e instanceof ApiError && e.status === 404) {
            set((state) => ({
              syncStatus: state.pendingMutations.length > 0 ? "offline-pending" : "synced",
              lastSyncedAt: Date.now(),
            }));
            return;
          }
          // Restore optimistic delete on hard failure.
          if (previous) {
            set((state) => ({
              savedTrips: [previous, ...state.savedTrips],
              syncStatus: "error",
            }));
          } else {
            set({ syncStatus: "error" });
          }
          throw e;
        }
      },

      clearCurrent: () =>
        set({ currentDestinations: [], currentName: "New Trip", currentTheme: "vacation" }),

      hydrate: async () => {
        set({ syncStatus: "loading" });
        try {
          const remote = await api.planner.list();
          set((state) => ({
            savedTrips: mergeSavedTrips(state.savedTrips, remote),
            syncStatus: "synced",
            lastSyncedAt: Date.now(),
          }));
          await get().drainPendingMutations();
        } catch {
          set((state) => ({
            syncStatus: state.pendingMutations.length > 0 ? "offline-pending" : "error",
          }));
        }
      },

      drainPendingMutations: async () => {
        const queue = get().pendingMutations;
        if (queue.length === 0) return;
        const remaining: PendingPlannerMutation[] = [];
        let drained = 0;
        for (const m of queue) {
          try {
            if (m.kind === "upsert") await api.planner.upsert(m.trip);
            else await api.planner.remove(m.id);
            drained += 1;
          } catch (e) {
            // 404 on remove = already gone server-side, treat as drained.
            if (m.kind === "remove" && e instanceof ApiError && e.status === 404) {
              drained += 1;
            } else {
              remaining.push(m);
            }
          }
        }
        set((state) => ({
          pendingMutations: remaining,
          syncStatus: remaining.length === 0 ? "synced" : "offline-pending",
          lastSyncedAt: remaining.length === 0 ? Date.now() : state.lastSyncedAt,
        }));
        if (drained > 0 && remaining.length === 0) {
          try {
            const remote = await api.planner.list();
            set((state) => ({ savedTrips: mergeSavedTrips(state.savedTrips, remote) }));
          } catch {
            /* swallow — next hydrate will reconcile */
          }
        }
      },
    }),
    {
      name: "globe-trip-planner",
      version: 2,
      partialize: (state) => ({
        savedTrips: state.savedTrips,
        pendingMutations: state.pendingMutations,
        lastSyncedAt: state.lastSyncedAt,
      }),
    },
  ),
);
