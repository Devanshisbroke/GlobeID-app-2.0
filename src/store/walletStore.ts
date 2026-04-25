import { create } from "zustand";
import { persist } from "zustand/middleware";

export interface WalletBalance {
  currency: string;
  symbol: string;
  amount: number;
  flag: string;
  rate: number; // rate to USD
}

export interface WalletTransaction {
  id: string;
  type: "payment" | "send" | "receive" | "convert" | "refund";
  description: string;
  merchant?: string;
  amount: number;
  currency: string;
  date: string;
  category: "transport" | "food" | "hotel" | "shopping" | "flight" | "transfer" | "entertainment";
  location?: string;
  country?: string;
  countryFlag?: string;
  icon: string;
}

interface WalletState {
  balances: WalletBalance[];
  transactions: WalletTransaction[];
  defaultCurrency: string;
  activeCountry: string | null;
  setDefaultCurrency: (c: string) => void;
  setActiveCountry: (c: string | null) => void;
  convertCurrency: (from: string, to: string, amount: number) => void;
  addTransaction: (tx: WalletTransaction) => void;
  deductBalance: (currency: string, amount: number) => void;
  addBalance: (currency: string, amount: number) => void;
}

const defaultBalances: WalletBalance[] = [
  { currency: "USD", symbol: "$", amount: 2150.0, flag: "🇺🇸", rate: 1 },
  { currency: "EUR", symbol: "€", amount: 780.5, flag: "🇪🇺", rate: 1.08 },
  { currency: "INR", symbol: "₹", amount: 45000, flag: "🇮🇳", rate: 0.012 },
  { currency: "SGD", symbol: "S$", amount: 1320, flag: "🇸🇬", rate: 0.74 },
  { currency: "JPY", symbol: "¥", amount: 85000, flag: "🇯🇵", rate: 0.0067 },
  { currency: "AED", symbol: "د.إ", amount: 3600, flag: "🇦🇪", rate: 0.27 },
];

const defaultTransactions: WalletTransaction[] = [
  { id: "tx1", type: "payment", description: "Airport Taxi", merchant: "Grab", amount: -18, currency: "SGD", date: "2025-03-07", category: "transport", location: "Changi Airport", country: "Singapore", countryFlag: "🇸🇬", icon: "Car" },
  { id: "tx2", type: "payment", description: "Hotel Booking", merchant: "Marina Bay Sands", amount: -450, currency: "SGD", date: "2025-03-06", category: "hotel", location: "Marina Bay", country: "Singapore", countryFlag: "🇸🇬", icon: "Building2" },
  { id: "tx3", type: "payment", description: "Restaurant Dinner", merchant: "Hawker Chan", amount: -12, currency: "SGD", date: "2025-03-06", category: "food", location: "Chinatown", country: "Singapore", countryFlag: "🇸🇬", icon: "UtensilsCrossed" },
  { id: "tx4", type: "payment", description: "Metro Ticket", merchant: "SMRT", amount: -2.5, currency: "SGD", date: "2025-03-05", category: "transport", location: "Orchard", country: "Singapore", countryFlag: "🇸🇬", icon: "Train" },
  { id: "tx5", type: "payment", description: "Flight Upgrade", merchant: "Singapore Airlines", amount: -320, currency: "USD", date: "2025-03-04", category: "flight", location: "In-flight", country: "Singapore", countryFlag: "🇸🇬", icon: "Plane" },
  { id: "tx6", type: "payment", description: "Duty Free Shopping", merchant: "DFS Galleria", amount: -89, currency: "USD", date: "2025-03-03", category: "shopping", location: "Terminal 3", country: "Singapore", countryFlag: "🇸🇬", icon: "ShoppingBag" },
  { id: "tx7", type: "receive", description: "Payment Received", amount: 500, currency: "USD", date: "2025-03-02", category: "transfer", icon: "ArrowDownLeft" },
  { id: "tx8", type: "payment", description: "Sushi Restaurant", merchant: "Sukiyabashi Jiro", amount: -8500, currency: "JPY", date: "2025-02-28", category: "food", location: "Ginza", country: "Japan", countryFlag: "🇯🇵", icon: "UtensilsCrossed" },
  { id: "tx9", type: "convert", description: "USD → EUR", amount: -200, currency: "USD", date: "2025-02-27", category: "transfer", icon: "RefreshCw" },
  { id: "tx10", type: "payment", description: "Uber Ride", merchant: "Uber", amount: -24, currency: "EUR", date: "2025-02-25", category: "transport", location: "Paris CDG", country: "France", countryFlag: "🇫🇷", icon: "Car" },
  { id: "tx11", type: "payment", description: "Theme Park Tickets", merchant: "Universal Studios", amount: -79, currency: "SGD", date: "2025-02-20", category: "entertainment", location: "Sentosa", country: "Singapore", countryFlag: "🇸🇬", icon: "Ticket" },
  { id: "tx12", type: "payment", description: "Street Food Market", merchant: "Chandni Chowk", amount: -850, currency: "INR", date: "2025-02-18", category: "food", location: "Old Delhi", country: "India", countryFlag: "🇮🇳", icon: "UtensilsCrossed" },
];

export const useWalletStore = create<WalletState>()(
  persist(
    (set) => ({
      balances: defaultBalances,
      transactions: defaultTransactions,
      defaultCurrency: "USD",
      activeCountry: null,
      setDefaultCurrency: (c) => set({ defaultCurrency: c }),
      setActiveCountry: (c) => set({ activeCountry: c }),
      convertCurrency: (from, to, amount) =>
        set((state) => {
          const fromBal = state.balances.find((b) => b.currency === from);
          const toBal = state.balances.find((b) => b.currency === to);
          if (!fromBal || !toBal || fromBal.amount < amount) return state;
          const usdAmount = amount * fromBal.rate;
          const converted = usdAmount / toBal.rate;
          const tx: WalletTransaction = {
            id: `tx-${Date.now()}`,
            type: "convert",
            description: `${from} → ${to}`,
            amount: -amount,
            currency: from,
            date: new Date().toISOString().split("T")[0],
            category: "transfer",
            icon: "RefreshCw",
          };
          return {
            balances: state.balances.map((b) => {
              if (b.currency === from) return { ...b, amount: b.amount - amount };
              if (b.currency === to) return { ...b, amount: b.amount + converted };
              return b;
            }),
            transactions: [tx, ...state.transactions],
          };
        }),
      addTransaction: (tx) => set((state) => ({ transactions: [tx, ...state.transactions] })),
      deductBalance: (currency, amount) =>
        set((state) => ({
          balances: state.balances.map((b) =>
            b.currency === currency ? { ...b, amount: Math.max(0, b.amount - amount) } : b
          ),
        })),
      addBalance: (currency, amount) =>
        set((state) => ({
          balances: state.balances.map((b) =>
            b.currency === currency ? { ...b, amount: b.amount + amount } : b
          ),
        })),
    }),
    { name: "globe-wallet" }
  )
);
