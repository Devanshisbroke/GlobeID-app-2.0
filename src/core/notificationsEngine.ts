/**
 * Slice-B Phase-8 — smart notifications engine.
 *
 * Sits between contextEngine (which produces ranked recommendations) and
 * `notificationService` (which actually fires the OS / web notification).
 *
 * Adds three real behaviours on top of the raw schedule:
 *  - **Priority levels** (`critical` | `high` | `normal` | `low`) so the
 *    UI banner stack and the OS channels can sort.
 *  - **Deduplication** by stable id, with a configurable cooldown window so
 *    re-evaluating the engine every minute doesn't re-fire the same alert.
 *  - **Batching** — multiple low-priority recs collapse into a single
 *    "3 updates" notification rather than 3 separate ones.
 *
 * State is held in module scope (Map keyed by id → last-fired timestamp).
 * That's correct for a single tab; with multiple tabs we'd persist via
 * `localStorage`. Slice B keeps the simpler in-memory model and surfaces
 * the limitation here.
 */
import type { ContextRecommendation } from "./contextEngine";

export type NotifPriority = "critical" | "high" | "normal" | "low";

export interface FiredNotification {
  id: string;
  priority: NotifPriority;
  title: string;
  body: string;
  recIds: string[];
  firedAt: number;
}

export interface EngineOptions {
  /** Cooldown for an id before it can re-fire. */
  cooldownMs?: number;
  /** How many normal+low recs to batch. */
  batchThreshold?: number;
  now?: number;
}

const DEFAULT_COOLDOWN = 30 * 60_000; // 30 minutes
const DEFAULT_BATCH_THRESHOLD = 3;

const lastFired = new Map<string, number>();

/** Reset internal state — useful for tests. */
export function _resetNotifications(): void {
  lastFired.clear();
}

/** Map a recommendation kind → notification priority. */
export function priorityFor(rec: ContextRecommendation): NotifPriority {
  if (rec.kind === "boarding_now") return "critical";
  if (rec.kind === "fraud_alert" && rec.priority >= 90) return "critical";
  if (rec.kind === "delay_alert" && rec.priority >= 75) return "high";
  if (rec.kind === "trip_imminent" && rec.priority >= 60) return "high";
  if (rec.kind === "weather_warning") return "high";
  if (rec.kind === "budget_alert" && rec.priority >= 50) return "high";
  if (
    rec.kind === "loyalty_milestone" ||
    rec.kind === "score_milestone" ||
    rec.kind === "esim_suggestion" ||
    rec.kind === "visa_check"
  )
    return "low";
  return "normal";
}

/**
 * Decide which notifications to fire from a fresh recommendation list.
 * Returns the list to fire and an `outcome` map for observability.
 */
export function planNotifications(
  recs: ContextRecommendation[],
  opts: EngineOptions = {},
): {
  fire: FiredNotification[];
  skipped: { id: string; reason: "cooldown" | "batched" }[];
} {
  const now = opts.now ?? Date.now();
  const cooldown = opts.cooldownMs ?? DEFAULT_COOLDOWN;
  const batchThreshold = opts.batchThreshold ?? DEFAULT_BATCH_THRESHOLD;

  const fire: FiredNotification[] = [];
  const skipped: { id: string; reason: "cooldown" | "batched" }[] = [];
  const lowQueue: ContextRecommendation[] = [];

  for (const rec of recs) {
    const last = lastFired.get(rec.id);
    if (last !== undefined && now - last < cooldown) {
      skipped.push({ id: rec.id, reason: "cooldown" });
      continue;
    }
    const p = priorityFor(rec);
    if (p === "critical" || p === "high") {
      fire.push({
        id: rec.id,
        priority: p,
        title: rec.title,
        body: rec.description,
        recIds: [rec.id],
        firedAt: now,
      });
      lastFired.set(rec.id, now);
    } else {
      lowQueue.push(rec);
    }
  }

  // Batch normal+low if there are enough; otherwise fire individually.
  if (lowQueue.length >= batchThreshold) {
    const batchId = `batch:${lowQueue.map((r) => r.id).sort().join("|")}`;
    const last = lastFired.get(batchId);
    if (last === undefined || now - last >= cooldown) {
      fire.push({
        id: batchId,
        priority: lowQueue.some((r) => priorityFor(r) === "normal") ? "normal" : "low",
        title: `${lowQueue.length} updates`,
        body: lowQueue
          .slice(0, 3)
          .map((r) => `• ${r.title}`)
          .join("\n"),
        recIds: lowQueue.map((r) => r.id),
        firedAt: now,
      });
      lastFired.set(batchId, now);
      for (const r of lowQueue) lastFired.set(r.id, now);
    } else {
      for (const r of lowQueue) skipped.push({ id: r.id, reason: "cooldown" });
    }
  } else {
    for (const r of lowQueue) {
      const last = lastFired.get(r.id);
      if (last !== undefined && now - last < cooldown) {
        skipped.push({ id: r.id, reason: "cooldown" });
        continue;
      }
      fire.push({
        id: r.id,
        priority: priorityFor(r),
        title: r.title,
        body: r.description,
        recIds: [r.id],
        firedAt: now,
      });
      lastFired.set(r.id, now);
    }
  }

  // Sort by priority (critical > high > normal > low)
  const rank: Record<NotifPriority, number> = {
    critical: 0,
    high: 1,
    normal: 2,
    low: 3,
  };
  fire.sort((a, b) => rank[a.priority] - rank[b.priority]);
  return { fire, skipped };
}
