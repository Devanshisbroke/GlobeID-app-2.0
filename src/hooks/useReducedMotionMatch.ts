/**
 * `prefers-reduced-motion: reduce` media-query observer.
 *
 * Lifted from useDeviceTilt so other hooks (scroll tint, parallax, etc.)
 * can share a single implementation without duplicating the listener.
 *
 * Defensive against SSR + browsers without matchMedia (returns false).
 */
import { useEffect, useState } from "react";

export function useReducedMotionMatch(): boolean {
  const [reduced, setReduced] = useState<boolean>(() => {
    if (typeof window === "undefined" || !window.matchMedia) return false;
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  });
  useEffect(() => {
    if (typeof window === "undefined" || !window.matchMedia) return;
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    const listener = (e: MediaQueryListEvent) => setReduced(e.matches);
    mq.addEventListener?.("change", listener);
    return () => mq.removeEventListener?.("change", listener);
  }, []);
  return reduced;
}
