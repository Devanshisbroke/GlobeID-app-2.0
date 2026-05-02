import { describe, it, expect, beforeEach } from "vitest";
import {
  isQuietHour,
  setQuietHours,
  getQuietHours,
} from "@/core/scheduledJobs";

function atLocalHour(h: number): number {
  const d = new Date();
  d.setHours(h, 0, 0, 0);
  return d.getTime();
}

describe("isQuietHour", () => {
  beforeEach(() => {
    try {
      localStorage.removeItem("globeid:scheduledJobs:prefs");
    } catch {
      /* ignore */
    }
  });

  it("returns true for the default 22→7 window at 23:00 and 03:00", () => {
    // Default prefs (no localStorage) should treat 22:00–07:00 as quiet.
    expect(isQuietHour(atLocalHour(23))).toBe(true);
    expect(isQuietHour(atLocalHour(3))).toBe(true);
  });

  it("returns false for the default window at 12:00 and 21:00", () => {
    expect(isQuietHour(atLocalHour(12))).toBe(false);
    expect(isQuietHour(atLocalHour(21))).toBe(false);
  });

  it("returns false when prefs.enabled is false", () => {
    setQuietHours({ enabled: false, startHour: 22, endHour: 7 });
    expect(isQuietHour(atLocalHour(2))).toBe(false);
    expect(getQuietHours().enabled).toBe(false);
  });

  it("supports same-day window (13→17)", () => {
    setQuietHours({ enabled: true, startHour: 13, endHour: 17 });
    expect(isQuietHour(atLocalHour(14))).toBe(true);
    expect(isQuietHour(atLocalHour(12))).toBe(false);
    expect(isQuietHour(atLocalHour(17))).toBe(false); // exclusive end
  });

  it("treats startHour === endHour as disabled", () => {
    setQuietHours({ enabled: true, startHour: 5, endHour: 5 });
    expect(isQuietHour(atLocalHour(5))).toBe(false);
  });
});
