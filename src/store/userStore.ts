import { create } from "zustand";
import { persist } from "zustand/middleware";
import { getAirport } from "@/lib/airports";

/**
 * TravelRecord is the canonical shape for any flight in the user's
 * journey — past, current, upcoming, or planner-derived. It replaces
 * the previous static `flightRoutes` array in `lib/airports.ts` so
 * the Map, Timeline, Services, and Wallet all read from one source.
 */
export interface TravelRecord {
  id: string;
  from: string; // IATA
  to: string;   // IATA
  date: string; // YYYY-MM-DD canonical
  airline: string;
  duration: string;
  type: "upcoming" | "past" | "current";
  /** Optional carrier code, e.g. "SQ 31" — used by the timeline. */
  flightNumber?: string;
  /** "history" = seeded or actual past trip; "planner" = added via Trip Planner / Copilot. */
  source: "history" | "planner";
}

export interface TravelDocument {
  id: string;
  type: "passport" | "visa" | "boarding_pass" | "travel_insurance";
  label: string;
  country: string;
  countryFlag: string;
  number: string;
  issueDate: string;
  expiryDate: string;
  status: "active" | "expired" | "pending";
}

export interface UserProfile {
  userId: string;
  name: string;
  passportNumber: string;
  nationality: string;
  nationalityFlag: string;
  verifiedStatus: "verified" | "pending" | "unverified";
  avatarUrl: string;
  email: string;
  memberSince: string;
  identityScore: number;
}

interface UserState {
  profile: UserProfile;
  travelHistory: TravelRecord[];
  documents: TravelDocument[];
  setUser: (profile: Partial<UserProfile>) => void;
  updateProfile: (updates: Partial<UserProfile>) => void;
  addTravelRecord: (record: TravelRecord) => void;
  addTravelRecords: (records: TravelRecord[]) => void;
  removeTravelRecord: (id: string) => void;
  addDocument: (doc: TravelDocument) => void;
  removeDocument: (id: string) => void;
}

const defaultProfile: UserProfile = {
  userId: "usr-001",
  name: "Devansh Barai",
  passportNumber: "P•••••48",
  nationality: "India",
  nationalityFlag: "🇮🇳",
  verifiedStatus: "verified",
  avatarUrl: "",
  email: "devansh@globeid.io",
  memberSince: "2024",
  identityScore: 92,
};

/**
 * Seed records form a coherent journey arc:
 *   past loop  : JFK → LHR → CDG → DXB → DEL → BOM → SFO
 *   upcoming   : SFO → SIN  (SQ 31 boarding-pass demo)
 *   upcoming   : SIN → NRT  (next leg)
 * Identical to the previous `flightRoutes` set so the Map renders
 * the same arcs after the unification.
 */
const defaultTravelHistory: TravelRecord[] = [
  { id: "tr-f1", from: "SFO", to: "SIN", date: "2026-03-10", airline: "Singapore Airlines", duration: "18h 15m", type: "upcoming", flightNumber: "SQ 31",  source: "history" },
  { id: "tr-f2", from: "JFK", to: "LHR", date: "2026-02-12", airline: "British Airways",   duration: "7h 10m",  type: "past",     flightNumber: "BA 178", source: "history" },
  { id: "tr-f3", from: "LHR", to: "CDG", date: "2026-02-15", airline: "Air France",        duration: "1h 20m",  type: "past",     flightNumber: "AF 1681",source: "history" },
  { id: "tr-f4", from: "CDG", to: "DXB", date: "2026-02-18", airline: "Emirates",          duration: "6h 40m",  type: "past",     flightNumber: "EK 73",  source: "history" },
  { id: "tr-f5", from: "DXB", to: "DEL", date: "2026-02-22", airline: "Emirates",          duration: "3h 30m",  type: "past",     flightNumber: "EK 510", source: "history" },
  { id: "tr-f6", from: "DEL", to: "BOM", date: "2026-02-25", airline: "Air India",         duration: "2h 10m",  type: "past",     flightNumber: "AI 865", source: "history" },
  { id: "tr-f7", from: "BOM", to: "SFO", date: "2026-03-01", airline: "United Airlines",   duration: "17h 45m", type: "past",     flightNumber: "UA 23",  source: "history" },
  { id: "tr-f8", from: "SIN", to: "NRT", date: "2026-03-20", airline: "ANA",               duration: "6h 50m",  type: "upcoming", flightNumber: "NH 802", source: "history" },
];

const defaultDocuments: TravelDocument[] = [
  { id: "td-1", type: "passport", label: "Indian Passport", country: "India", countryFlag: "🇮🇳", number: "P•••••48", issueDate: "2022-03-15", expiryDate: "2032-03-14", status: "active" },
  { id: "td-2", type: "visa", label: "US B1/B2 Visa", country: "United States", countryFlag: "🇺🇸", number: "V•••••12", issueDate: "2023-06-01", expiryDate: "2033-05-31", status: "active" },
  { id: "td-3", type: "visa", label: "UAE Residence Visa", country: "UAE", countryFlag: "🇦🇪", number: "R•••••67", issueDate: "2024-01-20", expiryDate: "2027-01-19", status: "active" },
  { id: "td-4", type: "boarding_pass", label: "SQ31 — SFO→SIN", country: "Singapore", countryFlag: "🇸🇬", number: "SQ31-AX7K", issueDate: "2026-03-08", expiryDate: "2026-03-10", status: "active" },
  { id: "td-5", type: "travel_insurance", label: "World Nomads Policy", country: "Global", countryFlag: "🌐", number: "WN-8827341", issueDate: "2026-03-01", expiryDate: "2026-06-01", status: "active" },
];

