import { describe, it, expect } from "vitest";
import { tripLifecycleSchema } from "@shared/types/lifecycle";
import { travelRecordToLifecycle } from "@/lib/tripLifecycle";
import type { TravelRecord } from "@/store/userStore";

const upcoming: TravelRecord = {
  id: "tr-up",
  from: "SFO",
  to: "SIN",
  date: "2099-01-01",
  airline: "Singapore Airlines",
  duration: "18h 15m",
  type: "upcoming",
  flightNumber: "SQ 31",
  source: "history",
};

const past: TravelRecord = {
  id: "tr-past",
  from: "JFK",
  to: "LHR",
  date: "2024-02-12",
  airline: "British Airways",
  duration: "7h 10m",
  type: "past",
  flightNumber: "BA 178",
  source: "history",
};

const current: TravelRecord = {
  id: "tr-cur",
  from: "LHR",
  to: "CDG",
  date: "2024-02-15",
  airline: "Air France",
  duration: "1h 20m",
  type: "current",
  flightNumber: "AF 1681",
  source: "planner",
};

describe("travelRecordToLifecycle()", () => {
  it("synthesises a schema-valid lifecycle for upcoming trips", () => {
    const lifecycle = travelRecordToLifecycle(upcoming);
    expect(() => tripLifecycleSchema.parse(lifecycle)).not.toThrow();
    expect(lifecycle.state).toBe("booked");
    expect(lifecycle.tripId).toBe("tr-up");
    expect(lifecycle.legs).toHaveLength(1);
    expect(lifecycle.legs[0].id).toBe("leg-tr-up");
    expect(lifecycle.legs[0].fromIata).toBe("SFO");
    expect(lifecycle.legs[0].toIata).toBe("SIN");
    expect(lifecycle.legs[0].flightNumber).toBe("SQ 31");
    expect(lifecycle.legs[0].source).toBe("history");
    expect(lifecycle.destinations).toEqual(["SIN"]);
    expect(lifecycle.reminders).toEqual([]);
  });

  it("marks past trips as `complete`", () => {
    const lifecycle = travelRecordToLifecycle(past);
    expect(() => tripLifecycleSchema.parse(lifecycle)).not.toThrow();
    expect(lifecycle.state).toBe("complete");
  });

  it("marks current/in-progress trips as `active`", () => {
    const lifecycle = travelRecordToLifecycle(current);
    expect(() => tripLifecycleSchema.parse(lifecycle)).not.toThrow();
    expect(lifecycle.state).toBe("active");
    expect(lifecycle.legs[0].source).toBe("planner");
  });

  it("uses the resolved city name in the lifecycle name when available", () => {
    const lifecycle = travelRecordToLifecycle(upcoming);
    // SFO and SIN are both in the bundled airport catalog.
    expect(lifecycle.name).toMatch(/San Francisco/);
    expect(lifecycle.name).toMatch(/Singapore/);
  });

  it("falls back to the flight number being null when the source has none", () => {
    const noFlight: TravelRecord = { ...upcoming, flightNumber: undefined };
    const lifecycle = travelRecordToLifecycle(noFlight);
    expect(lifecycle.legs[0].flightNumber).toBeNull();
  });
});
