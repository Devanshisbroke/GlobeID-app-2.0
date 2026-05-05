/**
 * Recent commands for the command palette (BACKLOG J 123).
 *
 * Stores the last 5 command IDs the user invoked, so the palette can
 * surface a "Recent" section above the static groups.
 */
import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";

const MAX_RECENT = 5;

interface CommandPaletteState {
  recents: string[];
  push: (id: string) => void;
  clear: () => void;
}

export const useCommandPaletteStore = create<CommandPaletteState>()(
  persist(
    (set) => ({
      recents: [],
      push: (id) =>
        set((s) => {
          const next = [id, ...s.recents.filter((r) => r !== id)];
          if (next.length > MAX_RECENT) next.length = MAX_RECENT;
          return { recents: next };
        }),
      clear: () => set({ recents: [] }),
    }),
    {
      name: "globeid:commandPalette",
      storage: createJSONStorage(() => localStorage),
    },
  ),
);