export const useUserStore = create<UserState>()(
  persist(
    (set) => ({
      profile: defaultProfile,
      travelHistory: defaultTravelHistory,
      documents: defaultDocuments,
      setUser: (profile) => set((state) => ({ profile: { ...state.profile, ...profile } })),
      updateProfile: (updates) => set((state) => ({ profile: { ...state.profile, ...updates } })),
      addTravelRecord: (record) => set((state) => ({ travelHistory: [record, ...state.travelHistory] })),
      addTravelRecords: (records) =>
        set((state) => {
          const existing = new Set(state.travelHistory.map((r) => r.id));
          const fresh = records.filter((r) => !existing.has(r.id));
          return { travelHistory: [...fresh, ...state.travelHistory] };
        }),
      removeTravelRecord: (id) =>
        set((state) => ({ travelHistory: state.travelHistory.filter((r) => r.id !== id) })),
      addDocument: (doc) => set((state) => ({ documents: [...state.documents, doc] })),
      removeDocument: (id) => set((state) => ({ documents: state.documents.filter((d) => d.id !== id) })),
    }),
    {
      name: "globe-user",
      version: 1,
    }
  )
);

/* ── Derived selectors (work in or out of React) ── */

/** Countries the user has been to (origin + destination of past trips). */
export function selectVisitedCountries(records: TravelRecord[]): string[] {
  const set = new Set<string>();
  for (const r of records) {
    if (r.type !== "past") continue;
    const fromApt = getAirport(r.from);
    const toApt = getAirport(r.to);
    if (fromApt) set.add(fromApt.country);
    if (toApt) set.add(toApt.country);
  }
  return Array.from(set);
}

/** Countries the user has upcoming trips to. */
export function selectUpcomingCountries(records: TravelRecord[]): string[] {
  const set = new Set<string>();
  for (const r of records) {
    if (r.type !== "upcoming" && r.type !== "current") continue;
    const toApt = getAirport(r.to);
    if (toApt) set.add(toApt.country);
  }
  return Array.from(set);
}

/** Most recent upcoming trip — used by location detection + boarding-pass card. */
export function selectNextUpcoming(records: TravelRecord[]): TravelRecord | undefined {
  return records
    .filter((r) => r.type === "upcoming" || r.type === "current")
    .slice()
    .sort((a, b) => a.date.localeCompare(b.date))[0];
}

const MONTH_SHORT = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

/** Format a YYYY-MM-DD canonical date as "Mar 10" for compact display. */
export function formatTripDate(date: string): string {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(date);
  if (m) {
    const month = MONTH_SHORT[Number(m[2]) - 1];
    const day = Number(m[3]);
    if (month) return `${month} ${day}`;
  }
  return date;
}

/** Best-effort country-name → flag mapping for the airports we ship. */
const COUNTRY_FLAGS: Record<string, string> = {
  "United States": "🇺🇸",
  "United Kingdom": "🇬🇧",
  "Canada": "🇨🇦",
  "Mexico": "🇲🇽",
  "France": "🇫🇷",
  "Germany": "🇩🇪",
  "Netherlands": "🇳🇱",
  "Spain": "🇪🇸",
  "Turkey": "🇹🇷",
  "Switzerland": "🇨🇭",
  "Singapore": "🇸🇬",
  "Japan": "🇯🇵",
  "China": "🇨🇳",
  "South Korea": "🇰🇷",
  "Thailand": "🇹🇭",
  "India": "🇮🇳",
  "UAE": "🇦🇪",
  "United Arab Emirates": "🇦🇪",
  "Australia": "🇦🇺",
  "Brazil": "🇧🇷",
  "Italy": "🇮🇹",
  "Indonesia": "🇮🇩",
  "Malaysia": "🇲🇾",
};

export function getCountryFlag(country: string): string {
  return COUNTRY_FLAGS[country] ?? "🏳️";
}

export interface CurrentLocation {
  country: string;
  countryFlag: string;
  city: string;
  iata: string;
}

/**
 * Resolve where the user currently *is* based on travel history.
 *  1. Active "current" trip → its destination
 *  2. Most recent past trip → its destination
 *  3. Fallback: profile nationality (caller can pass it in)
 */
export function selectCurrentLocation(
  records: TravelRecord[],
  fallback?: { country: string; city?: string; iata?: string }
): CurrentLocation {
  const current = records.find((r) => r.type === "current");
  const candidate =
    current ??
    records
      .filter((r) => r.type === "past")
      .slice()
      .sort((a, b) => b.date.localeCompare(a.date))[0];
  if (candidate) {
    const apt = getAirport(candidate.to);
    if (apt) {
      return {
        country: apt.country,
        countryFlag: getCountryFlag(apt.country),
        city: apt.city,
        iata: apt.iata,
      };
    }
  }
  return {
    country: fallback?.country ?? "Singapore",
    countryFlag: getCountryFlag(fallback?.country ?? "Singapore"),
    city: fallback?.city ?? fallback?.country ?? "Singapore",
    iata: fallback?.iata ?? "SIN",
  };
}
