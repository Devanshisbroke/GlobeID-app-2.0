import { describe, it, expect } from "vitest";
import {
  currencyForAirport,
  timezoneOffsetHours,
  timezoneDelta,
  localTimeAt,
  generatePackingList,
  loungesAt,
  groundTransportFor,
  climateBand,
} from "@/lib/tripIntel";
import { findAirport } from "@shared/data/airports";

describe("tripIntel — currency lookup", () => {
  it("maps known airports to ISO 4217", () => {
    expect(currencyForAirport("LHR")).toBe("GBP");
    expect(currencyForAirport("CDG")).toBe("EUR");
    expect(currencyForAirport("NRT")).toBe("JPY");
    expect(currencyForAirport("DEL")).toBe("INR");
    expect(currencyForAirport("SIN")).toBe("SGD");
    expect(currencyForAirport("DXB")).toBe("AED");
    expect(currencyForAirport("SYD")).toBe("AUD");
  });

  it("falls back to USD for unknown airports", () => {
    expect(currencyForAirport("ZZZ")).toBe("USD");
  });
});

describe("tripIntel — timezone", () => {
  it("returns hand-tuned overrides for common airports", () => {
    expect(timezoneOffsetHours("LHR")).toBe(0);
    expect(timezoneOffsetHours("DEL")).toBe(5.5);
    expect(timezoneOffsetHours("SFO")).toBe(-8);
    expect(timezoneOffsetHours("AKL")).toBe(13);
  });

  it("computes delta correctly across hemispheres", () => {
    const d = timezoneDelta("SFO", "SIN");
    expect(d.deltaHours).toBe(16);
    expect(d.pretty).toBe("+16h");
  });

  it("formats half-hour offsets", () => {
    const d = timezoneDelta("LHR", "DEL");
    expect(d.deltaHours).toBe(5.5);
    expect(d.pretty).toBe("+5h 30m");
  });

  it("handles negative deltas with minus sign", () => {
    const d = timezoneDelta("SIN", "SFO");
    expect(d.deltaHours).toBe(-16);
    expect(d.pretty).toMatch(/^[−-]16h$/);
  });

  it("returns Same time for matching offsets", () => {
    const d = timezoneDelta("LHR", "LHR");
    expect(d.pretty).toBe("Same time");
  });

  it("computes local time at destination consistently", () => {
    const fixed = new Date("2025-06-15T12:00:00Z");
    const local = localTimeAt("SFO", fixed);
    // SFO is UTC-8 (no DST handling) → 04:00
    expect(local.hours).toBe(4);
    expect(local.minutes).toBe(0);
  });
});

describe("tripIntel — packing list", () => {
  it("always includes essentials regardless of climate", () => {
    const list = generatePackingList("SFO", 5, 5);
    const ids = list.map((i) => i.id);
    expect(ids).toContain("passport");
    expect(ids).toContain("phone");
    expect(ids).toContain("wallet");
    expect(ids).toContain("toothbrush");
  });

  it("scales clothing counts with duration up to 7-day cap", () => {
    const short = generatePackingList("SFO", 3, 5);
    const long = generatePackingList("SFO", 14, 5);
    const shortUnderwear = short.find((i) => i.id === "underwear")!;
    const longUnderwear = long.find((i) => i.id === "underwear")!;
    expect(shortUnderwear.count).toBe(3);
    expect(longUnderwear.count).toBe(7); // capped
  });

  it("adds cold-weather gear for polar / cold destinations in northern winter", () => {
    // Reykjavik would be AKL? Use ICN in January (idx 0) — temperate band
    // for ICN (lat 37.46) is "temperate" / "cold" in winter.
    const list = generatePackingList("ICN", 7, 0);
    const ids = list.map((i) => i.id);
    expect(ids).toContain("jacket");
    expect(ids).toContain("gloves");
  });

  it("adds tropical gear for low-latitude destinations", () => {
    const list = generatePackingList("SIN", 5, 5);
    const ids = list.map((i) => i.id);
    expect(ids).toContain("sunscreen");
    expect(ids).toContain("swimwear");
  });

  it("adds long-trip extras at 7+ days", () => {
    const list = generatePackingList("LHR", 10, 5);
    const ids = list.map((i) => i.id);
    expect(ids).toContain("laundry-bag");
    expect(ids).toContain("extra-shoes");
  });

  it("clamps duration at 30 days even if asked for more", () => {
    const list = generatePackingList("LHR", 60, 5);
    // No throw, just clamped — sanity check
    expect(list.length).toBeGreaterThan(10);
  });

  it("classifies climate by latitude × month correctly", () => {
    const sin = findAirport("SIN")!;
    const lhr = findAirport("LHR")!;
    expect(climateBand(sin, 0)).toBe("tropical"); // lat 1.36 → always tropical
    expect(climateBand(sin, 6)).toBe("tropical");
    expect(climateBand(lhr, 0)).toBe("cold"); // northern winter
    expect(climateBand(lhr, 6)).toBe("temperate"); // northern summer
  });
});

describe("tripIntel — lounges", () => {
  it("returns lounges at Frankfurt for Star Alliance", () => {
    const matches = loungesAt("FRA", "Star Alliance");
    expect(matches.length).toBeGreaterThan(0);
    expect(matches[0]!.loungeName).toContain("Lufthansa");
  });

  it("filters by alliance when provided", () => {
    const all = loungesAt("ICN");
    const sky = loungesAt("ICN", "SkyTeam");
    expect(sky.length).toBeLessThan(all.length);
  });

  it("returns empty list for airports with no lounges", () => {
    expect(loungesAt("CUN")).toEqual([]);
  });
});

describe("tripIntel — ground transport", () => {
  it("includes Uber globally", () => {
    const links = groundTransportFor("LHR");
    expect(links.some((l) => l.id === "uber")).toBe(true);
  });

  it("includes Lyft only in US/Canada", () => {
    const sfo = groundTransportFor("SFO");
    const lhr = groundTransportFor("LHR");
    expect(sfo.some((l) => l.id === "lyft")).toBe(true);
    expect(lhr.some((l) => l.id === "lyft")).toBe(false);
  });

  it("includes Grab in Southeast Asia", () => {
    const sin = groundTransportFor("SIN");
    expect(sin.some((l) => l.id === "grab")).toBe(true);
  });

  it("includes Bolt in covered European countries", () => {
    const lhr = groundTransportFor("LHR");
    expect(lhr.some((l) => l.id === "bolt")).toBe(true);
  });

  it("returns empty list for unknown airports", () => {
    expect(groundTransportFor("ZZZ")).toEqual([]);
  });

  it("encodes destination coordinates into the deep-link URL", () => {
    const sfo = groundTransportFor("SFO");
    const uber = sfo.find((l) => l.id === "uber")!;
    expect(uber.url).toContain("dropoff[latitude]=37.6213");
    expect(uber.url).toContain("dropoff[longitude]=-122.379");
  });
});
