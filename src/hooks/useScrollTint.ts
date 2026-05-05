/**
 * Scroll-driven theme tint (BACKLOG K 133).
 *
 * Drives a subtle background hue shift on the host element as the user
 * scrolls. Useful on Home where the long timeline benefits from a
 * gentle "moving through time" colour cue.
 *
 *   scroll progress 0..1  →  hue offset 0..maxHueShift
 *
 * Implementation:
 *   - rAF-throttled scroll listener (single passive listener, no React
 *     state updates until the value actually changed beyond a delta).
 *   - Honours `prefers-reduced-motion: reduce` — locks at 0, no
 *     listener registered.
 *
 * Returns a CSSProperties partial intended to be spread onto the
 * scroll container so children can `style={{ background: var(...) }}`
 * without re-rendering.
 */
import { useEffect, useState } from "react";
import { useReducedMotionMatch } from "@/hooks/useReducedMotionMatch";

interface Options {
  /** How much the hue shifts at full progress (0..360, default 12). */
  maxHueShift?: number;
  /** Maximum scroll height to map to 100% (default 800px). */
  maxScrollPx?: number;
  /** Disable the listener entirely. */
  disabled?: boolean;
}

interface ScrollTint {
  /** 0..1 fraction of the configured max scroll. */
  progress: number;
  /** Absolute hue offset in degrees. */
  hueOffset: number;
  /** Inline style ready to spread onto the host. */
  style: React.CSSProperties;
}

export function useScrollTint(opts: Options = {}): ScrollTint {
  const reducedMotion = useReducedMotionMatch();
  const [progress, setProgress] = useState(0);
  const max = opts.maxScrollPx ?? 800;
  const maxHue = opts.maxHueShift ?? 12;

  useEffect(() => {
    if (reducedMotion || opts.disabled) {
      setProgress(0);
      return;
    }
    let raf = 0;
    let last = 0;
    const onScroll = () => {
      if (raf) return;
      raf = requestAnimationFrame(() => {
        raf = 0;
        const next = Math.min(1, Math.max(0, window.scrollY / max));
        // Snap to 0.01 to avoid spamming React with every pixel.
        if (Math.abs(next - last) > 0.01) {
          last = next;
          setProgress(next);
        }
      });
    };
    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
    return () => {
      window.removeEventListener("scroll", onScroll);
      if (raf) cancelAnimationFrame(raf);
    };
  }, [max, opts.disabled, reducedMotion]);

  const hueOffset = progress * maxHue;
  return {
    progress,
    hueOffset,
    style: {
      // CSS custom prop the host can use in a filter or background.
      "--p7-scroll-tint": `${hueOffset}deg`,
    } as React.CSSProperties,
  };
}
