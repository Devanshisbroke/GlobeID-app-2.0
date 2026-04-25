import { createRoot } from "react-dom/client";
import App from "./App.tsx";
import ErrorBoundary from "@/components/system/ErrorBoundary";
import { isNative } from "@/lib/nativeBridge";
import "./index.css";

/**
 * Phase 6 PR-α:
 *  - Wrap <App /> in <ErrorBoundary /> so a single thrown render error in
 *    any lazy-loaded screen no longer blanks the app.
 *  - Conditionally disable the Workbox service worker on Capacitor / native
 *    builds — the WebView shouldn't be caching its own bundled assets and
 *    serving them across upgrades. Browser PWA path is unchanged.
 */

// Strip any pre-existing service worker registrations in the native shell.
// `vite-plugin-pwa` will still inject the SW asset at build time, but we
// never register it — and we evict any leftover registration from a prior
// browser visit so the WebView always serves fresh bundled assets.
if (isNative() && "serviceWorker" in navigator) {
  void navigator.serviceWorker.getRegistrations().then((regs) => {
    regs.forEach((r) => void r.unregister());
  });
}

createRoot(document.getElementById("root")!).render(
  <ErrorBoundary>
    <App />
  </ErrorBoundary>,
);
