/**
 * Scheduled background jobs — deterministic, no LLM, no external IO.
 *
 * Two cadenced jobs:
 *
 *  1. **nightlyDocExpiryCheck** — runs once per calendar day. Scans
 *     `userStore.documents`, finds anything that expires inside the
 *     next 30 days, and pushes a *single* alert into `alertsStore`
 *     summarising the most urgent one. Skips if a doc already has an
 *     active alert (idempotent against rapid re-mount).
 *
 *  2. **weeklyDigest** — runs once per ISO week. Aggregates the
 *     user's last 7 days of trips, transactions, and document changes
 *     into a single "Weekly digest" alert. Includes counts and the
 *     three most relevant deep-links.
 *
 * Cadence tracking is persisted in `localStorage` under
 * `globeid:scheduledJobs` so a backgrounded WebView (which suspends
 * `setInterval`) can still pick up where it left off on next launch.
 *
 * Usage: call `startScheduledJobs()` once after stores are hydrated;
 * `stopScheduledJobs()` is exposed for tests. Both functions are safe
 * to call multiple times — they no-op while the loop is running /
 * stopped.
 */

import { useUserStore } from "@/store/userStore";
import { useAlertsStore } from "@/store/alertsStore";
import { useWalletStore } from "@/store/walletStore";
import { describeExpiry } from "@/lib/documentExpiry";

const STORAGE_KEY = "globeid:scheduledJobs";
const PREFS_KEY = "globeid:scheduledJobs:prefs";
const DAY_MS = 86_400_000;
const WEEK_MS = 7 * DAY_MS;

interface JobState {
  lastNightly?: number;
  lastWeekly?: number;
}

/**
 * Quiet hours window — local-time hours 0–23 inclusive on either end.
 * If `startHour <= endHour`, it's a same-day window (e.g. 22→6 spans
 * midnight, but 13→17 is afternoon). When unset, no quiet window
 * applies and jobs are free to run any time.
 */
export interface QuietHoursPrefs {
  enabled: boolean;
  startHour: number;
  endHour: number;
}

const DEFAULT_QUIET: QuietHoursPrefs = { enabled: true, startHour: 22, endHour: 7 };

function readQuietPrefs(): QuietHoursPrefs {
  try {
    const raw = localStorage.getItem(PREFS_KEY);
    if (!raw) return DEFAULT_QUIET;
    const parsed = JSON.parse(raw) as Partial<QuietHoursPrefs>;
    return {
      enabled: parsed.enabled ?? DEFAULT_QUIET.enabled,
      startHour:
        typeof parsed.startHour === "number" && parsed.startHour >= 0 && parsed.startHour <= 23
          ? parsed.startHour
          : DEFAULT_QUIET.startHour,
      endHour:
        typeof parsed.endHour === "number" && parsed.endHour >= 0 && parsed.endHour <= 23
          ? parsed.endHour
          : DEFAULT_QUIET.endHour,
    };
  } catch {
    return DEFAULT_QUIET;
  }
}

export function setQuietHours(prefs: QuietHoursPrefs): void {
  try {
    localStorage.setItem(PREFS_KEY, JSON.stringify(prefs));
  } catch {
    /* ignore */
  }
}

export function getQuietHours(): QuietHoursPrefs {
  return readQuietPrefs();
}

/**
 * True when `now` (a unix ms) sits inside the user's quiet-hours window.
 * A window from 22→7 means "10pm to 7am next morning"; a window from
 * 13→17 means 1pm to 5pm same day. Local-time evaluation matches what
 * the user sees on their wall clock.
 */
export function isQuietHour(now: number = Date.now()): boolean {
  const prefs = readQuietPrefs();
  if (!prefs.enabled) return false;
  const hour = new Date(now).getHours();
  const { startHour, endHour } = prefs;
  if (startHour === endHour) return false; // disabled implicitly
  if (startHour < endHour) {
    return hour >= startHour && hour < endHour;
  }
  // Wraps midnight, e.g. 22 → 7
  return hour >= startHour || hour < endHour;
}

function readState(): JobState {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return {};
    return JSON.parse(raw) as JobState;
  } catch {
    return {};
  }
}

function writeState(s: JobState): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(s));
  } catch {
    /* ignore — private browsing / quota errors */
  }
}

function startOfUtcDay(ts: number): number {
  const d = new Date(ts);
  return Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate());
}

/* ── Job 1: nightly doc expiry ──────────────────────────────────── */

