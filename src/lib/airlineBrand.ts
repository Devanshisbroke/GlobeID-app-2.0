/**
 * Airline brand colours (deterministic).
 *
 * Maps IATA / common airline codes to a brand-accurate gradient stop
 * triple. The wallet pass card uses these to theme the boarding-pass
 * background per carrier — Singapore Airlines blue, Emirates red,
 * Lufthansa yellow, etc. — instead of the generic sky-blue used for
 * every flight. This is a real Apple/Google-Wallet-style behaviour
 * (their backside JSON includes a `backgroundColor` field).
 *
 * The lookup is keyed by IATA code (preferred) or by airline name (case
 * insensitive substring) so that records seeded with friendly names
 * still resolve. When neither is found, we fall back to a deterministic
 * hash-based gradient so every airline still gets a stable colour
 * (instead of all unknown carriers sharing the same default — which is
 * what the previous static `from-sky-600 via-blue-700 to-slate-900`
 * gradient produced).
 *
 * No network calls, no animations, no heavy UI dependencies. This is a
 * pure helper so it can be imported from anywhere (PassStack, PassDetail,
 * TripDetail badges, AppleWallet/.pkpass exporters, etc.).
 */

import type { TravelDocument } from "@/store/userStore";

export interface AirlineBrand {
  /** Three-stop gradient — darker→darkest. Tailwind class string. */
  gradient: string;
  /** Foreground accent for chips / labels. */
  accent: string;
  /** Optional plain hex used by .pkpass / Google Wallet JSON. */
  hex: string;
  /** Display name (canonicalised). */
  name: string;
}

