import { create } from "zustand";
import { persist } from "zustand/middleware";

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

      deleteTrip: (id) =>
        set((s) => ({ savedTrips: s.savedTrips.filter((t) => t.id !== id) })),

      clearCurrent: () =>
        set({ currentDestinations: [], currentName: "New Trip", currentTheme: "vacation" }),
    }),
    { name: "globe-trip-planner" }
  )
);