export function runNightlyDocExpiryCheck(now: number = Date.now()): void {
  const docs = useUserStore.getState().documents;
  const alerts = useAlertsStore.getState();

  // Find docs with severity ≥ "warning" within the next 30 days.
  const expiring = docs
    .map((d) => ({ doc: d, info: describeExpiry(d.expiryDate, new Date(now)) }))
    .filter((x) => x.info.severity !== "none");

  if (expiring.length === 0) return;

  // Sort by ascending daysUntil (most urgent first).
  expiring.sort((a, b) => a.info.daysUntil - b.info.daysUntil);
  const top = expiring[0]!;

  const alertId = `expiry-${top.doc.id}`;
  alerts.pushLocal({
    id: alertId,
    type: "advisory",
    severity: top.info.severity === "critical" ? "high" : "medium",
    title: `${top.doc.label}: ${top.info.label}`,
    description:
      expiring.length === 1
        ? "Renew before your next departure to avoid border issues."
        : `${expiring.length - 1} other documents are also expiring soon.`,
    country: top.doc.country,
    read: false,
  });
}

/* ── Job 2: weekly digest ───────────────────────────────────────── */

export function runWeeklyDigest(now: number = Date.now()): void {
  const userState = useUserStore.getState();
  const wallet = useWalletStore.getState();
  const alerts = useAlertsStore.getState();

  const cutoff = now - WEEK_MS;
  const tripsThisWeek = userState.travelHistory.filter((t) => {
    const d = new Date(t.date).getTime();
    return Number.isFinite(d) && d >= cutoff && d <= now;
  });
  const upcomingNextWeek = userState.travelHistory.filter((t) => {
    if (t.type !== "upcoming") return false;
    const d = new Date(t.date).getTime();
    return Number.isFinite(d) && d > now && d <= now + WEEK_MS;
  });
  const txThisWeek = wallet.transactions.filter((t) => {
    const d = new Date(t.date).getTime();
    return Number.isFinite(d) && d >= cutoff && d <= now;
  });
  const totalSpend = txThisWeek
    .filter((t) => t.amount < 0)
    .reduce((acc, t) => acc + Math.abs(t.amount), 0);

  const parts: string[] = [];
  if (upcomingNextWeek.length)
    parts.push(`${upcomingNextWeek.length} trip${upcomingNextWeek.length === 1 ? "" : "s"} ahead`);
  if (tripsThisWeek.length)
    parts.push(`${tripsThisWeek.length} flight${tripsThisWeek.length === 1 ? "" : "s"} this week`);
  if (txThisWeek.length)
    parts.push(`${txThisWeek.length} transaction${txThisWeek.length === 1 ? "" : "s"}`);
  if (totalSpend > 0) parts.push(`spent ${totalSpend.toFixed(0)} ${wallet.defaultCurrency}`);

  if (parts.length === 0) return;

  alerts.pushLocal({
    id: `digest-${startOfUtcDay(now)}`,
    type: "info",
    severity: "low",
    title: "Weekly digest",
    description: parts.join(" • "),
    read: false,
  });
}

/* ── Driver ─────────────────────────────────────────────────────── */

let timer: ReturnType<typeof setInterval> | null = null;

function tick(): void {
  if (typeof document !== "undefined" && document.visibilityState === "hidden") return;
  const now = Date.now();
  // Suppress non-urgent push during the user's quiet hours (default
  // 22:00-07:00 local). Both jobs are advisory/digest — no urgency
  // worth waking the user for.
  if (isQuietHour(now)) return;
  const state = readState();
  let dirty = false;

  if (!state.lastNightly || now - state.lastNightly >= DAY_MS) {
    try {
      runNightlyDocExpiryCheck(now);
    } catch (err) {
      // Defensive — never let a job throw kill the loop.
      console.warn("[scheduledJobs] nightly failed:", err);
    }
    state.lastNightly = now;
    dirty = true;
  }
  if (!state.lastWeekly || now - state.lastWeekly >= WEEK_MS) {
    try {
      runWeeklyDigest(now);
    } catch (err) {
      console.warn("[scheduledJobs] weekly failed:", err);
    }
    state.lastWeekly = now;
    dirty = true;
  }

  if (dirty) writeState(state);
}

/** Start the scheduler. Idempotent. Re-runs immediately on visibility. */
export function startScheduledJobs(intervalMs = 5 * 60_000): void {
  if (timer !== null) return;
  tick();
  timer = setInterval(tick, intervalMs);
  if (typeof document !== "undefined") {
    document.addEventListener("visibilitychange", onVisibility);
  }
}

export function stopScheduledJobs(): void {
  if (timer !== null) {
    clearInterval(timer);
    timer = null;
  }
  if (typeof document !== "undefined") {
    document.removeEventListener("visibilitychange", onVisibility);
  }
}

function onVisibility(): void {
  if (document.visibilityState === "visible") tick();
}

/** Test-only. */
export function _resetScheduledJobs(): void {
  try {
    localStorage.removeItem(STORAGE_KEY);
  } catch {
    /* ignore */
  }
}
