/**
 * Slice-CDE — cross-platform permissions hook.
 *
 * Unifies the permission surface across:
 *  - web (`navigator.permissions.query` + implicit prompts on `getUserMedia`)
 *  - native Capacitor (`@capacitor/camera`, `@capacitor/geolocation`,
 *    `@capacitor-community/speech-recognition`, `@capacitor/local-notifications`)
 *
 * Returns a single `permissions` object and a `request(kind)` mutator that
 * kicks off the platform-appropriate prompt.
 */
import { useCallback, useEffect, useState } from "react";
import { Capacitor } from "@capacitor/core";

export type PermissionKind = "camera" | "microphone" | "geolocation" | "notifications";
export type PermissionState = "granted" | "denied" | "prompt" | "unsupported";
export type PermissionMap = Record<PermissionKind, PermissionState>;

const DEFAULT_STATE: PermissionMap = {
  camera: "prompt",
  microphone: "prompt",
  geolocation: "prompt",
  notifications: "prompt",
};

/** Web `PermissionName` values vary by browser; keep the list narrow. */
const WEB_PERM_NAMES: Partial<Record<PermissionKind, PermissionName>> = {
  camera: "camera" as PermissionName,
  microphone: "microphone" as PermissionName,
  geolocation: "geolocation" as PermissionName,
  notifications: "notifications" as PermissionName,
};

async function checkWeb(kind: PermissionKind): Promise<PermissionState> {
  if (typeof navigator === "undefined") return "unsupported";
  if (kind === "notifications" && "Notification" in window) {
    const p = Notification.permission;
    return p === "granted" ? "granted" : p === "denied" ? "denied" : "prompt";
  }
  if (!("permissions" in navigator)) return "prompt";
  const name = WEB_PERM_NAMES[kind];
  if (!name) return "unsupported";
  try {
    const s = await navigator.permissions.query({ name });
    return (s.state as PermissionState) ?? "prompt";
  } catch {
    return "prompt";
  }
}

async function requestWeb(kind: PermissionKind): Promise<PermissionState> {
  try {
    if (kind === "camera") {
      const stream = await navigator.mediaDevices.getUserMedia({ video: true });
      stream.getTracks().forEach((t) => t.stop());
      return "granted";
    }
    if (kind === "microphone") {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      stream.getTracks().forEach((t) => t.stop());
      return "granted";
    }
    if (kind === "geolocation") {
      return await new Promise<PermissionState>((resolve) => {
        navigator.geolocation.getCurrentPosition(
          () => resolve("granted"),
          (err) => resolve(err.code === err.PERMISSION_DENIED ? "denied" : "prompt"),
          { timeout: 5000 },
        );
      });
    }
    if (kind === "notifications" && "Notification" in window) {
      const p = await Notification.requestPermission();
      return p === "granted" ? "granted" : p === "denied" ? "denied" : "prompt";
    }
    return "unsupported";
  } catch {
    return "denied";
  }
}

async function checkNative(kind: PermissionKind): Promise<PermissionState> {
  try {
    if (kind === "camera") {
      const mod = (await import("@capacitor/camera")) as typeof import("@capacitor/camera");
      const r = await mod.Camera.checkPermissions();
      return r.camera === "granted" ? "granted" : r.camera === "denied" ? "denied" : "prompt";
    }
    if (kind === "microphone") {
      const mod = (await import("@capacitor-community/speech-recognition")) as {
        SpeechRecognition: { checkPermissions: () => Promise<{ speechRecognition: string }> };
      };
      const r = await mod.SpeechRecognition.checkPermissions();
      return r.speechRecognition === "granted"
        ? "granted"
        : r.speechRecognition === "denied"
          ? "denied"
          : "prompt";
    }
    if (kind === "geolocation") {
      const mod = (await import("@capacitor/geolocation")) as typeof import("@capacitor/geolocation");
      const r = await mod.Geolocation.checkPermissions();
      return r.location === "granted" ? "granted" : r.location === "denied" ? "denied" : "prompt";
    }
    if (kind === "notifications") {
      const mod = (await import("@capacitor/local-notifications")) as typeof import("@capacitor/local-notifications");
      const r = await mod.LocalNotifications.checkPermissions();
      return r.display === "granted" ? "granted" : r.display === "denied" ? "denied" : "prompt";
    }
    return "unsupported";
  } catch {
    return "unsupported";
  }
}

async function requestNative(kind: PermissionKind): Promise<PermissionState> {
  try {
    if (kind === "camera") {
      const mod = (await import("@capacitor/camera")) as typeof import("@capacitor/camera");
      const r = await mod.Camera.requestPermissions({ permissions: ["camera"] });
      return r.camera === "granted" ? "granted" : "denied";
    }
    if (kind === "microphone") {
      const mod = (await import("@capacitor-community/speech-recognition")) as {
        SpeechRecognition: {
          requestPermissions: () => Promise<{ speechRecognition: string }>;
        };
      };
      const r = await mod.SpeechRecognition.requestPermissions();
      return r.speechRecognition === "granted" ? "granted" : "denied";
    }
    if (kind === "geolocation") {
      const mod = (await import("@capacitor/geolocation")) as typeof import("@capacitor/geolocation");
      const r = await mod.Geolocation.requestPermissions();
      return r.location === "granted" ? "granted" : "denied";
    }
    if (kind === "notifications") {
      const mod = (await import("@capacitor/local-notifications")) as typeof import("@capacitor/local-notifications");
      const r = await mod.LocalNotifications.requestPermissions();
      return r.display === "granted" ? "granted" : "denied";
    }
    return "unsupported";
  } catch {
    return "denied";
  }
}

export interface UsePermissionsResult {
  permissions: PermissionMap;
  request: (kind: PermissionKind) => Promise<PermissionState>;
  refresh: () => Promise<void>;
  loading: boolean;
}

export function usePermissions(): UsePermissionsResult {
  const [permissions, setPermissions] = useState<PermissionMap>(DEFAULT_STATE);
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(async () => {
    const kinds: PermissionKind[] = ["camera", "microphone", "geolocation", "notifications"];
    const checker = Capacitor.isNativePlatform() ? checkNative : checkWeb;
    const results = await Promise.all(kinds.map((k) => checker(k).then((s) => [k, s] as const)));
    setPermissions(Object.fromEntries(results) as PermissionMap);
    setLoading(false);
  }, []);

  const request = useCallback(
    async (kind: PermissionKind): Promise<PermissionState> => {
      const req = Capacitor.isNativePlatform() ? requestNative : requestWeb;
      const result = await req(kind);
      setPermissions((p) => ({ ...p, [kind]: result }));
      return result;
    },
    [],
  );

  useEffect(() => {
    void refresh();
  }, [refresh]);

  return { permissions, request, refresh, loading };
}
