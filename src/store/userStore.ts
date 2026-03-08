import { create } from "zustand";
import { type FlightRoute } from "@/lib/airports";

export interface TravelRecord {
  id: string;
  from: string; // IATA
  to: string;   // IATA
  date: string;
  airline: string;
  duration: string;
  type: FlightRoute["type"];
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

const defaultTravelHistory: TravelRecord[] = [
  { id: "tr-1", from: "SFO", to: "SIN", date: "2026-03-10", airline: "Singapore Airlines", duration: "18h 15m", type: "upcoming" },
  { id: "tr-2", from: "SIN", to: "BOM", date: "2026-03-15", airline: "Air India", duration: "5h 30m", type: "upcoming" },
  { id: "tr-3", from: "JFK", to: "LHR", date: "2026-02-12", airline: "British Airways", duration: "7h 10m", type: "past" },
  { id: "tr-4", from: "LHR", to: "CDG", date: "2026-02-15", airline: "Air France", duration: "1h 20m", type: "past" },
  { id: "tr-5", from: "CDG", to: "DXB", date: "2026-02-18", airline: "Emirates", duration: "6h 40m", type: "past" },
  { id: "tr-6", from: "DEL", to: "BOM", date: "2026-02-25", airline: "Air India", duration: "2h 10m", type: "past" },
  { id: "tr-7", from: "SIN", to: "NRT", date: "2026-03-20", airline: "ANA", duration: "6h 50m", type: "upcoming" },
];

const defaultDocuments: TravelDocument[] = [
  { id: "td-1", type: "passport", label: "Indian Passport", country: "India", countryFlag: "🇮🇳", number: "P•••••48", issueDate: "2022-03-15", expiryDate: "2032-03-14", status: "active" },
  { id: "td-2", type: "visa", label: "US B1/B2 Visa", country: "United States", countryFlag: "🇺🇸", number: "V•••••12", issueDate: "2023-06-01", expiryDate: "2033-05-31", status: "active" },
  { id: "td-3", type: "visa", label: "UAE Residence Visa", country: "UAE", countryFlag: "🇦🇪", number: "R•••••67", issueDate: "2024-01-20", expiryDate: "2027-01-19", status: "active" },
  { id: "td-4", type: "boarding_pass", label: "SQ31 — SFO→SIN", country: "Singapore", countryFlag: "🇸🇬", number: "SQ31-AX7K", issueDate: "2026-03-08", expiryDate: "2026-03-10", status: "active" },
  { id: "td-5", type: "travel_insurance", label: "World Nomads Policy", country: "Global", countryFlag: "🌐", number: "WN-8827341", issueDate: "2026-03-01", expiryDate: "2026-06-01", status: "active" },
];

export const useUserStore = create<UserState>((set) => ({
  profile: defaultProfile,
  travelHistory: defaultTravelHistory,
  documents: defaultDocuments,
  setUser: (profile) => set((state) => ({ profile: { ...state.profile, ...profile } })),
  updateProfile: (updates) => set((state) => ({ profile: { ...state.profile, ...updates } })),
  addTravelRecord: (record) => set((state) => ({ travelHistory: [record, ...state.travelHistory] })),
  addDocument: (doc) => set((state) => ({ documents: [...state.documents, doc] })),
  removeDocument: (id) => set((state) => ({ documents: state.documents.filter((d) => d.id !== id) })),
}));
