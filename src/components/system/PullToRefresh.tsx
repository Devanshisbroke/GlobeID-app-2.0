/**
 * <PullToRefresh /> — drop-in wrapper that exposes a scroll container
 * with iOS-style pull-to-refresh (BACKLOG J 113).
 *
 * Usage:
 *   <PullToRefresh onRefresh={async () => { await reload(); }}>
 *     ...page content...
 *   </PullToRefresh>
 *
 * The wrapper renders a fixed-height spinner that animates its arc as
 * the user drags, snaps to a "refreshing" loop while the promise is
 * pending, and snaps back to 0 once it resolves. Honours reduced-motion
 * by skipping the rotation animation (the underlying hook handles
 * snap-back without easing).
 */
import React from "react";
import { Loader2 } from "lucide-react";
import { usePullToRefresh } from "@/hooks/usePullToRefresh";
import { cn } from "@/lib/utils";

interface Props {
  onRefresh: () => Promise<void> | void;
  className?: string;
  children: React.ReactNode;
  /** Override threshold in px (default 64). */
  threshold?: number;
}

const PullToRefresh: React.FC<Props> = ({
  onRefresh,
  className,
  children,
  threshold,
}) => {
  const { progress, distance, refreshing, touchHandlers } = usePullToRefresh({
    onRefresh,
    threshold,
  });

  return (
    <div
      className={cn("relative h-full overflow-y-auto overscroll-contain", className)}
      {...touchHandlers}
    >
      <div
        className="pointer-events-none absolute inset-x-0 top-0 z-10 flex items-center justify-center"
        style={{
          height: distance,
          opacity: Math.min(progress + (refreshing ? 1 : 0), 1),
          transition: refreshing ? "height 220ms ease-out" : undefined,
        }}
      >
        <Loader2
          className={cn(
            "h-5 w-5 text-foreground/70",
            refreshing ? "animate-spin" : "",
          )}
          style={
            refreshing
              ? undefined
              : { transform: `rotate(${progress * 360}deg)` }
          }
          strokeWidth={2}
          aria-hidden="true"
          role="presentation"
        />
      </div>
      <div style={{ transform: `translateY(${distance}px)` }}>{children}</div>
    </div>
  );
};

export default PullToRefresh;
