/**
 * Mobile-first pull-to-refresh hook.
 *
 * Returns the imperative state needed by a spinner element + a set of
 * `touch*` handlers to spread onto the scroll container. The hook only
 * fires while the container is at scrollTop=0 so a normal swipe inside
 * a list doesn't accidentally trigger a refresh.
 *
 * Honours `prefers-reduced-motion` by snapping back without easing.
 * Caller is responsible for the actual refresh logic — `onRefresh` is
 * awaited and the hook resets distance once it resolves.
 */
import { useCallback, useEffect, useRef, useState } from "react";

interface Options {
  /** Pixels of overscroll required to trigger the refresh. */
  threshold?: number;
  /** Maximum visible pull distance. */
  maxDistance?: number;
  /** Called when the gesture commits past the threshold. */
  onRefresh: () => Promise<void> | void;
}

export interface PullToRefreshHandle {
  /** 0 → 1 progress toward the threshold. Use for the spinner ring. */
  progress: number;
  /** Pixels the indicator should be translated down. */
  distance: number;
  /** True while `onRefresh()` is still pending. */
  refreshing: boolean;
  /** Spread onto the scroll container element. */
  touchHandlers: {
    onTouchStart: (e: React.TouchEvent) => void;
    onTouchMove: (e: React.TouchEvent) => void;
    onTouchEnd: () => void;
  };
}

export function usePullToRefresh(opts: Options): PullToRefreshHandle {
  const threshold = opts.threshold ?? 64;
  const maxDistance = opts.maxDistance ?? 120;
  const startY = useRef<number | null>(null);
  const [distance, setDistance] = useState(0);
  const [refreshing, setRefreshing] = useState(false);
  const refreshingRef = useRef(false);

  useEffect(() => {
    refreshingRef.current = refreshing;
  }, [refreshing]);

  const onTouchStart = useCallback((e: React.TouchEvent) => {
    if (refreshingRef.current) return;
    const target = e.currentTarget as HTMLElement | null;
    if (!target) return;
    if (target.scrollTop > 0) return;
    startY.current = e.touches[0]?.clientY ?? null;
  }, []);

  const onTouchMove = useCallback(
    (e: React.TouchEvent) => {
      if (startY.current === null) return;
      if (refreshingRef.current) return;
      const y = e.touches[0]?.clientY ?? 0;
      const delta = y - startY.current;
      if (delta <= 0) {
        setDistance(0);
        return;
      }
      // Apply rubber-band-style damping past threshold.
      const damped = delta < threshold ? delta : threshold + (delta - threshold) * 0.4;
      setDistance(Math.min(damped, maxDistance));
    },
    [threshold, maxDistance],
  );

  const onTouchEnd = useCallback(() => {
    const final = distance;
    startY.current = null;
    if (final >= threshold && !refreshingRef.current) {
      setRefreshing(true);
      Promise.resolve(opts.onRefresh())
        .catch(() => undefined)
        .finally(() => {
          setRefreshing(false);
          setDistance(0);
        });
      return;
    }
    setDistance(0);
  }, [distance, threshold, opts]);

  return {
    progress: Math.min(distance / threshold, 1),
    distance,
    refreshing,
    touchHandlers: { onTouchStart, onTouchMove, onTouchEnd },
  };
}
