import { describe, it, expect } from "vitest";
import { orderPasses } from "@/lib/passOrdering";
import type { TravelDocument } from "@/store/userStore";

const NOW = new Date("2026-03-09T12:00:00Z").getTime();

function mk(
  id: string,
  type: TravelDocument["type"],
  expiry: string,
  tripId?: string,
): TravelDocument {
  return {
    id,
    type,
    label: id,
    country: "Test",
    countryFlag: "🏳️",
    number: id.toUpperCase(),
    issueDate: "2026-01-01",
    expiryDate: expiry,
    status: "active",
    tripId: tripId ?? null,
  };
}

describe("orderPasses", () => {
  it("returns docs unchanged when nothing is imminent", () => {
    const docs = [
      mk("a", "passport", "2030-01-01"),
      mk("b", "boarding_pass", "2026-04-01"),
      mk("c", "visa", "2027-01-01"),
    ];
    const out = orderPasses(docs, NOW);
    expect(out.map((d) => d.id)).toEqual(["a", "b", "c"]);
  });

  it("pins a boarding pass departing within 24h to the top", () => {
    const docs = [
      mk("a", "passport", "2030-01-01"),
      mk("b", "boarding_pass", "2026-04-01"),
      mk("imminent", "boarding_pass", "2026-03-10"),
    ];
    const out = orderPasses(docs, NOW);
    expect(out[0]!.id).toBe("imminent");
  });

  it("groups multi-leg trip passes contiguously", () => {
    const docs = [
      mk("a", "passport", "2030-01-01"),
      mk("leg1", "boarding_pass", "2026-03-12", "trip-1"),
      mk("solo", "boarding_pass", "2026-04-01"),
      mk("leg2", "boarding_pass", "2026-03-13", "trip-1"),
    ];
    const out = orderPasses(docs, NOW).map((d) => d.id);
    const i1 = out.indexOf("leg1");
    const i2 = out.indexOf("leg2");
    expect(Math.abs(i1 - i2)).toBe(1);
  });

  it("sorts pinned groups by closest departure", () => {
    // expiryDate is the day-of-departure, midnight UTC; "now" is mid-day.
    // "imminent-soon" departs today (delta ≈ 12h), "imminent-far" departs
    // tomorrow (delta ≈ 12h+24h). Both are within 24h tolerance of `now`,
    // but the closer one wins.
    const earlyNow = new Date("2026-03-10T03:00:00Z").getTime();
    const docs = [
      mk("imminent-far", "boarding_pass", "2026-03-11"),
      mk("imminent-soon", "boarding_pass", "2026-03-10"),
    ];
    const out = orderPasses(docs, earlyNow).map((d) => d.id);
    expect(out[0]).toBe("imminent-soon");
  });
});
