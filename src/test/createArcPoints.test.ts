import { describe, it, expect, beforeEach } from "vitest";
import { createArcPoints, _clearArcCache } from "@/lib/airports";

describe("createArcPoints", () => {
  beforeEach(() => {
    _clearArcCache();
  });

  it("produces (segments+1) points on a smooth arc", () => {
    const pts = createArcPoints([1, 0, 0], [0, 1, 0], 32, 0.3);
    expect(pts).toHaveLength(33);
  });

  it("returns the same array reference on cache hit", () => {
    const a = createArcPoints([1, 0, 0], [0, 1, 0], 64, 0.25);
    const b = createArcPoints([1, 0, 0], [0, 1, 0], 64, 0.25);
    expect(a).toBe(b);
  });

  it("treats different arcHeights as distinct keys", () => {
    const a = createArcPoints([1, 0, 0], [0, 1, 0], 64, 0.2);
    const b = createArcPoints([1, 0, 0], [0, 1, 0], 64, 0.4);
    expect(a).not.toBe(b);
    expect(a[16]).not.toEqual(b[16]);
  });

  it("treats different segments as distinct", () => {
    const a = createArcPoints([1, 0, 0], [0, 1, 0], 32, 0.25);
    const b = createArcPoints([1, 0, 0], [0, 1, 0], 64, 0.25);
    expect(a.length).not.toBe(b.length);
  });

  it("midpoint sits above the chord by the arc height multiplier", () => {
    // Use 90° apart endpoints (NOT antipodal — antipodes hit the
    // origin under the lerp+normalise path and yield NaN).
    const pts = createArcPoints([1, 0, 0], [0, 0, 1], 64, 0.3);
    const mid = pts[32]!;
    const r = Math.sqrt(mid[0] ** 2 + mid[1] ** 2 + mid[2] ** 2);
    expect(r).toBeCloseTo(1.3, 2);
  });
});
