/**
 * Phase 8 — Copilot conversation history (closes deferred Phase 4.5 PR-B).
 *
 * Persists message history server-side via /copilot/respond + /copilot/history.
 * On app boot, hydrate() pulls the last N messages so the UI shows continuity
 * across reloads. The TravelCopilot component still owns the in-flight typing
 * indicator + currentTrip preview — this store only owns the canonical
 * message log.
 */
import { create } from "zustand";
import { persist } from "zustand/middleware";
import { api, ApiError } from "@/lib/apiClient";

export interface CopilotMessage {
  id: string;
  role: "user" | "assistant";
  content: string;
  createdAt: number;
}

export type CopilotSyncStatus = "idle" | "loading" | "synced" | "offline" | "error";

interface CopilotAction {
  type: string;
  payload: Record<string, unknown>;
}

interface CopilotState {
  messages: CopilotMessage[];
  syncStatus: CopilotSyncStatus;
  /** Append a local-only message (used for the welcome bubble + offline replies). */
  appendLocal: (m: CopilotMessage) => void;
  /** Send a prompt to the server and append both turns. Returns the action
   *  envelope (if any) so the UI can run client-side intent handlers. */
  sendPrompt: (prompt: string) => Promise<{ replyId: string; message: string; action: CopilotAction | null }>;
  /** Replace the whole log with what's on the server. */
  hydrate: () => Promise<void>;
  /** Clear local + server. */
  clear: () => Promise<void>;
}

export const useCopilotStore = create<CopilotState>()(
  persist(
    (set, get) => ({
      messages: [],
      syncStatus: "idle",

      appendLocal: (m) => set((s) => ({ messages: [...s.messages, m] })),

      sendPrompt: async (prompt) => {
        const userMsg: CopilotMessage = {
          id: crypto.randomUUID(),
          role: "user",
          content: prompt,
          createdAt: Date.now(),
        };
        // Optimistic insert.
        set((s) => ({ messages: [...s.messages, userMsg] }));

        try {
          const result = await api.copilot.respond(prompt);
          const assistantMsg: CopilotMessage = {
            id: result.reply.id,
            role: "assistant",
            content: result.reply.message,
            createdAt: Date.now(),
          };
          set((s) => ({ messages: [...s.messages, assistantMsg], syncStatus: "synced" }));
          return {
            replyId: result.reply.id,
            message: result.reply.message,
            action: (result.reply.action as CopilotAction | undefined) ?? null,
          };
        } catch (e) {
          // Network / 5xx → fall back to client-side intent so the UI
          // still feels responsive. The caller treats `action: generate_trip`
          // as a directive to run the local tripGenerator.
          if (!(e instanceof ApiError) || e.status >= 500 || e.status === 0) {
            set({ syncStatus: "offline" });
            return {
              replyId: crypto.randomUUID(),
              message: "(offline) Working from your device — server unreachable.",
              action: { type: "generate_trip", payload: { prompt } },
            };
          }
          set({ syncStatus: "error" });
          throw e;
        }
      },

      hydrate: async () => {
        set({ syncStatus: "loading" });
        try {
          const remote = await api.copilot.history();
          set({
            messages: remote.map((r) => ({
              id: r.id,
              role: r.role,
              content: r.content,
              createdAt: r.createdAt,
            })),
            syncStatus: "synced",
          });
        } catch {
          set({ syncStatus: "offline" });
        }
      },

      clear: async () => {
        set({ messages: [] });
        try {
          await api.copilot.clear();
          set({ syncStatus: "synced" });
        } catch {
          /* swallow — local cleared is enough */
          set({ syncStatus: "offline" });
        }
      },
    }),
    {
      name: "globe-copilot",
      version: 1,
      partialize: (state) => ({ messages: state.messages }),
    },
  ),
);
