/**
 * Slice-F — background evaluation loop for the context engine.
 *
 * Slice-B shipped the pure `evaluateContext()` function and a React hook
 * that subscribes to the source stores. But the engine only "fires" when
 * React re-renders the hook. That means a user who sits on the Wallet
 * tab for 10 minutes while their boarding window opens gets zero
 * proactive nudges until they switch tabs.
 *
 * This module closes that gap: it runs `evaluateContext()` on a timer,
 * compares the last-seen set of recommendations, and surfaces *new*
 * high-priority recommendations via a tiny subscription API that
 * `useContextNudges()` can hook into for in-app toasts / banners.
 *
 * Key properties:
 *  - Visibility-aware: pauses when the tab is hidden.
 *  - Idempotent: duplicate recommendations (same `id`) are filtered.
 *  - Opt-in: the loop must be explicitly started (in `main.tsx` after
 *    hydration) and can be stopped for tests.
 */
import { evaluateContext, type ContextRecommendation } from "./contextEngine";
import { useLifecycleStore } from "@/store/lifecycleStore";
import { useWeatherStore } from "@/store/weatherStore";
import { useScoreStore } from "@/store/scoreStore";
import { useLoyaltyStore } from "@/store/loyaltyStore";
import { useBudgetStore } from "@/store/budgetStore";
import { useFraudStore } from "@/store/fraudStore";
import { useWalletStore } from "@/store/walletStore";
import { useSafetyStore } from "@/store/safetyStore";

export type Nudge = ContextRecommendation & { firstSeenAt: number };
export type NudgeListener = (nudge: Nudge) => void;

const listeners = new Set<NudgeListener>();
const seenIds = new Set<string>();
let timer: ReturnType<typeof setInterval> | null = null;
let currentNudges: Nudge[] = [];

const DEFAULT_INTERVAL_MS = 30_000;

/** Read a single snapshot of all inputs — no subscriptions. */
function snapshot(): Parameters<typeof evaluateContext>[0] {
  const lifecycle = useLifecycleStore.getState();
  const weather = useWeatherStore.getState();
  const score = useScoreStore.getState();
  const loyalty = useLoyaltyStore.getState();
  const budget = useBudgetStore.getState();
  const fraud = useFraudStore.getState();
  const wallet = useWalletStore.getState();
  const safety = useSafetyStore.getState();
  return {
    now: Date.now(),
    trips: lifecycle.trips,
    flightStatuses: lifecycle.flightStatuses,
    weatherByIata: weather.byIata,
    score: score.score,
    loyalty: loyalty.snapshot,
    budget: budget.snapshot,
    fraudFindings: fraud.findings,
    walletBalances: wallet.balances,
    emergencyContactsCount: safety.contacts.length,
    activeCountryIso2: null,
  };
}

export function evaluateOnce(): ContextRecommendation[] {
  const result = evaluateContext(snapshot());
  return result.recommendations;
}

export function subscribeNudges(l: NudgeListener): () => void {
  listeners.add(l);
  return () => {
    listeners.delete(l);
  };
}

export function getCurrentNudges(): ReadonlyArray<Nudge> {
  return currentNudges;
}

function runEvaluation(): void {
  if (typeof document !== "undefined" && document.visibilityState === "hidden") return;
  const recs = evaluateOnce();
  const fresh: Nudge[] = [];
  for (const rec of recs) {
    if (rec.priority < 50) continue; // only mid+ priority surface as nudges
    if (seenIds.has(rec.id)) continue;
    seenIds.add(rec.id);
    const nudge: Nudge = { ...rec, firstSeenAt: Date.now() };
    fresh.push(nudge);
    for (const l of listeners) l(nudge);
  }
  currentNudges = recs.map((r) => ({ ...r, firstSeenAt: Date.now() }));
  // Prune seenIds so it doesn't grow unbounded — keep only IDs still present.
  const activeIds = new Set(recs.map((r) => r.id));
  for (const id of seenIds) if (!activeIds.has(id)) seenIds.delete(id);
  void fresh; // silence TS6133 in strictest mode
}

let activeIntervalMs = DEFAULT_INTERVAL_MS;

export function startContextLoop(intervalMs: number = DEFAULT_INTERVAL_MS): void {
  activeIntervalMs = intervalMs;
  if (timer !== null) return;
  // Immediate first evaluation, then on the tick.
  runEvaluation();
  timer = setInterval(runEvaluation, intervalMs);
  if (typeof document !== "undefined") {
    document.addEventListener("visibilitychange", onVisibility);
  }
}

export function stopContextLoop(): void {
  if (timer !== null) {
    clearInterval(timer);
    timer = null;
  }
  if (typeof document !== "undefined") {
    document.removeEventListener("visibilitychange", onVisibility);
  }
}

function onVisibility(): void {
  // Pause the timer when the WebView is backgrounded so we don't keep
  // running the rule engine; restart it (with an immediate evaluation) on
  // return to foreground.
  if (document.visibilityState === "hidden") {
    if (timer !== null) {
      clearInterval(timer);
      timer = null;
    }
    return;
  }
  if (timer === null) {
    runEvaluation();
    timer = setInterval(runEvaluation, activeIntervalMs);
  } else {
    runEvaluation();
  }
}

/** Test-only helper. */
export function _resetContextLoop(): void {
  stopContextLoop();
  listeners.clear();
  seenIds.clear();
  currentNudges = [];
}