const PALETTE: Record<string, AirlineBrand> = {
  // North America
  AA: { gradient: "from-red-700 via-red-800 to-slate-900", accent: "text-red-100",   hex: "#B91C1C", name: "American Airlines" },
  UA: { gradient: "from-blue-800 via-blue-900 to-slate-900", accent: "text-blue-100",  hex: "#1E3A8A", name: "United Airlines" },
  DL: { gradient: "from-red-600 via-blue-900 to-slate-900",  accent: "text-red-100",   hex: "#B91C1C", name: "Delta Air Lines" },
  AC: { gradient: "from-red-600 via-rose-700 to-slate-900",  accent: "text-red-100",   hex: "#DC2626", name: "Air Canada" },
  WN: { gradient: "from-blue-600 via-amber-600 to-slate-900",accent: "text-amber-100", hex: "#FBBF24", name: "Southwest" },
  B6: { gradient: "from-blue-600 via-blue-800 to-slate-900", accent: "text-blue-100",  hex: "#2563EB", name: "JetBlue" },
  AS: { gradient: "from-emerald-700 via-blue-900 to-slate-900", accent: "text-emerald-100", hex: "#047857", name: "Alaska Airlines" },

  // Europe
  BA: { gradient: "from-blue-800 via-red-700 to-slate-900",  accent: "text-blue-100",  hex: "#1D4ED8", name: "British Airways" },
  AF: { gradient: "from-blue-700 via-red-700 to-slate-900",  accent: "text-blue-100",  hex: "#1D4ED8", name: "Air France" },
  KL: { gradient: "from-sky-500 via-blue-700 to-slate-900",  accent: "text-sky-100",   hex: "#0EA5E9", name: "KLM" },
  LH: { gradient: "from-yellow-500 via-amber-700 to-slate-900", accent: "text-yellow-100", hex: "#F59E0B", name: "Lufthansa" },
  LX: { gradient: "from-rose-700 via-rose-900 to-slate-900", accent: "text-rose-100",  hex: "#9F1239", name: "SWISS" },
  IB: { gradient: "from-rose-600 via-amber-600 to-slate-900",accent: "text-rose-100",  hex: "#E11D48", name: "Iberia" },
  AY: { gradient: "from-blue-700 via-blue-900 to-slate-900", accent: "text-blue-100",  hex: "#1D4ED8", name: "Finnair" },
  TK: { gradient: "from-red-700 via-rose-800 to-slate-900",  accent: "text-red-100",   hex: "#B91C1C", name: "Turkish Airlines" },
  SK: { gradient: "from-blue-800 via-slate-800 to-slate-900",accent: "text-blue-100",  hex: "#1E40AF", name: "SAS" },
  EI: { gradient: "from-emerald-600 via-emerald-800 to-slate-900", accent: "text-emerald-100", hex: "#047857", name: "Aer Lingus" },
  VS: { gradient: "from-rose-600 via-purple-700 to-slate-900",  accent: "text-rose-100",   hex: "#E11D48", name: "Virgin Atlantic" },

  // Middle East
  EK: { gradient: "from-red-600 via-amber-600 to-slate-900", accent: "text-amber-100", hex: "#DC2626", name: "Emirates" },
  EY: { gradient: "from-amber-700 via-stone-700 to-slate-900", accent: "text-amber-100", hex: "#B45309", name: "Etihad" },
  QR: { gradient: "from-rose-800 via-rose-900 to-slate-900", accent: "text-rose-100",  hex: "#9F1239", name: "Qatar Airways" },
  SV: { gradient: "from-emerald-700 via-amber-700 to-slate-900", accent: "text-emerald-100", hex: "#047857", name: "Saudia" },

  // Asia
  SQ: { gradient: "from-blue-700 via-amber-600 to-slate-900",accent: "text-amber-100", hex: "#1D4ED8", name: "Singapore Airlines" },
  CX: { gradient: "from-emerald-700 via-emerald-900 to-slate-900", accent: "text-emerald-100", hex: "#047857", name: "Cathay Pacific" },
  JL: { gradient: "from-red-700 via-red-800 to-slate-900",   accent: "text-red-100",   hex: "#B91C1C", name: "Japan Airlines" },
  NH: { gradient: "from-blue-700 via-blue-900 to-slate-900", accent: "text-blue-100",  hex: "#1D4ED8", name: "All Nippon Airways" },
  KE: { gradient: "from-sky-600 via-sky-800 to-slate-900",   accent: "text-sky-100",   hex: "#0284C7", name: "Korean Air" },
  OZ: { gradient: "from-stone-600 via-stone-800 to-slate-900", accent: "text-stone-100", hex: "#57534E", name: "Asiana Airlines" },
  TG: { gradient: "from-purple-700 via-amber-600 to-slate-900", accent: "text-purple-100", hex: "#7E22CE", name: "Thai Airways" },
  AI: { gradient: "from-orange-600 via-rose-700 to-slate-900",accent: "text-orange-100", hex: "#EA580C", name: "Air India" },
  CA: { gradient: "from-red-700 via-amber-700 to-slate-900", accent: "text-red-100",   hex: "#B91C1C", name: "Air China" },
  CZ: { gradient: "from-blue-700 via-sky-700 to-slate-900",  accent: "text-blue-100",  hex: "#1D4ED8", name: "China Southern" },
  MU: { gradient: "from-red-700 via-rose-800 to-slate-900",  accent: "text-red-100",   hex: "#B91C1C", name: "China Eastern" },
  MH: { gradient: "from-blue-700 via-red-700 to-slate-900",  accent: "text-blue-100",  hex: "#1D4ED8", name: "Malaysia Airlines" },
  GA: { gradient: "from-sky-600 via-blue-800 to-slate-900",  accent: "text-sky-100",   hex: "#0284C7", name: "Garuda Indonesia" },
  PR: { gradient: "from-amber-600 via-blue-800 to-slate-900",accent: "text-amber-100", hex: "#D97706", name: "Philippine Airlines" },

  // Oceania
  QF: { gradient: "from-red-700 via-red-900 to-slate-900",   accent: "text-red-100",   hex: "#B91C1C", name: "Qantas" },
  NZ: { gradient: "from-stone-800 via-slate-800 to-slate-900", accent: "text-stone-100", hex: "#1F2937", name: "Air New Zealand" },

  // Africa / South America
  ET: { gradient: "from-emerald-700 via-amber-700 to-slate-900", accent: "text-emerald-100", hex: "#047857", name: "Ethiopian Airlines" },
  SA: { gradient: "from-sky-600 via-orange-600 to-slate-900",accent: "text-sky-100",   hex: "#0284C7", name: "South African Airways" },
  LA: { gradient: "from-rose-700 via-rose-900 to-slate-900", accent: "text-rose-100",  hex: "#9F1239", name: "LATAM" },
};

