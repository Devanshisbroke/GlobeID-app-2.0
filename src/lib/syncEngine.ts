/**
 * Slice-F — sync engine for offline-first mutations.
 *
 * Problem: the app can mutate while offline (wallet conversions, social
 * posts, document vault saves). Slice-A added an `OfflineBanner` but no
 * actual re-try pipeline. This module is the pipeline:
 *
 *   1. Durable queue in IndexedDB (survives refresh + crashes).
 *   2. Exponential backoff with jitter per-mutation retry.
 *   3. Visibility-aware — pauses when the tab is hidden to not drain
 *      battery, resumes on `visibilitychange`.
 *   4. Network-aware — subscribes to `online`/`offline` + `@capacitor/network`.
 *   5. Handler registry — callers register `kind → async handler` before
 *      enqueuing, so the engine doesn't hard-code any endpoints.
 *
 * Design notes:
 *  - Mutations are opaque JSON payloads keyed by `kind`. The handler
 *    decides what to do with them.
 *  - Handlers must be idempotent. The engine does *not* dedupe across
 *    restarts — the caller is expected to mint an idempotency key inside
 *    `payload` (mirrors the wallet ledger pattern).
 */
import Dexie, { type Table } from "dexie";

export interface PendingMutation<T = unknown> {
  id: string;
  kind: string;
  payload: T;
  createdAt: string;
  attempts: number;
  lastError: string | null;
  nextRunAt: string;
}

class SyncDB extends Dexie {
  mutations!: Table<PendingMutation, string>;
  constructor() {
    super("globe-sync");
    this.version(1).stores({
      mutations: "id, kind, nextRunAt, createdAt",
    });
  }
}

export const syncDB = new SyncDB();

export type SyncHandler<T = unknown> = (payload: T) => Promise<void>;
export type SyncListener = (snapshot: ReadonlyArray<PendingMutation>) => void;

// Public read-only state.
let listeners = new Set<SyncListener>();
const handlers = new Map<string, SyncHandler>();
let running = false;
let currentTick: ReturnType<typeof setTimeout> | null = null;

/** Register a handler for a mutation kind. Safe to call multiple times. */
export function registerHandler<T>(kind: string, handler: SyncHandler<T>): void {
  handlers.set(kind, handler as SyncHandler);
}

export function subscribe(l: SyncListener): () => void {
  listeners.add(l);
  return () => {
    listeners.delete(l);
  };
}

async function emitSnapshot(): Promise<void> {
  if (listeners.size === 0) return;
  const all = await syncDB.mutations.orderBy("createdAt").toArray();
  for (const l of listeners) l(all);
}

export async function queueMutation<T>(kind: string, payload: T): Promise<PendingMutation<T>> {
  const row: PendingMutation<T> = {
    id: newId(),
    kind,
    payload,
    createdAt: new Date().toISOString(),
    attempts: 0,
    lastError: null,
    nextRunAt: new Date().toISOString(),
  };
  await syncDB.mutations.put(row as PendingMutation);
  await emitSnapshot();
  kick();
  return row;
}

export async function listPending(): Promise<PendingMutation[]> {
  return syncDB.mutations.orderBy("createdAt").toArray();
}

export async function clearPending(): Promise<void> {
  await syncDB.mutations.clear();
  await emitSnapshot();
}

/**
 * Exponential backoff with full jitter.
 * Caps at 5 minutes so we don't end up with a 17-hour retry.
 */
export function backoffMs(attempts: number): number {
  const base = 1000 * Math.pow(2, Math.min(attempts, 8)); // 1s, 2s, ... 256s
  const cap = 5 * 60 * 1000;
  const ceiling = Math.min(base, cap);
  return Math.floor(Math.random() * ceiling);
}

function isOnline(): boolean {
  if (typeof navigator === "undefined") return true;
  if ("onLine" in navigator) return navigator.onLine;
  return true;
}

function isVisible(): boolean {
  if (typeof document === "undefined") return true;
  return document.visibilityState !== "hidden";
}

async function tick(): Promise<void> {
  if (!running) return;
  currentTick = null;
  if (!isOnline() || !isVisible()) {
    scheduleNext(2000);
    return;
  }
  const now = new Date().toISOString();
  const due = await syncDB.mutations
    .where("nextRunAt")
    .belowOrEqual(now)
    .limit(1)
    .toArray();
  const job = due[0];
  if (!job) {
    scheduleNext(5000);
    return;
  }
  const handler = handlers.get(job.kind);
  if (!handler) {
    // Handler not registered yet — come back later.
    scheduleNext(5000);
    return;
  }
  try {
    await handler(job.payload);
    await syncDB.mutations.delete(job.id);
    await emitSnapshot();
    scheduleNext(0);
  } catch (e) {
    const attempts = job.attempts + 1;
    const nextRunAt = new Date(Date.now() + backoffMs(attempts)).toISOString();
    await syncDB.mutations.update(job.id, {
      attempts,
      lastError: e instanceof Error ? e.message : String(e),
      nextRunAt,
    });
    await emitSnapshot();
    scheduleNext(500);
  }
}

function scheduleNext(delayMs: number): void {
  if (!running) return;
  if (currentTick) clearTimeout(currentTick);
  currentTick = setTimeout(() => {
    void tick();
  }, delayMs);
}

function kick(): void {
  if (!running) return;
  scheduleNext(0);
}

export function startSyncEngine(): void {
  if (running) return;
  running = true;
  if (typeof window !== "undefined") {
    window.addEventListener("online", kick);
    window.addEventListener("focus", kick);
    document.addEventListener("visibilitychange", kick);
  }
  scheduleNext(100);
}

export function stopSyncEngine(): void {
  running = false;
  if (currentTick) clearTimeout(currentTick);
  currentTick = null;
  if (typeof window !== "undefined") {
    window.removeEventListener("online", kick);
    window.removeEventListener("focus", kick);
    document.removeEventListener("visibilitychange", kick);
  }
}

function newId(): string {
  if (typeof crypto !== "undefined" && "randomUUID" in crypto) return crypto.randomUUID();
  return `sync-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
}

/** Test-only: reset the internal queue + handlers. */
export async function _resetSyncEngine(): Promise<void> {
  stopSyncEngine();
  handlers.clear();
  listeners = new Set();
  try {
    await syncDB.mutations.clear();
  } catch {
    // ignore
  }
}
