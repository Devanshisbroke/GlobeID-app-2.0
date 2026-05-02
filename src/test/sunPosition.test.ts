import { describe, it, expect } from "vitest";
import { sunDirection } from "@/lib/sunPosition";

function len(v: [number, number, number]): number {
  return Math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
}

describe("sunDirection", () => {
  it("returns a unit vector", () => {
    const v = sunDirection(new Date("2026-03-20T12:00:00Z"));
    expect(len(v)).toBeCloseTo(1, 4);
  });

  it("at March equinox noon UTC, sun is roughly above the equator on the prime meridian (lon=0)", () => {
    // March 20 is the equinox; noon UTC means sub-solar point is
    // (lat≈0, lng≈0). With the latLngToVector3 convention used here,
    // that's roughly (0, 0, +1)? Actually with theta=lon+180 and
    // x=-sin(phi)*cos(theta), the equator+lon=0 maps to:
    //   phi = π/2, theta = π → x = -sin(π/2)*cos(π) = +1, y=0, z=0
    const v = sunDirection(new Date("2026-03-20T12:00:00Z"));
    expect(v[0]).toBeGreaterThan(0.9);
    expect(Math.abs(v[1])).toBeLessThan(0.1);
    expect(Math.abs(v[2])).toBeLessThan(0.2);
  });

  it("at March equinox midnight UTC, sun direction is the antipode of noon", () => {
    const noon = sunDirection(new Date("2026-03-20T12:00:00Z"));
    const midnight = sunDirection(new Date("2026-03-20T00:00:00Z"));
    expect(noon[0]).toBeCloseTo(-midnight[0], 1);
    expect(noon[2]).toBeCloseTo(-midnight[2], 1);
  });

  it("solstice declination is near +23.44° (June solstice → sun above tropic of cancer)", () => {
    // y component on the unit sphere is sin(decl) when lat≈decl.
    // June 21 noon UTC: sun above ~23.44°N, lng≈0.
    const v = sunDirection(new Date("2026-06-21T12:00:00Z"));
    // y = cos(phi) where phi = π/2 - decl => y = sin(decl) ≈ 0.397
    expect(v[1]).toBeGreaterThan(0.35);
    expect(v[1]).toBeLessThan(0.45);
  });
});
