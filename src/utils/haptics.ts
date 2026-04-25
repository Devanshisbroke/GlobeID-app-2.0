/**
 * Haptic feedback for the GlobeID app.
 *
 * On Capacitor (Android / iOS native shell) we route through the
 * official `@capacitor/haptics` plugin, which maps to the iOS taptic
 * engine and Android's system HapticFeedback API for native-quality
 * feel. On web (and on Capacitor when the plugin call fails for any
 * reason) we fall back to the Vibration API with hand-tuned patterns.
 */

import { Haptics, ImpactStyle, NotificationType } from "@capacitor/haptics";
import { isCapacitor } from "@/hooks/useMobileDetect";

type HapticStyle = "light" | "medium" | "heavy" | "success" | "warning" | "error" | "selection";

const patterns: Record<HapticStyle, number[]> = {
  light: [8],
  medium: [15],
  heavy: [30],
  success: [10, 50, 10],
  warning: [15, 30, 15, 30, 15],
  error: [40, 50, 40],
  selection: [5],
};

function webVibrate(style: HapticStyle): void {
  if (typeof navigator !== "undefined" && "vibrate" in navigator) {
    try {
      navigator.vibrate(patterns[style]);
    } catch {
      /* Vibration not supported or blocked */
    }
  }
}

function fire(style: HapticStyle): void {
  if (isCapacitor()) {
    /* Fire-and-forget — the plugin returns a Promise we don't need
       to await, but we still want to fall back to web vibration if
       the call rejects (e.g. plugin not installed in the native shell). */
    const nativeCall = (() => {
      switch (style) {
        case "light":
        case "selection":
          return Haptics.impact({ style: ImpactStyle.Light });
        case "medium":
          return Haptics.impact({ style: ImpactStyle.Medium });
        case "heavy":
          return Haptics.impact({ style: ImpactStyle.Heavy });
        case "success":
          return Haptics.notification({ type: NotificationType.Success });
        case "warning":
          return Haptics.notification({ type: NotificationType.Warning });
        case "error":
          return Haptics.notification({ type: NotificationType.Error });
      }
    })();
    nativeCall?.catch(() => webVibrate(style));
    return;
  }
  webVibrate(style);
}

export const haptics = {
  light: () => fire("light"),
  medium: () => fire("medium"),
  heavy: () => fire("heavy"),
  success: () => fire("success"),
  warning: () => fire("warning"),
  error: () => fire("error"),
  selection: () => fire("selection"),
  /** Trigger on navigation changes */
  navigate: () => fire("light"),
  /** Trigger on payment actions */
  payment: () => fire("success"),
  /** Trigger on button press */
  tap: () => fire("selection"),
};
