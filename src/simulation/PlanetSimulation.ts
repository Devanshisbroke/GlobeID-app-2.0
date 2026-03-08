import { airports, type Airport } from "@/lib/airports";

export interface SimulatedFlight {
  id: number;
  from: Airport;
  to: Airport;
  frequency: number; // flights per day
  passengers: number; // avg per flight
  continent: string;
}

export interface ContinentTrafficData {
  name: string;
  share: number; // 0-100
  flights: number;
  color: string;
}

const hubIatas = new Set(["ATL", "LHR", "DXB", "SIN", "HND", "CDG", "JFK", "LAX", "HKG", "PEK", "FRA", "ICN", "BKK", "ORD", "AMS", "IST", "DFW", "SYD"]);

const continentMap: Record<string, string> = {
  "United States": "North America", "Canada": "North America", "Mexico": "North America",
  "United Kingdom": "Europe", "France": "Europe", "Germany": "Europe", "Netherlands": "Europe",
  "Spain": "Europe", "Turkey": "Europe", "Switzerland": "Europe",
  "Singapore": "Asia", "Japan": "Asia", "China": "Asia", "South Korea": "Asia",
  "Thailand": "Asia", "India": "Asia", "Malaysia": "Asia",
  "UAE": "Middle East", "Qatar": "Middle East",
  "Australia": "Oceania", "New Zealand": "Oceania",
  "Brazil": "South America", "Colombia": "South America", "Peru": "South America",
  "South Africa": "Africa", "Egypt": "Africa", "Kenya": "Africa",
};

const continentColors: Record<string, string> = {
  "Asia": "hsl(200, 85%, 52%)",
  "Europe": "hsl(220, 80%, 56%)",
  "North America": "hsl(168, 65%, 42%)",
  "Middle East": "hsl(42, 92%, 56%)",
  "Oceania": "hsl(258, 60%, 62%)",
  "South America": "hsl(12, 80%, 58%)",
  "Africa": "hsl(25, 95%, 55%)",
};

function getContinent(country: string): string {
  return continentMap[country] ?? "Other";
}

let cachedFlights: SimulatedFlight[] | null = null;

export function generateSimulatedFlights(count = 200): SimulatedFlight[] {
  if (cachedFlights && cachedFlights.length === count) return cachedFlights;

  const hubs = airports.filter((a) => hubIatas.has(a.iata));
  const flights: SimulatedFlight[] = [];

  for (let i = 0; i < count; i++) {
    const useHub = Math.random() > 0.25;
    const from = useHub ? hubs[Math.floor(Math.random() * hubs.length)] : airports[Math.floor(Math.random() * airports.length)];
    let to = airports[Math.floor(Math.random() * airports.length)];
    while (to.iata === from.iata) {
      to = airports[Math.floor(Math.random() * airports.length)];
    }
    flights.push({
      id: i,
      from,
      to,
      frequency: Math.round(2 + Math.random() * 18),
      passengers: Math.round(120 + Math.random() * 280),
      continent: getContinent(from.country),
    });
  }
  cachedFlights = flights;
  return flights;
}

export function getContinentTraffic(): ContinentTrafficData[] {
  const flights = generateSimulatedFlights();
  const map = new Map<string, number>();
  flights.forEach((f) => {
    map.set(f.continent, (map.get(f.continent) ?? 0) + f.frequency);
  });
  const total = Array.from(map.values()).reduce((a, b) => a + b, 0);
  return Array.from(map.entries())
    .map(([name, count]) => ({
      name,
      share: Math.round((count / total) * 100),
      flights: count,
      color: continentColors[name] ?? "hsl(220, 10%, 50%)",
    }))
    .sort((a, b) => b.share - a.share);
}

export function getSimulationStats(speedMultiplier = 1) {
  const base = generateSimulatedFlights();
  const totalFreq = base.reduce((a, f) => a + f.frequency, 0);
  const totalPax = base.reduce((a, f) => a + f.passengers * f.frequency, 0);
  return {
    flightsSimulated: Math.round(totalFreq * speedMultiplier),
    passengersSimulated: Math.round(totalPax * speedMultiplier),
    routesActive: base.length,
  };
}

/** Get hour-of-day traffic multiplier (simulates morning/evening peaks) */
export function getTimeMultiplier(hour: number): number {
  // peaks at 8am and 6pm
  const morning = Math.exp(-Math.pow(hour - 8, 2) / 8);
  const evening = Math.exp(-Math.pow(hour - 18, 2) / 8);
  return 0.3 + 0.7 * Math.max(morning, evening);
}

export function getHourlyPattern(): { hour: number; multiplier: number }[] {
  return Array.from({ length: 24 }, (_, h) => ({ hour: h, multiplier: getTimeMultiplier(h) }));
}
