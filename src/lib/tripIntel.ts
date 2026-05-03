/**
 * Trip intelligence — deterministic destination metadata + helpers.
 *
 * Backs five Trip-Detail enrichment surfaces (BACKLOG D 43, 44, 46, 49, 50):
 *   • Time-zone delta vs home + local time card
 *   • Currency converter prefilled with destination currency
 *   • Packing list driven by destination climate + duration + month
 *   • Ground transport options with deep-link URLs
 *   • Lounge access lookup by alliance + airport
 *
 * All data is static / deterministic — no live API. Indexed by IATA
 * code so airport / city changes don't drift. Fall-back logic:
 *  - timezone: lat/lng → integer offset (UTC ± hours from longitude/15)
 *  - currency: country-of-airport → ISO 4217 (small lookup table)
 *  - climate: lat band + month → tropical / temperate / cold
 *  - packing: rules engine on (climate, durationDays)
 *
 * Why static: airline / weather APIs require keys we don't have, and a
 * deterministic baseline is more useful for offline-first UX anyway.
 */
import type { Airport } from "@shared/data/airports";
import { findAirport } from "@shared/data/airports";

// ── Currency by country ───────────────────────────────────────────
// Curated subset covering every airport in shared/data/airports.ts.
// Falls back to USD if airport country isn't recognised.
const CURRENCY_BY_COUNTRY: Record<string, string> = {
  "United States": "USD",
  Canada: "CAD",
  Mexico: "MXN",
  "United Kingdom": "GBP",
  France: "EUR",
  Germany: "EUR",
  Netherlands: "EUR",
  Spain: "EUR",
  Turkey: "TRY",
  Switzerland: "CHF",
  Singapore: "SGD",
  Japan: "JPY",
  China: "CNY",
  "South Korea": "KRW",
  Thailand: "THB",
  India: "INR",
  Malaysia: "MYR",
  UAE: "AED",
  Qatar: "QAR",
  Australia: "AUD",
  "New Zealand": "NZD",
  Brazil: "BRL",
  Colombia: "COP",
  Peru: "PEN",
  Argentina: "ARS",
  "South Africa": "ZAR",
  Egypt: "EGP",
  Kenya: "KES",
};

export function currencyForAirport(iata: string): string {
  const a = findAirport(iata);
  if (!a) return "USD";
  return CURRENCY_BY_COUNTRY[a.country] ?? "USD";
}

// ── Timezone offset from longitude ────────────────────────────────
// Real-world timezones don't follow longitude exactly (DST, political
// boundaries) but for a UX hint "+5h vs home" this is good enough and
// requires no IANA db. Specific airports get hand-tuned overrides.
const TZ_OVERRIDE_BY_IATA: Record<string, number> = {
  // Asia
  SIN: 8,
  HKG: 8,
  NRT: 9,
  HND: 9,
  ICN: 9,
  PVG: 8,
  PEK: 8,
  BKK: 7,
  DEL: 5.5,
  BOM: 5.5,
  KUL: 8,
  // Middle East
  DXB: 4,
  AUH: 4,
  DOH: 3,
  // Europe (CET / GMT)
  LHR: 0,
  CDG: 1,
  FRA: 1,
  AMS: 1,
  MAD: 1,
  IST: 3,
  ZRH: 1,
  // North America
  SFO: -8,
  LAX: -8,
  SEA: -8,
  JFK: -5,
  ORD: -6,
  MIA: -5,
  DFW: -6,
  YYZ: -5,
  CUN: -5,
  // Oceania
  SYD: 11,
  MEL: 11,
  AKL: 13,
  // South America
  GRU: -3,
  BOG: -5,
  LIM: -5,
  // Africa
  CAI: 2,
  JNB: 2,
  NBO: 3,
};

export function timezoneOffsetHours(iata: string): number {
  if (TZ_OVERRIDE_BY_IATA[iata] !== undefined) {
    return TZ_OVERRIDE_BY_IATA[iata]!;
  }
  const a = findAirport(iata);
  if (!a) return 0;
  // Each 15° of longitude ~= 1 hour. Round to nearest 0.5 to keep the
  // few half-hour zones representable (India, Iran, Newfoundland).
  return Math.round((a.lng / 15) * 2) / 2;
}

