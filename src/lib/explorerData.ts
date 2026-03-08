export interface Destination {
  id: string;
  city: string;
  country: string;
  lat: number;
  lng: number;
  continent: string;
  popularity: number;
  description: string;
  highlights: string[];
  cuisine: string[];
  landmarks: string[];
  bestSeason: string;
  emoji: string;
}

export interface Landmark {
  id: string;
  name: string;
  lat: number;
  lng: number;
  icon: string; // emoji
  destinationId: string;
}

export interface ExplorationPath {
  id: string;
  name: string;
  description: string;
  stops: string[]; // destination ids
  color: string;
}

export interface Achievement {
  id: string;
  name: string;
  description: string;
  icon: string;
  requirement: number;
  type: "countries" | "landmarks" | "continents" | "destinations";
}

export const destinations: Destination[] = [
  {
    id: "paris", city: "Paris", country: "France", lat: 48.8566, lng: 2.3522,
    continent: "Europe", popularity: 95,
    description: "The City of Light enchants with iconic landmarks, world-class art, and legendary cuisine.",
    highlights: ["Art & Museums", "Historic Architecture", "Fashion Capital", "Romantic Walks"],
    cuisine: ["Croissants", "Coq au Vin", "Crème Brûlée", "Macarons"],
    landmarks: ["Eiffel Tower", "Louvre Museum", "Notre-Dame", "Champs-Élysées"],
    bestSeason: "Apr–Jun", emoji: "🇫🇷",
  },
  {
    id: "tokyo", city: "Tokyo", country: "Japan", lat: 35.6762, lng: 139.6503,
    continent: "Asia", popularity: 92,
    description: "A dazzling fusion of ultra-modern tech and ancient tradition in every corner.",
    highlights: ["Cherry Blossoms", "Anime Culture", "Temple Gardens", "Night Markets"],
    cuisine: ["Sushi", "Ramen", "Tempura", "Matcha"],
    landmarks: ["Shibuya Crossing", "Senso-ji Temple", "Tokyo Tower", "Meiji Shrine"],
    bestSeason: "Mar–May", emoji: "🇯🇵",
  },
  {
    id: "bali", city: "Bali", country: "Indonesia", lat: -8.3405, lng: 115.092,
    continent: "Asia", popularity: 90,
    description: "Island of the Gods — lush rice terraces, sacred temples, and pristine beaches.",
    highlights: ["Rice Terraces", "Temple Visits", "Surfing", "Yoga Retreats"],
    cuisine: ["Nasi Goreng", "Satay", "Babi Guling", "Lawar"],
    landmarks: ["Tanah Lot", "Uluwatu Temple", "Tegallalang", "Sacred Monkey Forest"],
    bestSeason: "Apr–Oct", emoji: "🇮🇩",
  },
  {
    id: "dubai", city: "Dubai", country: "UAE", lat: 25.2048, lng: 55.2708,
    continent: "Middle East", popularity: 91,
    description: "A futuristic desert metropolis of record-breaking architecture and luxury.",
    highlights: ["Desert Safari", "Luxury Shopping", "Sky Dining", "Gold Souks"],
    cuisine: ["Shawarma", "Al Machboos", "Luqaimat", "Arabic Coffee"],
    landmarks: ["Burj Khalifa", "Palm Jumeirah", "Dubai Mall", "Dubai Frame"],
    bestSeason: "Nov–Mar", emoji: "🇦🇪",
  },
  {
    id: "newyork", city: "New York", country: "United States", lat: 40.7128, lng: -74.006,
    continent: "North America", popularity: 94,
    description: "The city that never sleeps — Broadway, Central Park, and infinite energy.",
    highlights: ["Broadway Shows", "Street Food", "Museum Mile", "Skyline Views"],
    cuisine: ["Pizza", "Bagels", "Cheesecake", "Hot Dogs"],
    landmarks: ["Statue of Liberty", "Central Park", "Empire State Building", "Times Square"],
    bestSeason: "Sep–Nov", emoji: "🇺🇸",
  },
  {
    id: "rome", city: "Rome", country: "Italy", lat: 41.9028, lng: 12.4964,
    continent: "Europe", popularity: 93,
    description: "The Eternal City where ancient ruins meet la dolce vita.",
    highlights: ["Ancient History", "Gelato Walks", "Vatican Art", "Piazza Culture"],
    cuisine: ["Pasta Carbonara", "Gelato", "Supplì", "Tiramisu"],
    landmarks: ["Colosseum", "Vatican City", "Trevi Fountain", "Pantheon"],
    bestSeason: "Apr–Jun", emoji: "🇮🇹",
  },
  {
    id: "capetown", city: "Cape Town", country: "South Africa", lat: -33.9249, lng: 18.4241,
    continent: "Africa", popularity: 87,
    description: "Where mountains meet ocean — wine lands, wildlife, and vibrant culture.",
    highlights: ["Table Mountain", "Wine Tasting", "Safari Nearby", "Beaches"],
    cuisine: ["Braai", "Bobotie", "Biltong", "Koeksisters"],
    landmarks: ["Table Mountain", "Robben Island", "Cape of Good Hope", "V&A Waterfront"],
    bestSeason: "Oct–Mar", emoji: "🇿🇦",
  },
  {
    id: "singapore", city: "Singapore", country: "Singapore", lat: 1.3521, lng: 103.8198,
    continent: "Asia", popularity: 89,
    description: "A garden city of stunning architecture, hawker food, and multicultural charm.",
    highlights: ["Hawker Centers", "Gardens by the Bay", "Marina Bay", "Cultural Districts"],
    cuisine: ["Chicken Rice", "Laksa", "Chili Crab", "Kaya Toast"],
    landmarks: ["Marina Bay Sands", "Gardens by the Bay", "Merlion", "Sentosa"],
    bestSeason: "Feb–Apr", emoji: "🇸🇬",
  },
  {
    id: "london", city: "London", country: "United Kingdom", lat: 51.5074, lng: -0.1278,
    continent: "Europe", popularity: 93,
    description: "A timeless capital of royal heritage, theater, and global cuisine.",
    highlights: ["Royal Palaces", "West End Shows", "Pub Culture", "World-class Museums"],
    cuisine: ["Fish & Chips", "Sunday Roast", "Afternoon Tea", "Pie & Mash"],
    landmarks: ["Big Ben", "Tower of London", "Buckingham Palace", "British Museum"],
    bestSeason: "Jun–Aug", emoji: "🇬🇧",
  },
  {
    id: "machu", city: "Cusco", country: "Peru", lat: -13.1631, lng: -72.545,
    continent: "South America", popularity: 85,
    description: "Gateway to the ancient Incan citadel of Machu Picchu in the clouds.",
    highlights: ["Inca Trail", "Sacred Valley", "Andean Culture", "Mountain Treks"],
    cuisine: ["Ceviche", "Lomo Saltado", "Anticuchos", "Pisco Sour"],
    landmarks: ["Machu Picchu", "Sacsayhuamán", "Plaza de Armas", "Rainbow Mountain"],
    bestSeason: "May–Sep", emoji: "🇵🇪",
  },
  {
    id: "sydney", city: "Sydney", country: "Australia", lat: -33.8688, lng: 151.2093,
    continent: "Oceania", popularity: 88,
    description: "Sun-kissed harbor city with iconic architecture and beach culture.",
    highlights: ["Harbor Cruises", "Beach Life", "Coastal Walks", "Wildlife"],
    cuisine: ["Meat Pies", "Barramundi", "Pavlova", "Flat White"],
    landmarks: ["Sydney Opera House", "Harbour Bridge", "Bondi Beach", "Taronga Zoo"],
    bestSeason: "Sep–Nov", emoji: "🇦🇺",
  },
  {
    id: "istanbul", city: "Istanbul", country: "Turkey", lat: 41.0082, lng: 28.9784,
    continent: "Europe", popularity: 88,
    description: "A crossroads of civilizations where East meets West at every turn.",
    highlights: ["Bazaar Shopping", "Mosque Architecture", "Bosphorus Cruises", "Turkish Baths"],
    cuisine: ["Kebab", "Baklava", "Turkish Delight", "Pide"],
    landmarks: ["Hagia Sophia", "Blue Mosque", "Grand Bazaar", "Topkapi Palace"],
    bestSeason: "Apr–May", emoji: "🇹🇷",
  },
];

