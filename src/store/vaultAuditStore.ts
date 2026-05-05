import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";

/**
 * Vault audit log (BACKLOG P 175).
 *
 * Records who accessed the vault and when, so the user has visibility
 * into their own access history (especially valuable on shared/family
 * devices). Capped at the last 100 events to keep persistence small.
 *
 * Events are append-only from the user's perspective (no `delete`),
 * but a `clear` admin action is exposed for the security settings
 * screen (will require biometric re-confirm in a follow-up).
 */

export type AuditEventKind =
  | "unlock"
  | "unlock_failed"
  | "view_doc"
  | "delete_doc"
  | "export_doc"
  | "share_doc"
  | "auto_lock";

export interface AuditEvent {
  id: string;
  ts: number;
  kind: AuditEventKind;
  /** Optional document ID involved (omit for unlock/auto_lock). */
  docId?: string;
  /** Optional caller-supplied label (e.g. doc kind). */
  label?: string;
  /** Free-form note (e.g. "biometric ok" / "passcode fallback"). */
  note?: string;
}

interface VaultAuditState {
  events: AuditEvent[];
  log: (e: Omit<AuditEvent, "id" | "ts"> & { ts?: number; id?: string }) => void;
  clear: () => void;
}

const MAX_EVENTS = 100;

let counter = 0;
function nextId(): string {
  counter += 1;
  return `${Date.now().toString(36)}-${counter.toString(36)}`;
}

export const useVaultAuditStore = create<VaultAuditState>()(
  persist(
    (set) => ({
      events: [],
      log: (e) =>
        set((s) => {
          const evt: AuditEvent = {
            id: e.id ?? nextId(),
            ts: e.ts ?? Date.now(),
            kind: e.kind,
            docId: e.docId,
            label: e.label,
            note: e.note,
          };
          const next = [evt, ...s.events];
          if (next.length > MAX_EVENTS) next.length = MAX_EVENTS;
          return { events: next };
        }),
      clear: () => set({ events: [] }),
    }),
    {
      name: "globeid:vaultAudit",
      storage: createJSONStorage(() => localStorage),
    },
  ),
);
