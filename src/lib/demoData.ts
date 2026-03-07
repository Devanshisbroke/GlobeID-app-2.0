export const DEMO_MODE = true;

export const demoUser = {
  id: "usr-001",
  name: "Devansh",
  maskedName: "D***h",
  email: "devansh@globeid.io",
  avatar: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200&h=200&fit=crop&crop=face",
  identityLevel: "Verified" as const,
  identityScore: 92,
  countryFlags: ["🇮🇳", "🇺🇸", "🇦🇪", "🇸🇬"],
  memberSince: "2024",
  currentCountry: "United States",
  currentFlag: "🇺🇸",
};

export interface Document {
  id: string;
  type: "passport" | "visa" | "national_id";
  label: string;
  country: string;
  countryFlag: string;
  number: string;
  issueDate: string;
  expiryDate: string;
  status: "verified" | "pending" | "expired";
}

export const demoDocuments: Document[] = [
  {
    id: "doc-1",
    type: "passport",
    label: "Indian Passport",
    country: "India",
    countryFlag: "🇮🇳",
    number: "J•••••48",
    issueDate: "2022-03-15",
    expiryDate: "2032-03-14",
    status: "verified",
  },
  {
    id: "doc-2",
    type: "visa",
    label: "US B1/B2 Visa",
    country: "United States",
    countryFlag: "🇺🇸",
    number: "V•••••12",
    issueDate: "2023-06-01",
    expiryDate: "2033-05-31",
    status: "verified",
  },
  {
    id: "doc-3",
    type: "national_id",
    label: "Aadhaar Card",
    country: "India",
    countryFlag: "🇮🇳",
    number: "••••-••••-8945",
    issueDate: "2019-01-10",
    expiryDate: "N/A",
    status: "verified",
  },
  {
    id: "doc-4",
    type: "visa",
    label: "UAE Residence Visa",
    country: "UAE",
    countryFlag: "🇦🇪",
    number: "R•••••67",
    issueDate: "2024-01-20",
    expiryDate: "2027-01-19",
    status: "verified",
  },
];

export interface WalletBalance {
  currency: string;
  symbol: string;
  amount: number;
  flag: string;
}

export const demoBalances: WalletBalance[] = [
  { currency: "INR", symbol: "₹", amount: 24800, flag: "🇮🇳" },
  { currency: "USD", symbol: "$", amount: 2100, flag: "🇺🇸" },
  { currency: "CNY", symbol: "¥", amount: 5000, flag: "🇨🇳" },
  { currency: "AED", symbol: "د.إ", amount: 3400, flag: "🇦🇪" },
  { currency: "SGD", symbol: "S$", amount: 1850.75, flag: "🇸🇬" },
  { currency: "EUR", symbol: "€", amount: 1240.50, flag: "🇪🇺" },
];

export interface Transaction {
  id: string;
  type: "send" | "receive" | "convert" | "payment";
  description: string;
  amount: number;
  currency: string;
  date: string;
  category: "travel" | "food" | "transport" | "shopping" | "transfer";
  icon: string;
}

export const demoTransactions: Transaction[] = [
  { id: "tx-1", type: "payment", description: "Marina Bay Sands", amount: -580, currency: "SGD", date: "2026-03-06", category: "travel", icon: "🏨" },
  { id: "tx-2", type: "payment", description: "Grab Ride — Changi", amount: -24.5, currency: "SGD", date: "2026-03-06", category: "transport", icon: "🚗" },
  { id: "tx-3", type: "receive", description: "Refund — SQ Airlines", amount: 120, currency: "USD", date: "2026-03-05", category: "travel", icon: "✈️" },
  { id: "tx-4", type: "payment", description: "Din Tai Fung", amount: -42, currency: "SGD", date: "2026-03-05", category: "food", icon: "🍜" },
  { id: "tx-5", type: "convert", description: "USD → SGD", amount: -500, currency: "USD", date: "2026-03-04", category: "transfer", icon: "💱" },
  { id: "tx-6", type: "send", description: "To Priya M.", amount: -200, currency: "USD", date: "2026-03-03", category: "transfer", icon: "📤" },
  { id: "tx-7", type: "payment", description: "Uber — Downtown", amount: -18, currency: "SGD", date: "2026-03-03", category: "transport", icon: "🚗" },
  { id: "tx-8", type: "payment", description: "Uniqlo Orchard", amount: -89, currency: "SGD", date: "2026-03-02", category: "shopping", icon: "🛍️" },
  { id: "tx-9", type: "receive", description: "From Rahul S.", amount: 500, currency: "INR", date: "2026-03-01", category: "transfer", icon: "📥" },
  { id: "tx-10", type: "payment", description: "Careem — Dubai Mall", amount: -35, currency: "AED", date: "2026-02-28", category: "transport", icon: "🚗" },
];

