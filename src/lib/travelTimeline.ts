import { getAirport, type Airport } from "@/lib/airports";
import { useUserStore, type TravelRecord } from "@/store/userStore";

/* ── Timeline Entry ── */
export interface TimelineEntry {
  id: string;
  originIata: string;
  destinationIata: string;
  originCity: string;
  destinationCity: string;
  originCountry: string;
  destinationCountry: string;
  date: string;
  year: number;
  month: string;
  distance: number;
  airline: string;
  flightNumber: string;
  duration: string;
  continent: string;
  type: TravelRecord["type"];
  source: TravelRecord["source"];
}

/* ── Continent mapping ── */
const countryToContinent: Record<string, string> = {
  "United States": "North America",
  Canada: "North America",
  Mexico: "North America",
  "United Kingdom": "Europe",
  France: "Europe",
  Germany: "Europe",
  Netherlands: "Europe",
  Spain: "Europe",
  Turkey: "Europe",
  Switzerland: "Europe",
  Singapore: "Asia",
  Japan: "Asia",
  China: "Asia",
  "South Korea": "Asia",
  Thailand: "Asia",
  India: "Asia",
  Malaysia: "Asia",
  UAE: "Asia",
  Qatar: "Asia",
  Australia: "Oceania",
  "New Zealand": "Oceania",
  Brazil: "South America",
  Colombia: "South America",
  Peru: "South America",
  "South Africa": "Africa",
  Egypt: "Africa",
  Kenya: "Africa",
};

export function getContinent(country: string): string {
  return countryToContinent[country] ?? "Unknown";
}

/* ── Haversine distance (km) ── */
function haversine(a: Airport, b: Airport): number {
  const R = 6371;
  const dLat = ((b.lat - a.lat) * Math.PI) / 180;
  const dLng = ((b.lng - a.lng) * Math.PI) / 180;
  const x =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((a.lat * Math.PI) / 180) *
      Math.cos((b.lat * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(x), Math.sqrt(1 - x));
}

const MONTH_NAMES = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

function parseDate(date: string): { year: number; month: string } {
  // Canonical YYYY-MM-DD
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(date);
  if (m) {
    const year = Number(m[1]);
    const month = MONTH_NAMES[Number(m[2]) - 1] ?? "Jan";
    return { year, month };
  }
  // Fallback for any non-canonical date string
  const d = new Date(date);
  if (!Number.isNaN(d.getTime())) {
    return { year: d.getFullYear(), month: MONTH_NAMES[d.getMonth()] };
  }
  return { year: 2026, month: "Mar" };
}

/* ── Build timeline ── */
/**
 * Builds timeline entries from the user's travel history. If `records`
 * is omitted, reads the current snapshot from `useUserStore`.
 */
export function buildTimeline(records?: TravelRecord[]): TimelineEntry[] {
  const source = records ?? useUserStore.getState().travelHistory;
  return source
    .map((r) => {
      const orig = getAirport(r.from);
      const dest = getAirport(r.to);
      if (!orig || !dest) return null;
      const { year, month } = parseDate(r.date);
      return {
        id: r.id,
        originIata: r.from,
        destinationIata: r.to,
        originCity: orig.city,
        destinationCity: dest.city,
        originCountry: orig.country,
        destinationCountry: dest.country,
        date: r.date,
        year,
        month,
        distance: Math.round(haversine(orig, dest)),
        airline: r.airline,
        flightNumber: r.flightNumber ?? "",
        duration: r.duration,
        continent: getContinent(dest.country),
        type: r.type,
        source: r.source,
      } as TimelineEntry;
    })
    .filter(Boolean) as TimelineEntry[];
}

/* ── Stats ── */
export interface TimelineStats {
  totalCountries: number;
  totalFlights: number;
  totalDistance: number;
  longestFlight: TimelineEntry | null;
  continents: { name: string; countries: string[]; count: number }[];
}

export function computeStats(entries: TimelineEntry[]): TimelineStats {
  const countries = new Set<string>();
  const continentMap = new Map<string, Set<string>>();
  let longest: TimelineEntry | null = null;
  let totalDist = 0;

  for (const e of entries) {
    countries.add(e.destinationCountry);
    countries.add(e.originCountry);
    totalDist += e.distance;
    if (!longest || e.distance > longest.distance) longest = e;
    const c = getContinent(e.destinationCountry);
    if (!continentMap.has(c)) continentMap.set(c, new Set());
    continentMap.get(c)!.add(e.destinationCountry);
  }

  const allContinents = ["Asia", "Europe", "North America", "South America", "Oceania", "Africa"];
  const continents = allContinents.map((name) => {
    const set = continentMap.get(name);
    return { name, countries: set ? Array.from(set) : [], count: set?.size ?? 0 };
  });

  return {
    totalCountries: countries.size,
    totalFlights: entries.length,
    totalDistance: totalDist,
    longestFlight: longest,
    continents,
  };
}

/* ── Achievements ── */
export interface Achievement {
  id: string;
  title: string;
  description: string;
  icon: string;
  unlocked: boolean;
  gradient: string;
}

export function computeAchievements(stats: TimelineStats): Achievement[] {
  return [
    {
      id: "first-intl",
      title: "First International Flight",
      description: "Completed your first international trip",
      icon: "Plane",
      unlocked: stats.totalFlights >= 1,
      gradient: "bg-gradient-ocean",
    },
    {
      id: "5-countries",
      title: "5 Countries Visited",
      description: "Explored 5 different countries",
      icon: "Globe",
      unlocked: stats.totalCountries >= 5,
      gradient: "bg-gradient-forest",
    },
    {
      id: "10-countries",
      title: "10 Countries Visited",
      description: "Reached 10 unique countries",
      icon: "Map",
      unlocked: stats.totalCountries >= 10,
      gradient: "bg-gradient-cosmic",
    },
    {
      id: "50k-km",
      title: "50,000 KM Travelled",
      description: "Flew over 50,000 kilometres total",
      icon: "Route",
      unlocked: stats.totalDistance >= 50000,
      gradient: "bg-gradient-sunset",
    },
    {
      id: "100k-km",
      title: "100,000 KM Travelled",
      description: "Flew over 100,000 kilometres total",
      icon: "Zap",
      unlocked: stats.totalDistance >= 100000,
      gradient: "bg-gradient-aurora",
    },
    {
      id: "3-continents",
      title: "3 Continents Visited",
      description: "Set foot on 3 different continents",
      icon: "Earth",
      unlocked: stats.continents.filter((c) => c.count > 0).length >= 3,
      gradient: "bg-gradient-tropical",
    },
    {
      id: "5-continents",
      title: "5 Continents Visited",
      description: "A true global traveler",
      icon: "Award",
      unlocked: stats.continents.filter((c) => c.count > 0).length >= 5,
      gradient: "bg-gradient-magenta",
    },
  ];
}
