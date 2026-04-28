import { create } from "zustand";
import { persist } from "zustand/middleware";
import { api, ApiError } from "@/lib/apiClient";
import type {
  WalletBalance as ServerBalance,
  WalletTransaction as ServerTransaction,
  RecordTransactionRequest,
  ConvertRequest,
} from "@shared/types/wallet";

/**
 * Wallet store — Slice-A real-ledger edition.
 *
 * Source of truth is the backend. Local Zustand state is a hot read-cache
 * hydrated from `GET /wallet` and re-synced after every mutation. The
 * `persist` middleware keeps a snapshot in localStorage purely so the UI
 * has something to render before `hydrate()` resolves on cold launch.
 *
 * `recordTransaction()` and `convert()` always send a fresh
 * `idempotencyKey`, so retried requests (e.g. user double-taps "Pay" or
 * the network drops mid-flight and we resend) collapse onto a single
 * ledger row. The server is authoritative on insufficient-funds.
 */

export type WalletBalance = ServerBalance;

export type WalletTxType = ServerTransaction["type"];
export type WalletTxCategory = ServerTransaction["category"];
export type WalletTransaction = ServerTransaction;

interface WalletState {
  balances: WalletBalance[];
  transactions: WalletTransaction[];
  defaultCurrency: string;
  activeCountry: string | null;
  hydrated: boolean;
  /** Surfaced when the last mutation failed; UI can render an inline notice. */
  lastError: string | null;
  /** Loud reminder that the gateway is demo even though the ledger is real. */
  isDemoGateway: boolean;
  hydrate: () => Promise<void>;
  setDefaultCurrency: (c: string) => Promise<void>;
  setActiveCountry: (c: string | null) => Promise<void>;
  /** Append-only ledger write. Returns the canonical row + new balance. */
  recordTransaction: (req: Omit<RecordTransactionRequest, "idempotencyKey"> & { idempotencyKey?: string }) => Promise<WalletTransaction>;
  /** Two-leg currency conversion. Atomic on the server. */
  convert: (req: Omit<ConvertRequest, "idempotencyKey"> & { idempotencyKey?: string }) => Promise<{ debit: WalletTransaction; credit: WalletTransaction }>;
  /** Reset error after the UI has shown it. */
  clearError: () => void;
}

function newIdempotencyKey(): string {
  if (typeof crypto !== "undefined" && "randomUUID" in crypto) {
    return crypto.randomUUID();
  }
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 12)}`;
}

function errorMessage(e: unknown): string {
  if (e instanceof ApiError) return e.message;
  if (e instanceof Error) return e.message;
  return "Unknown wallet error";
}

const fallbackBalances: WalletBalance[] = [
  { currency: "USD", symbol: "$", amount: 0, flag: "🇺🇸", rate: 1 },
];

export const useWalletStore = create<WalletState>()(
  persist(
    (set, get) => ({
      balances: fallbackBalances,
      transactions: [],
      defaultCurrency: "USD",
      activeCountry: null,
      hydrated: false,
      lastError: null,
      isDemoGateway: true,

      hydrate: async () => {
        try {
          const snap = await api.wallet.snapshot();
          set({
            balances: snap.balances,
            transactions: snap.transactions,
            defaultCurrency: snap.state.defaultCurrency,
            activeCountry: snap.state.activeCountry,
            hydrated: true,
            lastError: null,
          });
        } catch (e) {
          // Soft-fail: keep persisted snapshot on screen, surface error.
          set({ hydrated: true, lastError: errorMessage(e) });
        }
      },

      setDefaultCurrency: async (c) => {
        set({ defaultCurrency: c });
        try {
          await api.wallet.updateState({ defaultCurrency: c });
        } catch (e) {
          set({ lastError: errorMessage(e) });
        }
      },

      setActiveCountry: async (c) => {
        // The wallet card sort and the country-aware UI both read this
        // synchronously — apply locally first, sync to server afterward.
        set({ activeCountry: c });
        try {
          await api.wallet.updateState({ activeCountry: c });
        } catch (e) {
          set({ lastError: errorMessage(e) });
        }
      },

      recordTransaction: async (req) => {
        const idempotencyKey = req.idempotencyKey ?? newIdempotencyKey();
        const fullReq: RecordTransactionRequest = { ...req, idempotencyKey };
        try {
          const res = await api.wallet.record(fullReq);
          set((state) => {
            const filtered = state.transactions.filter((t) => t.id !== res.transaction.id);
            const balances = state.balances.map((b) =>
              b.currency === res.balance.currency ? res.balance : b,
            );
            return {
              transactions: [res.transaction, ...filtered],
              balances,
              isDemoGateway: res.isDemoGateway,
              lastError: null,
            };
          });
          return res.transaction;
        } catch (e) {
          set({ lastError: errorMessage(e) });
          throw e;
        }
      },

      convert: async (req) => {
        const idempotencyKey = req.idempotencyKey ?? newIdempotencyKey();
        const fullReq: ConvertRequest = { ...req, idempotencyKey };
        try {
          const res = await api.wallet.convert(fullReq);
          set((state) => {
            const filtered = state.transactions.filter(
              (t) => t.id !== res.debit.id && t.id !== res.credit.id,
            );
            return {
              transactions: [res.credit, res.debit, ...filtered],
              balances: res.balances,
              lastError: null,
            };
          });
          return { debit: res.debit, credit: res.credit };
        } catch (e) {
          set({ lastError: errorMessage(e) });
          throw e;
        }
      },

      clearError: () => set({ lastError: null }),
    }),
    {
      name: "globe-wallet",
      // Only persist the read-cache, not the function refs or transient flags.
      partialize: (s) => ({
        balances: s.balances,
        transactions: s.transactions,
        defaultCurrency: s.defaultCurrency,
        activeCountry: s.activeCountry,
      }),
    },
  ),
);
