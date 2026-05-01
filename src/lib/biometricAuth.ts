/**
 * Cross-platform biometric authentication wrapper.
 *
 * On Capacitor (Android / iOS) the `@aparajita/capacitor-biometric-auth`
 * plugin is used. The plugin returns a typed result with a stable error
 * code. On the web we fall back to the WebAuthn `credentials.get()` API
 * with a "platform" authenticator hint, which prompts the same
 * Touch/Face ID UI on supported devices. If neither path is available
 * the helper returns `{ ok: false, code: "unsupported" }` so the caller
 * can gracefully fall through to PIN entry.
 *
 * No fake / silent success — every code path either runs a real
 * authenticator or fails explicitly.
 */
import { Capacitor } from "@capacitor/core";

export type BiometricCode =
  | "ok"
  | "cancelled"
  | "failed"
  | "lockout"
  | "unenrolled"
  | "unsupported";

export interface BiometricResult {
  ok: boolean;
  code: BiometricCode;
  message?: string;
}

/**
 * Probe whether biometric auth is available on the current device.
 * Returns a coarse result rather than the full provider list because
 * callers usually just want a yes/no for UI gating.
 */
export async function isBiometricAvailable(): Promise<boolean> {
  if (Capacitor.isNativePlatform()) {
    try {
      const mod = await import("@aparajita/capacitor-biometric-auth");
      const info = await mod.BiometricAuth.checkBiometry();
      return Boolean(info.isAvailable);
    } catch {
      return false;
    }
  }
  if (typeof window !== "undefined" && "PublicKeyCredential" in window) {
    try {
      const supported = await PublicKeyCredential
        .isUserVerifyingPlatformAuthenticatorAvailable?.();
      return Boolean(supported);
    } catch {
      return false;
    }
  }
  return false;
}

/**
 * Request biometric authentication. `reason` is the title shown in the
 * native sheet; `subtitle` is supplemental copy on platforms that
 * support it. Web fallback uses a WebAuthn `get()` challenge — the
 * caller must already have an enrolled credential on the device.
 */
export async function requestBiometricAuth(
  reason = "Unlock GlobeID",
  subtitle?: string,
): Promise<BiometricResult> {
  if (Capacitor.isNativePlatform()) {
    try {
      const mod = await import("@aparajita/capacitor-biometric-auth");
      await mod.BiometricAuth.authenticate({
        reason,
        cancelTitle: "Use PIN",
        allowDeviceCredential: true,
        iosFallbackTitle: "Use Passcode",
        androidTitle: reason,
        androidSubtitle: subtitle,
        androidConfirmationRequired: false,
      });
      return { ok: true, code: "ok" };
    } catch (err) {
      const e = err as { code?: string; message?: string };
      const code = e.code ?? "";
      if (code === "userCancel" || code === "appCancel") {
        return { ok: false, code: "cancelled", message: e.message };
      }
      if (code === "biometryLockout") {
        return { ok: false, code: "lockout", message: e.message };
      }
      if (code === "biometryNotEnrolled") {
        return { ok: false, code: "unenrolled", message: e.message };
      }
      if (code === "biometryNotAvailable") {
        return { ok: false, code: "unsupported", message: e.message };
      }
      return { ok: false, code: "failed", message: e.message };
    }
  }

  // Web fallback — best-effort WebAuthn discovery.
  if (typeof window === "undefined" || !("PublicKeyCredential" in window)) {
    return { ok: false, code: "unsupported" };
  }
  try {
    const challenge = new Uint8Array(32);
    crypto.getRandomValues(challenge);
    const cred = await navigator.credentials.get({
      publicKey: {
        challenge,
        timeout: 30_000,
        userVerification: "required",
        // Empty allowList → discoverable credentials only. If there's
        // no platform credential the call rejects, which we treat as
        // "unenrolled" / "unsupported" depending on the error.
        allowCredentials: [],
        rpId: window.location.hostname || undefined,
      },
    });
    return cred ? { ok: true, code: "ok" } : { ok: false, code: "failed" };
  } catch (err) {
    const e = err as DOMException & { name?: string };
    if (e.name === "NotAllowedError") return { ok: false, code: "cancelled" };
    if (e.name === "NotSupportedError") return { ok: false, code: "unsupported" };
    if (e.name === "InvalidStateError") return { ok: false, code: "unenrolled" };
    return { ok: false, code: "failed", message: e.message };
  }
}
