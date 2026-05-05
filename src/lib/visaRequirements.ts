/**
 * Visa requirements lookup — deterministic table (D 45).
 *
 * Backs the "Entry requirements" card in TripDetail. Indexed by
 * (citizen ISO-3166-1 alpha-2, destination ISO-3166-1 alpha-2). Returns
 * a high-level visa policy band — the data is curated, not exhaustive,
 * and the UI MUST show a "verify with the consulate" disclaimer.
 *
 * Why static: a real consular API requires per-country credentialing
 * we don't have, and policies are stable enough on a months-to-years
 * timescale that a curated table is reliable for the common pairs we
 * cover (G7 + EU + APAC + a few more).
 *
 * Bands (ascending difficulty):
 *  - "visa_free"   – entry without visa for stays up to maxDays.
 *  - "voa"         – visa on arrival, usually paid + 1 form.
 *  - "evisa"       – online application required before arrival.
 *  - "visa_required" – embassy/consulate appointment + paperwork.
 *  - "no_relations" – politically restricted / blocked entry.
 *
 * Returned shape includes `passportValidityMonths` so the UI can flag
 * passports about to expire (most countries require 6 months).
 */

export type VisaBand =
  | "visa_free"
  | "voa"
  | "evisa"
  | "visa_required"
  | "no_relations";

export interface VisaPolicy {
  band: VisaBand;
  /** Stay limit if band is visa_free / voa / evisa. */
  maxDays?: number;
  /** Required passport validity at arrival, in months. Default 6. */
  passportValidityMonths: number;
  /** Short human-readable note shown next to the band chip. */
  note?: string;
}

/** Convenience: human label for the chip. */
export function labelForBand(band: VisaBand): string {
  switch (band) {
    case "visa_free":
      return "Visa-free";
    case "voa":
      return "Visa on arrival";
    case "evisa":
      return "eVisa required";
    case "visa_required":
      return "Visa required";
    case "no_relations":
      return "Restricted";
  }
}

/** UI tone for the chip. */
export function toneForBand(band: VisaBand): "success" | "info" | "warning" | "critical" {
  switch (band) {
    case "visa_free":
      return "success";
    case "voa":
    case "evisa":
      return "info";
    case "visa_required":
      return "warning";
    case "no_relations":
      return "critical";
  }
}

