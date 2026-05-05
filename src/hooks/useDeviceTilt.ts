/**
 * useDeviceTilt — subscribe to deviceorientation events with permission
 * gating + reduced-motion fallback (BACKLOG C 25 — parallax pass tilt).
 *
 * Returns normalised tilt values in [-1, 1] for x (left/right) and
 * y (forward/back). Pure web API — no Capacitor plugin dependency.
 *
 * Browser quirks handled:
 *  - iOS 13+ requires a one-time permission prompt; we only request on
 *    a user gesture, so callers should attach `requestPermission` to a
 *    tap. Without permission we simply emit zero tilt.
 *  - Android Chrome reports beta/gamma in degrees ranges [-180,180] /
 *    [-90,90]; we clamp to ±30° and divide so the visible movement is
 *    contained, not wild.
 *  - Hidden tab: orientation events are throttled by browsers; nothing
 *    extra to do.
 *
 * Reduced-motion users see no tilt at all.
 */
import { useCallback, useEffect, useState } from "react";
import { useReducedMotionMatch } from "@/hooks/useReducedMotionMatch";

interface TiltState {
  /** -1 (full left) to +1 (full right). */
  x: number;
  /** -1 (lean back) to +1 (lean forward). */
  y: number;
  /** True once a permission request has resolved with grant. */
  enabled: boolean;
}

const ZERO: TiltState = { x: 0, y: 0, enabled: false };

const TILT_CLAMP_DEG = 30;

function clampNorm(deg: number): number {
  if (!Number.isFinite(deg)) return 0;
  const c = Math.max(-TILT_CLAMP_DEG, Math.min(TILT_CLAMP_DEG, deg));
  return c / TILT_CLAMP_DEG;
}

interface DeviceOrientationEventLike extends EventInit {
  beta: number | null;
  gamma: number | null;
  alpha: number | null;
}

interface DeviceOrientationEventCtor {
  requestPermission?: () => Promise<"granted" | "denied">;
}

export function useDeviceTilt(enabled: boolean = true): {
  tilt: { x: number; y: number };
  enabled: boolean;
  /** Wire to a button onClick to satisfy the iOS gesture requirement. */
  requestPermission: () => Promise<boolean>;
} {
  const [state, setState] = useState<TiltState>(ZERO);

  // Honor prefers-reduced-motion: never subscribe.
  const reducedMotion = useReducedMotionMatch();

  useEffect(() => {
    if (!enabled || reducedMotion) {
      setState(ZERO);
      return;
    }
    if (typeof window === "undefined") return;
    const onOrientation = (e: Event) => {
      const ev = e as Event & DeviceOrientationEventLike;
      const x = clampNorm(ev.gamma ?? 0);
      const y = clampNorm(ev.beta ?? 0);
      setState((prev) => ({ x, y, enabled: prev.enabled || true }));
    };
    window.addEventListener("deviceorientation", onOrientation, true);
    return () => {
      window.removeEventListener("deviceorientation", onOrientation, true);
    };
  }, [enabled, reducedMotion]);

  const requestPermission = useCallback(async () => {
    if (typeof window === "undefined") return false;
    const Ctor = window.DeviceOrientationEvent as unknown as
      | DeviceOrientationEventCtor
      | undefined;
    if (Ctor && typeof Ctor.requestPermission === "function") {
      try {
        const r = await Ctor.requestPermission();
        const granted = r === "granted";
        setState((prev) => ({ ...prev, enabled: granted }));
        return granted;
      } catch {
        return false;
      }
    }
    // No prompt required (Android / desktop).
    setState((prev) => ({ ...prev, enabled: true }));
    return true;
  }, []);

  return { tilt: { x: state.x, y: state.y }, enabled: state.enabled, requestPermission };
}

// Re-export so existing imports keep working.
export { useReducedMotionMatch };
