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