const NAME_INDEX: Array<{ needle: string; iata: keyof typeof PALETTE }> = [];
for (const [iata, brand] of Object.entries(PALETTE)) {
  NAME_INDEX.push({ needle: brand.name.toLowerCase(), iata: iata as keyof typeof PALETTE });
}

const FALLBACK_GRADIENTS: AirlineBrand[] = [
  { gradient: "from-indigo-600 via-indigo-800 to-slate-900", accent: "text-indigo-100", hex: "#4F46E5", name: "Carrier" },
  { gradient: "from-emerald-600 via-emerald-800 to-slate-900", accent: "text-emerald-100", hex: "#047857", name: "Carrier" },
  { gradient: "from-rose-600 via-rose-800 to-slate-900",     accent: "text-rose-100",     hex: "#9F1239", name: "Carrier" },
  { gradient: "from-amber-600 via-amber-800 to-slate-900",   accent: "text-amber-100",    hex: "#B45309", name: "Carrier" },
  { gradient: "from-cyan-600 via-cyan-800 to-slate-900",     accent: "text-cyan-100",     hex: "#0E7490", name: "Carrier" },
  { gradient: "from-purple-600 via-purple-800 to-slate-900", accent: "text-purple-100",   hex: "#6D28D9", name: "Carrier" },
  { gradient: "from-blue-600 via-blue-800 to-slate-900",     accent: "text-blue-100",     hex: "#1D4ED8", name: "Carrier" },
];

function djb2(s: string): number {
  let h = 5381;
  for (let i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) | 0;
  return Math.abs(h);
}

/**
 * Resolve an airline brand from an IATA code or airline name.
 * Falls back to a deterministic hash-coloured gradient.
 */
export function resolveAirlineBrand(input?: string | null): AirlineBrand {
  if (!input) return FALLBACK_GRADIENTS[0]!;
  const trimmed = input.trim();
  if (!trimmed) return FALLBACK_GRADIENTS[0]!;

  // 1) Direct IATA match. We accept "SQ", "SQ31", "SQ 31", " sq ".
  const iataMatch = trimmed.match(/^([A-Z]{2})\s?\d*$/i)?.[1]?.toUpperCase();
  if (iataMatch && PALETTE[iataMatch]) return PALETTE[iataMatch]!;

  // 2) Name substring match (case insensitive).
  const lower = trimmed.toLowerCase();
  const named = NAME_INDEX.find((n) => lower.includes(n.needle));
  if (named) return PALETTE[named.iata]!;

  // 3) Hash fallback — every unique input gets a stable colour.
  const idx = djb2(trimmed.toLowerCase()) % FALLBACK_GRADIENTS.length;
  return FALLBACK_GRADIENTS[idx]!;
}

/**
 * Convenience wrapper for a `TravelDocument` (boarding pass).
 *
 * Resolution order:
 *   1. IATA prefix extracted from `doc.number` (e.g. "SQ31-AX7K" → "SQ").
 *   2. The label / airline name substring.
 *   3. Hash-based fallback gradient.
 *
 * Step 2 runs only if step 1 resolves to a hash fallback — otherwise we
 * lock in the brand match from the document number even when the label
 * is empty.
 */
export function brandForBoardingPass(doc: TravelDocument): AirlineBrand {
  const iataFromNumber = doc.number.match(/^([A-Z]{2})\d/)?.[1];
  if (iataFromNumber && PALETTE[iataFromNumber.toUpperCase()]) {
    return PALETTE[iataFromNumber.toUpperCase()]!;
  }
  // Fall through to the label so a doc like number "ZZ7777-FOO" but
  // label "Lufthansa flight" still themes correctly.
  return resolveAirlineBrand(doc.label ?? doc.number ?? "");
}
