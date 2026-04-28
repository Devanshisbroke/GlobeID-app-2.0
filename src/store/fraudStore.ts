import { create } from "zustand";
import { persist } from "zustand/middleware";
import { api, ApiError } from "@/lib/apiClient";
import type { FraudFinding, FraudScanResponse } from "@shared/types/fraud";

interface FraudState {
  findings: FraudFinding[];
  scanned: number;
  lastScan: { alertsCreated: number; alertsDuplicate: number; at: string } | null;
  hydrated: boolean;
  lastError: string | null;
  refresh: () => Promise<void>;
  runScan: () => Promise<FraudScanResponse | null>;
}

function errorMessage(e: unknown): string {
  if (e instanceof ApiError) return e.message;
  if (e instanceof Error) return e.message;
  return "Unknown fraud error";
}

export const useFraudStore = create<FraudState>()(
  persist(
    (set) => ({
      findings: [],
      scanned: 0,
      lastScan: null,
      hydrated: false,
      lastError: null,

      refresh: async () => {
        try {
          const r = await api.fraud.findings();
          set({ findings: r.findings, scanned: r.scanned, hydrated: true, lastError: null });
        } catch (e) {
          set({ hydrated: true, lastError: errorMessage(e) });
        }
      },

      runScan: async () => {
        try {
          const r = await api.fraud.scan();
          set({
            findings: r.findings,
            scanned: r.scanned,
            lastScan: {
              alertsCreated: r.alertsCreated,
              alertsDuplicate: r.alertsDuplicate,
              at: new Date().toISOString(),
            },
            lastError: null,
          });
          return r;
        } catch (e) {
          set({ lastError: errorMessage(e) });
          return null;
        }
      },
    }),
    {
      name: "globe-fraud.v1",
      partialize: (s) => ({ findings: s.findings, scanned: s.scanned, lastScan: s.lastScan }),
    },
  ),
);
