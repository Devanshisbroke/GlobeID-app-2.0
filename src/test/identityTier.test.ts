import { describe, it, expect } from "vitest";
import {
  tierForScore,
  progressToNextTier,
  allTiers,
} from "@/lib/identityTier";

describe("identityTier", () => {
  it("maps low scores to Tier 0", () => {
    expect(tierForScore(0).id).toBe(0);
    expect(tierForScore(29).id).toBe(0);
  });
  it("maps mid scores correctly", () => {
    expect(tierForScore(30).id).toBe(1);
    expect(tierForScore(59).id).toBe(1);
    expect(tierForScore(60).id).toBe(2);
    expect(tierForScore(84).id).toBe(2);
  });
  it("clamps to Sovereign at 85+", () => {
    expect(tierForScore(85).id).toBe(3);
    expect(tierForScore(100).id).toBe(3);
  });

  it("computes progress within the current tier", () => {
    const r = progressToNextTier(45);
    expect(r.current.id).toBe(1);
    expect(r.next?.id).toBe(2);
    // 45 is 15/30 above tier 1 floor → 50%
    expect(r.pct).toBeCloseTo(0.5, 2);
    expect(r.remaining).toBe(15);
  });

  it("reports full progress at top tier", () => {
    const r = progressToNextTier(100);
    expect(r.current.id).toBe(3);
    expect(r.next).toBeNull();
    expect(r.pct).toBe(1);
    expect(r.remaining).toBe(0);
  });

  it("exposes all tiers in ascending order", () => {
    const t = allTiers();
    expect(t.map((x) => x.id)).toEqual([0, 1, 2, 3]);
  });
});