export interface TimezoneDelta {
  homeIata: string;
  destIata: string;
  homeOffset: number;
  destOffset: number;
  /** dest − home, positive means dest is "ahead". */
  deltaHours: number;
  /** Pretty string e.g. "+5h 30m" or "−8h". */
  pretty: string;
}

export function timezoneDelta(homeIata: string, destIata: string): TimezoneDelta {
  const homeOffset = timezoneOffsetHours(homeIata);
  const destOffset = timezoneOffsetHours(destIata);
  const delta = destOffset - homeOffset;
  return {
    homeIata,
    destIata,
    homeOffset,
    destOffset,
    deltaHours: delta,
    pretty: prettyOffset(delta),
  };
}

function prettyOffset(hours: number): string {
  if (hours === 0) return "Same time";
  const sign = hours > 0 ? "+" : "−";
  const abs = Math.abs(hours);
  const whole = Math.floor(abs);
  const mins = Math.round((abs - whole) * 60);
  if (mins === 0) return `${sign}${whole}h`;
  return `${sign}${whole}h ${mins}m`;
}

/** Local clock at destination, given a Date instance. Pure function. */
export function localTimeAt(iata: string, now: Date = new Date()): {
  hours: number;
  minutes: number;
  iso: string;
} {
  const offset = timezoneOffsetHours(iata);
  const utcMs = now.getTime() + now.getTimezoneOffset() * 60_000;
  const local = new Date(utcMs + offset * 3_600_000);
  return {
    hours: local.getHours(),
    minutes: local.getMinutes(),
    iso: local.toISOString(),
  };
}

// ── Climate band by latitude × month ──────────────────────────────
type Climate = "tropical" | "warm" | "temperate" | "cold" | "polar";

export function climateBand(
  airport: Airport,
  monthIndex: number, // 0 = Jan
): Climate {
  const lat = Math.abs(airport.lat);
  const isNorth = airport.lat >= 0;
  // Northern winter Dec/Jan/Feb (idx 11,0,1) ↔ Southern summer.
  const winterMonths = [11, 0, 1];
  const isWinter = isNorth
    ? winterMonths.includes(monthIndex)
    : !winterMonths.includes(monthIndex) && [5, 6, 7].includes(monthIndex);
  if (lat <= 23) return "tropical";
  if (lat <= 35) return isWinter ? "temperate" : "warm";
  if (lat <= 55) return isWinter ? "cold" : "temperate";
  if (lat <= 70) return isWinter ? "polar" : "cold";
  return "polar";
}

// ── Packing list rules engine ─────────────────────────────────────
export interface PackingItem {
  id: string;
  label: string;
  category: "essential" | "clothing" | "tech" | "documents" | "weather";
  /** Suggested count, scales with duration. */
  count: number;
}

/** Generate a packing list given destination + duration + month.
 * Deterministic: same inputs → same output. */
