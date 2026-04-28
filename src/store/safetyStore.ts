import { create } from "zustand";
import { persist } from "zustand/middleware";
import { api, ApiError } from "@/lib/apiClient";
import type {
  EmergencyContact,
  EmergencyContactCreate,
  EmergencyContactPatch,
} from "@shared/types/safety";

interface SafetyState {
  contacts: EmergencyContact[];
  hydrated: boolean;
  lastError: string | null;
  hydrate: () => Promise<void>;
  add: (req: EmergencyContactCreate) => Promise<void>;
  patch: (id: string, p: EmergencyContactPatch) => Promise<void>;
  remove: (id: string) => Promise<void>;
}

function errorMessage(e: unknown): string {
  if (e instanceof ApiError) return e.message;
  if (e instanceof Error) return e.message;
  return "Unknown safety error";
}

export const useSafetyStore = create<SafetyState>()(
  persist(
    (set) => ({
      contacts: [],
      hydrated: false,
      lastError: null,

      hydrate: async () => {
        try {
          const contacts = await api.safety.contacts();
          set({ contacts, hydrated: true, lastError: null });
        } catch (e) {
          set({ hydrated: true, lastError: errorMessage(e) });
        }
      },

      add: async (req) => {
        try {
          await api.safety.addContact(req);
          const contacts = await api.safety.contacts();
          set({ contacts, lastError: null });
        } catch (e) {
          set({ lastError: errorMessage(e) });
          throw e;
        }
      },

      patch: async (id, p) => {
        try {
          await api.safety.patchContact(id, p);
          const contacts = await api.safety.contacts();
          set({ contacts, lastError: null });
        } catch (e) {
          set({ lastError: errorMessage(e) });
          throw e;
        }
      },

      remove: async (id) => {
        try {
          await api.safety.deleteContact(id);
          const contacts = await api.safety.contacts();
          set({ contacts, lastError: null });
        } catch (e) {
          set({ lastError: errorMessage(e) });
          throw e;
        }
      },
    }),
    { name: "globe-safety.v1", partialize: (s) => ({ contacts: s.contacts }) },
  ),
);
