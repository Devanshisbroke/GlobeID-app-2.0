/**
 * Slice-B Phase-8 — notifications engine tests.
 */
import { describe, it, expect, beforeEach } from "vitest";
import {
  planNotifications,
  priorityFor,
  _resetNotifications,
} from "@/core/notificationsEngine";
import type { ContextRecommendation } from "@/core/contextEngine";

beforeEach(() => _resetNotifications());

function rec(over: Partial<ContextRecommendation>): ContextRecommendation {
  return {
    id: "id1",
    priority: 50,
    kind: "trip_imminent",
    title: "t",
    description: "d",
    sources: ["lifecycle"],
    ...over,
  };
}

describe("priorityFor", () => {
  it("treats boarding_now as critical", () => {
    expect(priorityFor(rec({ kind: "boarding_now" }))).toBe("critical");
  });
  it("treats high-priority fraud as critical", () => {
    expect(priorityFor(rec({ kind: "fraud_alert", priority: 95 }))).toBe("critical");
  });
  it("treats loyalty milestones as low", () => {
    expect(priorityFor(rec({ kind: "loyalty_milestone" }))).toBe("low");
  });
});

describe("planNotifications", () => {
  it("fires criticals immediately, not batched", () => {
    const now = 1_700_000_000_000;
    const { fire } = planNotifications(
      [rec({ id: "boarding:l1", kind: "boarding_now" })],
      { now },
    );
    expect(fire).toHaveLength(1);
    expect(fire[0]!.priority).toBe("critical");
  });

  it("dedupes within cooldown", () => {
    const now = 1_700_000_000_000;
    const r = rec({ id: "trip:imminent", priority: 80 });
    const a = planNotifications([r], { now });
    const b = planNotifications([r], { now: now + 60_000 });
    expect(a.fire).toHaveLength(1);
    expect(b.fire).toHaveLength(0);
    expect(b.skipped[0]!.reason).toBe("cooldown");
  });

  it("re-fires after cooldown elapses", () => {
    const now = 1_700_000_000_000;
    const r = rec({ id: "trip:imminent", priority: 80 });
    planNotifications([r], { now, cooldownMs: 60_000 });
    const b = planNotifications([r], { now: now + 60_001, cooldownMs: 60_000 });
    expect(b.fire).toHaveLength(1);
  });

  it("batches >=N low-priority recs into a single notification", () => {
    const now = 1_700_000_000_000;
    const recs = [
      rec({ id: "loyalty:1", kind: "loyalty_milestone", priority: 20 }),
      rec({ id: "score:1", kind: "score_milestone", priority: 15 }),
      rec({ id: "esim:1", kind: "esim_suggestion", priority: 18 }),
    ];
    const { fire } = planNotifications(recs, { now, batchThreshold: 3 });
    expect(fire).toHaveLength(1);
    expect(fire[0]!.recIds).toHaveLength(3);
  });

  it("does not batch below threshold", () => {
    const now = 1_700_000_000_000;
    const recs = [rec({ id: "loyalty:1", kind: "loyalty_milestone", priority: 20 })];
    const { fire } = planNotifications(recs, { now, batchThreshold: 3 });
    expect(fire).toHaveLength(1);
    expect(fire[0]!.recIds).toEqual(["loyalty:1"]);
  });

  it("sorts output by priority", () => {
    const now = 1_700_000_000_000;
    const recs = [
      rec({ id: "loyalty:1", kind: "loyalty_milestone", priority: 20 }),
      rec({ id: "boarding:1", kind: "boarding_now", priority: 100 }),
      rec({ id: "delay:1", kind: "delay_alert", priority: 80 }),
    ];
    const { fire } = planNotifications(recs, { now });
    expect(fire[0]!.priority).toBe("critical");
    expect(fire[1]!.priority).toBe("high");
  });
});
