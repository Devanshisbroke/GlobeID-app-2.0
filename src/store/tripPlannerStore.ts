import { create } from "zustand";
import { persist } from "zustand/middleware";
import { useUserStore, type TravelRecord } from "@/store/userStore";

export type TripTheme = "vacation" | "business" | "backpacking" | "world_tour";

export interface PlannedTrip {
  id: string;
  name: string;
  destinations: string[]; // IATA codes
  theme: TripTheme;
  createdAt: string;
}

interface TripPlannerState {
  // Current planning session
  currentDestinations: string[];
  currentName: string;
  currentTheme: TripTheme;
  // Saved trips
  savedTrips: PlannedTrip[];
  // Actions
  addDestination: (iata: string) => void;
  removeDestination: (iata: string) => void;
  reorderDestinations: (from: number, to: number) => void;
  setCurrentName: (name: string) => void;
  setCurrentTheme: (theme: TripTheme) => void;
  saveCurrentTrip: () => void;
  loadTrip: (id: string) => void;
  deleteTrip: (id: string) => void;
  clearCurrent: () => void;
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

export const useTripPlannerStore = create<TripPlannerState>()(
  persist(
    (set, get) => ({
      currentDestinations: [],
      currentName: "New Trip",
      currentTheme: "vacation",
      savedTrips: [],

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

      saveCurrentTrip: () => {
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
          useUserStore.getState().addTravelRecords(legs);
        }
        set((state) => ({
          savedTrips: [trip, ...state.savedTrips],
          currentDestinations: [],
          currentName: "New Trip",
          currentTheme: "vacation",
        }));
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

      deleteTrip: (id) => {
        // Drop the matching planner-derived records too.
        const userStore = useUserStore.getState();
        const prefix = `tr-planner-${id}-`;
        userStore.travelHistory
          .filter((r) => r.id.startsWith(prefix))
          .forEach((r) => userStore.removeTravelRecord(r.id));
        set((s) => ({ savedTrips: s.savedTrips.filter((t) => t.id !== id) }));
      },

      clearCurrent: () =>
        set({ currentDestinations: [], currentName: "New Trip", currentTheme: "vacation" }),
    }),
    { name: "globe-trip-planner" }
  )
);
