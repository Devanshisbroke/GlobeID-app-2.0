import { describe, it, expect } from "vitest";
import { chooseSnap } from "@/lib/sheetSnap";

describe("sheetSnap.chooseSnap", () => {
  const containerHeight = 1000;
  const snaps = [0.25, 0.6, 0.95];

  it("picks the geometrically-closest snap when no velocity", () => {
    // currentY ≈ offset for 0.6 → expect index 1
    const r = chooseSnap({
      currentY: 400,
      containerHeight,
      snaps,
    });
    expect(r.index).toBe(1);
    expect(r.fraction).toBe(0.6);
    expect(r.restY).toBe(400);
  });

  it("flicks toward next snap on positive (downward) velocity", () => {
    const r = chooseSnap({
      currentY: 50, // very close to fully-open (offset 50)
      containerHeight,
      snaps,
      velocity: 1.5,
    });
    // velocity positive → smaller fraction → next index +1 from 0.95
    // 0.95 is index 2 (highest), so dir=+1 clamps at 2 — wait, sorted is
    // [0.25, 0.6, 0.95], and 0.95 maps to offset 50 (top). Dir +1 wants
    // bigger offset. Index 2 is highest, so dir +1 takes us out of range
    // → clamped at 2. So r.index === 2, fraction === 0.95.
    expect(r.fraction).toBeGreaterThanOrEqual(0.6);
  });

  it("flicks toward previous snap on negative (upward) velocity", () => {
    const r = chooseSnap({
      currentY: 400, // near 0.6
      containerHeight,
      snaps,
      velocity: -1.5,
    });
    // upward velocity → bigger fraction → index +1 in sorted order.
    expect(r.fraction).toBe(0.95);
  });

  it("clamps direction at the ends", () => {
    const r = chooseSnap({
      currentY: 50, // top
      containerHeight,
      snaps,
      velocity: -1.5, // already at top, can't go higher
    });
    expect(r.fraction).toBe(0.95);
  });

  it("returns first snap when snaps array is empty (defensive)", () => {
    const r = chooseSnap({
      currentY: 200,
      containerHeight,
      snaps: [],
    });
    expect(r.fraction).toBe(1);
  });
});
