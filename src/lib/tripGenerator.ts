import { airports, type Airport } from "./airports";
import { haversineDistance } from "./distanceEngine";

// ── Region definitions ──
const regionAirports: Record<string, string[]> = {
  asia: ["SIN", "NRT", "HND", "HKG", "PVG", "PEK", "ICN", "BKK", "DEL", "BOM", "KUL"],
  europe: ["LHR", "CDG", "FRA", "AMS", "MAD", "IST", "ZRH"],
  middle_east: ["DXB", "AUH", "DOH"],
  north_america: ["SFO", "LAX", "JFK", "ORD", "MIA", "DFW", "SEA", "YYZ"],
  south_america: ["GRU", "BOG", "LIM"],
  oceania: ["SYD", "MEL", "AKL"],
  africa: ["JNB", "CAI", "NBO"],
};

const styleWeights: Record<string, Record<string, number>> = {
  luxury: { DXB: 3, SIN: 3, CDG: 2, LHR: 2, NRT: 2, ZRH: 2, AUH: 2, DOH: 2 },
  backpacking: { BKK: 3, KUL: 3, DEL: 2, BOG: 2, LIM: 2, NBO: 2, BOM: 2 },
  business: { LHR: 3, JFK: 3, SIN: 3, HKG: 3, FRA: 2, NRT: 2, ORD: 2 },
  adventure: { NBO: 3, AKL: 3, BOG: 2, LIM: 2, ICN: 2, MEL: 2, CUN: 2 },
};

export interface GeneratedStop {
  iata: string;
  city: string;
  country: string;
  days: number;
}

export interface GeneratedTrip {
  name: string;
  stops: GeneratedStop[];
  totalDays: number;
  style: string;
}

// ── Presets ──
export const tripPresets: { id: string; label: string; prompt: string; icon: string }[] = [
  { id: "world", label: "World Tour", prompt: "Round the world trip 21 days", icon: "🌍" },
  { id: "islands", label: "Island Hopper", prompt: "Southeast Asia island trip 10 days", icon: "🏝️" },
  { id: "capitals", label: "European Capitals", prompt: "Europe capitals tour 14 days", icon: "🏰" },
  { id: "food", label: "Asian Food Tour", prompt: "Asia food trip 12 days", icon: "🍜" },
];

// ── Prompt parser ──
function parsePrompt(prompt: string): { regions: string[]; days: number; style: string } {
  const lower = prompt.toLowerCase();
  const regions: string[] = [];

  if (/asia|asian|southeast|east/i.test(lower)) regions.push("asia");
  if (/europe|european/i.test(lower)) regions.push("europe");
  if (/middle east|dubai|gulf/i.test(lower)) regions.push("middle_east");
  if (/america|usa|us |canada|mexico/i.test(lower)) regions.push("north_america");
  if (/south america|latin/i.test(lower)) regions.push("south_america");
  if (/australia|oceania|new zealand/i.test(lower)) regions.push("oceania");
  if (/africa/i.test(lower)) regions.push("africa");
  if (/world|round the world|global/i.test(lower)) {
    regions.push("asia", "europe", "north_america", "middle_east");
  }
  if (regions.length === 0) regions.push("europe", "asia");

  const dayMatch = lower.match(/(\d+)\s*day/);
  const weekMatch = lower.match(/(\d+)\s*week/);
  let days = dayMatch ? parseInt(dayMatch[1]) : weekMatch ? parseInt(weekMatch[1]) * 7 : 10;
  days = Math.max(3, Math.min(days, 60));

  let style = "vacation";
  if (/luxury|premium|5.star/i.test(lower)) style = "luxury";
  else if (/backpack|budget|cheap/i.test(lower)) style = "backpacking";
  else if (/business|corporate|work/i.test(lower)) style = "business";
  else if (/adventure|trek|hik/i.test(lower)) style = "adventure";
  else if (/food|culinary|eat/i.test(lower)) style = "adventure";

  return { regions, days, style };
}

// ── Generator ──
export function generateTrip(prompt: string): GeneratedTrip {
  const { regions, days, style } = parsePrompt(prompt);

  // Collect candidate airports from regions
  const candidates = new Set<string>();
  regions.forEach((r) => (regionAirports[r] || []).forEach((a) => candidates.add(a)));

  // Score & sort by style weight
  const weights = styleWeights[style] || {};
  const scored = Array.from(candidates)
    .map((iata) => ({ iata, score: (weights[iata] || 1) + Math.random() * 0.5 }))
    .sort((a, b) => b.score - a.score);

  // Pick stops: roughly 1 stop per 2-3 days
  const numStops = Math.max(2, Math.min(Math.ceil(days / 2.5), scored.length, 8));
  const selected = scored.slice(0, numStops).map((s) => s.iata);

  // Optimize route order
  const optimized = optimizeRoute(selected);

  // Distribute days
  const baseDays = Math.floor(days / optimized.length);
  let remainder = days - baseDays * optimized.length;

  const stops: GeneratedStop[] = optimized.map((iata) => {
    const apt = airports.find((a) => a.iata === iata)!;
    const d = baseDays + (remainder > 0 ? 1 : 0);
    if (remainder > 0) remainder--;
    return { iata, city: apt.city, country: apt.country, days: d };
  });

  // Generate name
  const regionNames = regions.map((r) => r.replace("_", " ").replace(/\b\w/g, (c) => c.toUpperCase()));
  const name = `${regionNames.join(" & ")} ${style.charAt(0).toUpperCase() + style.slice(1)} Trip`;

  return { name, stops, totalDays: days, style };
}

/** Nearest-neighbor TSP heuristic */
function optimizeRoute(iatas: string[]): string[] {
  if (iatas.length <= 2) return iatas;
  const aptMap = new Map(airports.map((a) => [a.iata, a]));
  const remaining = new Set(iatas);
  const result: string[] = [iatas[0]];
  remaining.delete(iatas[0]);

  while (remaining.size > 0) {
    const last = aptMap.get(result[result.length - 1])!;
    let nearest = "";
    let minDist = Infinity;
    remaining.forEach((code) => {
      const apt = aptMap.get(code)!;
      const d = haversineDistance(last.lat, last.lng, apt.lat, apt.lng);
      if (d < minDist) { minDist = d; nearest = code; }
    });
    result.push(nearest);
    remaining.delete(nearest);
  }
  return result;
}

/** Regenerate with adjusted days */
export function adjustTripDays(trip: GeneratedTrip, newDays: number): GeneratedTrip {
  const baseDays = Math.floor(newDays / trip.stops.length);
  let remainder = newDays - baseDays * trip.stops.length;
  const stops = trip.stops.map((s) => {
    const d = baseDays + (remainder > 0 ? 1 : 0);
    if (remainder > 0) remainder--;
    return { ...s, days: d };
  });
  return { ...trip, stops, totalDays: newDays };
}
