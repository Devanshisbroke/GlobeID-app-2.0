/**
 * Slice-B Phase-1 — contextEngine pure function tests.
 */
import { describe, it, expect } from "vitest";
import { evaluateContext } from "@/core/contextEngine";
import type { TripLifecycle } from "@shared/types/lifecycle";

const NOW = 1_700_000_000_000;
const HOUR = 3_600_000;

function trip(over: Partial<TripLifecycle> = {}): TripLifecycle {
  return {
    tripId: "t1",
    name: "London Run",
    theme: "vacation",
    state: "booked",
    destinations: ["LHR"],
    legs: [
      {
        id: "leg1",
        fromIata: "JFK",
        toIata: "LHR",
        date: new Date(NOW + 4 * HOUR).toISOString(),
        airline: "BA",
        flightNumber: "118",
        type: "upcoming",
        source: "planner",
      },
    ],
    reminders: [],
    startsAt: new Date(NOW + 4 * HOUR).toISOString(),
    endsAt: new Date(NOW + 4 * HOUR).toISOString(),
    ...over,
  };
}

describe("contextEngine.evaluateContext", () => {
  it("returns empty recs for a cold input", () => {
    const r = evaluateContext({ now: NOW });
    expect(r.recommendations).toEqual([]);
    expect(r.summary.activeTripId).toBeNull();
  });

  it("flags trip imminent within 6h", () => {
    const r = evaluateContext({ now: NOW, trips: [trip()] });
    const ids = r.recommendations.map((x) => x.kind);
    expect(ids).toContain("trip_imminent");
  });

  it("emits high-priority fraud rec for high severity findings", () => {
    const r = evaluateContext({
      now: NOW,
      fraudFindings: [
        {
          rule: "velocity",
          severity: "high",
          message: "5 debits in 10 min",
          signature: "fraud:velocity:abc",
          transactionIds: ["t1"],
        },
      ],
    });
    const fraud = r.recommendations.find((x) => x.kind === "fraud_alert");
    expect(fraud).toBeDefined();
    expect(fraud!.priority).toBeGreaterThanOrEqual(80);
    expect(r.summary.fraudHighCount).toBe(1);
  });

  it("emits budget over rec when usage flagged", () => {
    const r = evaluateContext({
      now: NOW,
      budget: {
        defaultCurrency: "USD",
        caps: [],
        usage: [
          {
            scope: "category:food",
            cap: { scope: "category:food", capAmount: 100, currency: "USD", period: "trip", alertThreshold: 0.8 },
            spent: 150,
            remaining: -50,
            fractionUsed: 1.5,
            status: "over",
            period: { start: "2023-11-01", end: "2023-11-30" },
            excludedCurrencies: [],
          },
        ],
      },
    });
    expect(r.summary.budgetOverCount).toBe(1);
    expect(r.recommendations.find((x) => x.kind === "budget_alert")).toBeDefined();
  });

  it("nudges for emergency contact when none exist and no trips", () => {
    const r = evaluateContext({ now: NOW, emergencyContactsCount: 0 });
    expect(r.recommendations.find((x) => x.kind === "no_emergency_contact")).toBeDefined();
  });

  it("requests prefetch for cold inputs", () => {
    const r = evaluateContext({ now: NOW });
    expect(r.prefetch).toContain("budget");
    expect(r.prefetch).toContain("fraud");
  });

  it("sorts recommendations by priority descending", () => {
    const r = evaluateContext({
      now: NOW,
      trips: [trip()],
      fraudFindings: [
        { rule: "velocity", severity: "high", message: "x", signature: "fraud:velocity:1", transactionIds: ["a"] },
      ],
    });
    for (let i = 1; i < r.recommendations.length; i++) {
      expect(r.recommendations[i - 1]!.priority).toBeGreaterThanOrEqual(r.recommendations[i]!.priority);
    }
  });
});