// Curated table for common citizenship → destination pairs.
// Keyed as `${citizen}->${destination}` ISO-3166-1 alpha-2.
// Source: official government tourism / immigration pages, last reviewed
// 2025-Q4. UI must show a verification disclaimer regardless.
const TABLE: Record<string, VisaPolicy> = {
  // — US passport
  "US->GB": { band: "visa_free", maxDays: 180, passportValidityMonths: 6 },
  "US->FR": { band: "visa_free", maxDays: 90, passportValidityMonths: 3, note: "Schengen 90/180" },
  "US->DE": { band: "visa_free", maxDays: 90, passportValidityMonths: 3, note: "Schengen 90/180" },
  "US->NL": { band: "visa_free", maxDays: 90, passportValidityMonths: 3, note: "Schengen 90/180" },
  "US->ES": { band: "visa_free", maxDays: 90, passportValidityMonths: 3, note: "Schengen 90/180" },
  "US->IT": { band: "visa_free", maxDays: 90, passportValidityMonths: 3, note: "Schengen 90/180" },
  "US->CH": { band: "visa_free", maxDays: 90, passportValidityMonths: 3 },
  "US->SG": { band: "visa_free", maxDays: 90, passportValidityMonths: 6 },
  "US->JP": { band: "visa_free", maxDays: 90, passportValidityMonths: 6 },
  "US->KR": { band: "visa_free", maxDays: 90, passportValidityMonths: 6, note: "K-ETA may apply" },
  "US->TH": { band: "visa_free", maxDays: 60, passportValidityMonths: 6 },
  "US->IN": { band: "evisa", maxDays: 30, passportValidityMonths: 6, note: "Apply ≥4 days ahead" },
  "US->CN": { band: "visa_required", passportValidityMonths: 6 },
  "US->AE": { band: "visa_free", maxDays: 30, passportValidityMonths: 6 },
  "US->QA": { band: "visa_free", maxDays: 30, passportValidityMonths: 6 },
  "US->TR": { band: "evisa", maxDays: 90, passportValidityMonths: 6 },
  "US->AU": { band: "evisa", maxDays: 90, passportValidityMonths: 6, note: "ETA via app" },
  "US->NZ": { band: "evisa", maxDays: 90, passportValidityMonths: 3, note: "NZeTA required" },
  "US->BR": { band: "visa_free", maxDays: 90, passportValidityMonths: 6 },
  "US->ZA": { band: "visa_free", maxDays: 90, passportValidityMonths: 1 },
  "US->EG": { band: "voa", maxDays: 30, passportValidityMonths: 6 },
  "US->KE": { band: "evisa", maxDays: 90, passportValidityMonths: 6 },

  // — UK passport
  "GB->US": { band: "evisa", maxDays: 90, passportValidityMonths: 6, note: "ESTA required" },
  "GB->FR": { band: "visa_free", maxDays: 90, passportValidityMonths: 3, note: "Schengen 90/180" },
  "GB->DE": { band: "visa_free", maxDays: 90, passportValidityMonths: 3 },
  "GB->JP": { band: "visa_free", maxDays: 90, passportValidityMonths: 6 },
  "GB->SG": { band: "visa_free", maxDays: 90, passportValidityMonths: 6 },
  "GB->IN": { band: "evisa", maxDays: 30, passportValidityMonths: 6 },
  "GB->TH": { band: "visa_free", maxDays: 60, passportValidityMonths: 6 },
  "GB->AE": { band: "visa_free", maxDays: 30, passportValidityMonths: 6 },
  "GB->AU": { band: "evisa", maxDays: 90, passportValidityMonths: 6, note: "ETA required" },
  "GB->NZ": { band: "evisa", maxDays: 90, passportValidityMonths: 3 },

  // — Schengen / EU passports (sample row using DE; UI can repeat for FR/NL/etc.)
  "DE->US": { band: "evisa", maxDays: 90, passportValidityMonths: 6, note: "ESTA required" },
  "DE->GB": { band: "visa_free", maxDays: 180, passportValidityMonths: 1 },
  "DE->JP": { band: "visa_free", maxDays: 90, passportValidityMonths: 6 },
  "DE->SG": { band: "visa_free", maxDays: 90, passportValidityMonths: 6 },
  "DE->IN": { band: "evisa", maxDays: 30, passportValidityMonths: 6 },
  "DE->AE": { band: "visa_free", maxDays: 90, passportValidityMonths: 6 },
  "DE->AU": { band: "evisa", maxDays: 90, passportValidityMonths: 6, note: "ETA required" },

  // — India passport
  "IN->US": { band: "visa_required", passportValidityMonths: 6 },
  "IN->GB": { band: "visa_required", passportValidityMonths: 6 },
  "IN->SG": { band: "voa", maxDays: 30, passportValidityMonths: 6 },
  "IN->TH": { band: "visa_free", maxDays: 60, passportValidityMonths: 6 },
  "IN->AE": { band: "evisa", maxDays: 60, passportValidityMonths: 6 },
  "IN->JP": { band: "visa_required", passportValidityMonths: 6 },

  // — Japan passport
  "JP->US": { band: "evisa", maxDays: 90, passportValidityMonths: 6, note: "ESTA required" },
  "JP->FR": { band: "visa_free", maxDays: 90, passportValidityMonths: 3 },
  "JP->SG": { band: "visa_free", maxDays: 90, passportValidityMonths: 6 },
  "JP->KR": { band: "visa_free", maxDays: 90, passportValidityMonths: 6 },
};

export function lookupVisaPolicy(
  citizenIso: string,
  destinationIso: string,
): VisaPolicy {
  const key = `${citizenIso.toUpperCase()}->${destinationIso.toUpperCase()}`;
  const hit = TABLE[key];
  if (hit) return hit;
  // Sensible default for unknown pairs: assume embassy visa, 6mo
  // passport validity. The UI surfaces this with the disclaimer copy.
  return {
    band: "visa_required",
    passportValidityMonths: 6,
    note: "Verify with embassy",
  };
}

/** Map a country name (as returned by `findAirport`) → ISO alpha-2. */
const COUNTRY_TO_ISO: Record<string, string> = {
  "United States": "US",
  Canada: "CA",
  Mexico: "MX",
  "United Kingdom": "GB",
  France: "FR",
  Germany: "DE",
  Netherlands: "NL",
  Spain: "ES",
  Italy: "IT",
  Switzerland: "CH",
  Turkey: "TR",
  Singapore: "SG",
  Japan: "JP",
  China: "CN",
  "South Korea": "KR",
  Thailand: "TH",
  India: "IN",
  Malaysia: "MY",
  UAE: "AE",
  Qatar: "QA",
  Australia: "AU",
  "New Zealand": "NZ",
  Brazil: "BR",
  Colombia: "CO",
  Peru: "PE",
  Argentina: "AR",
  "South Africa": "ZA",
  Egypt: "EG",
  Kenya: "KE",
};

export function isoForCountry(country: string): string | null {
  return COUNTRY_TO_ISO[country] ?? null;
}
