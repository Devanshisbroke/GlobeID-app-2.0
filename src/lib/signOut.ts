/**
 * Centralised sign-out (BACKLOG B 15).
 *
 * Performs a comprehensive wipe so the next launch is indistinguishable
 * from a fresh install:
 *  - Clears every key in `localStorage` namespaced under `globeid:`.
 *  - Clears the onboarding flag (so `/onboarding` runs again).
 *  - Cancels all scheduled local notifications (so a sign-out doesn't
 *    leave behind a "Leave for the airport" alarm).
 *  - Best-effort revokes any cached auth/session tokens — currently a
 *    no-op since the demo backend uses an in-memory token, but the
 *    seam is here for future Lucia/better-auth integration.
 *  - Calls `navigator.credentials.preventSilentAccess()` so any
 *    PassKey-style credential won't auto-resolve on the next visit.
 *
 * Usage:
 *   await signOut({ navigate });
 */

import { resetOnboarding } from "@/lib/onboarding";
import { LocalNotifications } from "@capacitor/local-notifications";
import { Capacitor } from "@capacitor/core";

interface SignOutOptions {
  /** React-router navigate fn to redirect after the wipe completes. */
  navigate?: (to: string, opts?: { replace?: boolean }) => void;
  /** Override fetch impl for tests. */
  fetchImpl?: typeof fetch;
}

export async function signOut(opts: SignOutOptions = {}): Promise<void> {
  // 1) Clear globeid:* keys from localStorage.
  try {
    for (const key of Object.keys(localStorage)) {
      if (key.startsWith("globeid:")) localStorage.removeItem(key);
    }
  } catch {
    // localStorage can throw in private mode — swallow.
  }

  // 2) Reset onboarding flag (survived above wipe in case prefix changes).
  try {
    resetOnboarding();
  } catch {
    /* ignore */
  }

  // 3) Cancel scheduled local notifications (best-effort, native-only).
  if (Capacitor.isNativePlatform()) {
    try {
      const pending = await LocalNotifications.getPending();
      if (pending.notifications.length > 0) {
        await LocalNotifications.cancel({
          notifications: pending.notifications.map((n) => ({ id: n.id })),
        });
      }
    } catch {
      /* plugin not enabled or no permission — silent fallback */
    }
  }

  // 4) Best-effort token revoke. Real auth: POST /api/auth/sign-out.
  //    Demo backend doesn't enforce session, so a 404 is fine. Failure
  //    here MUST NOT block the local wipe.
  const fetcher = opts.fetchImpl ?? (typeof fetch === "function" ? fetch : null);
  if (fetcher) {
    try {
      await fetcher("/api/auth/sign-out", {
        method: "POST",
        credentials: "include",
      });
    } catch {
      /* swallow */
    }
  }

  // 5) Tell the credentials store not to auto-resolve next time.
  try {
    if (
      typeof navigator !== "undefined" &&
      navigator.credentials &&
      typeof navigator.credentials.preventSilentAccess === "function"
    ) {
      await navigator.credentials.preventSilentAccess();
    }
  } catch {
    /* unsupported / silent */
  }

  // 6) Hard redirect so React state across all stores is fully discarded.
  if (opts.navigate) {
    opts.navigate("/onboarding", { replace: true });
  } else if (typeof window !== "undefined") {
    window.location.assign("/onboarding");
  }
}
