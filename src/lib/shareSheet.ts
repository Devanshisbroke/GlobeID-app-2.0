/**
 * Cross-target share helper. Prefers the native OS share sheet via
 * `@capacitor/share` when running in a Capacitor shell, falls back to
 * the Web Share API on browsers that support it (Chrome Android, iOS
 * Safari, modern Edge), and finally falls back to a download trigger
 * via a temporary `<a download>` link so desktop browsers and old
 * webviews still get *something* useful.
 *
 * The Capacitor Share plugin is loaded dynamically so the dependency
 * is optional at install time — this lib also works on plain web
 * builds (e.g. Vercel preview).
 */
import { Capacitor } from "@capacitor/core";

export type ShareKind = "ics" | "text" | "url";

export interface ShareInput {
  /** Text shown by the OS share sheet. */
  title: string;
  /** Free-form body for `text` shares; ignored for `ics`. */
  text?: string;
  /** Destination URL for `url` shares; ignored for `ics`. */
  url?: string;
  /** Required for `ics` shares: full iCalendar payload. */
  icsContent?: string;
  /** Filename used by the download fallback. */
  filename?: string;
}

function downloadFallback(payload: string, filename: string, mime: string): void {
  const blob = new Blob([payload], { type: mime });
  const objectUrl = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = objectUrl;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  // Revoke after the click so the download is allowed to start first.
  setTimeout(() => URL.revokeObjectURL(objectUrl), 5_000);
}

/**
 * Trigger a native share sheet (Capacitor) → Web Share API → download
 * fallback chain. Returns the channel actually used so callers can
 * surface the right toast ("Shared", "Downloaded", etc).
 */
export async function shareOrDownload(
  kind: ShareKind,
  input: ShareInput,
): Promise<"native" | "web-share" | "download" | "skipped"> {
  // Capacitor native share
  if (Capacitor.isNativePlatform()) {
    try {
      const mod = await import("@capacitor/share");
      if (kind === "ics" && input.icsContent) {
        // Capacitor's Share plugin doesn't accept raw blobs across all
        // versions; instead, write the ICS to a tmp file via the
        // Filesystem plugin and share the resulting URI. Lazy-imported
        // so the dep is optional too.
        const fs = await import("@capacitor/filesystem");
        const filename = input.filename ?? "trip.ics";
        const written = await fs.Filesystem.writeFile({
          path: filename,
          data: input.icsContent,
          directory: fs.Directory.Cache,
          encoding: fs.Encoding.UTF8,
        });
        await mod.Share.share({
          title: input.title,
          text: input.text,
          url: written.uri,
          dialogTitle: input.title,
        });
        return "native";
      }
      if (kind === "text" || kind === "url") {
        await mod.Share.share({
          title: input.title,
          text: input.text,
          url: input.url,
          dialogTitle: input.title,
        });
        return "native";
      }
    } catch {
      // Fall through to web/download fallbacks.
    }
  }

  // Web Share API — only for text/url payloads. ICS shares fall through
  // because Web Share doesn't accept arbitrary file blobs reliably.
  if (
    (kind === "text" || kind === "url") &&
    typeof navigator !== "undefined" &&
    typeof navigator.share === "function"
  ) {
    try {
      await navigator.share({
        title: input.title,
        text: input.text,
        url: input.url,
      });
      return "web-share";
    } catch (err) {
      // User cancelled
      if (err instanceof DOMException && err.name === "AbortError") {
        return "skipped";
      }
      // Other failure — fall through to download.
    }
  }

  // Download fallback
  if (kind === "ics" && input.icsContent) {
    downloadFallback(
      input.icsContent,
      input.filename ?? "trip.ics",
      "text/calendar;charset=utf-8",
    );
    return "download";
  }

  if (kind === "text" || kind === "url") {
    const payload = [input.title, input.text, input.url].filter(Boolean).join("\n");
    if (typeof navigator !== "undefined" && navigator.clipboard) {
      try {
        await navigator.clipboard.writeText(payload);
        return "download";
      } catch {
        /* clipboard may be denied */
      }
    }
  }

  return "skipped";
}
