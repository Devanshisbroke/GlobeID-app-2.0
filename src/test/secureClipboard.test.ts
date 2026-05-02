import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { secureCopy, _cancelPendingClears } from "@/lib/secureClipboard";

describe("secureCopy", () => {
  let writeText: ReturnType<typeof vi.fn>;
  let readText: ReturnType<typeof vi.fn>;
  let clipboardValue = "";

  beforeEach(() => {
    vi.useFakeTimers();
    clipboardValue = "";
    writeText = vi.fn(async (s: string) => {
      clipboardValue = s;
    });
    readText = vi.fn(async () => clipboardValue);
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: { writeText, readText },
    });
  });

  afterEach(() => {
    _cancelPendingClears();
    vi.useRealTimers();
  });

  it("writes the value to the clipboard immediately", async () => {
    const ok = await secureCopy("P-123");
    expect(ok).toBe(true);
    expect(writeText).toHaveBeenCalledWith("P-123");
    expect(clipboardValue).toBe("P-123");
  });

  it("auto-clears the clipboard after the TTL elapses", async () => {
    await secureCopy("P-123", { ttlMs: 1000 });
    expect(clipboardValue).toBe("P-123");
    await vi.advanceTimersByTimeAsync(1100);
    expect(clipboardValue).toBe("");
  });

  it("does NOT clear if the user has copied something else in the meantime", async () => {
    await secureCopy("P-123", { ttlMs: 1000 });
    // Simulate the user copying their own value:
    clipboardValue = "user-typed-thing";
    await vi.advanceTimersByTimeAsync(1100);
    expect(clipboardValue).toBe("user-typed-thing");
  });

  it("re-copying with the same key cancels the prior pending clear", async () => {
    await secureCopy("first", { ttlMs: 1000, key: "doc" });
    await secureCopy("second", { ttlMs: 1000, key: "doc" });
    await vi.advanceTimersByTimeAsync(800); // less than the second TTL
    expect(clipboardValue).toBe("second");
    // Now the second timer should fire
    await vi.advanceTimersByTimeAsync(400);
    expect(clipboardValue).toBe("");
  });

  it("returns false when the clipboard write throws", async () => {
    writeText.mockRejectedValueOnce(new Error("permission denied"));
    const ok = await secureCopy("P-123");
    expect(ok).toBe(false);
  });
});
