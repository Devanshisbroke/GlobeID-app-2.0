import { describe, it, expect } from "vitest";
import {
  detectTightConnections,
  type FlightLeg,
} from "@/lib/connectionDetector";

const baseLeg = (overrides: Partial<FlightLeg>): FlightLeg => ({
  id: "x",
  arrivalAirportIata: "X",
  departureAirportIata: "Y",
  arrivalAt: "2025-01-01T10:00:00Z",
  departureAt: "2025-01-01T08:00:00Z",
  ...overrides,
});

describe("connectionDetector.detectTightConnections", () => {
  it("returns empty for fewer than 2 legs", () => {
    expect(detectTightConnections([])).toEqual([]);
    expect(detectTightConnections([baseLeg({})])).toEqual([]);
  });

  it("flags missed connection when below MCT", () => {
    const a = baseLeg({
      id: "a",
      arrivalAirportIata: "LHR",
      arrivalAt: "2025-01-01T10:00:00Z",
      type: "international",
    });
    const b = baseLeg({
      id: "b",
      departureAirportIata: "LHR",
      arrivalAirportIata: "MAN",
      departureAt: "2025-01-01T11:00:00Z", // 60 min layover, MCT=75
      arrivalAt: "2025-01-01T12:00:00Z",
      type: "domestic",
    });
    const flags = detectTightConnections([a, b]);
    expect(flags).toHaveLength(1);
    expect(flags[0].severity).toBe("missed");
    expect(flags[0].layoverMinutes).toBe(60);
    expect(flags[0].requiredMinutes).toBe(75);
  });

  it("flags tight connection when within 30 min of MCT", () => {
    const a = baseLeg({
      id: "a",
      arrivalAirportIata: "JFK",
      arrivalAt: "2025-01-01T10:00:00Z",
      type: "domestic",
    });
    const b = baseLeg({
      id: "b",
      departureAirportIata: "JFK",
      departureAt: "2025-01-01T10:50:00Z", // 50 min, MCT=30, < 30+30
      arrivalAt: "2025-01-01T12:00:00Z",
      type: "domestic",
    });
    const flags = detectTightConnections([a, b]);
    expect(flags).toHaveLength(1);
    expect(flags[0].severity).toBe("tight");
  });

  it("ignores comfortable connections", () => {
    const a = baseLeg({
      id: "a",
      arrivalAirportIata: "JFK",
      arrivalAt: "2025-01-01T10:00:00Z",
    });
    const b = baseLeg({
      id: "b",
      departureAirportIata: "JFK",
      departureAt: "2025-01-01T13:00:00Z", // 3-hour layover
      arrivalAt: "2025-01-01T15:00:00Z",
    });
    expect(detectTightConnections([a, b])).toEqual([]);
  });

  it("ignores legs that don't connect (different airports)", () => {
    const a = baseLeg({ id: "a", arrivalAirportIata: "JFK" });
    const b = baseLeg({ id: "b", departureAirportIata: "LAX" });
    expect(detectTightConnections([a, b])).toEqual([]);
  });

  it("adds 30 minutes when terminal changes", () => {
    const a = baseLeg({
      id: "a",
      arrivalAirportIata: "LHR",
      arrivalAt: "2025-01-01T10:00:00Z",
      type: "international",
      terminal: "T2",
    });
    const b = baseLeg({
      id: "b",
      departureAirportIata: "LHR",
      departureAt: "2025-01-01T11:30:00Z", // 90 min, MCT=75+30=105
      arrivalAt: "2025-01-01T13:00:00Z",
      type: "domestic",
      terminal: "T5",
    });
    const flags = detectTightConnections([a, b]);
    expect(flags).toHaveLength(1);
    expect(flags[0].requiredMinutes).toBe(105);
  });
});
