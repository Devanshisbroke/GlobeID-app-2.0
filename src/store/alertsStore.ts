/** Alerts cache layer.
 *
 *  - Backend (`/api/v1/alerts`) is the source of truth. The store mirrors
 *    server state and persists locally for offline cold boot.
 *  - System alerts (e.g. "Trip to Japan in 14 days — JPY ready") are
 *    derived server-side on every read against the latest travel + wallet
 *    state. Their dedup key is the server-side `signature` so re-deriving
 *    is idempotent.
 *  - `markRead` / `dismissAlert` are optimistic with the same offline
 *    queue + drain pattern as `userStore`. On 5xx / network failure the
 *    mutation queues and is replayed on reconnect. */
import { create } from "zustand";
import { persist } from "zustand/middleware";
import { api, ApiError } from "@/lib/apiClient";
import type { Alert as BackendAlert } from "@shared/types/alerts";

export interface TravelAlert {
  id: string;
  type: "visa_change" | "flight_disruption" | "advisory" | "info";
  title: string;
  description: string;
  country?: string;
  severity: "low" | "medium" | "high";
  timestamp: string;
  read: boolean;
  source: "seed" | "system";
}

type SyncStatus = "idle" | "loading" | "synced" | "offline-pending" | "error";

type AlertMutation =
  | { kind: "markRead"; id: string }
  | { kind: "dismiss"; id: string };

interface AlertsState {
  alerts: TravelAlert[];
  syncStatus: SyncStatus;
  lastHydratedAt: number | null;
  pendingMutations: AlertMutation[];
  markRead: (id: string) => Promise<void>;
  dismissAlert: (id: string) => Promise<void>;
  hydrate: () => Promise<void>;
  drainPendingMutations: () => Promise<void>;
  unreadCount: () => number;
}

const CATEGORY_TO_TYPE: Record<BackendAlert["category"], TravelAlert["type"]> = {
  visa: "visa_change",
  flight: "flight_disruption",
  wallet: "info",
  advisory: "advisory",
  info: "info",
  system: "info",
};

function relativeTime(createdAt: number): string {
  const diff = Date.now() - createdAt;
  const min = Math.round(diff / 60_000);
  if (min < 1) return "just now";
  if (min < 60) return `${min} min ago`;
  const hr = Math.round(min / 60);
  if (hr < 24) return `${hr} hour${hr === 1 ? "" : "s"} ago`;
  const d = Math.round(hr / 24);
  if (d < 14) return `${d} day${d === 1 ? "" : "s"} ago`;
  return new Date(createdAt).toISOString().slice(0, 10);
}

function fromBackend(a: BackendAlert): TravelAlert {
  return {
    id: a.id,
    type: CATEGORY_TO_TYPE[a.category],
    title: a.title,
    description: a.message,
    severity: a.severity,
    timestamp: relativeTime(a.createdAt),
    read: a.read,
    source: a.source,
  };
}

/** Fallback seed used only when the backend has never been reached. Once
 *  hydrated, server data replaces this. Kept lean — three entries — so the
 *  cold-boot UI is not noisy. */
const fallbackSeed: TravelAlert[] = [
  {
    id: "seed-1",
    type: "info",
    title: "Sync pending",
    description: "Connecting to your GlobeID server…",
    severity: "low",
    timestamp: "now",
    read: true,
    source: "seed",
  },
];

export const useAlertsStore = create<AlertsState>()(
  persist(
    (set, get) => ({
      alerts: fallbackSeed,
      syncStatus: "idle",
      lastHydratedAt: null,
      pendingMutations: [],

      markRead: async (id) => {
        set((state) => ({
          alerts: state.alerts.map((a) => (a.id === id ? { ...a, read: true } : a)),
        }));
        try {
          await api.alerts.patch(id, { read: true });
          set((state) => ({
            syncStatus: state.pendingMutations.length > 0 ? "offline-pending" : "synced",
          }));
        } catch (e) {
          if (!(e instanceof ApiError) || e.status >= 500 || e.status === 0) {
            set((state) => ({
              syncStatus: "offline-pending",
              pendingMutations: [...state.pendingMutations, { kind: "markRead", id }],
            }));
            return;
          }
          // 4xx — surface but keep optimistic state (read=true is harmless if alert id is stale)
          set({ syncStatus: "error" });
        }
      },

      dismissAlert: async (id) => {
        const previous = get().alerts.find((a) => a.id === id);
        set((state) => ({ alerts: state.alerts.filter((a) => a.id !== id) }));
        try {
          await api.alerts.patch(id, { dismissed: true });
          set((state) => ({
            syncStatus: state.pendingMutations.length > 0 ? "offline-pending" : "synced",
          }));
        } catch (e) {
          if (!(e instanceof ApiError) || e.status >= 500 || e.status === 0) {
            set((state) => ({
              syncStatus: "offline-pending",
              pendingMutations: [...state.pendingMutations, { kind: "dismiss", id }],
            }));
            return;
          }
          if (previous) {
            set((state) => ({
              alerts: [previous, ...state.alerts],
              syncStatus: "error",
            }));
          }
        }
      },

      hydrate: async () => {
        set({ syncStatus: "loading" });
        try {
          const remote = await api.alerts.list();
          // Filter dismissed server-side already; double-check defensively.
          const live = remote.filter((a) => !a.dismissed).map(fromBackend);
          set({ alerts: live, syncStatus: "synced", lastHydratedAt: Date.now() });
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
        const remaining: AlertMutation[] = [];
        for (const m of queue) {
          try {
            if (m.kind === "markRead") await api.alerts.patch(m.id, { read: true });
            else await api.alerts.patch(m.id, { dismissed: true });
          } catch {
            remaining.push(m);
          }
        }
        set({
          pendingMutations: remaining,
          syncStatus: remaining.length === 0 ? "synced" : "offline-pending",
        });
      },

      unreadCount: () => get().alerts.filter((a) => !a.read).length,
    }),
    {
      name: "globe-alerts",
      version: 3,
      partialize: (state) => ({
        alerts: state.alerts,
        pendingMutations: state.pendingMutations,
        lastHydratedAt: state.lastHydratedAt,
      }),
    }
  )
);
