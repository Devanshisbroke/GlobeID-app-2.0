/**
 * Slice-D — cross-platform still capture.
 *
 * Single function that returns a `Blob` regardless of platform:
 *  - Native Capacitor: uses `@capacitor/camera` to open the camera UI and
 *    receive a base64 JPEG.
 *  - Web: opens `<input type="file" accept="image/*" capture="environment">`
 *    which on Android/iOS Chrome and Safari surfaces the camera UI; on
 *    desktop it falls back to a file picker.
 *
 * Resolves `null` if the user cancels.
 */
import { Capacitor } from "@capacitor/core";

export async function capturePhoto(): Promise<Blob | null> {
  if (Capacitor.isNativePlatform()) {
    try {
      const mod = (await import("@capacitor/camera")) as typeof import("@capacitor/camera");
      const photo = await mod.Camera.getPhoto({
        quality: 85,
        allowEditing: false,
        resultType: mod.CameraResultType.DataUrl,
        source: mod.CameraSource.Camera,
        correctOrientation: true,
      });
      if (!photo.dataUrl) return null;
      return dataUrlToBlob(photo.dataUrl);
    } catch {
      return null;
    }
  }
  return webFilePick();
}

function webFilePick(): Promise<Blob | null> {
  return new Promise<Blob | null>((resolve) => {
    const input = document.createElement("input");
    input.type = "file";
    input.accept = "image/*";
    input.capture = "environment";
    input.onchange = () => {
      const file = input.files?.[0] ?? null;
      resolve(file);
    };
    input.oncancel = () => resolve(null);
    // Clicking triggers the OS sheet. On Android Chrome this shows the
    // camera directly; on desktop it opens a file dialog.
    input.click();
  });
}

function dataUrlToBlob(dataUrl: string): Blob {
  const [meta, b64] = dataUrl.split(",");
  const m = meta?.match(/data:(.+);base64/);
  const mime = m?.[1] ?? "image/jpeg";
  const bin = atob(b64 ?? "");
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return new Blob([bytes], { type: mime });
}
