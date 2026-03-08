import { create } from "zustand";
import { persist } from "zustand/middleware";

interface ServiceFavoritesState {
  favorites: string[]; // service/hotel/restaurant IDs
  history: { id: string; type: string; name: string; date: string }[];
  toggleFavorite: (id: string) => void;
  isFavorite: (id: string) => boolean;
  addHistory: (entry: { id: string; type: string; name: string }) => void;
}

export const useServiceFavoritesStore = create<ServiceFavoritesState>()(
  persist(
    (set, get) => ({
      favorites: [],
      history: [
        { id: "hist-1", type: "ride", name: "Grab to Changi Airport", date: "Mar 5" },
        { id: "hist-2", type: "food", name: "Din Tai Fung — Dumplings", date: "Mar 4" },
        { id: "hist-3", type: "hotel", name: "Marina Bay Sands — 2 nights", date: "Mar 3" },
        { id: "hist-4", type: "activity", name: "Gardens by the Bay Tour", date: "Mar 2" },
      ],
      toggleFavorite: (id) =>
        set((s) => ({
          favorites: s.favorites.includes(id)
            ? s.favorites.filter((f) => f !== id)
            : [...s.favorites, id],
        })),
      isFavorite: (id) => get().favorites.includes(id),
      addHistory: (entry) =>
        set((s) => ({
          history: [{ ...entry, date: new Date().toLocaleDateString("en-US", { month: "short", day: "numeric" }) }, ...s.history].slice(0, 20),
        })),
    }),
    { name: "globe-service-favorites" }
  )
);
