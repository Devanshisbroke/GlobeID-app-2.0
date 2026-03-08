export interface PredictedDestination {
  city: string;
  country: string;
  flag: string;
  score: number; // 0-100 prediction confidence
  reason: string;
  expectedGrowth: number; // %
  trendCategory: "emerging" | "rising" | "trending" | "breakout";
}

export const predictions: PredictedDestination[] = [
  { city: "Lisbon", country: "Portugal", flag: "🇵🇹", score: 94, reason: "Digital nomad hub with growing tech scene", expectedGrowth: 28, trendCategory: "breakout" },
  { city: "Bali", country: "Indonesia", flag: "🇮🇩", score: 91, reason: "Remote work paradise with affordable living", expectedGrowth: 22, trendCategory: "trending" },
  { city: "Seoul", country: "South Korea", flag: "🇰🇷", score: 89, reason: "K-culture boom driving tourism surge", expectedGrowth: 19, trendCategory: "rising" },
  { city: "Mexico City", country: "Mexico", flag: "🇲🇽", score: 87, reason: "Cultural renaissance and culinary tourism", expectedGrowth: 24, trendCategory: "breakout" },
  { city: "Tbilisi", country: "Georgia", flag: "🇬🇪", score: 84, reason: "Emerging European gateway with visa-free access", expectedGrowth: 35, trendCategory: "emerging" },
  { city: "Medellín", country: "Colombia", flag: "🇨🇴", score: 82, reason: "Innovation hub with year-round spring climate", expectedGrowth: 20, trendCategory: "rising" },
  { city: "Tirana", country: "Albania", flag: "🇦🇱", score: 79, reason: "Mediterranean gem with ultra-affordable costs", expectedGrowth: 31, trendCategory: "emerging" },
  { city: "Taipei", country: "Taiwan", flag: "🇹🇼", score: 77, reason: "Tech infrastructure meets traditional culture", expectedGrowth: 15, trendCategory: "rising" },
];

export function getTopPredictions(n = 5): PredictedDestination[] {
  return predictions.slice(0, n);
}

export function getByCategory(cat: PredictedDestination["trendCategory"]): PredictedDestination[] {
  return predictions.filter((p) => p.trendCategory === cat);
}

const categoryColors: Record<string, string> = {
  emerging: "text-accent",
  rising: "text-primary",
  trending: "text-[hsl(var(--ocean-aqua))]",
  breakout: "text-destructive",
};

export function getCategoryColor(cat: string): string {
  return categoryColors[cat] ?? "text-muted-foreground";
}
