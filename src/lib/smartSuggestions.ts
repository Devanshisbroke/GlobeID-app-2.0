/**
 * Smart suggestion engine — deterministic, no LLM.
 *
 * Produces an ordered list of `Suggestion` records for the Home screen
 * based on the user's current state:
 *
 *   1. Documents expiring within 30 days  (severity = high)
 *   2. Boarding passes departing within 24h (severity = high)
 *   3. Upcoming international trips with no travel insurance (severity = medium)
 *   4. Currency holdings whose home-currency value moved >5% in the
 *      last 7d (severity = medium) — placeholder hook for the wallet
 *      store; only computed when `fxDelta` is provided.
 *   5. Trips next week without a booked hotel / ride / activity
 *      (severity = low)
 *
 * The engine is pure and side-effect free so it composes cleanly with
 * Zustand selectors and is trivially testable.
 */

import type { TravelDocument, TravelRecord } from "@/store/userStore";
import { describeExpiry } from "@/lib/documentExpiry";

export type SuggestionSeverity = "high" | "medium" | "low";

export type SuggestionKind =
  | "doc_expiry"
  | "imminent_departure"
  | "missing_insurance"
  | "fx_drop"
  | "missing_booking";

export interface Suggestion {
  id: string;
  kind: SuggestionKind;
  severity: SuggestionSeverity;
  title: string;
  body: string;
  /** Deep-link href the Home card should navigate to on tap. */
  href: string;
}

export interface SuggestionInput {
  documents: TravelDocument[];
  trips: TravelRecord[];
  /** Optional: current home-currency value vs 7-day avg, normalised. */
  fxDelta?: { code: string; pct: number };
  now?: number;
}

const DAY_MS = 86_400_000;

function isoOnly(d: string): string {
  return d.slice(0, 10);
}

function daysFromNow(iso: string, now: number): number {
  const ts = new Date(/^\d{4}-\d{2}-\d{2}$/.test(iso) ? `${iso}T00:00:00Z` : iso).getTime();
  if (!Number.isFinite(ts)) return Number.POSITIVE_INFINITY;
  return Math.round((ts - now) / DAY_MS);
}

export function computeSuggestions({
  documents,
  trips,
  fxDelta,
  now = Date.now(),
}: SuggestionInput): Suggestion[] {
  const out: Suggestion[] = [];

  // 1) Document expiry
  for (const doc of documents) {
    const info = describeExpiry(doc.expiryDate, new Date(now));
    if (info.severity === "critical") {
      out.push({
        id: `exp-${doc.id}`,
        kind: "doc_expiry",
        severity: "high",
        title: `${doc.label} ${info.daysUntil < 0 ? "expired" : "expires soon"}`,
        body: `${info.label} — renew before your next trip to avoid border issues.`,
        href: "/vault",
      });
    } else if (info.severity === "warning") {
      out.push({
        id: `exp-${doc.id}`,
        kind: "doc_expiry",
        severity: "medium",
        title: `${doc.label} expires in ${info.daysUntil} days`,
        body: `Tap to view your document and start the renewal process.`,
        href: "/vault",
      });
    }
  }

  // 2) Imminent boarding passes (≤24h)
  for (const doc of documents) {
    if (doc.type !== "boarding_pass") continue;
    const dt = daysFromNow(isoOnly(doc.expiryDate), now);
    if (dt >= 0 && dt <= 1) {
      out.push({
        id: `imminent-${doc.id}`,
        kind: "imminent_departure",
        severity: "high",
        title: `Departing ${dt === 0 ? "today" : "tomorrow"}: ${doc.label}`,
        body: `Tap to open your boarding pass. We'll surface it as you approach the gate.`,
        href: doc.tripId ? `/trip/${doc.tripId}` : "/wallet",
      });
    }
  }

  // 3) Missing travel insurance
  const insuranceCountries = new Set(
    documents.filter((d) => d.type === "travel_insurance" && d.status === "active").map((d) => d.country.toLowerCase()),
  );
  for (const trip of trips) {
    if (trip.type !== "upcoming") continue;
    const dt = daysFromNow(trip.date, now);
    if (dt < 0 || dt > 14) continue;
    // Heuristic: int'l = different IATA region. We don't have the
    // mapping here so flag any upcoming trip without ANY active
    // insurance, rather than per-country. Caller can refine.
    if (insuranceCountries.size === 0) {
      out.push({
        id: `ins-${trip.id}`,
        kind: "missing_insurance",
        severity: "medium",
        title: `Add insurance for ${trip.from}→${trip.to}`,
        body: `Your trip is ${dt === 0 ? "today" : `in ${dt} days`}. We don't see active travel insurance.`,
        href: "/services",
      });
      break; // surface once
    }
  }

  // 4) Currency drop
  if (fxDelta && Math.abs(fxDelta.pct) >= 5) {
    out.push({
      id: `fx-${fxDelta.code}`,
      kind: "fx_drop",
      severity: "medium",
      title: `${fxDelta.code} ${fxDelta.pct < 0 ? "dropped" : "jumped"} ${Math.abs(fxDelta.pct).toFixed(1)}%`,
      body: `7-day move vs. your home currency. Consider rebalancing your travel wallet.`,
      href: "/wallet",
    });
  }

  // 5) Missing bookings (low priority placeholder — we only flag if
  //    a trip is within 7 days and the user has no boarding pass yet).
  for (const trip of trips) {
    if (trip.type !== "upcoming") continue;
    const dt = daysFromNow(trip.date, now);
    if (dt < 0 || dt > 7) continue;
    const hasPass = documents.some(
      (d) =>
        d.type === "boarding_pass" &&
        d.label.toUpperCase().includes(trip.from.toUpperCase()) &&
        d.label.toUpperCase().includes(trip.to.toUpperCase()),
    );
    if (!hasPass) {
      out.push({
        id: `book-${trip.id}`,
        kind: "missing_booking",
        severity: "low",
        title: `Book your ${trip.from}→${trip.to} flight`,
        body: `Trip in ${dt} days; we don't see a boarding pass yet. Plan rides and a hotel from Services.`,
        href: "/services",
      });
    }
  }

  // Severity sort: high → medium → low (stable within bucket).
  const order: Record<SuggestionSeverity, number> = { high: 0, medium: 1, low: 2 };
  return out.sort((a, b) => order[a.severity] - order[b.severity]);
}
