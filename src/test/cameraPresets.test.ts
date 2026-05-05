import { describe, it, expect } from "vitest";
import {
  homeView,
  nextTripView,
  flightTrackerView,
  haversineKm,
  greatCircleMidpoint,
} from "@/lib/cameraPresets";

describe("cameraPresets", () => {
  it("homeView returns default SFO when no home is given", () => {
    const v = homeView();
    expect(v.label).toBe("Home view");
    expect(v.lat).toBeCloseTo(37.7749, 4);
    expect(v.lng).toBeCloseTo(-122.4194, 4);
  });

  it("homeView returns custom home", () => {
    const v = homeView({ lat: 51.5, lng: -0.12 });
    expect(v.lat).toBeCloseTo(51.5, 4);
    expect(v.lng).toBeCloseTo(-0.12, 4);
  });

  it("nextTripView is centred on the midpoint and zooms out for long-haul", () => {
    const sfo = { lat: 37.7749, lng: -122.4194 };
    const tyo = { lat: 35.6762, lng: 139.6503 };
    const v = nextTripView(sfo, tyo);
    expect(v.zoom).toBe(4);
    // Midpoint of SFO-TYO crosses the dateline northward.
    expect(v.lat).toBeGreaterThan(45);
  });

  it("nextTripView short-haul zoom level", () => {
    const lhr = { lat: 51.47, lng: -0.45 };
    const cdg = { lat: 49.0097, lng: 2.5479 };
    const v = nextTripView(lhr, cdg);
    expect(v.zoom).toBe(2);
  });

  it("flightTrackerView frames at zoom 1.5", () => {
    const v = flightTrackerView({ lat: 0, lng: 0 });
    expect(v.zoom).toBe(1.5);
  });

  it("haversineKm SFO→TYO ≈ 8270 km", () => {
    const km = haversineKm(
      { lat: 37.7749, lng: -122.4194 },
      { lat: 35.6762, lng: 139.6503 },
    );
    expect(km).toBeGreaterThan(8000);
    expect(km).toBeLessThan(8500);
  });

  it("greatCircleMidpoint near-zero distance preserves coord", () => {
    const m = greatCircleMidpoint(
      { lat: 35, lng: 139 },
      { lat: 35.0001, lng: 139.0001 },
    );
    expect(m.lat).toBeCloseTo(35, 3);
    expect(m.lng).toBeCloseTo(139, 3);
  });
});
