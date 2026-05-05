/**
 * Capacitor native bridge.
 *
 * Phase 6 PR-α — small, defensive wrapper around the four native plugins
 * we ship in the APK:
 *
 *  - `@capacitor/app`           — Android hardware back button.
 *  - `@capacitor/network`       — Doze-aware online/offline transitions.
 *  - `@capacitor/status-bar`    — theme the status bar to match dark UI.
 *  - `@capacitor/splash-screen` — hide the native splash once React paints.
 *
 * Every call is guarded with `Capacitor.isNativePlatform()` so the same code
 * runs unchanged in the browser PWA path (where the plugins are no-ops).
 */
import { Capacitor } from "@capacitor/core";
import { App as CapApp } from "@capacitor/app";
import { Network } from "@capacitor/network";
import { StatusBar, Style } from "@capacitor/status-bar";
import { SplashScreen } from "@capacitor/splash-screen";

export const isNative = (): boolean => Capacitor.isNativePlatform();

/**
 * Apply native chrome — status bar style + hide native splash. Safe to call
 * multiple times. Resolves once both plugin calls settle (or resolves
 * immediately on the browser).
 */
export async function applyNativeChrome(): Promise<void> {
  if (!isNative()) return;
  // Both plugin calls are best-effort: if the plugin isn't registered for
  // some reason (older Android version, missing manifest entry, etc.), we
  // don't want to crash the app on first paint.
  await Promise.allSettled([
    StatusBar.setStyle({ style: Style.Dark }),
    StatusBar.setBackgroundColor({ color: "#040406" }),
    SplashScreen.hide({ fadeOutDuration: 200 }),
  ]);
}

/**
 * Wire the Android hardware back button into a router-back handler.
 * Returns an unsubscribe fn; if not on native, the unsubscribe is a no-op.
 *
 * Behaviour:
 *  - If the navigator can go back (in-app history), pop the stack.
 *  - Otherwise, exit the app (Android default behaviour).
 */
export async function wireBackButton(
  canGoBack: () => boolean,
  goBack: () => void,
): Promise<() => void> {
  if (!isNative()) return () => undefined;

  const handle = await CapApp.addListener("backButton", () => {
    if (canGoBack()) {
      goBack();
    } else {
      void CapApp.exitApp();
    }
  });
  return () => {
    void handle.remove();
  };
}

/**
 * Subscribe to native network status changes. Returns an unsubscribe fn.
 * On the browser, falls back to native `online` / `offline` window events.
 */
export async function wireNetworkListener(
  onChange: (online: boolean) => void,
): Promise<() => void> {
  if (!isNative()) {
    const onOnline = (): void => onChange(true);
    const onOffline = (): void => onChange(false);
    window.addEventListener("online", onOnline);
    window.addEventListener("offline", onOffline);
    return () => {
      window.removeEventListener("online", onOnline);
      window.removeEventListener("offline", onOffline);
    };
  }

  const handle = await Network.addListener("networkStatusChange", (status) => {
    onChange(status.connected);
  });
  return () => {
    void handle.remove();
  };
}

/**
 * Subscribe to foreground/background transitions (BACKLOG R 205 + B 20).
 *
 * Fires `onForeground()` whenever the app returns from background — the
 * primary use case is to re-hydrate stale stores (FX rates, trip data,
 * notifications). On the browser, falls back to the standard Page
 * Visibility API for parity.
 */
export async function wireAppStateListener(
  onForeground: () => void,
  onBackground?: () => void,
): Promise<() => void> {
  if (!isNative()) {
    const handler = () => {
      if (document.hidden) onBackground?.();
      else onForeground();
    };
    document.addEventListener("visibilitychange", handler);
    return () => document.removeEventListener("visibilitychange", handler);
  }
  const handle = await CapApp.addListener("appStateChange", (state) => {
    if (state.isActive) onForeground();
    else onBackground?.();
  });
  return () => {
    void handle.remove();
  };
}

/**
 * Subscribe to deep-link / custom URL scheme launches (BACKLOG B 21 +
 * R 205). The handler receives the raw URL — caller is responsible for
 * mapping it to a router push.
 *
 * Recognised scheme:
 *   globeid://trip/<id>     → /trip/<id>
 *   globeid://pass/<code>   → /wallet?pass=<code>
 *   globeid://wallet        → /wallet
 *   globeid://verify        → /kiosk
 *
 * On the browser the listener is a no-op; web deep-linking is handled
 * via standard URL routing.
 */
export async function wireUrlOpenListener(
  onUrl: (url: string) => void,
): Promise<() => void> {
  if (!isNative()) return () => undefined;
  const handle = await CapApp.addListener("appUrlOpen", (event) => {
    if (event.url) onUrl(event.url);
  });
  return () => {
    void handle.remove();
  };
}

/**
 * Map a `globeid://` URL into a router path. Pure function so it can be
 * unit-tested without spinning up a router.
 *
 * Returns `null` for unrecognised paths — caller is responsible for the
 * fallback (e.g. show a toast).
 */
export function deepLinkToPath(url: string): string | null {
  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    return null;
  }
  // Path segments are *already* percent-decoded by URL.pathname when
  // accessed through `pathname.split("/")`, but the raw path string
  // retains the encoding. We split off the raw pathname so the trip
  // ID retains whatever encoding the caller intended.
  const segments = parsed.pathname.replace(/^\/+/, "").split("/").filter(Boolean);

  // Decide the head:
  //   - For `globeid://trip/123` the protocol is `globeid:` and host
  //     is "trip" so we use that.
  //   - For `https://*.globeid.app/trip/123` the host is a real domain
  //     so we promote the first segment.
  const isCustomScheme = !!parsed.protocol && parsed.protocol !== "https:" && parsed.protocol !== "http:";
  const head = isCustomScheme ? parsed.host : segments.shift();

  switch (head) {
    case "trip": {
      const id = segments[0];
      if (!id) return null;
      return `/trip/${encodeURIComponent(decodeURIComponent(id))}`;
    }
    case "pass": {
      const code = segments[0];
      if (!code) return null;
      return `/wallet?pass=${encodeURIComponent(decodeURIComponent(code))}`;
    }
    case "wallet":
      return "/wallet";
    case "verify":
    case "kiosk":
      return "/kiosk";
    case "trips":
      return "/trips";
    case "vault":
    case "documents":
      return "/vault";
    default:
      return null;
  }
}
