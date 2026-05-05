import { describe, it, expect } from "vitest";
import { buildTravelHeatmap } from "@/lib/travelHeatmap";

describe("travelHeatmap.buildTravelHeatmap", () => {
  it("returns empty for no coords", () => {
    expect(buildTravelHeatmap([])).toEqual([]);
  });

  it("buckets nearby coords (within bucket) into one cell", () => {
    const out = buildTravelHeatmap([
      { lat: 35.66, lng: 139.65 }, // Tokyo HND
      { lat: 35.7, lng: 139.7 }, // Tokyo Shinjuku (same 5° bucket)
    ]);
    expect(out).toHaveLength(1);
    expect(out[0].count).toBe(2);
    expect(out[0].intensity).toBe(1);
  });

  it("separates Tokyo HND and Tokyo NRT (cross 5° lng boundary)", () => {
    const out = buildTravelHeatmap([
      { lat: 35.66, lng: 139.65 }, // HND
      { lat: 35.78, lng: 140.39 }, // NRT
    ]);
    expect(out).toHaveLength(2);
  });

  it("separates distant coords into different cells", () => {
    const out = buildTravelHeatmap([
      { lat: 35.66, lng: 139.65 }, // Tokyo
      { lat: 51.47, lng: -0.45 }, // London LHR
    ]);
    expect(out).toHaveLength(2);
  });

  it("normalises intensity by max count", () => {
    const out = buildTravelHeatmap([
      { lat: 35.66, lng: 139.65 },
      { lat: 35.66, lng: 139.65 },
      { lat: 35.66, lng: 139.65 },
      { lat: 51.47, lng: -0.45 },
    ]);
    const tokyo = out.find((p) => p.count === 3);
    const london = out.find((p) => p.count === 1);
    expect(tokyo?.intensity).toBe(1);
    expect(london?.intensity).toBeCloseTo(1 / 3, 5);
  });

  it("respects custom bucket size", () => {
    const out = buildTravelHeatmap(
      [
        { lat: 0, lng: 0 },
        { lat: 0.5, lng: 0.5 },
      ],
      { bucketDeg: 1 },
    );
    expect(out).toHaveLength(1);
  });
});