export interface Booking {
  id: string;
  type: "flight" | "hotel";
  title: string;
  subtitle: string;
  date: string;
  status: "confirmed" | "upcoming" | "completed";
  code: string;
  details: Record<string, string>;
  image?: string;
}

export const demoBookings: Booking[] = [
  {
    id: "bk-1",
    type: "flight",
    title: "SFO → SIN",
    subtitle: "Singapore Airlines SQ31",
    date: "2026-03-10",
    status: "upcoming",
    code: "SQ31-AX7K",
    details: { departure: "10:35 AM", arrival: "6:50 PM +1", seat: "12A", class: "Business" },
  },
  {
    id: "bk-2",
    type: "flight",
    title: "SIN → BOM",
    subtitle: "Air India AI345",
    date: "2026-03-15",
    status: "upcoming",
    code: "AI345-BM2P",
    details: { departure: "2:15 PM", arrival: "5:30 PM", seat: "8F", class: "Economy Plus" },
  },
  {
    id: "bk-3",
    type: "hotel",
    title: "Marina Bay Sands",
    subtitle: "Singapore — Deluxe Room",
    date: "2026-03-10",
    status: "confirmed",
    code: "MBS-92847",
    details: { checkIn: "Mar 10", checkOut: "Mar 14", room: "4012", guests: "1" },
    image: "https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=400&h=250&fit=crop",
  },
  {
    id: "bk-4",
    type: "hotel",
    title: "Taj Mahal Palace",
    subtitle: "Mumbai — Heritage Suite",
    date: "2026-03-15",
    status: "upcoming",
    code: "TMP-38291",
    details: { checkIn: "Mar 15", checkOut: "Mar 18", room: "TBD", guests: "1" },
    image: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&h=250&fit=crop",
  },
];

export interface ActivityItem {
  id: string;
  type: "scan" | "travel" | "payment" | "security" | "booking";
  title: string;
  description: string;
  timestamp: string;
  icon: string;
}

export const demoActivity: ActivityItem[] = [
  { id: "act-1", type: "scan", title: "Passport Verified", description: "Indian passport scanned and stored", timestamp: "2 hours ago", icon: "🛂" },
  { id: "act-2", type: "payment", title: "Payment Sent", description: "₹24,800 received from Rahul", timestamp: "5 hours ago", icon: "💸" },
  { id: "act-3", type: "booking", title: "Hotel Booked", description: "Marina Bay Sands — Mar 10-14", timestamp: "Yesterday", icon: "🏨" },
  { id: "act-4", type: "travel", title: "Flight Confirmed", description: "SQ31 SFO→SIN Business", timestamp: "Yesterday", icon: "✈️" },
  { id: "act-5", type: "security", title: "Biometric Updated", description: "Face ID re-enrolled", timestamp: "2 days ago", icon: "🔐" },
  { id: "act-6", type: "payment", title: "Currency Converted", description: "$500 → S$670.50", timestamp: "3 days ago", icon: "💱" },
  { id: "act-7", type: "travel", title: "Ride Completed", description: "Grab — Changi to Marina Bay", timestamp: "3 days ago", icon: "🚗" },
  { id: "act-8", type: "booking", title: "Flight Booked", description: "AI345 SIN→BOM Economy Plus", timestamp: "4 days ago", icon: "✈️" },
  { id: "act-9", type: "payment", title: "Restaurant", description: "Din Tai Fung — S$42", timestamp: "4 days ago", icon: "🍜" },
  { id: "act-10", type: "scan", title: "Visa Verified", description: "US B1/B2 visa scanned", timestamp: "1 week ago", icon: "🛂" },
];

export const quickActions = [
  { id: "qa-1", label: "Scan Passport", icon: "🛂", route: "/identity", gradient: "from-primary to-neon-indigo" },
  { id: "qa-2", label: "Send Payment", icon: "💸", route: "/wallet", gradient: "from-neon-cyan to-neon-teal" },
  { id: "qa-3", label: "Book Flight", icon: "✈️", route: "/travel", gradient: "from-neon-indigo to-primary" },
  { id: "qa-4", label: "Book Hotel", icon: "🏨", route: "/travel", gradient: "from-neon-teal to-neon-cyan" },
  { id: "qa-5", label: "Request Ride", icon: "🚗", route: "/services", gradient: "from-amber-500 to-orange-600" },
  { id: "qa-6", label: "Order Food", icon: "🍽️", route: "/services", gradient: "from-rose-500 to-pink-600" },
  { id: "qa-7", label: "AI Assistant", icon: "✨", route: "", gradient: "from-violet-500 to-purple-600" },
];
