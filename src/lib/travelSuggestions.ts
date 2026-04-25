import { getVisaFreeDestinations } from "@/lib/visaEngine";

export interface TravelSuggestion {
  id: string;
  type: "visa-free" | "trending" | "regional" | "score-boost";
  title: string;
  description: string;
  countries: string[];
  icon: string;
  gradient: string;
}

const trendingDestinations = [
  { country: "Japan", reason: "Cherry blossom season approaching" },
  { country: "Indonesia", reason: "Bali — top beach destination" },
  { country: "Turkey", reason: "Historic sites + affordable travel" },
  { country: "Thailand", reason: "Street food & temples" },
];

const regionalPopular: Record<string, string[]> = {
  India: ["Thailand", "Sri Lanka", "Maldives", "Nepal", "Indonesia", "Malaysia"],
  "United States": ["Japan", "France", "United Kingdom", "Thailand", "Indonesia"],
};

export function getTravelSuggestions(nationality: string, visitedCountries: string[]): TravelSuggestion[] {
  const suggestions: TravelSuggestion[] = [];

  // Visa-free destinations
  const visaFree = getVisaFreeDestinations(nationality).filter(c => !visitedCountries.includes(c));
  if (visaFree.length > 0) {
    suggestions.push({
      id: "sug-visa-free",
      type: "visa-free",
      title: "Visa-Free for You",
      description: `${visaFree.length} countries you can visit without a visa`,
      countries: visaFree.slice(0, 5),
      icon: "shield-check",
      gradient: "bg-gradient-brand",
    });
  }

  // Trending
  const trendingUnvisited = trendingDestinations.filter(t => !visitedCountries.includes(t.country));
  if (trendingUnvisited.length > 0) {
    suggestions.push({
      id: "sug-trending",
      type: "trending",
      title: "Trending Destinations",
      description: trendingUnvisited[0].reason,
      countries: trendingUnvisited.map(t => t.country),
      icon: "trending-up",
      gradient: "bg-gradient-brand",
    });
  }

  // Regional popular
  const regional = regionalPopular[nationality]?.filter(c => !visitedCountries.includes(c)) ?? [];
  if (regional.length > 0) {
    suggestions.push({
      id: "sug-regional",
      type: "regional",
      title: "Popular from Your Region",
      description: `Top destinations travelers from ${nationality} love`,
      countries: regional.slice(0, 4),
      icon: "map-pin",
      gradient: "bg-gradient-brand",
    });
  }

  // Score boost
  suggestions.push({
    id: "sug-score",
    type: "score-boost",
    title: "Boost Your Travel Score",
    description: "Visit a new continent to unlock achievements",
    countries: ["Brazil", "Kenya", "Australia", "Japan"].filter(c => !visitedCountries.includes(c)).slice(0, 3),
    icon: "trophy",
    gradient: "bg-gradient-brand",
  });

  return suggestions;
}

// Calculate travel score
export function calculateTravelScore(
  countriesVisited: number,
  totalFlightDistanceKm: number,
  uniqueVisaTypes: number
): { score: number; level: string; nextMilestone: string } {
  // Countries: up to 40 points (1 pt per country, max 40)
  const countryPoints = Math.min(countriesVisited * 5, 40);
  // Distance: up to 35 points (based on circumference multiples)
  const distPoints = Math.min(Math.floor(totalFlightDistanceKm / 5000) * 2, 35);
  // Visa diversity: up to 25 points
  const visaPoints = Math.min(uniqueVisaTypes * 8, 25);

  const score = Math.min(countryPoints + distPoints + visaPoints, 100);

  let level = "Explorer";
  if (score >= 90) level = "World Traveler";
  else if (score >= 70) level = "Globetrotter";
  else if (score >= 50) level = "Adventurer";
  else if (score >= 30) level = "Voyager";

  const nextMilestone = score < 30
    ? "Visit 2 more countries"
    : score < 50
    ? "Fly to a new continent"
    : score < 70
    ? "Visit 5 more countries"
    : score < 90
    ? "Reach 15 countries"
    : "Maximum achieved!";

  return { score, level, nextMilestone };
}
