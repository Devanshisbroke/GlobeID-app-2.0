/**
 * <VirtualList /> — minimal windowed list (BACKLOG M 155).
 *
 * Renders only the items currently visible in the scroll viewport plus
 * a small overscan buffer, so a 1,000-row notification list doesn't
 * mount 1,000 React subtrees.
 *
 * Limitations (deliberate, to keep deps zero):
 *   - Fixed item height. Variable-height needs a different sizing
 *     strategy and that's a separate feature.
 *   - No horizontal virtualisation.
 *   - No `react-window` dependency. We use the platform: `scrollTop`,
 *     `clientHeight`, `requestAnimationFrame`, `position: absolute`.
 *
 * Usage:
 *   <VirtualList
 *     items={notifications}
 *     itemHeight={72}
 *     height={480}
 *     renderItem={(item) => <NotificationRow {...item} />}
 *   />
 */
import React, { useEffect, useRef, useState } from "react";
import { cn } from "@/lib/utils";

interface Props<T> {
  items: T[];
  itemHeight: number;
  /** Total visible height of the scroller. */
  height: number;
  renderItem: (item: T, index: number) => React.ReactNode;
  /** Extra rows to render above/below the viewport (default 4). */
  overscan?: number;
  /** Stable key extractor (defaults to index). */
  keyOf?: (item: T, index: number) => string | number;
  className?: string;
  emptyState?: React.ReactNode;
}

function VirtualListInner<T>({
  items,
  itemHeight,
  height,
  renderItem,
  overscan = 4,
  keyOf,
  className,
  emptyState,
}: Props<T>): React.ReactElement {
  const ref = useRef<HTMLDivElement>(null);
  const [scrollTop, setScrollTop] = useState(0);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    let raf = 0;
    const onScroll = () => {
      if (raf) return;
      raf = requestAnimationFrame(() => {
        raf = 0;
        setScrollTop(el.scrollTop);
      });
    };
    el.addEventListener("scroll", onScroll, { passive: true });
    return () => {
      el.removeEventListener("scroll", onScroll);
      if (raf) cancelAnimationFrame(raf);
    };
  }, []);

  if (items.length === 0 && emptyState) return <>{emptyState}</>;

  const totalHeight = items.length * itemHeight;
  const startIndex = Math.max(0, Math.floor(scrollTop / itemHeight) - overscan);
  const visibleCount = Math.ceil(height / itemHeight) + overscan * 2;
  const endIndex = Math.min(items.length, startIndex + visibleCount);

  const offsetY = startIndex * itemHeight;
  const slice = items.slice(startIndex, endIndex);

  return (
    <div
      ref={ref}
      className={cn("relative overflow-auto", className)}
      style={{ height }}
    >
      <div style={{ height: totalHeight, position: "relative" }}>
        <div
          style={{
            position: "absolute",
            top: 0,
            left: 0,
            right: 0,
            transform: `translateY(${offsetY}px)`,
          }}
        >
          {slice.map((item, i) => {
            const idx = startIndex + i;
            return (
              <div
                key={keyOf ? keyOf(item, idx) : idx}
                style={{ height: itemHeight }}
              >
                {renderItem(item, idx)}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

const VirtualList = VirtualListInner as <T>(p: Props<T>) => React.ReactElement;
export default VirtualList;
