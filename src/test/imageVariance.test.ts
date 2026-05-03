import { describe, it, expect } from "vitest";
import {
  createVarianceTracker,
  downsampleSignature,
  pushFrame,
  signatureDistance,
  STEADY_FRAMES,
  SIGNATURE_SIZE,
} from "@/lib/imageVariance";

function flat(w: number, h: number, v: number): Uint8ClampedArray {
  const buf = new Uint8ClampedArray(w * h * 4);
  for (let i = 0; i < w * h; i++) {
    buf[i * 4] = v;
    buf[i * 4 + 1] = v;
    buf[i * 4 + 2] = v;
    buf[i * 4 + 3] = 255;
  }
  return buf;
}

describe("imageVariance", () => {
  it("downsampleSignature returns SIGNATURE_SIZE^2 bytes", () => {
    const sig = downsampleSignature(flat(64, 64, 200), 64, 64);
    expect(sig.length).toBe(SIGNATURE_SIZE * SIGNATURE_SIZE);
    // For a uniform grey image every cell should be ~200.
    expect(sig[0]).toBe(200);
    expect(sig[sig.length - 1]).toBe(200);
  });

  it("signatureDistance is 0 for identical images", () => {
    const a = downsampleSignature(flat(64, 64, 128), 64, 64);
    const b = downsampleSignature(flat(64, 64, 128), 64, 64);
    expect(signatureDistance(a, b)).toBe(0);
  });

  it("signatureDistance is large for very different images", () => {
    const a = downsampleSignature(flat(64, 64, 0), 64, 64);
    const b = downsampleSignature(flat(64, 64, 255), 64, 64);
    expect(signatureDistance(a, b)).toBeGreaterThan(200);
  });

  it("pushFrame returns steady=false until enough frames have elapsed", () => {
    const tracker = createVarianceTracker();
    const sig = downsampleSignature(flat(64, 64, 128), 64, 64);
    let steady = false;
    for (let i = 0; i < STEADY_FRAMES + 2; i++) {
      const r = pushFrame(tracker, sig);
      if (i < STEADY_FRAMES) {
        // We need more frames before steady fires.
        if (i === 0) expect(r.steady).toBe(false);
      } else {
        if (r.steady) steady = true;
      }
    }
    expect(steady).toBe(true);
  });

  it("pushFrame resets steadyCount when motion appears", () => {
    const tracker = createVarianceTracker();
    const stable = downsampleSignature(flat(64, 64, 128), 64, 64);
    const moved = downsampleSignature(flat(64, 64, 250), 64, 64);
    for (let i = 0; i < STEADY_FRAMES; i++) pushFrame(tracker, stable);
    const r = pushFrame(tracker, moved);
    expect(r.steady).toBe(false);
    expect(tracker.steadyCount).toBe(0);
  });
});
