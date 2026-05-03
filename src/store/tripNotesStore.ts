import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";

/**
 * Per-trip rich-text notes (BACKLOG D 45).
 *
 * Stored as serialised Tiptap/ProseMirror JSON keyed by trip ID. We
 * avoid persisting the editor instance directly — only the document
 * snapshot. Hydration is via zustand's localStorage adapter.
 */
export interface TripNotesState {
  notes: Record<string, unknown>;
  setNote: (tripId: string, doc: unknown) => void;
  clearNote: (tripId: string) => void;
  getNote: (tripId: string) => unknown | null;
}

export const useTripNotesStore = create<TripNotesState>()(
  persist(
    (set, get) => ({
      notes: {},
      setNote: (tripId, doc) =>
        set((s) => ({ notes: { ...s.notes, [tripId]: doc } })),
      clearNote: (tripId) =>
        set((s) => {
          const next = { ...s.notes };
          delete next[tripId];
          return { notes: next };
        }),
      getNote: (tripId) => get().notes[tripId] ?? null,
    }),
    {
      name: "globeid:tripNotes",
      storage: createJSONStorage(() => localStorage),
    },
  ),
);
