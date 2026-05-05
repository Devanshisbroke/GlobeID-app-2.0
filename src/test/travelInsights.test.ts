import { describe, it, expect } from "vitest";
import {
  detectSpendAnomalies,
  computeTravelPattern,
  estimateFlightCarbon,
  detectTightConnections,
  detectFrequentRoutes,
  type Transaction,
} from "@/lib/travelInsights";
import type { TravelRecord } from "@/store/userStore";

const NOW = Date.UTC(2026, 0, 15, 12, 0, 0);
const day = (n: number) => NOW - n * 24 * 60 * 60 * 1000;

describe("detectSpendAnomalies", () => {
  it("flags merchants whose current week is >3σ above 8-week mean", () => {
    // Stable history of $20-23 weekly at "Lyft", then a $90 spike this week.
    const txs: Transaction[] = [
      { id: "a", ts: day(2), amountUSD: 90, merchant: "Lyft" },
      { id: "b", ts: day(8), amountUSD: 20, merchant: "Lyft" },
      { id: "c", ts: day(15), amountUSD: 21, merchant: "Lyft" },
      { id: "d", ts: day(22), amountUSD: 22, merchant: "Lyft" },
      { id: "e", ts: day(29), amountUSD: 21, merchant: "Lyft" },
      { id: "f", ts: day(36), amountUSD: 23, merchant: "Lyft" },
    ];
    const flags = detectSpendAnomalies(txs, NOW);
    expect(flags.length).toBe(1);
    expect(flags[0]!.merchant).toBe("Lyft");
    expect(flags[0]!.zScore).toBeGreaterThan(3);
  });

  it("does not flag noisy merchants with too few prior weeks", () => {
    const txs: Transaction[] = [
      { id: "a", ts: day(2), amountUSD: 90, merchant: "NewCafe" },
      { id: "b", ts: day(9), amountUSD: 5, merchant: "NewCafe" },
    ];
    expect(detectSpendAnomalies(txs, NOW)).toEqual([]);
  });

  it("does not flag a stable spend with no spike", () => {
    const txs: Transaction[] = [
      { id: "a", ts: day(2), amountUSD: 50, merchant: "Spotify" },
      { id: "b", ts: day(9), amountUSD: 50, merchant: "Spotify" },
      { id: "c", ts: day(16), amountUSD: 50, merchant: "Spotify" },
      { id: "d", ts: day(23), amountUSD: 50, merchant: "Spotify" },
      { id: "e", ts: day(30), amountUSD: 50, merchant: "Spotify" },
    ];
    expect(detectSpendAnomalies(txs, NOW)).toEqual([]);
  });
});

describe("computeTravelPattern", () => {
  it("returns null sentinels for empty history", () => {
    const r = computeTravelPattern([], NOW);
    expect(r.topDestinationIata).toBeNull();
    expect(r.preferredWeekday).toBeNull();
    expect(r.totalFlightsWindow).toBe(0);
  });

  it("identifies the most-visited destination over the last year", () => {
    const records: TravelRecord[] = [
      mkFlight("a", "SFO", "TYO", "2025-10-01"),
      mkFlight("b", "SFO", "TYO", "2025-11-01"),
      mkFlight("c", "SFO", "TYO", "2025-12-01"),
      mkFlight("d", "SFO", "SIN", "2025-09-01"),
    ];
    const r = computeTravelPattern(records, NOW);
    expect(r.topDestinationIata).toBe("TYO");
    expect(r.topDestinationVisits).toBe(3);
    expect(r.totalFlightsWindow).toBe(4);
  });
});

describe("estimateFlightCarbon", () => {
  it("uses the long-haul factor on intercontinental flights", () => {
    const c = estimateFlightCarbon(8800, "economy");
    // 8800 * 0.134 = 1179.2
    expect(c.kgCo2e).toBe(1179);
    expect(c.cabinClass).toBe("economy");
  });
  it("applies the business cabin multiplier (×2.9)", () => {
    const eco = estimateFlightCarbon(8800, "economy").kgCo2e;
    const biz = estimateFlightCarbon(8800, "business").kgCo2e;
    expect(biz).toBeGreaterThan(eco * 2.5);
    expect(biz).toBeLessThan(eco * 3.5);
  });
});

describe("detectTightConnections", () => {
  it("flags layovers under 60 minutes as critical", () => {
    const out = detectTightConnections([
      {
        id: "L1",
        fromIata: "SFO",
        toIata: "LHR",
        departureTs: Date.UTC(2026, 1, 1, 10, 0, 0),
        arrivalTs: Date.UTC(2026, 1, 1, 18, 0, 0),
      },
      {
        id: "L2",
        fromIata: "LHR",
        toIata: "FRA",
        departureTs: Date.UTC(2026, 1, 1, 18, 45, 0),
        arrivalTs: Date.UTC(2026, 1, 1, 21, 0, 0),
      },
    ]);
    expect(out).toHaveLength(1);
    expect(out[0]!.severity).toBe("critical");
    expect(out[0]!.layoverMinutes).toBe(45);
  });

  it("does not flag comfortable layovers", () => {
    const out = detectTightConnections([
      {
        id: "L1",
        fromIata: "SFO",
        toIata: "LHR",
        departureTs: Date.UTC(2026, 1, 1, 10, 0, 0),
        arrivalTs: Date.UTC(2026, 1, 1, 18, 0, 0),
      },
      {
        id: "L2",
        fromIata: "LHR",
        toIata: "FRA",
        departureTs: Date.UTC(2026, 1, 1, 22, 0, 0),
        arrivalTs: Date.UTC(2026, 1, 2, 0, 0, 0),
      },
    ]);
    expect(out).toEqual([]);
  });
});

describe("detectFrequentRoutes", () => {
  it("counts ≥3 same (origin→dest) within 12 months as frequent", () => {
    const records: TravelRecord[] = [
      mkFlight("a", "SFO", "JFK", "2025-04-01"),
      mkFlight("b", "SFO", "JFK", "2025-06-01"),
      mkFlight("c", "SFO", "JFK", "2025-09-01"),
      mkFlight("d", "SFO", "TYO", "2025-10-01"),
    ];
    const out = detectFrequentRoutes(records, NOW);
    expect(out).toHaveLength(1);
    expect(out[0]!.fromIata).toBe("SFO");
    expect(out[0]!.toIata).toBe("JFK");
    expect(out[0]!.count).toBe(3);
  });
});

function mkFlight(
  id: string,
  from: string,
  to: string,
  date: string,
): TravelRecord {
  return {
    id,
    from,
    to,
    date,
    airline: "Test Air",
    duration: "10h",
    type: "past",
    source: "history",
  };
}