export function generatePackingList(
  destIata: string,
  durationDays: number,
  monthIndex: number = new Date().getMonth(),
): PackingItem[] {
  const a = findAirport(destIata);
  const climate: Climate = a ? climateBand(a, monthIndex) : "temperate";
  const days = Math.max(1, Math.min(durationDays, 30));

  const items: PackingItem[] = [
    // Essentials — always present
    { id: "passport", label: "Passport", category: "documents", count: 1 },
    { id: "visa", label: "Visa / entry permit", category: "documents", count: 1 },
    { id: "boarding-pass", label: "Boarding pass", category: "documents", count: 1 },
    { id: "wallet", label: "Wallet + cards", category: "essential", count: 1 },
    { id: "phone", label: "Phone + charger", category: "tech", count: 1 },
    { id: "headphones", label: "Headphones", category: "tech", count: 1 },
    { id: "powerbank", label: "Power bank", category: "tech", count: 1 },
    { id: "adapter", label: "Travel adapter", category: "tech", count: 1 },
    { id: "toothbrush", label: "Toothbrush + paste", category: "essential", count: 1 },
    { id: "meds", label: "Personal medication", category: "essential", count: 1 },

    // Clothing — scales with duration (cap at 7-day rotations)
    { id: "underwear", label: "Underwear", category: "clothing", count: Math.min(days, 7) },
    { id: "socks", label: "Socks", category: "clothing", count: Math.min(days, 7) },
    { id: "tshirts", label: "T-shirts / tops", category: "clothing", count: Math.min(days, 5) },
    { id: "trousers", label: "Trousers / shorts", category: "clothing", count: Math.min(Math.ceil(days / 2), 4) },
  ];

  // Climate-driven adds
  if (climate === "tropical" || climate === "warm") {
    items.push(
      { id: "sunscreen", label: "Sunscreen SPF 30+", category: "weather", count: 1 },
      { id: "sunglasses", label: "Sunglasses", category: "weather", count: 1 },
      { id: "hat", label: "Sun hat / cap", category: "weather", count: 1 },
      { id: "swimwear", label: "Swimwear", category: "clothing", count: 1 },
      { id: "sandals", label: "Sandals", category: "clothing", count: 1 },
      { id: "bug-spray", label: "Insect repellent", category: "weather", count: 1 },
    );
  }
  if (climate === "cold" || climate === "polar") {
    items.push(
      { id: "jacket", label: "Heavy jacket / coat", category: "weather", count: 1 },
      { id: "thermal", label: "Thermal layer", category: "weather", count: 2 },
      { id: "gloves", label: "Gloves", category: "weather", count: 1 },
      { id: "beanie", label: "Beanie / wool hat", category: "weather", count: 1 },
      { id: "scarf", label: "Scarf", category: "weather", count: 1 },
      { id: "boots", label: "Insulated boots", category: "clothing", count: 1 },
      { id: "moisturiser", label: "Moisturiser (dry climate)", category: "essential", count: 1 },
    );
  }
  if (climate === "temperate") {
    items.push(
      { id: "light-jacket", label: "Light jacket", category: "weather", count: 1 },
      { id: "umbrella", label: "Compact umbrella", category: "weather", count: 1 },
    );
  }

  // Long-trip extras
  if (days >= 7) {
    items.push(
      { id: "laundry-bag", label: "Laundry bag", category: "essential", count: 1 },
      { id: "extra-shoes", label: "Second pair of shoes", category: "clothing", count: 1 },
    );
  }

  return items;
}

// ── Lounge access by alliance × airport ───────────────────────────
export type Alliance = "Star Alliance" | "Oneworld" | "SkyTeam" | "Independent";

interface LoungeRecord {
  iata: string;
  alliance: Alliance;
  loungeName: string;
  terminal?: string;
}

const LOUNGES: readonly LoungeRecord[] = [
  // Star Alliance
  { iata: "FRA", alliance: "Star Alliance", loungeName: "Lufthansa Senator Lounge", terminal: "T1" },
  { iata: "MUC", alliance: "Star Alliance", loungeName: "Lufthansa First Class Terminal" },
  { iata: "SFO", alliance: "Star Alliance", loungeName: "United Polaris Lounge", terminal: "International G" },
  { iata: "ICN", alliance: "Star Alliance", loungeName: "Asiana Business Lounge", terminal: "T1" },
  { iata: "ZRH", alliance: "Star Alliance", loungeName: "Swiss Senator Lounge", terminal: "E" },
  // Oneworld
  { iata: "LHR", alliance: "Oneworld", loungeName: "British Airways Concorde Room", terminal: "T5" },
  { iata: "JFK", alliance: "Oneworld", loungeName: "American Flagship Lounge", terminal: "T8" },
  { iata: "HND", alliance: "Oneworld", loungeName: "JAL First Class Lounge", terminal: "I" },
  { iata: "DFW", alliance: "Oneworld", loungeName: "American Flagship Lounge", terminal: "D" },
  { iata: "DOH", alliance: "Oneworld", loungeName: "Qatar Airways Al Mourjan" },
  // SkyTeam
  { iata: "CDG", alliance: "SkyTeam", loungeName: "Air France La Première", terminal: "2E" },
  { iata: "AMS", alliance: "SkyTeam", loungeName: "KLM Crown Lounge", terminal: "Non-Schengen" },
  { iata: "ATL", alliance: "SkyTeam", loungeName: "Delta Sky Club" },
  { iata: "ICN", alliance: "SkyTeam", loungeName: "Korean Air KAL Lounge", terminal: "T2" },
  // Independent / pay-per-use
  { iata: "DXB", alliance: "Independent", loungeName: "Marhaba Lounge", terminal: "T3" },
  { iata: "SIN", alliance: "Independent", loungeName: "SATS Premier Lounge", terminal: "T3" },
  { iata: "HKG", alliance: "Independent", loungeName: "Plaza Premium Lounge" },
  { iata: "DEL", alliance: "Independent", loungeName: "ITC Green Lounge", terminal: "T3" },
];

