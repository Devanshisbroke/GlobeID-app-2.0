import { useEffect } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { wireBackButton } from "@/lib/nativeBridge";

/**
 * Wires the Android hardware back button into React Router.
 *
 * Phase 6 PR-α — without this, the OS-level back gesture closes the
 * Capacitor activity instead of popping the in-app history stack. On the
 * browser path (where `wireBackButton` returns a no-op), this component
 * mounts but does nothing.
 *
 * Lives inside <BrowserRouter /> so it can call `useNavigate()`.
 */
const NativeBackButton: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    let cancelled = false;
    let unsubscribe: (() => void) | null = null;

    const canGoBack = (): boolean => {
      // Treat the home tab as the root: don't pop into a previous app.
      if (location.pathname === "/") return false;
      return window.history.length > 1;
    };

    void wireBackButton(canGoBack, () => navigate(-1)).then((un) => {
      if (cancelled) {
        un();
        return;
      }
      unsubscribe = un;
    });

    return () => {
      cancelled = true;
      unsubscribe?.();
    };
    // `location` and `navigate` are stable per react-router's contract.
  }, [navigate, location.pathname]);

  return null;
};

export default NativeBackButton;
