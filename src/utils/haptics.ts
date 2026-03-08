/**
 * Haptic feedback simulation for web
 * Uses Vibration API where available, falls back to visual/audio cues
 */

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

function vibrate(style: HapticStyle): void {
  if (typeof navigator !== "undefined" && "vibrate" in navigator) {
    try {
      navigator.vibrate(patterns[style]);
    } catch {
      // Vibration not supported or blocked
    }
  }
}

export const haptics = {
  light: () => vibrate("light"),
  medium: () => vibrate("medium"),
  heavy: () => vibrate("heavy"),
  success: () => vibrate("success"),
  warning: () => vibrate("warning"),
  error: () => vibrate("error"),
  selection: () => vibrate("selection"),
  /** Trigger on navigation changes */
  navigate: () => vibrate("light"),
  /** Trigger on payment actions */
  payment: () => vibrate("success"),
  /** Trigger on button press */
  tap: () => vibrate("selection"),
};