export function loungesAt(iata: string, alliance?: Alliance): LoungeRecord[] {
  const all = LOUNGES.filter((l) => l.iata === iata);
  if (alliance) return all.filter((l) => l.alliance === alliance);
  return all;
}

// ── Ground transport deep links ───────────────────────────────────
export interface GroundTransportLink {
  id: "uber" | "bolt" | "lyft" | "didi" | "grab";
  label: string;
  /** Deep link URL (mobile schemes preferred; web fallback included). */
  url: string;
}

/** Canonical mobile deep links. The Uber + Lyft schemes work cross-platform;
 * Bolt + Grab + Didi fall back to their web sites if app isn't installed.
 * Coordinates pre-fill the dropoff for one-tap booking from a trip card. */
export function groundTransportFor(
  iata: string,
  pickupLabel = "My location",
): GroundTransportLink[] {
  const a = findAirport(iata);
  if (!a) return [];
  const lat = a.lat;
  const lng = a.lng;
  const dropoffName = encodeURIComponent(`${a.name} (${a.iata})`);
  const pickupName = encodeURIComponent(pickupLabel);

  // Uber: works in 70+ countries
  const uber = `uber://?action=setPickup&pickup=my_location&dropoff[latitude]=${lat}&dropoff[longitude]=${lng}&dropoff[nickname]=${dropoffName}`;
  // Lyft: US/Canada
  const lyft = `lyft://ridetype?id=lyft&pickup[latitude]=${lat}&pickup[longitude]=${lng}&destination[latitude]=${lat}&destination[longitude]=${lng}`;
  // Bolt: Europe + Africa, falls back to web
  const bolt = `https://bolt.eu/en/cities/?lat=${lat}&lng=${lng}`;
  // Grab: Southeast Asia
  const grab = `https://www.grab.com/sg/transport/?dropoff_lat=${lat}&dropoff_lng=${lng}&dropoff=${dropoffName}&pickup=${pickupName}`;
  // Didi: China only
  const didi = `https://page.udache.com/passenger/intl-redirect?lat=${lat}&lng=${lng}`;

  const links: GroundTransportLink[] = [
    { id: "uber", label: "Uber", url: uber },
  ];
  // Region-aware filtering — only show options that are likely to work
  // wherever this airport is, to avoid 4 useless buttons everywhere.
  if (["United States", "Canada"].includes(a.country)) {
    links.push({ id: "lyft", label: "Lyft", url: lyft });
  }
  if (
    [
      "United Kingdom",
      "France",
      "Germany",
      "Netherlands",
      "Spain",
      "Turkey",
      "Switzerland",
      "South Africa",
      "Kenya",
      "Egypt",
    ].includes(a.country)
  ) {
    links.push({ id: "bolt", label: "Bolt", url: bolt });
  }
  if (
    ["Singapore", "Thailand", "Malaysia", "Indonesia", "Philippines", "Vietnam"].includes(
      a.country,
    )
  ) {
    links.push({ id: "grab", label: "Grab", url: grab });
  }
  if (a.country === "China") {
    links.push({ id: "didi", label: "Didi", url: didi });
  }
  return links;
}
