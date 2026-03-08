import type { Airport } from "@/lib/airports";

let cachedAirports: Airport[] | null = null;
let loadPromise: Promise<Airport[]> | null = null;

const parseCsvLine = (line: string): string[] => {
  const fields: string[] = [];
  let current = "";
  let inQuotes = false;

  for (let i = 0; i < line.length; i += 1) {
    const char = line[i];
    if (char === '"') {
      inQuotes = !inQuotes;
      continue;
    }
    if (char === "," && !inQuotes) {
      fields.push(current);
      current = "";
      continue;
    }
    current += char;
  }
  fields.push(current);
  return fields;
};

export const parseOpenFlightsAirports = (raw: string): Airport[] =>
  raw
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .map(parseCsvLine)
    .map((fields): Airport | null => {
      if (fields.length < 8) return null;
      const [_, name, city, country, iata, __, latRaw, lngRaw] = fields;
      const lat = Number(latRaw);
      const lng = Number(lngRaw);
      if (!iata || iata === "\\N" || Number.isNaN(lat) || Number.isNaN(lng)) return null;
      return { name, iata, lat, lng, city, country };
    })
    .filter((airport): airport is Airport => Boolean(airport));

export const loadAirportDataset = async (fallback: Airport[]): Promise<Airport[]> => {
  if (cachedAirports) return cachedAirports;
  if (!loadPromise) {
    loadPromise = fetch("/assets/airports/airports.dat")
      .then((res) => {
        if (!res.ok) throw new Error("airports.dat fetch failed");
        return res.text();
      })
      .then((raw) => {
        const parsed = parseOpenFlightsAirports(raw);
        cachedAirports = parsed.length > 0 ? parsed : fallback;
        return cachedAirports;
      })
      .catch(() => {
        cachedAirports = fallback;
        return cachedAirports;
      });
  }
  return loadPromise;
};
