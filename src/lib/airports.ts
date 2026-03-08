import { loadAirportDataset } from "@/lib/airportParser";

export interface Airport {
  name: string;
  iata: string;
  lat: number;
  lng: number;
  country: string;
  city: string;
}

const fallbackAirports: Airport[] = [
  { name: "San Francisco International", iata: "SFO", lat: 37.6213, lng: -122.379, country: "United States", city: "San Francisco" },
  { name: "Los Angeles International", iata: "LAX", lat: 33.9425, lng: -118.408, country: "United States", city: "Los Angeles" },
  { name: "John F. Kennedy International", iata: "JFK", lat: 40.6413, lng: -73.7781, country: "United States", city: "New York" },
  { name: "London Heathrow", iata: "LHR", lat: 51.47, lng: -0.4543, country: "United Kingdom", city: "London" },
  { name: "Paris Charles de Gaulle", iata: "CDG", lat: 49.0097, lng: 2.5479, country: "France", city: "Paris" },
  { name: "Dubai International", iata: "DXB", lat: 25.2532, lng: 55.3657, country: "UAE", city: "Dubai" },
  { name: "Indira Gandhi International", iata: "DEL", lat: 28.5562, lng: 77.1, country: "India", city: "New Delhi" },
  { name: "Chhatrapati Shivaji Maharaj International", iata: "BOM", lat: 19.0896, lng: 72.8656, country: "India", city: "Mumbai" },
  { name: "Singapore Changi", iata: "SIN", lat: 1.3644, lng: 103.9915, country: "Singapore", city: "Singapore" },
  { name: "Tokyo Narita", iata: "NRT", lat: 35.7647, lng: 140.3864, country: "Japan", city: "Tokyo" },
];

export let airports: Airport[] = [...fallbackAirports];
let airportsPromise: Promise<Airport[]> | null = null;

export const loadAirportsDataset = async (): Promise<Airport[]> => {
  if (!airportsPromise) {
    airportsPromise = loadAirportDataset(fallbackAirports).then((parsed) => {
      airports = parsed;
      return airports;
    });
  }
  return airportsPromise;
};

export interface FlightRoute {
  id: string;
  from: string;
  to: string;
  type: "past" | "upcoming" | "current";
  airline?: string;
  date?: string;
  duration?: string;
}

export const flightRoutes: FlightRoute[] = [
  { id: "f1", from: "SFO", to: "SIN", type: "upcoming", airline: "Singapore Airlines", date: "Today", duration: "18h 15m" },
  { id: "f2", from: "JFK", to: "LHR", type: "past", airline: "British Airways", date: "Feb 12", duration: "7h 10m" },
  { id: "f3", from: "LHR", to: "CDG", type: "past", airline: "Air France", date: "Feb 15", duration: "1h 20m" },
  { id: "f4", from: "CDG", to: "DXB", type: "past", airline: "Emirates", date: "Feb 18", duration: "6h 40m" },
  { id: "f5", from: "DXB", to: "DEL", type: "past", airline: "Emirates", date: "Feb 22", duration: "3h 30m" },
  { id: "f6", from: "DEL", to: "BOM", type: "past", airline: "Air India", date: "Feb 25", duration: "2h 10m" },
  { id: "f7", from: "BOM", to: "SFO", type: "past", airline: "United Airlines", date: "Mar 1", duration: "17h 45m" },
  { id: "f8", from: "SIN", to: "NRT", type: "upcoming", airline: "ANA", date: "Mar 20", duration: "6h 50m" },
];

export const visitedCountries = ["United States", "United Kingdom", "France", "UAE", "India", "Singapore"];
export const upcomingCountries = ["Singapore", "Japan"];

export function getAirport(iata: string): Airport | undefined {
  return airports.find((a) => a.iata === iata);
}

export function latLngToVector3(lat: number, lng: number, radius: number): [number, number, number] {
  const phi = (90 - lat) * (Math.PI / 180);
  const theta = (lng + 180) * (Math.PI / 180);
  const x = -(radius * Math.sin(phi) * Math.cos(theta));
  const y = radius * Math.cos(phi);
  const z = radius * Math.sin(phi) * Math.sin(theta);
  return [x, y, z];
}

export function createArcPoints(
  from: [number, number, number],
  to: [number, number, number],
  segments = 64,
  minHeight = 0.06
): [number, number, number][] {
  const fromLen = Math.hypot(...from);
  const toLen = Math.hypot(...to);
  const radius = (fromLen + toLen) * 0.5;

  const a = [from[0] / fromLen, from[1] / fromLen, from[2] / fromLen];
  const b = [to[0] / toLen, to[1] / toLen, to[2] / toLen];

  const dot = Math.min(1, Math.max(-1, a[0] * b[0] + a[1] * b[1] + a[2] * b[2]));
  const omega = Math.acos(dot);
  const sinOmega = Math.sin(omega);
  const arcHeight = Math.max(minHeight, omega * 0.15);

  const points: [number, number, number][] = [];

  for (let i = 0; i <= segments; i += 1) {
    const t = i / segments;
    let x = 0;
    let y = 0;
    let z = 0;

    if (sinOmega < 1e-6) {
      x = a[0] + (b[0] - a[0]) * t;
      y = a[1] + (b[1] - a[1]) * t;
      z = a[2] + (b[2] - a[2]) * t;
      const len = Math.hypot(x, y, z) || 1;
      x /= len;
      y /= len;
      z /= len;
    } else {
      const w0 = Math.sin((1 - t) * omega) / sinOmega;
      const w1 = Math.sin(t * omega) / sinOmega;
      x = a[0] * w0 + b[0] * w1;
      y = a[1] * w0 + b[1] * w1;
      z = a[2] * w0 + b[2] * w1;
    }

    const height = 1 + arcHeight * Math.sin(Math.PI * t);
    points.push([x * radius * height, y * radius * height, z * radius * height]);
  }

  return points;
}

void loadAirportsDataset();
