export interface Airport {
  name: string;
  iata: string;
  lat: number;
  lng: number;
  country: string;
  city: string;
}

export const airports: Airport[] = [
  // North America
  { name: "San Francisco International", iata: "SFO", lat: 37.6213, lng: -122.379, country: "United States", city: "San Francisco" },
  { name: "Los Angeles International", iata: "LAX", lat: 33.9425, lng: -118.408, country: "United States", city: "Los Angeles" },
  { name: "John F. Kennedy International", iata: "JFK", lat: 40.6413, lng: -73.7781, country: "United States", city: "New York" },
  { name: "Chicago O'Hare International", iata: "ORD", lat: 41.9742, lng: -87.9073, country: "United States", city: "Chicago" },
  { name: "Miami International", iata: "MIA", lat: 25.7959, lng: -80.287, country: "United States", city: "Miami" },
  { name: "Dallas/Fort Worth International", iata: "DFW", lat: 32.8998, lng: -97.0403, country: "United States", city: "Dallas" },
  { name: "Seattle-Tacoma International", iata: "SEA", lat: 47.4502, lng: -122.3088, country: "United States", city: "Seattle" },
  { name: "Toronto Pearson International", iata: "YYZ", lat: 43.6777, lng: -79.6248, country: "Canada", city: "Toronto" },
  { name: "Cancún International", iata: "CUN", lat: 21.0365, lng: -86.8771, country: "Mexico", city: "Cancún" },

  // Europe
  { name: "London Heathrow", iata: "LHR", lat: 51.47, lng: -0.4543, country: "United Kingdom", city: "London" },
  { name: "Paris Charles de Gaulle", iata: "CDG", lat: 49.0097, lng: 2.5479, country: "France", city: "Paris" },
  { name: "Frankfurt Airport", iata: "FRA", lat: 50.0379, lng: 8.5622, country: "Germany", city: "Frankfurt" },
  { name: "Amsterdam Schiphol", iata: "AMS", lat: 52.3105, lng: 4.7683, country: "Netherlands", city: "Amsterdam" },
  { name: "Madrid Barajas", iata: "MAD", lat: 40.4983, lng: -3.5676, country: "Spain", city: "Madrid" },
  { name: "Istanbul Airport", iata: "IST", lat: 41.2753, lng: 28.7519, country: "Turkey", city: "Istanbul" },
  { name: "Zurich Airport", iata: "ZRH", lat: 47.4647, lng: 8.5492, country: "Switzerland", city: "Zurich" },

  // Asia
  { name: "Singapore Changi", iata: "SIN", lat: 1.3644, lng: 103.9915, country: "Singapore", city: "Singapore" },
  { name: "Tokyo Narita", iata: "NRT", lat: 35.7647, lng: 140.3864, country: "Japan", city: "Tokyo" },
  { name: "Tokyo Haneda", iata: "HND", lat: 35.5494, lng: 139.7798, country: "Japan", city: "Tokyo" },
  { name: "Hong Kong International", iata: "HKG", lat: 22.308, lng: 113.9185, country: "China", city: "Hong Kong" },
  { name: "Shanghai Pudong", iata: "PVG", lat: 31.1443, lng: 121.8083, country: "China", city: "Shanghai" },
  { name: "Beijing Capital", iata: "PEK", lat: 40.0799, lng: 116.6031, country: "China", city: "Beijing" },
  { name: "Seoul Incheon", iata: "ICN", lat: 37.4602, lng: 126.4407, country: "South Korea", city: "Seoul" },
  { name: "Bangkok Suvarnabhumi", iata: "BKK", lat: 13.69, lng: 100.7501, country: "Thailand", city: "Bangkok" },
  { name: "Indira Gandhi International", iata: "DEL", lat: 28.5562, lng: 77.1, country: "India", city: "New Delhi" },
  { name: "Chhatrapati Shivaji Maharaj International", iata: "BOM", lat: 19.0896, lng: 72.8656, country: "India", city: "Mumbai" },
  { name: "Kuala Lumpur International", iata: "KUL", lat: 2.7456, lng: 101.71, country: "Malaysia", city: "Kuala Lumpur" },

  // Middle East
  { name: "Dubai International", iata: "DXB", lat: 25.2532, lng: 55.3657, country: "UAE", city: "Dubai" },
  { name: "Abu Dhabi International", iata: "AUH", lat: 24.4331, lng: 54.6511, country: "UAE", city: "Abu Dhabi" },
  { name: "Hamad International", iata: "DOH", lat: 25.2731, lng: 51.6081, country: "Qatar", city: "Doha" },

  // Oceania
  { name: "Sydney Kingsford Smith", iata: "SYD", lat: -33.9461, lng: 151.177, country: "Australia", city: "Sydney" },
  { name: "Melbourne Airport", iata: "MEL", lat: -37.6733, lng: 144.8433, country: "Australia", city: "Melbourne" },
  { name: "Auckland Airport", iata: "AKL", lat: -37.0082, lng: 174.792, country: "New Zealand", city: "Auckland" },

  // South America
  { name: "São Paulo–Guarulhos", iata: "GRU", lat: -23.4356, lng: -46.4731, country: "Brazil", city: "São Paulo" },
  { name: "El Dorado International", iata: "BOG", lat: 4.7016, lng: -74.1469, country: "Colombia", city: "Bogotá" },
  { name: "Jorge Chávez International", iata: "LIM", lat: -12.0219, lng: -77.1143, country: "Peru", city: "Lima" },

  // Africa
  { name: "O. R. Tambo International", iata: "JNB", lat: -26.1392, lng: 28.246, country: "South Africa", city: "Johannesburg" },
  { name: "Cairo International", iata: "CAI", lat: 30.1219, lng: 31.4056, country: "Egypt", city: "Cairo" },
  { name: "Jomo Kenyatta International", iata: "NBO", lat: -1.3192, lng: 36.9278, country: "Kenya", city: "Nairobi" },
];

