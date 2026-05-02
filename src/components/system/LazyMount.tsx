/**
 * IntersectionObserver-mounted lazy region.
 *
 * Wraps any expensive children (Three.js canvas, animated SVG, large
 * lists) and defers their mount until the placeholder enters the
 * viewport (or its rootMargin band). On mount the wrapper hands off to
 * the children — it does NOT wrap them in any extra DOM node so layout
 * is unaffected.
 *
 * Falls back to mounting immediately if `IntersectionObserver` is
 * unavailable (older WebViews, SSR snapshot generators).
 *
 * Capacitor compatibility: WebView's IntersectionObserver is available
 * everywhere we ship. No polyfill needed.
 */

import React, { useEffect, useRef, useState } from "react";

export interface LazyMountProps {
  /** Pre-mount placeholder. Pass a `<Skeleton />` or a sized div. */
  fallback?: React.ReactNode;
  /** rootMargin for the observer. Default "200px" to start mounting
   *  slightly before the section scrolls into view, hiding any setup
   *  jank. */
  rootMargin?: string;
  /** When true, mount once and never unmount (default). When false the
   *  child unmounts as the placeholder leaves the viewport — useful
   *  for very heavy GL scenes. */
  mountOnce?: boolean;
  /** Optional className applied to the placeholder wrapper. */
  className?: string;
  children: React.ReactNode;
}

const LazyMount: React.FC<LazyMountProps> = ({
  fallback = null,
  rootMargin = "200px",
  mountOnce = true,
  className,
  children,
}) => {
  const ref = useRef<HTMLDivElement | null>(null);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    const node = ref.current;
    if (!node) return;
    if (typeof IntersectionObserver === "undefined") {
      setMounted(true);
      return;
    }
    const obs = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            setMounted(true);
            if (mountOnce) {
              obs.disconnect();
              return;
            }
          } else if (!mountOnce) {
            setMounted(false);
          }
        }
      },
      { rootMargin },
    );
    obs.observe(node);
    return () => obs.disconnect();
  }, [rootMargin, mountOnce]);

  return (
    <div ref={ref} className={className}>
      {mounted ? children : fallback}
    </div>
  );
};

export default LazyMount;
