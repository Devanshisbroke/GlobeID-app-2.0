import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";

describe("audioCues", () => {
  beforeEach(() => {
    try {
      localStorage.clear();
    } catch {
      /* ignore */
    }
    vi.resetModules();
  });

  afterEach(() => {
    try {
      localStorage.clear();
    } catch {
      /* ignore */
    }
  });

  it("setEnabled persists to localStorage and isEnabled reads it back", async () => {
    const { audioCues } = await import("@/lib/audioCues");
    expect(audioCues.isEnabled()).toBe(true);
    audioCues.setEnabled(false);
    expect(audioCues.isEnabled()).toBe(false);
    audioCues.setEnabled(true);
    expect(audioCues.isEnabled()).toBe(true);
  });

  it("calling cues when audio is disabled is a no-op (resolves without throwing)", async () => {
    const { audioCues } = await import("@/lib/audioCues");
    audioCues.setEnabled(false);
    await expect(audioCues.success()).resolves.toBeUndefined();
    await expect(audioCues.error()).resolves.toBeUndefined();
    await expect(audioCues.scan()).resolves.toBeUndefined();
    await expect(audioCues.tap()).resolves.toBeUndefined();
    await expect(audioCues.unlock()).resolves.toBeUndefined();
  });

  it("invalid persisted value defaults to enabled", async () => {
    localStorage.setItem("globeid:audioCues:enabled", "true");
    const { audioCues } = await import("@/lib/audioCues");
    expect(audioCues.isEnabled()).toBe(true);
  });
});
