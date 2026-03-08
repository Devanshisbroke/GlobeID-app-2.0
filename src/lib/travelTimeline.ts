import { getAirport, flightRoutes, type FlightRoute, type Airport } from "@/lib/airports";

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
  type: FlightRoute["type"];
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

const flightNumbers: Record<string, string> = {
  f1: "SQ 31",
  f2: "BA 178",
  f3: "AF 1681",
  f4: "EK 73",
  f5: "EK 510",
  f6: "AI 865",
  f7: "UA 23",
  f8: "NH 802",
};

const fullDates: Record<string, { full: string; year: number; month: string }> = {
  f1: { full: "2026-03-10", year: 2026, month: "Mar" },
  f2: { full: "2026-02-12", year: 2026, month: "Feb" },
  f3: { full: "2026-02-15", year: 2026, month: "Feb" },
  f4: { full: "2026-02-18", year: 2026, month: "Feb" },
  f5: { full: "2026-02-22", year: 2026, month: "Feb" },
  f6: { full: "2026-02-25", year: 2026, month: "Feb" },
  f7: { full: "2026-03-01", year: 2026, month: "Mar" },
  f8: { full: "2026-03-20", year: 2026, month: "Mar" },
};

/* ── Build timeline ── */
export function buildTimeline(): TimelineEntry[] {
  return flightRoutes
    .map((fr) => {
      const orig = getAirport(fr.from);
      const dest = getAirport(fr.to);
      if (!orig || !dest) return null;
      const d = fullDates[fr.id] ?? { full: fr.date ?? "", year: 2026, month: "Mar" };
      return {
        id: fr.id,
        originIata: fr.from,
        destinationIata: fr.to,
        originCity: orig.city,
        destinationCity: dest.city,
        originCountry: orig.country,
        destinationCountry: dest.country,
        date: d.full,
        year: d.year,
        month: d.month,
        distance: Math.round(haversine(orig, dest)),
        airline: fr.airline ?? "",
        flightNumber: flightNumbers[fr.id] ?? "",
        duration: fr.duration ?? "",
        continent: getContinent(dest.country),
        type: fr.type,
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
