/**
 * Slice-G – iOS-style edge-swipe-to-go-back gesture.
 *
 * Listens for a touch that starts within 24 px of the left screen edge
 * and tracks horizontal movement. If the user pulls past 80 px AND the
 * gesture finishes with a positive horizontal velocity, navigate back.
 *
 * Excluded routes: `/`, `/onboarding`, `/lock` — the home tab and
 * full-screen first-run gates have nowhere meaningful to go back to.
 *
 * Pure side-effect, mounts once near the App root. No JSX rendered —
 * the visual breadcrumb of the gesture is the page itself sliding via
 * `PageTransition` after `navigate(-1)` fires.
 */
import { useEffect } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { haptics } from "@/utils/haptics";

const EDGE_PX = 24;
const PULL_THRESHOLD_PX = 80;
const EXCLUDED_ROUTES = new Set<string>(["/", "/onboarding", "/lock"]);

export const EdgeSwipeBack: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();

  useEffect(() => {
    if (EXCLUDED_ROUTES.has(location.pathname)) return undefined;

    let startX = 0;
    let startY = 0;
    let armed = false;
    let lastX = 0;
    let lastT = 0;
    let velocity = 0;

    const onStart = (e: TouchEvent) => {
      const t = e.touches[0];
      if (!t) return;
      if (t.clientX > EDGE_PX) return;
      armed = true;
      startX = t.clientX;
      startY = t.clientY;
      lastX = t.clientX;
      lastT = performance.now();
    };

    const onMove = (e: TouchEvent) => {
      if (!armed) return;
      const t = e.touches[0];
      if (!t) return;
      const dx = t.clientX - startX;
      const dy = Math.abs(t.clientY - startY);
      // Reject if mostly vertical (page scroll wins).
      if (dy > Math.abs(dx) && dy > 16) {
        armed = false;
        return;
      }
      const now = performance.now();
      const dt = Math.max(1, now - lastT);
      velocity = (t.clientX - lastX) / dt;
      lastX = t.clientX;
      lastT = now;
    };

    const onEnd = () => {
      if (!armed) return;
      const dx = lastX - startX;
      armed = false;
      if (dx > PULL_THRESHOLD_PX && velocity > 0) {
        haptics.medium();
        navigate(-1);
      }
    };

    window.addEventListener("touchstart", onStart, { passive: true });
    window.addEventListener("touchmove", onMove, { passive: true });
    window.addEventListener("touchend", onEnd, { passive: true });
    window.addEventListener("touchcancel", onEnd, { passive: true });

    return () => {
      window.removeEventListener("touchstart", onStart);
      window.removeEventListener("touchmove", onMove);
      window.removeEventListener("touchend", onEnd);
      window.removeEventListener("touchcancel", onEnd);
    };
  }, [location.pathname, navigate]);

  return null;
};

export default EdgeSwipeBack;
