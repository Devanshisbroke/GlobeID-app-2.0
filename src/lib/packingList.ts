/**
 * Deterministic packing-list generator (BACKLOG D 46).
 *
 * Given destination weather + duration + activity hints, produce a
 * categorised packing list. Pure function, no LLM, no network.
 *
 *   - Always-include essentials (passport, phone charger, etc.)
 *   - Climate-driven tier:
 *       cold:      <=10°C avg high → coat, gloves, beanie, thermals
 *       cool:      11-18°C        → jacket, layered shirts
 *       mild:      19-24°C        → cardigan, light jacket
 *       warm:      25-30°C        → t-shirts, shorts, sunscreen
 *       hot:       >30°C          → tank tops, sun hat, electrolytes
 *   - Precipitation-driven (>= 30% over the trip): umbrella, rain shell
 *   - Duration-driven: per-day socks/underwear floor
 *   - Activity-driven: business → blazer, beach → swimsuit, hiking →
 *     trail runners
 */

export type Climate = "cold" | "cool" | "mild" | "warm" | "hot";
export type Activity = "business" | "leisure" | "beach" | "hiking" | "ski";

export interface PackingInput {
  /** Mean of `tempMaxC` across the trip's daily forecast. */
  meanHighC: number;
  /** Mean precipitation probability (0..1). */
  meanPrecipChance?: number;
  /** Trip duration in nights. */
  nights: number;
  /** Activities the user plans to do at the destination. */
  activities?: Activity[];
}

export interface PackingItem {
  id: string;
  label: string;
  category:
    | "essentials"
    | "clothing"
    | "shoes"
    | "weather"
    | "tech"
    | "toiletries"
    | "documents"
    | "activities";
  /** Quantity to pack. */
  qty: number;
}

export function climateForTemp(c: number): Climate {
  if (c <= 10) return "cold";
  if (c <= 18) return "cool";
  if (c <= 24) return "mild";
  if (c <= 30) return "warm";
  return "hot";
}

const ESSENTIALS: PackingItem[] = [
  { id: "passport", label: "Passport / ID", qty: 1, category: "documents" },
  { id: "phone", label: "Phone", qty: 1, category: "tech" },
  { id: "charger", label: "Phone charger", qty: 1, category: "tech" },
  { id: "wallet", label: "Wallet & cards", qty: 1, category: "essentials" },
  { id: "headphones", label: "Headphones", qty: 1, category: "tech" },
  { id: "toothbrush", label: "Toothbrush + paste", qty: 1, category: "toiletries" },
  { id: "deodorant", label: "Deodorant", qty: 1, category: "toiletries" },
  { id: "skincare", label: "Skincare basics", qty: 1, category: "toiletries" },
];

