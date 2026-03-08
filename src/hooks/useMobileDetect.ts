/**
 * Detects if running inside a Capacitor/WebView or mobile browser.
 * Used for adaptive rendering (lower particle counts, DPR, etc.)
 */
export function isMobileDevice(): boolean {
  if (typeof navigator === "undefined") return false;
  return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
}

export function isCapacitor(): boolean {
  return typeof (window as any)?.Capacitor !== "undefined";
}

export function isMobileOrCapacitor(): boolean {
  return isMobileDevice() || isCapacitor();
}
