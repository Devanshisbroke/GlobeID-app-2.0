/**
 * Slice-B Phase-7 — serviceEngine ranking tests.
 */
import { describe, it, expect } from "vitest";
import { rankServices } from "@/core/serviceEngine";

describe("serviceEngine.rankServices", () => {
  it("boosts visa+insurance for foreign trips in <30 days", () => {
    const r = rankServices({
      activeCountryIso2: "US",
      nextDestinationIso2: "GB",
      nextTrip: null,
      budget: null,
      daysToNextTrip: 14,
    });
    const visaIdx = r.findIndex((x) => x.tab === "visa");
    const localIdx = r.findIndex((x) => x.tab === "local");
    expect(visaIdx).toBeLessThan(localIdx);
  });

  it("boosts rides+food when trip imminent", () => {
    const r = rankServices({
      activeCountryIso2: "US",
      nextDestinationIso2: "FR",
      nextTrip: null,
      budget: null,
      daysToNextTrip: 1,
    });
    const top = r.slice(0, 3).map((x) => x.tab);
    expect(top).toContain("rides");
  });

  it("favours local when no upcoming trip", () => {
    const r = rankServices({
      activeCountryIso2: "JP",
      nextDestinationIso2: null,
      nextTrip: null,
      budget: null,
      daysToNextTrip: Number.POSITIVE_INFINITY,
    });
    const local = r.find((x) => x.tab === "local");
    expect(local).toBeDefined();
    expect(local!.score).toBeGreaterThan(1);
  });

  it("returns deterministic ordering for identical inputs", () => {
    const i = {
      activeCountryIso2: "US",
      nextDestinationIso2: "GB",
      nextTrip: null,
      budget: null,
      daysToNextTrip: 5,
    };
    const a = rankServices(i);
    const b = rankServices(i);
    expect(a.map((x) => x.tab)).toEqual(b.map((x) => x.tab));
  });
});
