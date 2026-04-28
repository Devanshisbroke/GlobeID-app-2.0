/**
 * Slice-A — local notifications.
 *
 * Wraps `@capacitor/local-notifications` so the rest of the app can fire
 * scheduled boarding / delay reminders without caring whether we're on
 * Android (real OS notifications) or in the browser PWA (Notifications
 * API + ServiceWorker fallback). Web notifications only fire while a tab
 * is open — an honest limitation we surface in the audit report rather
 * than fake around.
 *
 * Permission UX:
 *  - On native, we ask once on first scheduling attempt.
 *  - On web, ditto via `Notification.requestPermission()`.
 *  - If denied, we no-op silently — caller logic must still drive the UI.
 *
 * Idempotency:
 *  - Each scheduled notification carries a stable numeric ID derived from
 *    `kind:legId` so re-running `scheduleTripReminders()` after a hydrate
 *    upserts rather than duplicates.
 */
import { Capacitor } from "@capacitor/core";
import { LocalNotifications } from "@capacitor/local-notifications";
import type { TripLifecycle, TripLeg } from "@shared/types/lifecycle";

type NotifKind = "boarding-2h" | "boarding-30m" | "departure" | "delay";

export interface ScheduledNotification {
  id: number;
  kind: NotifKind;
  legId: string;
  scheduledAt: number;
  title: string;
  body: string;
}

const isNative = (): boolean => Capacitor.isNativePlatform();

let permissionGranted: boolean | null = null;

/**
 * Stable hash → small positive int. Capacitor IDs must fit into 31-bit
 * signed range; using a djb2-style hash keeps collisions vanishingly rare
 * across the typical 5–20 active legs in a user's plans.
 */
function notifId(kind: NotifKind, legId: string): number {
  let h = 5381;
  const key = `${kind}:${legId}`;
  for (let i = 0; i < key.length; i++) {
    h = ((h << 5) + h + key.charCodeAt(i)) | 0;
  }
  return Math.abs(h);
}

export async function ensurePermission(): Promise<boolean> {
  if (permissionGranted !== null) return permissionGranted;

  if (isNative()) {
    const status = await LocalNotifications.checkPermissions();
    if (status.display === "granted") {
      permissionGranted = true;
      return true;
    }
    if (status.display === "denied") {
      permissionGranted = false;
      return false;
    }
    const req = await LocalNotifications.requestPermissions();
    permissionGranted = req.display === "granted";
    return permissionGranted;
  }

  if (typeof window === "undefined" || !("Notification" in window)) {
    permissionGranted = false;
    return false;
  }
  if (Notification.permission === "granted") {
    permissionGranted = true;
    return true;
  }
  if (Notification.permission === "denied") {
    permissionGranted = false;
    return false;
  }
  const req = await Notification.requestPermission();
  permissionGranted = req === "granted";
  return permissionGranted;
}

/** Cancel any previously-scheduled GlobeID notifications for these IDs. */
async function cancelByIds(ids: number[]): Promise<void> {
  if (ids.length === 0) return;
  if (isNative()) {
    await LocalNotifications.cancel({ notifications: ids.map((id) => ({ id })) });
  }
  // Web Notifications API has no "cancel scheduled" — they fire immediately.
}

/**
 * Compute a leg's likely boarding/departure timestamps. The TripLeg only
 * carries an ISO date (no clock time), so we use 09:00 local as a stable
 * heuristic — annotated in the notif body so the user knows it's a
 * placeholder departure time, not airline-confirmed.
 */
function legTimes(leg: TripLeg): { departure: number; boarding30m: number; boarding2h: number } {
  const departure = new Date(`${leg.date}T09:00:00`).getTime();
  return {
    departure,
    boarding30m: departure - 30 * 60_000,
    boarding2h: departure - 2 * 3_600_000,
  };
}

/**
 * Schedule boarding + departure reminders for every upcoming leg of a
 * single trip. Idempotent: safe to call after every `lifecycleStore.hydrate()`.
 *
 * Returns the list of scheduled notifications (for UI surface / debug).
 */
