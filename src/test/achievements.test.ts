import { describe, it, expect } from "vitest";
import { diffAchievements, getAchievement } from "@/lib/achievements";

const empty = { trips: 0, scans: 0, countries: 0, continents: 0 };

describe("achievements.diffAchievements", () => {
  it("fires nothing when no threshold crossed", () => {
    expect(diffAchievements(empty, empty)).toEqual([]);
    expect(
      diffAchievements({ ...empty, trips: 4 }, { ...empty, trips: 4 }),
    ).toEqual([]);
  });

  it("fires first-trip + first-country on initial trip", () => {
    const next = { trips: 1, scans: 0, countries: 1, continents: 1 };
    const ids = diffAchievements(empty, next).map((a) => a.id);
    expect(ids).toContain("first-trip");
    expect(ids).toContain("first-country");
  });

  it("fires trips-5 once when count goes from 4 to 5", () => {
    const ids = diffAchievements(
      { ...empty, trips: 4 },
      { ...empty, trips: 5 },
    ).map((a) => a.id);
    expect(ids).toContain("trips-5");
  });

  it("fires multiple ladder steps when jumping by more than one threshold", () => {
    const ids = diffAchievements(
      { ...empty, trips: 0 },
      { ...empty, trips: 11 },
    ).map((a) => a.id);
    expect(ids).toEqual(
      expect.arrayContaining(["first-trip", "trips-5", "trips-10"]),
    );
  });

  it("dedupes if the same id is computed in multiple ladders (defensive)", () => {
    const ids = diffAchievements(empty, {
      trips: 1,
      scans: 1,
      countries: 1,
      continents: 1,
    });
    const idSet = new Set(ids.map((a) => a.id));
    expect(idSet.size).toBe(ids.length);
  });

  it("does not refire achievement on repeat snapshots", () => {
    const a = { trips: 5, scans: 0, countries: 0, continents: 0 };
    expect(diffAchievements(a, a)).toEqual([]);
  });

  it("crosses continent-all only at 7", () => {
    const ids6 = diffAchievements(
      { ...empty, continents: 5 },
      { ...empty, continents: 6 },
    ).map((a) => a.id);
    expect(ids6).not.toContain("continent-all");
    const ids7 = diffAchievements(
      { ...empty, continents: 6 },
      { ...empty, continents: 7 },
    ).map((a) => a.id);
    expect(ids7).toContain("continent-all");
  });

  it("getAchievement returns metadata", () => {
    expect(getAchievement("first-trip").title).toBe("First trip booked");
    expect(getAchievement("countries-100").tone).toBe("premium");
  });
});
