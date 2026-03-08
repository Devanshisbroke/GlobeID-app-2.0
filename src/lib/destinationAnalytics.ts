import { airports, type Airport } from "./airports";

export interface DestinationData {
  iata: string;
  city: string;
  country: string;
  popularity: number; // 0-100
  continent: string;
  growth: number; // % YoY
  monthlyTraffic: number[]; // 12 months
  isHub: boolean;
}

const continentMap: Record<string, string> = {
  "United States": "North America", "Canada": "North America", "Mexico": "North America",
  "United Kingdom": "Europe", "France": "Europe", "Germany": "Europe", "Netherlands": "Europe",
  "Spain": "Europe", "Turkey": "Europe", "Switzerland": "Europe",
  "Singapore": "Asia", "Japan": "Asia", "China": "Asia", "South Korea": "Asia",
  "Thailand": "Asia", "India": "Asia", "UAE": "Middle East",
  "Australia": "Oceania", "New Zealand": "Oceania",
  "Brazil": "South America", "Colombia": "South America", "Peru": "South America",
  "South Africa": "Africa", "Egypt": "Africa", "Kenya": "Africa",
};

const hubIatas = new Set(["ATL", "LHR", "DXB", "SIN", "HND", "CDG", "JFK", "LAX", "HKG", "PEK", "FRA", "ICN", "BKK", "ORD"]);

function generateMonthly(): number[] {
  const base = 40 + Math.random() * 40;
  return Array.from({ length: 12 }, (_, m) => {
    const seasonal = Math.sin(((m - 3) / 12) * Math.PI * 2) * 15;
    return Math.round(base + seasonal + (Math.random() - 0.5) * 10);
  });
}

export const destinations: DestinationData[] = airports.map((a) => ({
  iata: a.iata,
  city: a.city,
  country: a.country,
  popularity: Math.round(hubIatas.has(a.iata) ? 80 + Math.random() * 20 : 40 + Math.random() * 45),
  continent: continentMap[a.country] ?? "Other",
  growth: Math.round((Math.random() * 30 - 5) * 10) / 10,
  monthlyTraffic: generateMonthly(),
  isHub: hubIatas.has(a.iata),
})).sort((a, b) => b.popularity - a.popularity);

export function getTopDestinations(n = 10): DestinationData[] {
  return destinations.slice(0, n);
}

export function getByContinent(continent: string): DestinationData[] {
  return destinations.filter((d) => d.continent === continent);
}

export function getFastestGrowing(n = 5): DestinationData[] {
  return [...destinations].sort((a, b) => b.growth - a.growth).slice(0, n);
}

export function getHubs(): DestinationData[] {
  return destinations.filter((d) => d.isHub);
}

export interface GlobalStats {
  totalFlightsToday: number;
  totalPassengers: number;
  totalRoutes: number;
  topRoute: string;
  mostPopularCity: string;
}

export function getGlobalStats(): GlobalStats {
  return {
    totalFlightsToday: 118_294,
    totalPassengers: 12_847_000,
    totalRoutes: 67_432,
    topRoute: "LHR → JFK",
    mostPopularCity: destinations[0]?.city ?? "London",
  };
}

/** Generate global flight routes for visualization */
export interface GlobalRoute {
  from: string;
  to: string;
  traffic: number; // 0-1 intensity
}

export function generateGlobalRoutes(count = 80): GlobalRoute[] {
  const hubs = airports.filter((a) => hubIatas.has(a.iata));
  const routes: GlobalRoute[] = [];

  for (let i = 0; i < count; i++) {
    const fromPool = Math.random() > 0.3 ? hubs : airports;
    const toPool = Math.random() > 0.3 ? hubs : airports;
    const from = fromPool[Math.floor(Math.random() * fromPool.length)];
    let to = toPool[Math.floor(Math.random() * toPool.length)];
    while (to.iata === from.iata) {
      to = toPool[Math.floor(Math.random() * toPool.length)];
    }
    routes.push({ from: from.iata, to: to.iata, traffic: 0.3 + Math.random() * 0.7 });
  }
  return routes;
}
