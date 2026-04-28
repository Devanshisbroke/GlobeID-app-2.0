import React, { useEffect, useState } from "react";
import { CloudOff, RefreshCw } from "lucide-react";
import { wireNetworkListener } from "@/lib/nativeBridge";

/**
 * Slice-A — full-width offline banner.
 *
 * Listens to the same `wireNetworkListener` channel `App.tsx` uses for its
 * hydrate-on-online retry, so this banner reflects the same connectivity
 * signal the rest of the app sees (Capacitor `@capacitor/network` on
 * Android, `window.online` events in the browser PWA).
 *
 * Placed *inside* `AppChrome` above the main scroll area so it doesn't
 * collide with the safe-area-anchored top widgets (theme toggle, sync
 * badge). Animates in/out via Tailwind transitions; no extra deps.
 */
const OfflineBanner: React.FC = () => {
  const [online, setOnline] = useState<boolean>(
    typeof navigator !== "undefined" ? navigator.onLine : true,
  );
  const [retrying, setRetrying] = useState(false);

  useEffect(() => {
    let cancelled = false;
    let unsubscribe: (() => void) | null = null;
    void wireNetworkListener((isOnline) => {
      if (cancelled) return;
      setOnline(isOnline);
    }).then((un) => {
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
  }, []);

  if (online) return null;

  const retry = async () => {
    setRetrying(true);
    // Re-probe via a tiny HEAD; if it works, the network listener will fire
    // first and hide the banner before this resolves.
    try {
      await fetch("/api/v1/health", { method: "GET", cache: "no-store" });
      setOnline(true);
    } catch {
      /* still offline — leave banner up */
    } finally {
      setRetrying(false);
    }
  };

  return (
    <div
      role="status"
      aria-live="polite"
      className="sticky top-0 z-50 px-3 py-2 bg-amber-500/15 border-b border-amber-500/30 backdrop-blur-md flex items-center justify-between gap-2 text-amber-700 dark:text-amber-300"
    >
      <div className="flex items-center gap-2 min-w-0">
        <CloudOff className="w-3.5 h-3.5 shrink-0" />
        <p className="text-[11px] leading-tight truncate">
          You're offline — changes are queued and will sync when you reconnect.
        </p>
      </div>
      <button
        type="button"
        onClick={retry}
        disabled={retrying}
        className="text-[11px] font-medium px-2 py-1 rounded-md border border-amber-500/40 hover:bg-amber-500/10 active:scale-95 transition-transform disabled:opacity-40 inline-flex items-center gap-1"
      >
        <RefreshCw className={"w-3 h-3 " + (retrying ? "animate-spin" : "")} />
        Retry
      </button>
    </div>
  );
};

export default OfflineBanner;
