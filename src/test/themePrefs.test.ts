import { describe, it, expect, beforeEach } from "vitest";
import {
  ACCENTS,
  applyThemePrefs,
  getThemePrefs,
  setAccent,
  setReduceTransparency,
  DEFAULT_ACCENT_ID,
} from "@/lib/themePrefs";

describe("themePrefs", () => {
  beforeEach(() => {
    try {
      localStorage.removeItem("globeid:themePrefs");
    } catch {
      /* ignore */
    }
    document.documentElement.style.removeProperty("--p7-brand");
    document.documentElement.dataset.reduceTransparency = "false";
  });

  it("falls back to default accent when storage is empty", () => {
    expect(getThemePrefs().accentId).toBe(DEFAULT_ACCENT_ID);
    expect(getThemePrefs().reduceTransparency).toBe(false);
  });

  it("setAccent persists and sets the --p7-brand CSS variable", () => {
    const violet = ACCENTS.find((a) => a.id === "violet")!;
    setAccent("violet");
    expect(getThemePrefs().accentId).toBe("violet");
    expect(document.documentElement.style.getPropertyValue("--p7-brand")).toBe(
      violet.hsl,
    );
  });

  it("setAccent ignores unknown ids and falls back to first accent", () => {
    setAccent("nope");
    expect(getThemePrefs().accentId).toBe(ACCENTS[0].id);
  });

  it("setReduceTransparency persists and sets the data attribute", () => {
    setReduceTransparency(true);
    expect(getThemePrefs().reduceTransparency).toBe(true);
    expect(document.documentElement.dataset.reduceTransparency).toBe("true");
    setReduceTransparency(false);
    expect(getThemePrefs().reduceTransparency).toBe(false);
    expect(document.documentElement.dataset.reduceTransparency).toBe("false");
  });

  it("applyThemePrefs is idempotent and applies the persisted accent", () => {
    setAccent("amber");
    setReduceTransparency(true);
    // Wipe inline style to simulate a fresh boot
    document.documentElement.style.removeProperty("--p7-brand");
    applyThemePrefs();
    const amber = ACCENTS.find((a) => a.id === "amber")!;
    expect(document.documentElement.style.getPropertyValue("--p7-brand")).toBe(
      amber.hsl,
    );
    expect(document.documentElement.dataset.reduceTransparency).toBe("true");
  });
});