/** User's travel history — flights taken */
export interface FlightRoute {
  id: string;
  from: string; // IATA
  to: string;   // IATA
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

/** Countries visited */
export const visitedCountries = [
  "United States", "United Kingdom", "France", "UAE", "India", "Singapore",
];

export const upcomingCountries = ["Singapore", "Japan"];

/** Get airport by IATA code */
export function getAirport(iata: string): Airport | undefined {
  return airports.find(a => a.iata === iata);
}

/** Convert lat/lng to 3D sphere position */
export function latLngToVector3(lat: number, lng: number, radius: number): [number, number, number] {
  const phi = (90 - lat) * (Math.PI / 180);
  const theta = (lng + 180) * (Math.PI / 180);
  const x = -(radius * Math.sin(phi) * Math.cos(theta));
  const y = radius * Math.cos(phi);
  const z = radius * Math.sin(phi) * Math.sin(theta);
  return [x, y, z];
}

/** Create a curved arc between two points on a sphere */
export function createArcPoints(
  from: [number, number, number],
  to: [number, number, number],
  segments = 64,
  arcHeight = 0.3
): [number, number, number][] {
  const points: [number, number, number][] = [];
  for (let i = 0; i <= segments; i++) {
    const t = i / segments;
    // Lerp
    const x = from[0] + (to[0] - from[0]) * t;
    const y = from[1] + (to[1] - from[1]) * t;
    const z = from[2] + (to[2] - from[2]) * t;
    // Normalize to sphere surface
    const len = Math.sqrt(x * x + y * y + z * z);
    // Arc height peaks at midpoint
    const heightMultiplier = 1 + arcHeight * Math.sin(t * Math.PI);
    const nx = (x / len) * heightMultiplier;
    const ny = (y / len) * heightMultiplier;
    const nz = (z / len) * heightMultiplier;
    points.push([nx, ny, nz]);
  }
  return points;
}
