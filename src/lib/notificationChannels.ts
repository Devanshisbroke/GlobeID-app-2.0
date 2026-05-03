/**
 * Per-channel notification preferences (BACKLOG O 164).
 *
 * The user can opt in or out of each notification channel
 * independently. Persisted to localStorage; defaults are conservative
 * (every channel on so the user gets value out of the box, then can
 * turn things down).
 *
 * Channels:
 *  - docExpiry  → "Your visa expires in 30 days"
 *  - tripDeparture → "Leave for the airport in 90 min"
 *  - currencyDrop → "EUR is at a 6-month low against USD"
 *  - weeklyDigest → Sunday 9am summary
 *  - securityAlert → security relevant events (sign-in, vault unlock)
 */

export const NOTIFICATION_CHANNELS = [
  "docExpiry",
  "tripDeparture",
  "currencyDrop",
  "weeklyDigest",
  "securityAlert",
] as const;

export type NotificationChannel = (typeof NOTIFICATION_CHANNELS)[number];

export type NotificationChannelPrefs = Record<NotificationChannel, boolean>;

export const DEFAULT_CHANNEL_PREFS: NotificationChannelPrefs = {
  docExpiry: true,
  tripDeparture: true,
  currencyDrop: true,
  weeklyDigest: true,
  securityAlert: true,
};

export const CHANNEL_LABELS: Record<NotificationChannel, { title: string; description: string }> = {
  docExpiry: {
    title: "Document expiry",
    description: "Visa, passport, and policy expiry warnings ahead of time.",
  },
  tripDeparture: {
    title: "Trip departure",
    description: "Reminders to leave for the airport, gate changes, and check-in.",
  },
  currencyDrop: {
    title: "Currency drops",
    description: "When a currency you've recently used hits a multi-month low.",
  },
  weeklyDigest: {
    title: "Weekly digest",
    description: "Sunday morning summary of upcoming trips, expiries, and spend.",
  },
  securityAlert: {
    title: "Security alerts",
    description: "New device sign-ins, vault unlocks, and biometric events.",
  },
};

const STORAGE_KEY = "globeid:notificationChannels";

export function getChannelPrefs(): NotificationChannelPrefs {
  if (typeof localStorage === "undefined") return { ...DEFAULT_CHANNEL_PREFS };
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return { ...DEFAULT_CHANNEL_PREFS };
    const parsed = JSON.parse(raw) as Partial<NotificationChannelPrefs>;
    return { ...DEFAULT_CHANNEL_PREFS, ...parsed };
  } catch {
    return { ...DEFAULT_CHANNEL_PREFS };
  }
}

export function setChannelPref(channel: NotificationChannel, enabled: boolean): NotificationChannelPrefs {
  const next = { ...getChannelPrefs(), [channel]: enabled };
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
  } catch {
    /* ignore */
  }
  return next;
}

/** Used by the scheduled-jobs layer to gate emit calls. */
export function isChannelEnabled(channel: NotificationChannel): boolean {
  return getChannelPrefs()[channel];
}
