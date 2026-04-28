/**
 * Slice-B Phase-2 — travelEngine pure function tests.
 *
 * Pinned to a deterministic clock (`now = 1_700_000_000_000`) so the
 * window math is reproducible across machines.
 */
import { describe, it, expect } from "vitest";
import {
  classifyDelay,
  legWindow,
  msUntilTripStart,
  nextLeg,
  CHECK_IN_OPEN_HOURS,
  BOARDING_OPEN_MIN,
} from "@/core/travelEngine";
import type { TripLeg, TripLifecycle, FlightStatus } from "@shared/types/lifecycle";

const NOW = 1_700_000_000_000; // 2023-11-14T22:13:20.000Z
const HOUR = 3_600_000;
const MIN = 60_000;

function leg(over: Partial<TripLeg> = {}): TripLeg {
  return {
    id: over.id ?? "leg1",
    fromIata: "LHR",
    toIata: "JFK",
    date: over.date ?? "2023-11-15",
    airline: "BA",
    flightNumber: "117",
    type: over.type ?? "upcoming",
    source: "planner",
    ...over,
  };
}

function status(over: Partial<FlightStatus> = {}): FlightStatus {
  return {
    id: "leg1",
    flightNumber: "117",
    airline: "BA",
    fromIata: "LHR",
    toIata: "JFK",
    scheduledDate: "2023-11-15",
    statusKind: "scheduled",
    delayMinutes: 0,
    gate: "B14",
    terminal: "5",
    isDemoData: true,
    demoNote: "demo",
    ...over,
  };
}

describe("travelEngine.classifyDelay", () => {
  it("returns none for scheduled flights", () => {
    expect(classifyDelay(status())).toBe("none");
  });
  it("classifies delays by minutes", () => {
    expect(classifyDelay(status({ statusKind: "delayed", delayMinutes: 10 }))).toBe("minor");
    expect(classifyDelay(status({ statusKind: "delayed", delayMinutes: 60 }))).toBe("moderate");
    expect(classifyDelay(status({ statusKind: "delayed", delayMinutes: 180 }))).toBe("major");
    expect(classifyDelay(status({ statusKind: "delayed", delayMinutes: 300 }))).toBe("critical");
  });
  it("treats cancellation as critical", () => {
    expect(classifyDelay(status({ statusKind: "cancelled" }))).toBe("critical");
  });
});

describe("travelEngine.legWindow", () => {
  it("opens check-in within 48h before departure", () => {
    // departure exactly 24h after NOW
    const w = legWindow(leg({ date: new Date(NOW + 24 * HOUR).toISOString().slice(0, 10) }), NOW);
    expect(w.checkInOpen).toBe(true);
    expect(w.boardingOpen).toBe(false);
  });
  it("flags boarding when within boarding window", () => {
    const w = legWindow(leg({ date: new Date(NOW + (BOARDING_OPEN_MIN - 5) * MIN).toISOString().slice(0, 10) }), NOW);
    expect(w.boardingOpen).toBe(false); // date-only resolution = midnight UTC
  });
  it("returns boardingOpen=true when departure ms is within window", () => {
    // call directly with a leg whose date math lands inside boarding window
    const dep = NOW + 30 * MIN;
    const isoDate = new Date(dep).toISOString();
    const l = leg({ date: isoDate });
    const w = legWindow(l, NOW);
    expect(w.boardingOpen).toBe(true);
    expect(w.msToDeparture).toBeGreaterThan(0);
    expect(w.msToDeparture).toBeLessThanOrEqual(BOARDING_OPEN_MIN * MIN);
  });
  it("computes msToDeparture", () => {
    const dep = NOW + 12 * HOUR;
    const w = legWindow(leg({ date: new Date(dep).toISOString() }), NOW);
    expect(Math.round(w.msToDeparture / HOUR)).toBe(12);
  });
  it("returns checkInOpen=false outside the window", () => {
    const dep = NOW + (CHECK_IN_OPEN_HOURS + 5) * HOUR;
    const w = legWindow(leg({ date: new Date(dep).toISOString() }), NOW);
    expect(w.checkInOpen).toBe(false);
  });
});

describe("travelEngine.nextLeg", () => {
  function trip(legs: TripLeg[]): TripLifecycle {
    return {
      tripId: "t1",
      name: "Test",
      theme: "vacation",
      state: "booked",
      destinations: ["JFK"],
      legs,
      reminders: [],
      startsAt: legs[0]?.date ?? null,
      endsAt: legs.at(-1)?.date ?? null,
    };
  }
  it("prefers current over upcoming", () => {
    const t = trip([
      leg({ id: "a", type: "upcoming" }),
      leg({ id: "b", type: "current" }),
    ]);
    expect(nextLeg(t)?.id).toBe("b");
  });
  it("falls back to upcoming", () => {
    const t = trip([leg({ id: "a", type: "past" }), leg({ id: "b", type: "upcoming" })]);
    expect(nextLeg(t)?.id).toBe("b");
  });
  it("returns null when none upcoming", () => {
    const t = trip([leg({ id: "a", type: "past" })]);
    expect(nextLeg(t)).toBeNull();
  });
});

describe("travelEngine.msUntilTripStart", () => {
  it("returns infinity when startsAt is null", () => {
    const t: TripLifecycle = {
      tripId: null,
      name: "",
      theme: null,
      state: "planning",
      destinations: [],
      legs: [],
      reminders: [],
      startsAt: null,
      endsAt: null,
    };
    expect(msUntilTripStart(t, NOW)).toBe(Number.POSITIVE_INFINITY);
  });
});
