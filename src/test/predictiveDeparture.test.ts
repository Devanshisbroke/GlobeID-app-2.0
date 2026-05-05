import { describe, it, expect } from "vitest";
import { predictDeparture } from "@/lib/predictiveDeparture";

describe("predictiveDeparture", () => {
  it("computes fire time = departure - (commute + buffer)", () => {
    const r = predictDeparture({
      departureIso: "2025-06-01T18:00:00Z",
      baseCommuteMinutes: 30,
      airportBufferMinutes: 90,
      now: new Date("2025-06-01T12:00:00Z"),
    });
    // 30 + 90 = 120 minutes before 18:00 → 16:00 UTC
    expect(r.fireAtIso).toBe("2025-06-01T16:00:00.000Z");
    expect(r.effectiveCommuteMinutes).toBe(30);
    expect(r.totalLeadMinutes).toBe(120);
    expect(r.alreadyPast).toBe(false);
  });

  it("scales commute by traffic factor", () => {
    const r = predictDeparture({
      departureIso: "2025-06-01T18:00:00Z",
      baseCommuteMinutes: 30,
      airportBufferMinutes: 90,
      trafficFactor: 1.5,
      now: new Date("2025-06-01T12:00:00Z"),
    });
    expect(r.effectiveCommuteMinutes).toBe(45);
    expect(r.totalLeadMinutes).toBe(135);
    expect(r.copy).toContain("heavier than usual");
  });

  it("clamps absurd traffic factors", () => {
    const r = predictDeparture({
      departureIso: "2025-06-01T18:00:00Z",
      baseCommuteMinutes: 30,
      trafficFactor: 99,
      now: new Date("2025-06-01T12:00:00Z"),
    });
    expect(r.effectiveCommuteMinutes).toBe(90); // 30 * 3
  });

  it("flags alreadyPast when fire time is in the past", () => {
    const r = predictDeparture({
      departureIso: "2025-06-01T13:00:00Z",
      baseCommuteMinutes: 30,
      airportBufferMinutes: 90,
      now: new Date("2025-06-01T12:00:00Z"), // < 2h before departure
    });
    expect(r.alreadyPast).toBe(true);
  });

  it("uses defaults when buffer omitted", () => {
    const r = predictDeparture({
      departureIso: "2025-06-01T18:00:00Z",
      baseCommuteMinutes: 30,
      now: new Date("2025-06-01T12:00:00Z"),
    });
    expect(r.totalLeadMinutes).toBe(120);
  });
});
