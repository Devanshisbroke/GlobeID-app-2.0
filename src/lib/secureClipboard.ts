/**
 * Secure clipboard helper.
 *
 * Mirrors the behaviour of password managers: when sensitive text
 * (passport number, MRZ, OTP) is copied, schedule a best-effort
 * auto-clear after a short window so it doesn't sit in the OS
 * clipboard waiting to be pasted into an unrelated app.
 *
 * Implementation:
 *  - `secureCopy` writes to navigator.clipboard, then schedules a
 *    `setTimeout` to overwrite the clipboard with an empty string
 *    *only if* it still contains the same value we wrote (so we
 *    don't accidentally wipe something the user copied themselves
 *    in the meantime).
 *  - If the platform doesn't expose `clipboard.readText` (some
 *    iOS WebViews), we fall back to an unconditional clear after
 *    the TTL — still safer than leaving the value indefinitely.
 *  - All clipboard calls are wrapped in try/catch so a permission
 *    error never propagates into the calling UI.
 *
 * No external dependencies. Capacitor-friendly: navigator.clipboard
 * is supported across Android WebView 66+ and iOS 13.4+.
 */

const DEFAULT_TTL_MS = 30_000;
const pending = new Map<string, ReturnType<typeof setTimeout>>();

export interface SecureCopyOptions {
  /** Time-to-live in ms before the clipboard is cleared. Default 30 s. */
  ttlMs?: number;
  /** Optional logical key — copies under the same key cancel any prior pending clear. */
  key?: string;
}

export async function secureCopy(
  text: string,
  options: SecureCopyOptions = {},
): Promise<boolean> {
  const ttl = options.ttlMs ?? DEFAULT_TTL_MS;
  const key = options.key ?? text;

  try {
    await navigator.clipboard.writeText(text);
  } catch {
    return false;
  }

  // Cancel any earlier pending clear for the same logical key.
  const prev = pending.get(key);
  if (prev) clearTimeout(prev);

  const handle = setTimeout(async () => {
    pending.delete(key);
    try {
      const current = await tryReadClipboard();
      // Only clear if the clipboard still holds *our* value — never
      // overwrite something the user copied themselves later.
      if (current === null || current === text) {
        await navigator.clipboard.writeText("");
      }
    } catch {
      /* ignore — best-effort */
    }
  }, ttl);
  pending.set(key, handle);
  return true;
}

/** Attempt to read the current clipboard. Returns null on failure. */
async function tryReadClipboard(): Promise<string | null> {
  try {
    if (!navigator.clipboard.readText) return null;
    return await navigator.clipboard.readText();
  } catch {
    return null;
  }
}

/** Cancel any pending auto-clear for the given key (or all). Test helper. */
export function _cancelPendingClears(key?: string): void {
  if (key) {
    const h = pending.get(key);
    if (h) {
      clearTimeout(h);
      pending.delete(key);
    }
    return;
  }
  for (const h of pending.values()) clearTimeout(h);
  pending.clear();
}
