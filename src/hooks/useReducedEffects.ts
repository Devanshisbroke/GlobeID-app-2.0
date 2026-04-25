import { useEffect, useState } from "react";
import { isMobileOrCapacitor } from "@/hooks/useMobileDetect";

/**
 * Returns `true` when ambient/decorative effects should be reduced:
 *   - the user is on a mobile browser or inside the Capacitor WebView, OR
 *   - the OS-level `prefers-reduced-motion` media query matches.
 *
 * Components opt into the lighter render path (fewer particles, no
 * infinite paint-bound animations, simpler shaders) without changing
 * their public API. Desktop with no reduced-motion preference renders
 * the full premium experience exactly as before.
 */
export function useReducedEffects(): boolean {
  const [reduced, setReduced] = useState<boolean>(() => {
    if (typeof window === "undefined") return false;
    if (isMobileOrCapacitor()) return true;
    return window.matchMedia?.("(prefers-reduced-motion: reduce)").matches ?? false;
  });

  useEffect(() => {
    if (typeof window === "undefined" || !window.matchMedia) return;
    const mql = window.matchMedia("(prefers-reduced-motion: reduce)");
    const onChange = () => setReduced(isMobileOrCapacitor() || mql.matches);
    mql.addEventListener?.("change", onChange);
    return () => mql.removeEventListener?.("change", onChange);
  }, []);

  return reduced;
}
