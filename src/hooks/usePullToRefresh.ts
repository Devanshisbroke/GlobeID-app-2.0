/**
 * Slice-F — pull-to-refresh gesture hook built on `@use-gesture/react`.
 *
 * Binds pointer drag to any ref. When the user pulls down far enough
 * (past `threshold` px) the caller's `onRefresh` callback runs. The
 * hook returns a `progress` value (0..1) + `armed` flag so the UI can
 * animate a spinner / chevron without its own gesture state.
 *
 * Usage:
 *   const { bind, progress, refreshing } = usePullToRefresh({
 *     onRefresh: async () => { await refetch(); },
 *   });
 *   return <div {...bind()}>…</div>;
 */
import { useState, useCallback, useRef } from "react";
import { useDrag } from "@use-gesture/react";

export interface PullToRefreshOptions {
  onRefresh: () => Promise<void>;
  threshold?: number;
  enabled?: boolean;
}

export interface PullToRefreshState {
  bind: ReturnType<typeof useDrag>;
  progress: number;
  refreshing: boolean;
  armed: boolean;
}

export function usePullToRefresh({
  onRefresh,
  threshold = 80,
  enabled = true,
}: PullToRefreshOptions): PullToRefreshState {
  const [progress, setProgress] = useState(0);
  const [refreshing, setRefreshing] = useState(false);
  const [armed, setArmed] = useState(false);
  const busyRef = useRef(false);

  const reset = useCallback(() => {
    setProgress(0);
    setArmed(false);
  }, []);

  const bind = useDrag(
    ({ down, movement: [, my], cancel }) => {
      if (!enabled || busyRef.current) {
        cancel?.();
        return;
      }
      const scrolled = window.scrollY;
      // Only engage if the page is already at the top — otherwise the
      // user is just scrolling normally.
      if (scrolled > 0 && my > 0) {
        cancel?.();
        return;
      }
      if (my <= 0) {
        reset();
        return;
      }
      const p = Math.min(1, my / threshold);
      setProgress(p);
      setArmed(p >= 1);
      if (!down) {
        if (p >= 1) {
          busyRef.current = true;
          setRefreshing(true);
          void onRefresh()
            .finally(() => {
              busyRef.current = false;
              setRefreshing(false);
              reset();
            });
        } else {
          reset();
        }
      }
    },
    { axis: "y", filterTaps: true, pointer: { touch: true } },
  );

  return { bind, progress, refreshing, armed };
}
