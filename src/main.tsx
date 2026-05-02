import { createRoot } from "react-dom/client";
import App from "./App.tsx";
import ErrorBoundary from "@/components/system/ErrorBoundary";
import { isNative } from "@/lib/nativeBridge";

// Phase 7 PR-α — self-hosted variable type stack.
// `Inter` provides body + UI sizes; `Inter` with `font-optical-sizing: auto`
// also serves the display tier (Inter v4+ includes the InterDisplay optical
// axis directly in the variable file). `JetBrains Mono` is reserved for
// technical IDs (MRZ, tx hashes, route codes). All three load locally so the
// Capacitor APK has zero font network dependency on first launch.
import "@fontsource-variable/inter";
import "@fontsource-variable/jetbrains-mono";

import "./index.css";

// Slice-C: boot react-i18next before React mounts so the first render has
// the resolved language. Importing for side-effects only.
import "./i18n";

// Slice-F: boot the offline sync engine + context background loop. Both
// idempotent, both safe to start at module-init time; they internally gate
// on visibility + network so they don't burn CPU when the tab is hidden.
import { startSyncEngine } from "@/lib/syncEngine";
import { startContextLoop } from "@/core/contextBackgroundLoop";
import { startScheduledJobs } from "@/core/scheduledJobs";
startSyncEngine();
startContextLoop();
startScheduledJobs();

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
