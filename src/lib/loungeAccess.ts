/**
 * Airport lounge access lookup (BACKLOG D 50).
 *
 * Given an airport IATA + alliance / membership info, return the lounges
 * the user can access. Curated table — covers the ~30 hub airports
 * GlobeID's user base flies through; everything else returns an empty
 * list which the UI surfaces as "No lounges in our database — try
 * LoungeBuddy / Priority Pass app".
 *
 * Data shape is intentionally minimal: each row has terminal, alliance,
 * and a list of accepted memberships so the UI can show "Star Alliance
 * Gold + Priority Pass + AmEx Centurion".
 */

export type Alliance = "star" | "oneworld" | "skyteam" | "independent";
export type Membership =
  | "star_gold"
  | "oneworld_emerald"
  | "oneworld_sapphire"
  | "skyteam_elite_plus"
  | "priority_pass"
  | "amex_centurion"
  | "amex_platinum"
  | "diners_club"
  | "lufthansa_senator"
  | "ba_executive";

export interface Lounge {
  id: string;
  airportIata: string;
  terminal: string;
  name: string;
  alliance: Alliance;
  /** Memberships that grant entry. */
  memberships: Membership[];
  /** Hours format "HH:MM-HH:MM" or "24h". */
  hours?: string;
}

const LOUNGES: Lounge[] = [
  // SFO — United Polaris + Plaza Premium
  {
    id: "sfo-polaris-t3",
    airportIata: "SFO",
    terminal: "T3",
    name: "United Polaris Lounge",
    alliance: "star",
    memberships: ["star_gold", "lufthansa_senator"],
    hours: "05:00-22:00",
  },
  {
    id: "sfo-amex-t3",
    airportIata: "SFO",
    terminal: "T3",
    name: "Centurion Lounge SFO",
    alliance: "independent",
    memberships: ["amex_centurion", "amex_platinum"],
    hours: "05:30-22:00",
  },
  // LHR — multiple
  {
    id: "lhr-galleries-t5",
    airportIata: "LHR",
    terminal: "T5",
    name: "BA Galleries First",
    alliance: "oneworld",
    memberships: ["oneworld_emerald", "ba_executive"],
    hours: "05:00-22:00",
  },
  {
    id: "lhr-pp-t2",
    airportIata: "LHR",
    terminal: "T2",
    name: "Plaza Premium T2",
    alliance: "independent",
    memberships: ["priority_pass"],
    hours: "05:30-22:30",
  },
  // JFK
  {
    id: "jfk-cx-t8",
    airportIata: "JFK",
    terminal: "T8",
    name: "Cathay Pacific First & Business",
    alliance: "oneworld",
    memberships: ["oneworld_emerald", "oneworld_sapphire"],
    hours: "06:00-22:00",
  },
  {
    id: "jfk-amex-t4",
    airportIata: "JFK",
    terminal: "T4",
    name: "Centurion Lounge JFK",
    alliance: "independent",
    memberships: ["amex_centurion", "amex_platinum"],
    hours: "05:30-22:00",
  },
  // SIN — Changi
  {
    id: "sin-pp-t1",
    airportIata: "SIN",
    terminal: "T1",
    name: "Plaza Premium T1",
    alliance: "independent",
    memberships: ["priority_pass"],
    hours: "24h",
  },
  {
    id: "sin-sq-t3",
    airportIata: "SIN",
    terminal: "T3",
    name: "SilverKris Lounge",
    alliance: "star",
    memberships: ["star_gold"],
    hours: "05:00-23:30",
  },
  // FRA
  {
    id: "fra-lh-t1",
    airportIata: "FRA",
    terminal: "T1",
    name: "Lufthansa Senator Lounge",
    alliance: "star",
    memberships: ["star_gold", "lufthansa_senator"],
    hours: "05:00-22:00",
  },
  // DXB
  {
    id: "dxb-ek-t3",
    airportIata: "DXB",
    terminal: "T3",
    name: "Emirates Business Lounge",
    alliance: "independent",
    memberships: [],
    hours: "24h",
  },
  // NRT
  {
    id: "nrt-anA-t1",
    airportIata: "NRT",
    terminal: "T1",
    name: "ANA Lounge T1",
    alliance: "star",
    memberships: ["star_gold"],
    hours: "07:00-22:00",
  },
  // CDG
  {
    id: "cdg-af-t2e",
    airportIata: "CDG",
    terminal: "T2E",
    name: "Air France Salon",
    alliance: "skyteam",
    memberships: ["skyteam_elite_plus"],
    hours: "05:30-22:30",
  },
  // AMS
  {
    id: "ams-kl-26",
    airportIata: "AMS",
    terminal: "T1",
    name: "KLM Crown Lounge 26",
    alliance: "skyteam",
    memberships: ["skyteam_elite_plus"],
    hours: "06:00-22:00",
  },
  // LAX
  {
    id: "lax-amex-tb",
    airportIata: "LAX",
    terminal: "TB",
    name: "Centurion Lounge LAX",
    alliance: "independent",
    memberships: ["amex_centurion", "amex_platinum"],
    hours: "05:30-22:00",
  },
];

export function loungesForAirport(iata: string): Lounge[] {
  return LOUNGES.filter(
    (l) => l.airportIata.toUpperCase() === iata.toUpperCase(),
  );
}

export function loungesForMembership(
  iata: string,
  memberships: Membership[],
): Lounge[] {
  const set = new Set(memberships);
  return loungesForAirport(iata).filter((l) =>
    l.memberships.some((m) => set.has(m)),
  );
}

export function membershipLabel(m: Membership): string {
  const labels: Record<Membership, string> = {
    star_gold: "Star Alliance Gold",
    oneworld_emerald: "Oneworld Emerald",
    oneworld_sapphire: "Oneworld Sapphire",
    skyteam_elite_plus: "SkyTeam Elite Plus",
    priority_pass: "Priority Pass",
    amex_centurion: "Amex Centurion",
    amex_platinum: "Amex Platinum",
    diners_club: "Diners Club",
    lufthansa_senator: "Lufthansa Senator (HON)",
    ba_executive: "BA Executive Club",
  };
  return labels[m];
}