export const landmarks: Landmark[] = [
  { id: "l1", name: "Eiffel Tower", lat: 48.8584, lng: 2.2945, icon: "🗼", destinationId: "paris" },
  { id: "l2", name: "Great Wall of China", lat: 40.4319, lng: 116.5704, icon: "🏯", destinationId: "tokyo" },
  { id: "l3", name: "Burj Khalifa", lat: 25.1972, lng: 55.2744, icon: "🏙️", destinationId: "dubai" },
  { id: "l4", name: "Statue of Liberty", lat: 40.6892, lng: -74.0445, icon: "🗽", destinationId: "newyork" },
  { id: "l5", name: "Machu Picchu", lat: -13.1631, lng: -72.545, icon: "🏔️", destinationId: "machu" },
  { id: "l6", name: "Colosseum", lat: 41.8902, lng: 12.4922, icon: "🏛️", destinationId: "rome" },
  { id: "l7", name: "Sydney Opera House", lat: -33.8568, lng: 151.2153, icon: "🎭", destinationId: "sydney" },
  { id: "l8", name: "Big Ben", lat: 51.5007, lng: -0.1246, icon: "🕰️", destinationId: "london" },
  { id: "l9", name: "Marina Bay Sands", lat: 1.2834, lng: 103.8607, icon: "🏨", destinationId: "singapore" },
  { id: "l10", name: "Table Mountain", lat: -33.9625, lng: 18.4039, icon: "⛰️", destinationId: "capetown" },
  { id: "l11", name: "Hagia Sophia", lat: 41.0086, lng: 28.9802, icon: "🕌", destinationId: "istanbul" },
  { id: "l12", name: "Tanah Lot Temple", lat: -8.6211, lng: 115.0868, icon: "⛩️", destinationId: "bali" },
];

