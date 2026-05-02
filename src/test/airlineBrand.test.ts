import { describe, it, expect } from "vitest";
import {
  resolveAirlineBrand,
  brandForBoardingPass,
} from "@/lib/airlineBrand";
import type { TravelDocument } from "@/store/userStore";

const mkDoc = (
  number: string,
  label: string,
  overrides: Partial<TravelDocument> = {},
): TravelDocument => ({
  id: "td-test",
  type: "boarding_pass",
  label,
  country: "Test",
  countryFlag: "🏳️",
  number,
  issueDate: "2026-03-01",
  expiryDate: "2026-03-10",
  status: "active",
  ...overrides,
});

describe("resolveAirlineBrand", () => {
  it("matches IATA code with adjacent flight number", () => {
    const sq = resolveAirlineBrand("SQ31");
    expect(sq.name).toBe("Singapore Airlines");
    expect(sq.gradient).toContain("from-blue-700");
  });

  it("matches IATA with whitespace", () => {
    const ek = resolveAirlineBrand("EK 73");
    expect(ek.name).toBe("Emirates");
  });

  it("matches by full carrier name (case insensitive)", () => {
    const af = resolveAirlineBrand("AIR FRANCE");
    expect(af.name).toBe("Air France");
  });

  it("falls back to a stable hash gradient for unknown carriers", () => {
    const a = resolveAirlineBrand("Unicorn Air");
    const b = resolveAirlineBrand("Unicorn Air");
    expect(a.gradient).toBe(b.gradient);
  });

  it("returns a non-empty default for null/empty", () => {
    expect(resolveAirlineBrand("").gradient).toBeTruthy();
    expect(resolveAirlineBrand(null).gradient).toBeTruthy();
    expect(resolveAirlineBrand(undefined).gradient).toBeTruthy();
  });
});

describe("brandForBoardingPass", () => {
  it("extracts IATA from doc number prefix", () => {
    const doc = mkDoc("SQ31-AX7K", "SQ31 — SFO→SIN");
    expect(brandForBoardingPass(doc).name).toBe("Singapore Airlines");
  });

  it("falls back to label name when number prefix is unknown", () => {
    // The first match step extracts the prefix from `^([A-Z]{2})\d`
    // which on "XX1234" yields "XX" — not in PALETTE — so we fall back
    // to the label substring index.
    const doc = mkDoc("ZZ7777-FOO", "Lufthansa flight");
    expect(brandForBoardingPass(doc).name).toBe("Lufthansa");
  });
});