export function generatePackingList(input: PackingInput): PackingItem[] {
  const climate = climateForTemp(input.meanHighC);
  const items: PackingItem[] = [...ESSENTIALS];
  const nights = Math.max(1, Math.round(input.nights));

  // Underwear + socks floor: nights+1 (so day-0 + cushion).
  items.push({
    id: "socks",
    label: "Socks (pairs)",
    qty: Math.min(nights + 1, 14),
    category: "clothing",
  });
  items.push({
    id: "underwear",
    label: "Underwear (pairs)",
    qty: Math.min(nights + 1, 14),
    category: "clothing",
  });

  // Shirts floor: ceil(nights / 2)
  items.push({
    id: "shirts",
    label: "Tops / shirts",
    qty: Math.max(2, Math.ceil(nights / 2)),
    category: "clothing",
  });

  // Climate-driven layers.
  switch (climate) {
    case "cold":
      items.push(
        { id: "coat", label: "Heavy coat", qty: 1, category: "weather" },
        { id: "gloves", label: "Gloves", qty: 1, category: "weather" },
        { id: "beanie", label: "Beanie / wool hat", qty: 1, category: "weather" },
        { id: "thermals", label: "Thermal base layer", qty: 1, category: "clothing" },
        { id: "boots", label: "Insulated boots", qty: 1, category: "shoes" },
      );
      break;
    case "cool":
      items.push(
        { id: "jacket", label: "Mid-weight jacket", qty: 1, category: "weather" },
        { id: "sweater", label: "Sweater / hoodie", qty: 1, category: "clothing" },
        { id: "sneakers", label: "Comfortable shoes", qty: 1, category: "shoes" },
      );
      break;
    case "mild":
      items.push(
        { id: "cardigan", label: "Light cardigan / overshirt", qty: 1, category: "clothing" },
        { id: "sneakers", label: "Comfortable shoes", qty: 1, category: "shoes" },
      );
      break;
    case "warm":
      items.push(
        { id: "tshirt", label: "T-shirts", qty: Math.ceil(nights / 2), category: "clothing" },
        { id: "shorts", label: "Shorts", qty: 2, category: "clothing" },
        { id: "sunscreen", label: "Sunscreen SPF 30+", qty: 1, category: "toiletries" },
        { id: "sneakers", label: "Comfortable shoes", qty: 1, category: "shoes" },
      );
      break;
    case "hot":
      items.push(
        { id: "tank", label: "Tank tops / breathable shirts", qty: nights, category: "clothing" },
        { id: "shorts", label: "Shorts", qty: 2, category: "clothing" },
        { id: "sunhat", label: "Sun hat", qty: 1, category: "weather" },
        { id: "sunglasses", label: "Sunglasses", qty: 1, category: "essentials" },
        { id: "sunscreen", label: "Sunscreen SPF 50+", qty: 1, category: "toiletries" },
        { id: "electrolytes", label: "Electrolyte tabs", qty: 1, category: "essentials" },
      );
      break;
  }

  // Rain.
  if ((input.meanPrecipChance ?? 0) >= 0.3) {
    items.push(
      { id: "umbrella", label: "Compact umbrella", qty: 1, category: "weather" },
      { id: "rainshell", label: "Rain shell / waterproof jacket", qty: 1, category: "weather" },
    );
  }

  // Activities.
  for (const act of input.activities ?? []) {
    switch (act) {
      case "business":
        items.push(
          { id: "blazer", label: "Blazer / suit", qty: 1, category: "activities" },
          { id: "dress-shirts", label: "Dress shirts", qty: 2, category: "activities" },
          { id: "dress-shoes", label: "Dress shoes", qty: 1, category: "activities" },
          { id: "laptop", label: "Laptop + charger", qty: 1, category: "tech" },
        );
        break;
      case "beach":
        items.push(
          { id: "swimsuit", label: "Swimsuit", qty: 2, category: "activities" },
          { id: "towel", label: "Quick-dry towel", qty: 1, category: "activities" },
          { id: "flipflops", label: "Flip-flops / sandals", qty: 1, category: "shoes" },
        );
        break;
      case "hiking":
        items.push(
          { id: "trail-runners", label: "Trail runners / hiking boots", qty: 1, category: "shoes" },
          { id: "daypack", label: "Daypack", qty: 1, category: "activities" },
          { id: "water-bottle", label: "Water bottle", qty: 1, category: "essentials" },
        );
        break;
      case "ski":
        items.push(
          { id: "ski-jacket", label: "Ski jacket", qty: 1, category: "activities" },
          { id: "ski-pants", label: "Ski pants", qty: 1, category: "activities" },
          { id: "ski-goggles", label: "Goggles", qty: 1, category: "activities" },
        );
        break;
      case "leisure":
      default:
        // No additional items.
        break;
    }
  }

  // De-duplicate by id (later additions win on qty).
  const byId = new Map<string, PackingItem>();
  for (const it of items) byId.set(it.id, it);
  return Array.from(byId.values());
}

/** Group helper for UI: Map<category, items>. */
export function groupPackingList(
  items: PackingItem[],
): Array<{ category: PackingItem["category"]; items: PackingItem[] }> {
  const order: PackingItem["category"][] = [
    "documents",
    "essentials",
    "clothing",
    "shoes",
    "weather",
    "tech",
    "toiletries",
    "activities",
  ];
  const buckets = new Map<PackingItem["category"], PackingItem[]>();
  for (const it of items) {
    const list = buckets.get(it.category) ?? [];
    list.push(it);
    buckets.set(it.category, list);
  }
  return order
    .filter((k) => buckets.has(k))
    .map((category) => ({ category, items: buckets.get(category)! }));
}
