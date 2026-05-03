import { describe, it, expect } from "vitest";
import { detectEdges, sobel, toLuminance } from "@/lib/imageEdge";

/** Build a flat RGBA buffer of a given size, filled with one colour. */
function flat(w: number, h: number, r: number, g: number, b: number): Uint8ClampedArray {
  const buf = new Uint8ClampedArray(w * h * 4);
  for (let i = 0; i < w * h; i++) {
    buf[i * 4] = r;
    buf[i * 4 + 1] = g;
    buf[i * 4 + 2] = b;
    buf[i * 4 + 3] = 255;
  }
  return buf;
}

describe("imageEdge", () => {
  it("toLuminance applies BT.601 weights", () => {
    const rgba = flat(2, 2, 200, 100, 50);
    const luma = toLuminance(rgba, 2, 2);
    // 200*0.299 + 100*0.587 + 50*0.114 ≈ 124.2 → 124
    expect(luma[0]).toBe(124);
    expect(luma).toHaveLength(4);
  });

  it("sobel detects no edges on a flat image", () => {
    const luma = toLuminance(flat(8, 8, 128, 128, 128), 8, 8);
    const edges = sobel(luma, 8, 8);
    // Every alpha channel byte should be 0 (no edges).
    for (let i = 3; i < edges.length; i += 4) {
      expect(edges[i]).toBe(0);
    }
  });

  it("sobel detects a vertical edge", () => {
    // Half-black / half-white image.
    const w = 8;
    const h = 8;
    const rgba = new Uint8ClampedArray(w * h * 4);
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        const i = (y * w + x) * 4;
        const v = x < 4 ? 0 : 255;
        rgba[i] = v;
        rgba[i + 1] = v;
        rgba[i + 2] = v;
        rgba[i + 3] = 255;
      }
    }
    const edges = detectEdges(rgba, w, h, 50);
    // The seam should have at least one pixel marked as edge (alpha > 0)
    // along the boundary.
    let hits = 0;
    for (let y = 1; y < h - 1; y++) {
      const i = (y * w + 4) * 4;
      if (edges[i + 3]! > 0) hits++;
    }
    expect(hits).toBeGreaterThan(0);
  });
});