export async function scheduleTripReminders(trip: TripLifecycle): Promise<ScheduledNotification[]> {
  const ok = await ensurePermission();
  if (!ok) return [];

  const now = Date.now();
  const scheduled: ScheduledNotification[] = [];
  const cancelIds: number[] = [];

  for (const leg of trip.legs) {
    if (leg.type === "past") continue;
    const { departure, boarding30m, boarding2h } = legTimes(leg);

    const candidates: Array<{ kind: NotifKind; at: number; title: string; body: string }> = [
      {
        kind: "boarding-2h",
        at: boarding2h,
        title: `Heads up: ${leg.airline} ${leg.flightNumber ?? ""}`.trim(),
        body: `Departing ${leg.fromIata} → ${leg.toIata} in ~2 hours (estimated 09:00 local — confirm with airline).`,
      },
      {
        kind: "boarding-30m",
        at: boarding30m,
        title: `Boarding soon: ${leg.fromIata} → ${leg.toIata}`,
        body: `Boarding window opens in ~30 minutes. Have your boarding pass ready.`,
      },
      {
        kind: "departure",
        at: departure,
        title: `Departure: ${leg.airline} ${leg.flightNumber ?? ""}`.trim(),
        body: `Scheduled to depart ${leg.fromIata} → ${leg.toIata} now.`,
      },
    ];

    for (const c of candidates) {
      const id = notifId(c.kind, leg.id);
      if (c.at <= now) {
        cancelIds.push(id);
        continue;
      }
      scheduled.push({
        id,
        kind: c.kind,
        legId: leg.id,
        scheduledAt: c.at,
        title: c.title,
        body: c.body,
      });
    }
  }

  await cancelByIds(cancelIds);

  if (scheduled.length === 0) return [];

  if (isNative()) {
    await LocalNotifications.schedule({
      notifications: scheduled.map((n) => ({
        id: n.id,
        title: n.title,
        body: n.body,
        schedule: { at: new Date(n.scheduledAt) },
        smallIcon: "ic_stat_icon_config_sample",
      })),
    });
  } else {
    // Browser fallback: setTimeout in-session. Not durable, but gives
    // immediate-feedback UX for users testing in the PWA. We ceiling at
    // 1h horizon so we don't pin long-lived timers unnecessarily.
    const horizonMs = 60 * 60_000;
    for (const n of scheduled) {
      const delay = n.scheduledAt - Date.now();
      if (delay <= 0 || delay > horizonMs) continue;
      window.setTimeout(() => {
        try {
          new Notification(n.title, { body: n.body });
        } catch {
          /* ignore */
        }
      }, delay);
    }
  }

  return scheduled;
}

/** Fire a single delay notification immediately. Idempotent per legId. */
export async function notifyDelay(
  legId: string,
  airline: string,
  flightNumber: string | null,
  delayMinutes: number,
): Promise<void> {
  const ok = await ensurePermission();
  if (!ok) return;
  const id = notifId("delay", legId);
  const title = `${airline} ${flightNumber ?? ""} delayed`.trim();
  const body = `Estimated delay: ${delayMinutes} min. We'll update boarding reminders shortly.`;

  if (isNative()) {
    await LocalNotifications.schedule({
      notifications: [
        {
          id,
          title,
          body,
          schedule: { at: new Date(Date.now() + 1_000) },
          smallIcon: "ic_stat_icon_config_sample",
        },
      ],
    });
    return;
  }
  try {
    new Notification(title, { body });
  } catch {
    /* permission lost mid-flight; nothing to recover */
  }
}

/** Cancel every GlobeID-scheduled notification (on sign-out, for instance). */
export async function clearAllScheduled(): Promise<void> {
  if (!isNative()) return;
  const pending = await LocalNotifications.getPending();
  if (pending.notifications.length > 0) {
    await LocalNotifications.cancel({
      notifications: pending.notifications.map((n) => ({ id: n.id })),
    });
  }
}
