/**
 * Minimal ISO-3 → (display name, flag emoji) lookup.
 *
 * MRZ-issued documents encode the issuing country and nationality as ISO
 * 3166-1 alpha-3 (e.g. `USA`, `IND`, `GBR`). The wallet pass UI wants a
 * human-readable country and a flag emoji; this module provides both
 * without pulling in a multi-MB country dataset.
 *
 * The map intentionally covers the high-volume travel corridors used by
 * the seed data + the main test fixtures. Unknown codes fall back to
 * the raw ISO-3 string and a generic 🌐 emoji so callers never crash.
 */

export interface CountryDisplay {
  /** ISO 3166-1 alpha-2 (used to derive the flag emoji). */
  iso2: string;
  /** Human-readable country name. */
  name: string;
  /** Pre-rendered flag emoji. */
  flag: string;
}

/**
 * Convert an ISO-2 code into a regional-indicator flag emoji.
 * `US` → 🇺🇸. Returns the input unchanged if it isn't a 2-letter code.
 */
export function iso2ToFlag(iso2: string): string {
  const code = iso2.trim().toUpperCase();
  if (!/^[A-Z]{2}$/.test(code)) return "🌐";
  const offset = 0x1f1e6 - 0x41;
  return String.fromCodePoint(
    code.charCodeAt(0) + offset,
    code.charCodeAt(1) + offset,
  );
}

const ISO3_TO_DISPLAY: Record<string, { iso2: string; name: string }> = {
  AFG: { iso2: "AF", name: "Afghanistan" },
  ARE: { iso2: "AE", name: "United Arab Emirates" },
  ARG: { iso2: "AR", name: "Argentina" },
  AUS: { iso2: "AU", name: "Australia" },
  AUT: { iso2: "AT", name: "Austria" },
  BEL: { iso2: "BE", name: "Belgium" },
  BGD: { iso2: "BD", name: "Bangladesh" },
  BRA: { iso2: "BR", name: "Brazil" },
  CAN: { iso2: "CA", name: "Canada" },
  CHE: { iso2: "CH", name: "Switzerland" },
  CHN: { iso2: "CN", name: "China" },
  COL: { iso2: "CO", name: "Colombia" },
  CZE: { iso2: "CZ", name: "Czechia" },
  DEU: { iso2: "DE", name: "Germany" },
  DNK: { iso2: "DK", name: "Denmark" },
  EGY: { iso2: "EG", name: "Egypt" },
  ESP: { iso2: "ES", name: "Spain" },
  FIN: { iso2: "FI", name: "Finland" },
  FRA: { iso2: "FR", name: "France" },
  GBR: { iso2: "GB", name: "United Kingdom" },
  GRC: { iso2: "GR", name: "Greece" },
  HKG: { iso2: "HK", name: "Hong Kong" },
  IDN: { iso2: "ID", name: "Indonesia" },
  IND: { iso2: "IN", name: "India" },
  IRL: { iso2: "IE", name: "Ireland" },
  ISL: { iso2: "IS", name: "Iceland" },
  ISR: { iso2: "IL", name: "Israel" },
  ITA: { iso2: "IT", name: "Italy" },
  JPN: { iso2: "JP", name: "Japan" },
  KEN: { iso2: "KE", name: "Kenya" },
  KOR: { iso2: "KR", name: "South Korea" },
  LKA: { iso2: "LK", name: "Sri Lanka" },
  MAR: { iso2: "MA", name: "Morocco" },
  MEX: { iso2: "MX", name: "Mexico" },
  MYS: { iso2: "MY", name: "Malaysia" },
  NGA: { iso2: "NG", name: "Nigeria" },
  NLD: { iso2: "NL", name: "Netherlands" },
  NOR: { iso2: "NO", name: "Norway" },
  NPL: { iso2: "NP", name: "Nepal" },
  NZL: { iso2: "NZ", name: "New Zealand" },
  PAK: { iso2: "PK", name: "Pakistan" },
  PER: { iso2: "PE", name: "Peru" },
  PHL: { iso2: "PH", name: "Philippines" },
  POL: { iso2: "PL", name: "Poland" },
  PRT: { iso2: "PT", name: "Portugal" },
  QAT: { iso2: "QA", name: "Qatar" },
  ROU: { iso2: "RO", name: "Romania" },
  RUS: { iso2: "RU", name: "Russia" },
  SAU: { iso2: "SA", name: "Saudi Arabia" },
  SGP: { iso2: "SG", name: "Singapore" },
  SWE: { iso2: "SE", name: "Sweden" },
  THA: { iso2: "TH", name: "Thailand" },
  TUR: { iso2: "TR", name: "Türkiye" },
  TWN: { iso2: "TW", name: "Taiwan" },
  UKR: { iso2: "UA", name: "Ukraine" },
  USA: { iso2: "US", name: "United States" },
  VNM: { iso2: "VN", name: "Vietnam" },
  ZAF: { iso2: "ZA", name: "South Africa" },
};

/**
 * Resolve any 2- or 3-letter country code to a `CountryDisplay`. Falls
 * back to the raw input + 🌐 if the code isn't in the lookup table —
 * never throws.
 */
export function resolveCountry(code: string | null | undefined): CountryDisplay {
  const trimmed = (code ?? "").trim().toUpperCase();
  if (trimmed.length === 3 && ISO3_TO_DISPLAY[trimmed]) {
    const { iso2, name } = ISO3_TO_DISPLAY[trimmed];
    return { iso2, name, flag: iso2ToFlag(iso2) };
  }
  if (trimmed.length === 2) {
    return { iso2: trimmed, name: trimmed, flag: iso2ToFlag(trimmed) };
  }
  return { iso2: "", name: trimmed || "Unknown", flag: "🌐" };
}