export const explorationPaths: ExplorationPath[] = [
  {
    id: "ep1", name: "European Capitals Tour",
    description: "Experience the grandeur of Europe's most iconic cities",
    stops: ["london", "paris", "rome", "istanbul"],
    color: "hsl(220, 80%, 56%)",
  },
  {
    id: "ep2", name: "Asian Discovery",
    description: "Explore the diverse cultures and flavors of Asia",
    stops: ["tokyo", "singapore", "bali"],
    color: "hsl(168, 65%, 42%)",
  },
  {
    id: "ep3", name: "World Wonders Journey",
    description: "Visit humanity's most awe-inspiring creations",
    stops: ["rome", "machu", "dubai", "paris"],
    color: "hsl(42, 92%, 56%)",
  },
  {
    id: "ep4", name: "Southern Hemisphere Explorer",
    description: "Discover the beauty of the southern world",
    stops: ["sydney", "capetown", "bali", "machu"],
    color: "hsl(258, 60%, 62%)",
  },
];

export const achievements: Achievement[] = [
  { id: "a1", name: "First Steps", description: "Discover your first destination", icon: "🌱", requirement: 1, type: "destinations" },
  { id: "a2", name: "Explorer", description: "Discover 5 destinations", icon: "🧭", requirement: 5, type: "destinations" },
  { id: "a3", name: "World Traveler", description: "Discover 10 destinations", icon: "🌍", requirement: 10, type: "destinations" },
  { id: "a4", name: "Landmark Hunter", description: "Find 5 landmarks", icon: "📍", requirement: 5, type: "landmarks" },
  { id: "a5", name: "Culture Seeker", description: "Visit 3 continents", icon: "🎭", requirement: 3, type: "continents" },
  { id: "a6", name: "Globe Master", description: "Visit all continents", icon: "👑", requirement: 6, type: "continents" },
];

/** Get continent count from discovered destinations */
export function getContinentsDiscovered(discoveredIds: string[]): number {
  const continents = new Set(
    destinations.filter((d) => discoveredIds.includes(d.id)).map((d) => d.continent)
  );
  return continents.size;
}

export function getExplorationProgress(discoveredIds: string[]): number {
  return Math.round((discoveredIds.length / destinations.length) * 100);
}
