/**
 * Itinerary tight-connection detector (BACKLOG I 107).
 *
 * Looks at consecutive flight legs and flags layovers below the safe
 * minimum-connection-time (MCT) for the connection airport's country.
 *
 * Pure function — no IO. Caller (TripDetail) decides UX (warning toast,
 * suggested rebooking, etc.).
 *
 * MCT thresholds (in minutes) — heuristics from IATA reference data:
 *   - same-airport, domestic→domestic     : 30
 *   - same-airport, domestic→international : 75
 *   - same-airport, international→domestic : 75
 *   - same-airport, international→international : 90
 *   - terminal change adds                 : 30 minutes
 */

export interface FlightLeg {
  id: string;
  arrivalAirportIata: string;
  departureAirportIata: string;
  /** ISO datetime string for arrival. */
  arrivalAt: string;
  /** ISO datetime string for departure. */
  departureAt: string;
  /** "domestic" or "international" — caller decides. */
  type?: "domestic" | "international";
  /** Optional terminal ("T1", "T5", ...). */
  terminal?: string;
}

export interface TightConnectionFlag {
  legA: FlightLeg;
  legB: FlightLeg;
  /** Layover duration in minutes (positive). */
  layoverMinutes: number;
  /** Required minimum connection time. */
  requiredMinutes: number;
  /** "tight" (within 30 min of MCT) | "missed" (below MCT). */
  severity: "tight" | "missed";
  reason: string;
}

function minutesBetween(aIso: string, bIso: string): number {
  return (new Date(bIso).getTime() - new Date(aIso).getTime()) / 60000;
}

function requiredMct(legA: FlightLeg, legB: FlightLeg): number {
  const aType = legA.type ?? "domestic";
  const bType = legB.type ?? "domestic";
  let base = 30;
  if (aType === "international" && bType === "international") base = 90;
  else if (aType === "international" || bType === "international") base = 75;
  if (legA.terminal && legB.terminal && legA.terminal !== legB.terminal) {
    base += 30;
  }
  return base;
}

/**
 * Walk the legs in chronological order, return any tight or missed
 * connections.
 */
export function detectTightConnections(
  legs: FlightLeg[],
): TightConnectionFlag[] {
  if (legs.length < 2) return [];
  const sorted = [...legs].sort(
    (a, b) =>
      new Date(a.departureAt).getTime() - new Date(b.departureAt).getTime(),
  );
  const flags: TightConnectionFlag[] = [];
  for (let i = 0; i < sorted.length - 1; i += 1) {
    const a = sorted[i];
    const b = sorted[i + 1];
    if (a.arrivalAirportIata !== b.departureAirportIata) continue;
    const layover = minutesBetween(a.arrivalAt, b.departureAt);
    if (layover <= 0) continue; // same-day overlap, ignore
    const req = requiredMct(a, b);
    if (layover >= req + 30) continue; // comfortable
    const severity: "tight" | "missed" = layover < req ? "missed" : "tight";
    const reason =
      severity === "missed"
        ? `Below the ${req}-minute minimum at ${a.arrivalAirportIata}.`
        : `Within 30 minutes of the ${req}-minute minimum at ${a.arrivalAirportIata}.`;
    flags.push({
      legA: a,
      legB: b,
      layoverMinutes: Math.round(layover),
      requiredMinutes: req,
      severity,
      reason,
    });
  }
  return flags;
}
