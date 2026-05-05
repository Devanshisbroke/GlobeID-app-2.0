import { describe, it, expect } from "vitest";
import {
  NAV_STARS,
  equatorialToCartesian,
  magnitudeToSize,
  projectStars,
} from "@/lib/starCatalog";

describe("starCatalog", () => {
  it("seed catalog has at least 30 navigation stars", () => {
    expect(NAV_STARS.length).toBeGreaterThanOrEqual(30);
  });

  it("Polaris is near the north celestial pole", () => {
    const polaris = NAV_STARS.find((s) => s.name === "Polaris");
    expect(polaris).toBeDefined();
    expect(polaris!.dec).toBeGreaterThan(89);
    const c = equatorialToCartesian(polaris!.ra, polaris!.dec);
    // Should be near (0, 1, 0) — top of unit sphere.
    expect(c.y).toBeGreaterThan(0.99);
  });

  it("equatorialToCartesian RA=0, Dec=0 → (1,0,0)", () => {
    const c = equatorialToCartesian(0, 0);
    expect(c.x).toBeCloseTo(1, 6);
    expect(c.y).toBeCloseTo(0, 6);
    expect(c.z).toBeCloseTo(0, 6);
  });

  it("equatorialToCartesian respects radius", () => {
    const c = equatorialToCartesian(0, 0, 5);
    expect(c.x).toBeCloseTo(5, 6);
  });

  it("magnitudeToSize: brighter = bigger", () => {
    const sirius = magnitudeToSize(-1.46);
    const dim = magnitudeToSize(2);
    expect(sirius).toBeGreaterThan(dim);
  });

  it("magnitudeToSize clamped to [0.4, 2.5]", () => {
    expect(magnitudeToSize(-99)).toBe(2.5);
    expect(magnitudeToSize(99)).toBe(0.4);
  });

  it("projectStars produces brightness 0..1 with brightest at 1", () => {
    const stars = projectStars(100);
    expect(stars.length).toBe(NAV_STARS.length);
    const brightest = Math.max(...stars.map((s) => s.brightness));
    expect(brightest).toBe(1);
    expect(stars.every((s) => s.brightness >= 0 && s.brightness <= 1)).toBe(true);
  });
});
