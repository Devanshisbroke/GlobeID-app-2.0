import { describe, it, expect, beforeEach, afterEach } from "vitest";
import {
  backoffMs,
  queueMutation,
  registerHandler,
  startSyncEngine,
  listPending,
  _resetSyncEngine,
} from "@/lib/syncEngine";

describe("backoffMs", () => {
  it("returns a non-negative value within the exponential envelope", () => {
    for (let attempts = 0; attempts < 10; attempts++) {
      const b = backoffMs(attempts);
      expect(b).toBeGreaterThanOrEqual(0);
      expect(b).toBeLessThanOrEqual(5 * 60 * 1000);
    }
  });

  it("caps the envelope at 5 minutes", () => {
    // With a huge attempt count, the ceiling caps at 5min.
    const samples = Array.from({ length: 200 }, () => backoffMs(100));
    const max = Math.max(...samples);
    expect(max).toBeLessThanOrEqual(5 * 60 * 1000);
  });
});

describe("queueMutation", () => {
  beforeEach(async () => {
    await _resetSyncEngine();
  });
  afterEach(async () => {
    await _resetSyncEngine();
  });

  it("persists a new mutation with createdAt and zero attempts", async () => {
    const row = await queueMutation("wallet/convert", { from: "USD", to: "EUR" });
    expect(row.kind).toBe("wallet/convert");
    expect(row.attempts).toBe(0);
    expect(row.lastError).toBeNull();
    const pending = await listPending();
    expect(pending.length).toBe(1);
    expect(pending[0]!.kind).toBe("wallet/convert");
  });

  it("drives registered handlers to completion and clears the queue", async () => {
    const calls: unknown[] = [];
    registerHandler("echo", async (payload) => {
      calls.push(payload);
    });
    await queueMutation("echo", { hello: "world" });
    startSyncEngine();
    // Wait long enough for the scheduler to fire a tick.
    await new Promise((r) => setTimeout(r, 250));
    expect(calls.length).toBe(1);
    const remaining = await listPending();
    expect(remaining.length).toBe(0);
  });
});
