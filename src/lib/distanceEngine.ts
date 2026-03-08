import { getAirport } from "./airports";

/** Haversine distance in km */
export function haversineDistance(
  lat1: number, lng1: number,
  lat2: number, lng2: number
): number {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/** Distance between two IATA airports */
export function distanceBetween(fromIata: string, toIata: string): number {
  const a = getAirport(fromIata);
  const b = getAirport(toIata);
  if (!a || !b) return 0;
  return Math.round(haversineDistance(a.lat, a.lng, b.lat, b.lng));
}

/** Estimated flight duration string */
export function estimateDuration(distanceKm: number): string {
  const hours = distanceKm / 850; // avg speed
  const h = Math.floor(hours);
  const m = Math.round((hours - h) * 60);
  return `${h}h ${m}m`;
}

/** Total distance for a multi-stop journey */
export function totalJourneyDistance(iatas: string[]): number {
  let total = 0;
  for (let i = 0; i < iatas.length - 1; i++) {
    total += distanceBetween(iatas[i], iatas[i + 1]);
  }
  return total;
}

/** Unique countries for a list of IATA codes */
export function uniqueCountries(iatas: string[]): string[] {
  const countries = new Set<string>();
  iatas.forEach(code => {
    const apt = getAirport(code);
    if (apt) countries.add(apt.country);
  });
  return Array.from(countries);
}

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

export function uniqueContinents(iatas: string[]): string[] {
  const continents = new Set<string>();
  iatas.forEach(code => {
    const apt = getAirport(code);
    if (apt && continentMap[apt.country]) continents.add(continentMap[apt.country]);
  });
  return Array.from(continents);
}
