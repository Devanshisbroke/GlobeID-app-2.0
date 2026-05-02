import { describe, it, expect } from "vitest";
import { computeSuggestions } from "@/lib/smartSuggestions";
import type { TravelDocument, TravelRecord } from "@/store/userStore";

const NOW = new Date("2026-03-09T12:00:00Z").getTime();

const passport = (expires: string): TravelDocument => ({
  id: "p1",
  type: "passport",
  label: "Passport",
  country: "US",
  countryFlag: "🇺🇸",
  number: "P-123",
  issueDate: "2020-01-01",
  expiryDate: expires,
  status: "active",
});

const boarding = (id: string, expiry: string, tripId?: string): TravelDocument => ({
  id,
  type: "boarding_pass",
  label: `BP ${id}`,
  country: "Test",
  countryFlag: "🏳️",
  number: id,
  issueDate: "2026-01-01",
  expiryDate: expiry,
  status: "active",
  tripId: tripId ?? null,
});

const trip = (
  id: string,
  date: string,
  type: TravelRecord["type"] = "upcoming",
): TravelRecord => ({
  id,
  from: "SFO",
  to: "SIN",
  date,
  airline: "Singapore Airlines",
  duration: "18h",
  type,
  source: "history",
});

describe("computeSuggestions", () => {
  it("flags a document expiring within 30 days as medium", () => {
    const out = computeSuggestions({
      documents: [passport("2026-03-25")],
      trips: [],
      now: NOW,
    });
    expect(out[0]?.kind).toBe("doc_expiry");
    expect(out[0]?.severity).toBe("medium");
  });

  it("flags an expired document as high", () => {
    const out = computeSuggestions({
      documents: [passport("2026-02-01")],
      trips: [],
      now: NOW,
    });
    expect(out[0]?.severity).toBe("high");
  });

  it("flags an imminent boarding pass as high", () => {
    const out = computeSuggestions({
      documents: [boarding("bp1", "2026-03-09")],
      trips: [],
      now: NOW,
    });
    expect(out.some((s) => s.kind === "imminent_departure")).toBe(true);
  });

  it("suggests insurance for trips within 14 days when none exists", () => {
    const out = computeSuggestions({
      documents: [],
      trips: [trip("t1", "2026-03-12")],
      now: NOW,
    });
    expect(out.some((s) => s.kind === "missing_insurance")).toBe(true);
  });

  it("flags FX moves >=5%", () => {
    const out = computeSuggestions({
      documents: [],
      trips: [],
      fxDelta: { code: "JPY", pct: -7.2 },
      now: NOW,
    });
    expect(out.some((s) => s.kind === "fx_drop")).toBe(true);
  });

  it("ignores past trips", () => {
    const out = computeSuggestions({
      documents: [],
      trips: [trip("t-past", "2025-01-01", "past")],
      now: NOW,
    });
    expect(out.some((s) => s.kind === "missing_insurance")).toBe(false);
  });

  it("orders high severity suggestions before medium", () => {
    const out = computeSuggestions({
      documents: [
        passport("2026-03-25"), // medium
        boarding("bp1", "2026-03-09"), // high
      ],
      trips: [],
      now: NOW,
    });
    expect(out[0]?.severity).toBe("high");
  });
});
