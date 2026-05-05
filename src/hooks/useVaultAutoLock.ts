/**
 * Vault auto-lock (BACKLOG E 59 + P 171).
 *
 * Tracks user activity (`pointer*`, `key*`, `touch*`) and the document
 * visibility state. If the user is idle for `timeoutMs` (default 5 min)
 * OR the page has been hidden for `backgroundTimeoutMs` (default 30 s),
 * we navigate to /lock + log an audit event.
 *
 * Why both timers: idle-only would let a phone sit unlocked in a bag
 * while the screen is off (visibility=visible but no input); visibility-
 * only would lock too aggressively on a quick app-switch. Using both
 * gives the iOS-style behaviour of "stays unlocked while in use, locks
 * if you walk away".
 */
import { useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { useVaultAuditStore } from "@/store/vaultAuditStore";

interface Options {
  /** Idle timeout in ms. Default 5 minutes. */
  timeoutMs?: number;
  /** Background visibility timeout in ms. Default 30 seconds. */
  backgroundTimeoutMs?: number;
  /** Disable the hook (for unit tests / lock screen itself). */
  disabled?: boolean;
}

const ACTIVITY_EVENTS: Array<keyof WindowEventMap> = [
  "pointerdown",
  "pointermove",
  "keydown",
  "touchstart",
  "scroll",
  "wheel",
];

export function useVaultAutoLock(opts: Options = {}): void {
  const navigate = useNavigate();
  const log = useVaultAuditStore((s) => s.log);
  const timeoutMs = opts.timeoutMs ?? 5 * 60_000;
  const bgTimeoutMs = opts.backgroundTimeoutMs ?? 30_000;
  const idleTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const bgTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    if (opts.disabled) return;

    const lock = (note: string) => {
      try {
        log({ kind: "auto_lock", note });
      } catch {
        /* ignore */
      }
      navigate("/lock", { replace: true });
    };

    const resetIdle = () => {
      if (idleTimerRef.current) clearTimeout(idleTimerRef.current);
      idleTimerRef.current = setTimeout(() => lock("idle timeout"), timeoutMs);
    };

    const onVisibility = () => {
      if (document.hidden) {
        if (bgTimerRef.current) clearTimeout(bgTimerRef.current);
        bgTimerRef.current = setTimeout(
          () => lock("background timeout"),
          bgTimeoutMs,
        );
      } else {
        if (bgTimerRef.current) clearTimeout(bgTimerRef.current);
        resetIdle();
      }
    };

    for (const evt of ACTIVITY_EVENTS) {
      window.addEventListener(evt, resetIdle, { passive: true });
    }
    document.addEventListener("visibilitychange", onVisibility);
    resetIdle();

    return () => {
      for (const evt of ACTIVITY_EVENTS) {
        window.removeEventListener(evt, resetIdle);
      }
      document.removeEventListener("visibilitychange", onVisibility);
      if (idleTimerRef.current) clearTimeout(idleTimerRef.current);
      if (bgTimerRef.current) clearTimeout(bgTimerRef.current);
    };
  }, [bgTimeoutMs, log, navigate, opts.disabled, timeoutMs]);
}
