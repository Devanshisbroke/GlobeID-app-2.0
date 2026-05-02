/**
 * Wallet pass ordering rules.
 *
 * Apple/Google Wallet auto-pin a boarding pass to the top of the stack
 * when departure is imminent (≤24h). We replicate that with a pure
 * sort: boarding passes whose `expiryDate` (used here as the
 * departure date proxy — boarding passes expire on the day of travel)
 * falls within the next 24 hours bubble to the top, ordered by
 * proximity. Everything else preserves source order so the user's
 * intentional ordering still applies once nothing is imminent.
 *
 * Multi-leg trip grouping: passes that share the same `tripId` are
 * kept contiguous so a SFO→SIN→NRT trip shows its 2 boarding passes
 * back-to-back. The lead pass of the group inherits the earliest
 * departure for pin priority. Passes without a trip id are sorted
 * individually.
 */

import type { TravelDocument } from "@/store/userStore";

const TWENTY_FOUR_HOURS_MS = 24 * 60 * 60 * 1000;

function isBoardingPass(doc: TravelDocument): boolean {
  return doc.type === "boarding_pass";
}

function timeToDepartureMs(doc: TravelDocument, now: number): number {
  const departure = new Date(doc.expiryDate + "T00:00:00").getTime();
  return Number.isFinite(departure) ? departure - now : Number.POSITIVE_INFINITY;
}

function shouldAutoPin(doc: TravelDocument, now: number): boolean {
  if (!isBoardingPass(doc)) return false;
  const dt = timeToDepartureMs(doc, now);
  return dt >= -TWENTY_FOUR_HOURS_MS && dt <= TWENTY_FOUR_HOURS_MS;
}

export interface PassGroup {
  /** Trip lifecycle id, or `null` for ungrouped passes. */
  tripId: string | null;
  /** Documents in source order, lead pass first. */
  docs: TravelDocument[];
  /** Pin priority: earliest absolute time to a leg, in ms. */
  priorityMs: number;
}

function groupKey(doc: TravelDocument): string {
  // Boarding passes group by tripId; everything else stays singleton.
  if (isBoardingPass(doc) && doc.tripId) return `trip:${doc.tripId}`;
  return `solo:${doc.id}`;
}

/**
 * Group passes by tripId, then sort groups so:
 *   1. Any group containing a within-24h boarding pass comes first,
 *      sorted by closest departure.
 *   2. Remaining groups preserve original ordering.
 */
export function orderPasses(
  documents: TravelDocument[],
  now: number = Date.now(),
): TravelDocument[] {
  const groups: PassGroup[] = [];
  const groupIndex = new Map<string, number>();

  for (const doc of documents) {
    const key = groupKey(doc);
    let idx = groupIndex.get(key);
    if (idx === undefined) {
      idx = groups.length;
      groupIndex.set(key, idx);
      groups.push({
        tripId: isBoardingPass(doc) ? doc.tripId ?? null : null,
        docs: [],
        priorityMs: Number.POSITIVE_INFINITY,
      });
    }
    groups[idx]!.docs.push(doc);
    if (isBoardingPass(doc)) {
      const dt = Math.abs(timeToDepartureMs(doc, now));
      if (dt < groups[idx]!.priorityMs) groups[idx]!.priorityMs = dt;
    }
  }

  // Stable sort: pinned groups first (sorted by priority asc), then the rest in source order.
  const annotated = groups.map((g, i) => ({
    g,
    sourceOrder: i,
    pin: g.docs.some((d) => shouldAutoPin(d, now)),
  }));
  annotated.sort((a, b) => {
    if (a.pin !== b.pin) return a.pin ? -1 : 1;
    if (a.pin) return a.g.priorityMs - b.g.priorityMs;
    return a.sourceOrder - b.sourceOrder;
  });

  return annotated.flatMap((a) => a.g.docs);
}

export const _testHelpers = { isBoardingPass, shouldAutoPin };
