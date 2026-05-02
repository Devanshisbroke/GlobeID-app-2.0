/**
 * `useVisibleClock` — visibility-aware tick.
 *
 * Returns the current `Date.now()` and re-renders the consumer at most
 * once per `intervalMs`. The internal scheduler runs via
 * `requestAnimationFrame` while the tab is visible and is paused on
 * `visibilitychange` to avoid burning the battery on background tabs and
 * on locked Capacitor WebViews. This is the canonical replacement for
 * `setInterval(() => setNow(Date.now()), …)` in components that show
 * countdowns / live timestamps.
 *
 * Implementation details:
 *  - rAF cadence is throttled to `intervalMs` resolution by tracking the
 *    last update timestamp; this keeps the scheduler honest even if the
 *    browser starts coalescing rAF callbacks.
 *  - On Page Visibility hidden, the rAF loop is cancelled. A single
 *    `setNow(Date.now())` call fires when the page returns to visible
 *    so countdowns "snap" to current time without one-tick lag.
 *  - All listeners are removed on unmount.
 */
import { useEffect, useState } from "react";

export function useVisibleClock(intervalMs = 1000): number {
  const [now, setNow] = useState<number>(() => Date.now());

  useEffect(() => {
    let rafId = 0;
    let last = performance.now();
    let cancelled = false;

    const tick = () => {
      if (cancelled) return;
      const t = performance.now();
      if (t - last >= intervalMs) {
        last = t;
        setNow(Date.now());
      }
      rafId = requestAnimationFrame(tick);
    };

    const start = () => {
      last = performance.now();
      rafId = requestAnimationFrame(tick);
    };

    const stop = () => {
      cancelAnimationFrame(rafId);
      rafId = 0;
    };

    const onVisibility = () => {
      if (document.hidden) {
        stop();
      } else {
        setNow(Date.now());
        if (rafId === 0) start();
      }
    };

    if (!document.hidden) start();
    document.addEventListener("visibilitychange", onVisibility);

    return () => {
      cancelled = true;
      stop();
      document.removeEventListener("visibilitychange", onVisibility);
    };
  }, [intervalMs]);

  return now;
}
